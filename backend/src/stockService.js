const { unitAllowsFraction } = require('./units');
const { ValidationError } = require('./validate');
// ─────────────────────────────────────────────────────────────────────────────
// Stock ledger.
//
// `Product.currentStock` is the running total; `stock_movements` is the
// append-only log that explains it. Every write goes through here so the two
// can never drift: a purchase adds stock, a sale removes it, and deleting
// either order reverses exactly the rows it created.
//
// All helpers take a Prisma transaction client (`tx`) so callers can bundle
// the order write and the stock write into one atomic operation.
// ─────────────────────────────────────────────────────────────────────────────

const { Prisma } = require('@prisma/client');

/// Takes a row lock on the products involved, for the rest of the transaction.
///
/// "Is there enough?" followed by "take it" is two steps. Without a lock, two
/// requests arriving together both ran the first step against the same numbers
/// and both passed — four simultaneous sales of 4 against a stock of 5 all
/// saved. With the lock the second request waits for the first to commit, then
/// checks against what is really left. Ids are locked in ascending order so two
/// requests touching the same products can't deadlock.
async function lockProducts(tx, productIds) {
  const ids = [...new Set(productIds)].filter((n) => Number.isInteger(n)).sort((a, b) => a - b);
  if (!ids.length || typeof tx.$queryRaw !== 'function') return;
  await tx.$queryRaw`SELECT id FROM products WHERE id IN (${Prisma.join(ids)}) ORDER BY id FOR UPDATE`;
}

class InsufficientStockError extends Error {
  constructor(details) {
    // Name the products in the message itself — the apps show err.message as
    // the toast, and "Insufficient stock" alone never said which product.
    const first = (details || [])
      .slice(0, 3)
      .map((d) => `${d.product}: only ${d.available} available, ${d.requested} requested`)
      .join('; ');
    super(first ? `Not enough stock — ${first}` : 'Insufficient stock');
    this.name = 'InsufficientStockError';
    this.details = details;
    this.status = 409;
  }
}

/// Collapses order items down to { productId, qty } totals, skipping rows that
/// aren't linked to a real product (free-typed lines) or have no quantity.
function toStockLines(items = []) {
  const byProduct = new Map();
  for (const item of items) {
    const productId = Number(item.productId);
    const qty = Number(item.qty);
    if (!Number.isInteger(productId) || productId <= 0) continue;
    if (!Number.isFinite(qty) || qty <= 0) continue;
    byProduct.set(productId, (byProduct.get(productId) || 0) + qty);
  }
  return [...byProduct.entries()].map(([productId, qty]) => ({ productId, qty }));
}

/// Applies stock lines in `direction` (+1 adds, -1 removes) and logs a movement
/// row for each. Throws InsufficientStockError when a removal would go
/// negative, so the surrounding transaction rolls back.

/// Moves a product's running total by [delta], floored at zero.
///
/// Physical stock cannot be negative — you cannot hold -2 kg of fibre. Two
/// paths could previously drive it below zero, because neither has a
/// shortfall check the way a sale does:
///
///   * reversing a received purchase whose goods have since been sold,
///   * deleting a manual adjustment whose quantity is no longer in stock.
///
/// The second one shipped a real -2 onto a dashboard. Both now stop at zero.
/// Read-modify-write rather than  because that is the only way to
/// apply the floor; it is safe here since every caller is already inside a
/// transaction.
/// Stock is kept to 3 decimals (grams of a kg, millimetres of a metre); this
/// strips the binary-float tail before it is stored or compared.
const round3 = (n) => Math.round(n * 1000) / 1000;

/// Refuses a fractional quantity on a product counted in whole units
/// (pieces, rolls, bags…) — see units.js. A measured unit (kg, m) may carry
/// decimals. [lines] are { productId, qty, product? }.
async function assertUnitQuantities(tx, lines) {
  const fractional = lines.filter(
    (l) => l.productId && Number(l.qty) !== Math.round(Number(l.qty))
  );
  if (!fractional.length) return;
  const products = await tx.product.findMany({
    where: { id: { in: fractional.map((l) => l.productId) } },
    select: { id: true, name: true, unit: true },
  });
  for (const p of products) {
    if (!unitAllowsFraction(p.unit)) {
      throw new ValidationError(
        `"${p.name}" is counted in ${p.unit || 'whole units'} — the quantity must be a whole number`
      );
    }
  }
}

async function shiftStock(tx, productId, delta) {
  const product = await tx.product.findUnique({
    where: { id: productId },
    select: { currentStock: true },
  });
  if (!product) return; // deleted since the movement was written
  const next = Math.max(0, round3(product.currentStock + delta));
  await tx.product.update({
    where: { id: productId },
    data: { currentStock: next, modifiedAt: new Date() },
  });
}

async function applyStock(tx, { lines, direction, type, refType, refId, reference, note = '', createdBy = 'Admin', rate = null }) {
  if (!lines.length) return [];

  if (direction < 0) await lockProducts(tx, lines.map((l) => l.productId));

  const products = await tx.product.findMany({
    where: { id: { in: lines.map((l) => l.productId) } },
    select: { id: true, name: true, currentStock: true },
  });
  const byId = new Map(products.map((p) => [p.id, p]));

  if (direction < 0) {
    const short = [];
    for (const line of lines) {
      const product = byId.get(line.productId);
      if (!product) continue;
      if (product.currentStock < line.qty) {
        short.push({
          productId: product.id,
          product: product.name,
          requested: line.qty,
          available: product.currentStock,
        });
      }
    }
    if (short.length) throw new InsufficientStockError(short);
  }

  const written = [];
  for (const line of lines) {
    if (!byId.has(line.productId)) continue; // product deleted since
    await tx.product.update({
      where: { id: line.productId },
      data: {
        currentStock: { increment: round3(direction * line.qty) },
        modifiedAt: new Date(),
      },
    });
    written.push(
      await tx.stockMovement.create({
        data: {
          productId: line.productId,
          type,
          qty: line.qty,
          rate,
          refType,
          refId: refId ?? null,
          reference,
          note,
          createdBy,
        },
      })
    );
  }
  return written;
}

/// Undoes every movement logged against a given order and deletes the log rows,
/// leaving currentStock exactly where it was before the order existed.
async function reverseStockFor(tx, refType, refId) {
  const movements = await tx.stockMovement.findMany({ where: { refType, refId } });
  for (const m of movements) {
    const delta = m.type === 'IN' ? -m.qty : m.qty;
    // Floored, and a product deleted since the movement was written is
    // skipped rather than failing the whole undo.
    await shiftStock(tx, m.productId, delta);
  }
  await tx.stockMovement.deleteMany({ where: { refType, refId } });
  return movements.length;
}

// ─────────────────────────────────────────────────────────────────────────────
// Delivery gating.
//
// Stock does not move when an order is written — it moves when the goods
// actually change hands. A purchase books its IN once it is "Received"; a sale
// books its OUT once it is "Delivered". Every other status (Pending, Partial,
// Confirmed, Processing, Shipped, Cancelled) leaves the ledger untouched, and
// moving back out of a delivered status reverses what was booked.
// ─────────────────────────────────────────────────────────────────────────────

const DELIVERED_STATUS = { purchase: 'Received', sale: 'Delivered' };

/// True when [status] is the one that means the goods have moved for [refType].
function movesStock(refType, status) {
  return String(status || '').trim() === DELIVERED_STATUS[refType];
}

/// Brings the ledger in line with an order's status: books the movements the
/// first time it reaches its delivered status, reverses them if it leaves that
/// status, and does nothing when the two already agree.
///
/// Callers that rewrote the order's items (PUT) pass `force: true`, having
/// already reversed the old rows, so the new lines are re-booked.
async function syncStockForStatus(
  tx,
  { refType, refId, status, lines, reference, note, createdBy, force = false }
) {
  const shouldHold = movesStock(refType, status);
  const booked = force
    ? 0
    : await tx.stockMovement.count({ where: { refType, refId } });

  if (shouldHold && booked === 0) {
    return applyStock(tx, {
      lines,
      direction: refType === 'purchase' ? +1 : -1,
      type: refType === 'purchase' ? 'IN' : 'OUT',
      refType,
      refId,
      reference,
      note,
      createdBy,
    });
  }
  if (!shouldHold && booked > 0) {
    await reverseStockFor(tx, refType, refId);
  }
  return [];
}

/// Sale statuses that no longer (or never will) hold stock back: Delivered has
/// already taken it out, Cancelled never will.
const SALE_SETTLED = ['Delivered', 'Cancelled'];

/// Units promised to customers but not yet delivered, per product.
///
/// A sale only takes stock out when it reaches "Delivered", so between saving
/// and delivering the goods are still in the warehouse yet already spoken for.
/// Without counting them, two open orders could each be checked against the
/// same 5 units and both pass, and the second one would then fail at delivery
/// (or, via the delivery sweep, fail every 15 minutes with nobody told).
///
/// [excludeSalesOrderId] leaves one order out — the one being edited, which
/// must not count against itself.
///
/// Returns Map<productId, quantity>.
async function committedByProduct(db, { excludeSalesOrderId = null } = {}) {
  const salesOrder = { status: { notIn: SALE_SETTLED } };
  if (excludeSalesOrderId != null) salesOrder.id = { not: excludeSalesOrderId };
  const rows = await db.saleItem.findMany({
    where: { productId: { not: null }, salesOrder },
    select: { productId: true, qty: true },
  });
  const byProduct = new Map();
  for (const r of rows) {
    byProduct.set(r.productId, (byProduct.get(r.productId) || 0) + Number(r.qty));
  }
  return byProduct;
}

/// Throws InsufficientStockError when the lines of an OPEN sale ask for more
/// than is free: in the warehouse, minus what other open sales already hold.
/// Delivered / Cancelled sales are not checked here — delivery has its own
/// check in applyStock, and a cancelled sale takes nothing.
async function assertSaleCoverable(db, { lines, status, excludeSalesOrderId = null }) {
  if (!lines.length || SALE_SETTLED.includes(String(status || '').trim())) return;
  await lockProducts(db, lines.map((l) => l.productId));
  const committed = await committedByProduct(db, { excludeSalesOrderId });
  const products = await db.product.findMany({
    where: { id: { in: lines.map((l) => l.productId) } },
    select: { id: true, name: true, currentStock: true },
  });
  const byId = new Map(products.map((p) => [p.id, p]));
  const short = [];
  for (const line of lines) {
    const p = byId.get(line.productId);
    if (!p) continue;
    const free = p.currentStock - (committed.get(p.id) || 0);
    if (line.qty > free) {
      short.push({
        productId: p.id,
        product: p.name,
        requested: line.qty,
        available: Math.max(free, 0),
      });
    }
  }
  if (short.length) throw new InsufficientStockError(short);
}

/// Derived status shown in the inventory list.
///
/// [lowStockThreshold] is the business-wide fallback from AppSetting — used
/// only when the product has no per-item minimumStock (<= 0). A product's own
/// minimumStock always wins; 0 threshold means "no global rule".
function stockStatus(product, lowStockThreshold = 0) {
  if (product.isActive === false) return 'inactive';
  if (product.currentStock <= 0) return 'outOfStock';
  const threshold = product.minimumStock > 0 ? product.minimumStock : lowStockThreshold;
  if (threshold > 0 && product.currentStock <= threshold) return 'lowStock';
  return 'inStock';
}

module.exports = {
  InsufficientStockError,
  toStockLines,
  applyStock,
  reverseStockFor,
  shiftStock,
  stockStatus,
  movesStock,
  syncStockForStatus,
  committedByProduct,
  assertSaleCoverable,
  lockProducts,
  assertUnitQuantities,
  round3,
  SALE_SETTLED,
  DELIVERED_STATUS,
};

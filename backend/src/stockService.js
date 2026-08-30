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

class InsufficientStockError extends Error {
  constructor(details) {
    super('Insufficient stock');
    this.name = 'InsufficientStockError';
    this.details = details;
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
async function applyStock(tx, { lines, direction, type, refType, refId, reference, note = '', createdBy = 'Admin', rate = null }) {
  if (!lines.length) return [];

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
        currentStock: { increment: direction * Math.round(line.qty) },
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
    const delta = m.type === 'IN' ? -Math.round(m.qty) : Math.round(m.qty);
    // The product may have been deleted; skip rather than fail the whole undo.
    const exists = await tx.product.findUnique({ where: { id: m.productId }, select: { id: true } });
    if (exists) {
      await tx.product.update({
        where: { id: m.productId },
        data: { currentStock: { increment: delta }, modifiedAt: new Date() },
      });
    }
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
  stockStatus,
  movesStock,
  syncStockForStatus,
  DELIVERED_STATUS,
};

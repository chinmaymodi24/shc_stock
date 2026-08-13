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
async function applyStock(tx, { lines, direction, type, refType, refId, reference, note = '', createdBy = 'Admin' }) {
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

/// Derived status shown in the inventory list.
function stockStatus(product) {
  if (product.isActive === false) return 'inactive';
  if (product.currentStock <= 0) return 'outOfStock';
  if (product.currentStock <= product.minimumStock) return 'lowStock';
  return 'inStock';
}

module.exports = {
  InsufficientStockError,
  toStockLines,
  applyStock,
  reverseStockFor,
  stockStatus,
};

const express = require('express');
const prisma = require('../prismaClient');
const {
  InsufficientStockError,
  applyStock,
  stockStatus,
} = require('../stockService');

const router = express.Router();

/// Inventory rows are products viewed through their stock. Purchases and sales
/// move the numbers automatically (see stockService); this route covers the
/// manual side — adjustments, and editing the reorder settings.
function toInventoryRow(p) {
  return {
    id: p.id,
    productId: p.id,
    code: p.sku,
    sku: p.sku,
    name: p.name,
    category: p.category ? p.category.name : '',
    subCategory: p.subCategory ? p.subCategory.name : '',
    unit: p.unit,
    stockInHand: p.currentStock,
    availableStock: p.currentStock,
    minimumStock: p.minimumStock,
    costPrice: p.costPrice,
    sellingPrice: p.sellingPrice,
    stockValue: Number((p.currentStock * p.costPrice).toFixed(2)),
    stockLocation: p.stockLocation,
    isActive: p.isActive,
    status: stockStatus(p),
    modifiedBy: p.modifiedBy,
    modifiedAt: p.modifiedAt,
  };
}

const productInclude = { category: true, subCategory: true };

// GET /api/inventory
router.get('/', async (req, res, next) => {
  try {
    // Newest activity first: whatever was last added or modified (a manual
    // adjustment, a purchase/sale movement, a reorder-setting edit) tops the
    // list. Rows that never carried a modifiedAt fall back to id order.
    const products = await prisma.product.findMany({
      orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
      include: productInclude,
    });
    res.json(products.map(toInventoryRow));
  } catch (err) {
    next(err);
  }
});

// GET /api/inventory/movements?productId=&limit=
router.get('/movements', async (req, res, next) => {
  try {
    const where = {};
    const productId = Number(req.query.productId);
    if (Number.isInteger(productId) && productId > 0) where.productId = productId;
    const take = Math.min(Number(req.query.limit) || 100, 500);
    const movements = await prisma.stockMovement.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take,
      include: { product: { select: { name: true, sku: true, unit: true } } },
    });
    res.json(movements);
  } catch (err) {
    next(err);
  }
});

// POST /api/inventory/adjust — the manual "insert" for inventory.
// { productId, type: 'IN' | 'OUT', qty, note }
router.post('/adjust', async (req, res, next) => {
  try {
    const productId = Number(req.body.productId);
    const qty = Number(req.body.qty);
    const type = String(req.body.type || 'IN').toUpperCase();
    // Optional — only set when the person doing the adjustment chose to
    // record a per-unit price (e.g. an opening-balance entry). Left null
    // otherwise, same as a purchase/sale movement's price living on the
    // order instead.
    let rate = null;
    if (req.body.rate !== undefined && req.body.rate !== null && req.body.rate !== '') {
      rate = Number(req.body.rate);
      if (!Number.isFinite(rate) || rate < 0) {
        return res.status(400).json({ error: 'rate must be 0 or more' });
      }
    }

    if (!Number.isInteger(productId) || productId <= 0) {
      return res.status(400).json({ error: 'productId is required' });
    }
    if (!Number.isFinite(qty) || qty <= 0) {
      return res.status(400).json({ error: 'qty must be greater than 0' });
    }
    if (type !== 'IN' && type !== 'OUT') {
      return res.status(400).json({ error: "type must be 'IN' or 'OUT'" });
    }

    const product = await prisma.product.findUnique({ where: { id: productId } });
    if (!product) return res.status(404).json({ error: 'Product not found' });

    const row = await prisma.$transaction(async (tx) => {
      const [movement] = await applyStock(tx, {
        lines: [{ productId, qty }],
        direction: type === 'IN' ? +1 : -1,
        type: 'ADJUST',
        refType: 'manual',
        refId: null,
        reference: req.body.reference || 'Manual adjustment',
        note: req.body.note || '',
        createdBy: req.body.createdBy || 'Admin',
        rate,
      });
      // ADJUST loses the direction, so keep it on the row for the ledger view.
      await tx.stockMovement.update({ where: { id: movement.id }, data: { type } });
      const fresh = await tx.product.findUnique({
        where: { id: productId },
        include: productInclude,
      });
      return { movementId: movement.id, item: toInventoryRow(fresh) };
    });
    res.status(201).json(row);
  } catch (err) {
    next(err);
  }
});

// PUT /api/inventory/:productId — reorder settings for a stock row.
// { minimumStock, stockLocation, isActive }
router.put('/:productId', async (req, res, next) => {
  try {
    const id = Number(req.params.productId);
    const data = { modifiedAt: new Date() };
    if (req.body.minimumStock !== undefined) {
      const min = Number(req.body.minimumStock);
      if (!Number.isFinite(min) || min < 0) {
        return res.status(400).json({ error: 'minimumStock must be 0 or more' });
      }
      data.minimumStock = Math.trunc(min);
    }
    if (req.body.stockLocation !== undefined) {
      data.stockLocation = String(req.body.stockLocation).trim();
    }
    if (req.body.isActive !== undefined) data.isActive = req.body.isActive === true;
    if (req.body.modifiedBy) data.modifiedBy = String(req.body.modifiedBy);

    const product = await prisma.product.update({
      where: { id },
      data,
      include: productInclude,
    });
    res.json(toInventoryRow(product));
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Product not found' });
    next(err);
  }
});

// DELETE /api/inventory/movements/:id — undo a manual adjustment. Only manual
// rows are deletable; purchase/sale movements are owned by their order and are
// reversed by deleting that order instead.
router.delete('/movements/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const movement = await prisma.stockMovement.findUnique({ where: { id } });
    if (!movement) return res.status(404).json({ error: 'Movement not found' });
    if (movement.refType !== 'manual') {
      return res.status(400).json({
        error: 'Only manual adjustments can be deleted here — delete the linked order instead',
      });
    }

    const item = await prisma.$transaction(async (tx) => {
      const delta = movement.type === 'IN' ? -Math.round(movement.qty) : Math.round(movement.qty);
      await tx.product.update({
        where: { id: movement.productId },
        data: { currentStock: { increment: delta }, modifiedAt: new Date() },
      });
      await tx.stockMovement.delete({ where: { id } });
      const fresh = await tx.product.findUnique({
        where: { id: movement.productId },
        include: productInclude,
      });
      return toInventoryRow(fresh);
    });
    res.json(item);
  } catch (err) {
    next(err);
  }
});

router.use((err, req, res, next) => {
  if (err instanceof InsufficientStockError) {
    return res.status(409).json({ error: err.message, details: err.details });
  }
  next(err);
});

module.exports = router;

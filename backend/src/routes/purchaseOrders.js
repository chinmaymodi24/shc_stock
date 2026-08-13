const express = require('express');
const prisma = require('../prismaClient');
const {
  InsufficientStockError,
  toStockLines,
  applyStock,
  reverseStockFor,
} = require('../stockService');

const router = express.Router();

const orderInclude = { items: true };
const REF_TYPE = 'purchase';

function toItemsData(items) {
  return (items || []).map((i) => ({
    productId: Number.isInteger(Number(i.productId)) && Number(i.productId) > 0
      ? Number(i.productId)
      : null,
    product: i.product || '',
    hsn: i.hsn || '',
    grade: i.grade || '',
    density: i.density || '',
    qty: Number(i.qty) || 0,
    unit: i.unit || '',
    rate: Number(i.rate) || 0,
  }));
}

function orderFields(body) {
  return {
    supplier: String(body.supplier || '').trim(),
    supplierIcon: body.supplierIcon || '',
    date: new Date(body.date),
    amount: Number(body.amount) || 0,
    status: body.status || 'Pending',
    modifiedBy: body.modifiedBy || 'Admin',
    modifiedAt: new Date(),
    supplierAddress: body.supplierAddress || '',
    buyerGst: body.buyerGst || '',
    pan: body.pan || '',
    invoiceNo: body.invoiceNo || '',
    invoiceDate: body.invoiceDate ? new Date(body.invoiceDate) : null,
    despatchThrough: body.despatchThrough || '',
    lrNo: body.lrNo || '',
    lrDate: body.lrDate ? new Date(body.lrDate) : null,
    vehicleNo: body.vehicleNo || '',
    freight: Number(body.freight) || 0,
    placeOfSupply: body.placeOfSupply || '',
    dueDate: body.dueDate ? new Date(body.dueDate) : null,
  };
}

function validate(body, { requirePoNumber }) {
  if (requirePoNumber && !String(body.poNumber || '').trim()) return 'poNumber is required';
  if (!String(body.supplier || '').trim()) return 'supplier is required';
  if (!body.date) return 'date is required';
  return null;
}

// GET /api/purchase-orders
router.get('/', async (req, res, next) => {
  try {
    const orders = await prisma.purchaseOrder.findMany({
      orderBy: { date: 'desc' },
      include: orderInclude,
    });
    res.json(orders);
  } catch (err) {
    next(err);
  }
});

// POST /api/purchase-orders — receiving goods, so every linked item adds stock.
router.post('/', async (req, res, next) => {
  try {
    const invalid = validate(req.body, { requirePoNumber: true });
    if (invalid) return res.status(400).json({ error: invalid });

    const items = toItemsData(req.body.items);
    const order = await prisma.$transaction(async (tx) => {
      const created = await tx.purchaseOrder.create({
        data: {
          ...orderFields(req.body),
          poNumber: String(req.body.poNumber).trim(),
          items: { create: items },
        },
        include: orderInclude,
      });
      await applyStock(tx, {
        lines: toStockLines(items),
        direction: +1,
        type: 'IN',
        refType: REF_TYPE,
        refId: created.id,
        reference: created.poNumber,
        note: `Purchase ${created.poNumber}`,
        createdBy: created.modifiedBy,
      });
      return created;
    });
    res.status(201).json(order);
  } catch (err) {
    if (err.code === 'P2002') return res.status(409).json({ error: 'PO number already exists' });
    next(err);
  }
});

// PUT /api/purchase-orders/:id — replaces the order and its items, reversing
// the old stock movements and applying the new ones in the same transaction.
router.put('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const invalid = validate(req.body, { requirePoNumber: false });
    if (invalid) return res.status(400).json({ error: invalid });

    const items = toItemsData(req.body.items);
    const order = await prisma.$transaction(async (tx) => {
      const existing = await tx.purchaseOrder.findUnique({ where: { id } });
      if (!existing) {
        const e = new Error('not found');
        e.code = 'P2025';
        throw e;
      }
      await reverseStockFor(tx, REF_TYPE, id);
      await tx.purchaseItem.deleteMany({ where: { purchaseOrderId: id } });

      const data = orderFields(req.body);
      const poNumber = String(req.body.poNumber || '').trim();
      if (poNumber) data.poNumber = poNumber;

      const updated = await tx.purchaseOrder.update({
        where: { id },
        data: { ...data, items: { create: items } },
        include: orderInclude,
      });
      await applyStock(tx, {
        lines: toStockLines(items),
        direction: +1,
        type: 'IN',
        refType: REF_TYPE,
        refId: id,
        reference: updated.poNumber,
        note: `Purchase ${updated.poNumber} (edited)`,
        createdBy: updated.modifiedBy,
      });
      return updated;
    });
    res.json(order);
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Purchase order not found' });
    if (err.code === 'P2002') return res.status(409).json({ error: 'PO number already exists' });
    next(err);
  }
});

// PATCH /api/purchase-orders/:id/status  { status: 'Received' }
router.patch('/:id/status', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const { status } = req.body;
    if (!status) return res.status(400).json({ error: 'status is required' });
    const order = await prisma.purchaseOrder.update({
      where: { id },
      data: { status },
      include: orderInclude,
    });
    res.json(order);
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Purchase order not found' });
    next(err);
  }
});

// DELETE /api/purchase-orders/:id — takes the received stock back out.
router.delete('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    await prisma.$transaction(async (tx) => {
      await reverseStockFor(tx, REF_TYPE, id);
      await tx.purchaseOrder.delete({ where: { id } });
    });
    res.status(204).send();
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Purchase order not found' });
    next(err);
  }
});

// Surfaces a stock shortfall as a 409 rather than a generic 500.
router.use((err, req, res, next) => {
  if (err instanceof InsufficientStockError) {
    return res.status(409).json({ error: err.message, details: err.details });
  }
  next(err);
});

module.exports = router;

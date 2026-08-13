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
const REF_TYPE = 'sale';

function toItemsData(items) {
  return (items || []).map((i) => ({
    productId: Number.isInteger(Number(i.productId)) && Number(i.productId) > 0
      ? Number(i.productId)
      : null,
    product: i.product || '',
    hsn: i.hsn || '',
    qty: Number(i.qty) || 0,
    unit: i.unit || '',
    rate: Number(i.rate) || 0,
  }));
}

function orderFields(body) {
  return {
    client: String(body.client || '').trim(),
    clientBadge: body.clientBadge || '',
    date: new Date(body.date),
    amount: Number(body.amount) || 0,
    status: body.status || 'Confirmed',
    paymentStatus: body.paymentStatus || 'Pending',
    modifiedBy: body.modifiedBy || 'Admin',
    modifiedAt: new Date(),
    clientAddress: body.clientAddress || '',
    buyerGstin: body.buyerGstin || '',
    pan: body.pan || '',
    invoiceNo: body.invoiceNo || '',
    invoiceDate: body.invoiceDate ? new Date(body.invoiceDate) : null,
    despatchedThrough: body.despatchedThrough || '',
    destination: body.destination || '',
  };
}

function validate(body, { requireSoNumber }) {
  if (requireSoNumber && !String(body.soNumber || '').trim()) return 'soNumber is required';
  if (!String(body.client || '').trim()) return 'client is required';
  if (!body.date) return 'date is required';
  return null;
}

// GET /api/sales-orders
router.get('/', async (req, res, next) => {
  try {
    const orders = await prisma.salesOrder.findMany({
      orderBy: { date: 'desc' },
      include: orderInclude,
    });
    res.json(orders);
  } catch (err) {
    next(err);
  }
});

// POST /api/sales-orders — goods going out, so every linked item removes stock.
// Rejected with 409 if any line would take a product below zero.
router.post('/', async (req, res, next) => {
  try {
    const invalid = validate(req.body, { requireSoNumber: true });
    if (invalid) return res.status(400).json({ error: invalid });

    const items = toItemsData(req.body.items);
    const order = await prisma.$transaction(async (tx) => {
      const created = await tx.salesOrder.create({
        data: {
          ...orderFields(req.body),
          soNumber: String(req.body.soNumber).trim(),
          items: { create: items },
        },
        include: orderInclude,
      });
      await applyStock(tx, {
        lines: toStockLines(items),
        direction: -1,
        type: 'OUT',
        refType: REF_TYPE,
        refId: created.id,
        reference: created.soNumber,
        note: `Sale ${created.soNumber}`,
        createdBy: created.modifiedBy,
      });
      return created;
    });
    res.status(201).json(order);
  } catch (err) {
    if (err.code === 'P2002') return res.status(409).json({ error: 'SO number already exists' });
    next(err);
  }
});

// PUT /api/sales-orders/:id — replaces the order and its items, reversing the
// old stock movements and applying the new ones in the same transaction.
router.put('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const invalid = validate(req.body, { requireSoNumber: false });
    if (invalid) return res.status(400).json({ error: invalid });

    const items = toItemsData(req.body.items);
    const order = await prisma.$transaction(async (tx) => {
      const existing = await tx.salesOrder.findUnique({ where: { id } });
      if (!existing) {
        const e = new Error('not found');
        e.code = 'P2025';
        throw e;
      }
      await reverseStockFor(tx, REF_TYPE, id);
      await tx.saleItem.deleteMany({ where: { salesOrderId: id } });

      const data = orderFields(req.body);
      const soNumber = String(req.body.soNumber || '').trim();
      if (soNumber) data.soNumber = soNumber;

      const updated = await tx.salesOrder.update({
        where: { id },
        data: { ...data, items: { create: items } },
        include: orderInclude,
      });
      await applyStock(tx, {
        lines: toStockLines(items),
        direction: -1,
        type: 'OUT',
        refType: REF_TYPE,
        refId: id,
        reference: updated.soNumber,
        note: `Sale ${updated.soNumber} (edited)`,
        createdBy: updated.modifiedBy,
      });
      return updated;
    });
    res.json(order);
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Sales order not found' });
    if (err.code === 'P2002') return res.status(409).json({ error: 'SO number already exists' });
    next(err);
  }
});

// PATCH /api/sales-orders/:id/status  { status?: 'Delivered', paymentStatus?: 'Paid' }
router.patch('/:id/status', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const { status, paymentStatus } = req.body;
    if (!status && !paymentStatus) {
      return res.status(400).json({ error: 'status or paymentStatus is required' });
    }
    const data = {};
    if (status) data.status = status;
    if (paymentStatus) data.paymentStatus = paymentStatus;
    const order = await prisma.salesOrder.update({
      where: { id },
      data,
      include: orderInclude,
    });
    res.json(order);
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Sales order not found' });
    next(err);
  }
});

// DELETE /api/sales-orders/:id — puts the sold stock back.
router.delete('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    await prisma.$transaction(async (tx) => {
      await reverseStockFor(tx, REF_TYPE, id);
      await tx.salesOrder.delete({ where: { id } });
    });
    res.status(204).send();
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Sales order not found' });
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

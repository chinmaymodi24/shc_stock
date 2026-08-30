const express = require('express');
const prisma = require('../prismaClient');
const {
  InsufficientStockError,
  toStockLines,
  reverseStockFor,
  syncStockForStatus,
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
    expectedDelivery: body.expectedDelivery ? new Date(body.expectedDelivery) : null,
    paymentType: body.paymentType || '',
    paidAmount: Number(body.paidAmount) || 0,
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
    // Last added / modified first — not the order date, so a freshly entered
    // or edited order tops the list even if it is back-dated.
    const orders = await prisma.salesOrder.findMany({
      orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
      include: orderInclude,
    });
    res.json(orders);
  } catch (err) {
    next(err);
  }
});

// POST /api/sales-orders — the stock OUT is booked only if the order is already
// marked "Delivered"; otherwise it waits for delivery (a manual status change,
// or the expectedDelivery sweep). Rejected with 409 if a booked line would take
// a product below zero.
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
      await syncStockForStatus(tx, {
        refType: REF_TYPE,
        refId: created.id,
        status: created.status,
        lines: toStockLines(items),
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

// PUT /api/sales-orders/:id — replaces the order and its items. Anything the
// old version had booked is reversed, and the new lines are booked again only
// if the order is (still) "Delivered".
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
      await syncStockForStatus(tx, {
        refType: REF_TYPE,
        refId: id,
        status: updated.status,
        lines: toStockLines(items),
        reference: updated.soNumber,
        note: `Sale ${updated.soNumber} (edited)`,
        createdBy: updated.modifiedBy,
        force: true,
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
    const data = { modifiedAt: new Date() };
    if (status) data.status = status;
    if (paymentStatus) data.paymentStatus = paymentStatus;
    // Reaching "Delivered" is what takes the goods out of stock; leaving it
    // puts them back.
    const order = await prisma.$transaction(async (tx) => {
      const updated = await tx.salesOrder.update({
        where: { id },
        data,
        include: orderInclude,
      });
      await syncStockForStatus(tx, {
        refType: REF_TYPE,
        refId: id,
        status: updated.status,
        lines: toStockLines(updated.items),
        reference: updated.soNumber,
        note: `Sale ${updated.soNumber} (${updated.status})`,
        createdBy: updated.modifiedBy,
      });
      return updated;
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

const express = require('express');
const prisma = require('../prismaClient');

const router = express.Router();

const TYPES = ['Inbound', 'Outbound'];
const STATUSES = ['Received', 'Shipped', 'Pending', 'Delivered'];

const str = (v, fallback = '') =>
  v === undefined || v === null ? fallback : String(v).trim();

function txnData(body) {
  const type = str(body.type);
  const status = str(body.status);
  return {
    item: str(body.item),
    type: TYPES.includes(type) ? type : 'Inbound',
    party: str(body.party),
    poNumber: str(body.poNumber),
    date: body.date ? new Date(body.date) : new Date(),
    status: STATUSES.includes(status) ? status : 'Pending',
    notes: str(body.notes),
    modifiedBy: str(body.modifiedBy, 'Admin') || 'Admin',
    modifiedAt: new Date(),
  };
}

function validate(body) {
  if (!str(body.item)) return 'item is required';
  if (!body.date) return 'date is required';
  const type = str(body.type);
  if (type && !TYPES.includes(type)) return `type must be one of ${TYPES.join(', ')}`;
  const status = str(body.status);
  if (status && !STATUSES.includes(status)) {
    return `status must be one of ${STATUSES.join(', ')}`;
  }
  return null;
}

// GET /api/transactions
router.get('/', async (req, res, next) => {
  try {
    const transactions = await prisma.transaction.findMany({
      orderBy: [{ date: 'desc' }, { id: 'desc' }],
    });
    res.json(transactions);
  } catch (err) {
    next(err);
  }
});

// POST /api/transactions
router.post('/', async (req, res, next) => {
  try {
    const invalid = validate(req.body);
    if (invalid) return res.status(400).json({ error: invalid });
    const txn = await prisma.transaction.create({ data: txnData(req.body) });
    res.status(201).json(txn);
  } catch (err) {
    next(err);
  }
});

// PUT /api/transactions/:id
router.put('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const invalid = validate(req.body);
    if (invalid) return res.status(400).json({ error: invalid });
    const txn = await prisma.transaction.update({
      where: { id },
      data: txnData(req.body),
    });
    res.json(txn);
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Transaction not found' });
    next(err);
  }
});

// PATCH /api/transactions/:id/status  { status: 'Delivered' }
router.patch('/:id/status', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const status = str(req.body.status);
    if (!STATUSES.includes(status)) {
      return res.status(400).json({ error: `status must be one of ${STATUSES.join(', ')}` });
    }
    const txn = await prisma.transaction.update({
      where: { id },
      data: { status, modifiedAt: new Date() },
    });
    res.json(txn);
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Transaction not found' });
    next(err);
  }
});

// DELETE /api/transactions/:id
router.delete('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    await prisma.transaction.delete({ where: { id } });
    res.status(204).send();
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Transaction not found' });
    next(err);
  }
});

module.exports = router;

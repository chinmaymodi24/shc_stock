const express = require('express');
const prisma = require('../prismaClient');
const { actorName } = require('../auth/middleware');
const { listResponse } = require('../pagination');

const router = express.Router();
router.param('id', require('../validate').idParam);
const V = require('../validate');
const { PAYMENT_MODES } = require('../salePayments');

const TYPES = ['Inbound', 'Outbound'];
const STATUSES = ['Received', 'Shipped', 'Pending', 'Delivered'];

const str = (v, fallback = '') =>
  v === undefined || v === null ? fallback : String(v).trim();

function txnData(body, actor) {
  const type = str(body.type);
  const status = str(body.status);
  return {
    item: V.text(body.item, 'item', { max: 200 }),
    type: TYPES.includes(type) ? type : 'Inbound',
    party: V.text(body.party, 'party', { max: 200 }),
    poNumber: V.text(body.poNumber, 'poNumber', { max: 60 }),
    date: V.date(body.date, 'date') || new Date(),
    status: STATUSES.includes(status) ? status : 'Pending',
    notes: V.text(body.notes, 'notes', { max: 1000 }),
    amount: V.money(body.amount, 'amount'),
    mode: V.oneOf(body.mode, 'mode', PAYMENT_MODES, { fallback: '' }),
    modifiedBy: actor,
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

/// Rows generated from an order (a payment on a sale, a paid purchase) belong
/// to that order: changing one here would leave the order saying something
/// else, so they are edited from the order. 404 when the row does not exist.
async function assertHandEntered(id) {
  const row = await prisma.transaction.findUnique({
    where: { id },
    select: { refType: true, poNumber: true },
  });
  if (!row) {
    const e = new Error('not found');
    e.code = 'P2025';
    throw e;
  }
  if (row.refType) {
    const what = row.refType === 'sale' ? 'sale' : 'purchase';
    const e = new Error(
      `This row comes from ${what} ${row.poNumber}. Change it from that ${what} instead.`,
    );
    e.status = 409;
    throw e;
  }
}

// GET /api/transactions
router.get('/', async (req, res, next) => {
  try {
    // Last added / modified first (updatedAt covers both).
    res.json(await listResponse({
      query: req.query,
      findMany: (page) => prisma.transaction.findMany({
        orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
        ...page,
      }),
      count: () => prisma.transaction.count(),
    }));
  } catch (err) {
    next(err);
  }
});

// POST /api/transactions
router.post('/', async (req, res, next) => {
  try {
    const invalid = validate(req.body);
    if (invalid) return res.status(400).json({ error: invalid });
    const txn = await prisma.transaction.create({ data: txnData(req.body, actorName(req)) });
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
    await assertHandEntered(id);
    const txn = await prisma.transaction.update({
      where: { id },
      data: txnData(req.body, actorName(req)),
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
    await assertHandEntered(id);
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
    await assertHandEntered(id);
    await prisma.transaction.delete({ where: { id } });
    res.status(204).send();
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Transaction not found' });
    next(err);
  }
});

module.exports = router;

const express = require('express');
const prisma = require('../prismaClient');
const { stampDone } = require('../doneDate');
const { nextNumber, createNumbered } = require('../docNumber');

/// Sales order series: SO/0001/26-27.
const SO_PREFIX = 'SO';
const { actorName } = require('../auth/middleware');
const { listResponse } = require('../pagination');
const {
  InsufficientStockError,
  toStockLines,
  reverseStockFor,
  syncStockForStatus,
  assertSaleCoverable,
  assertUnitQuantities,
} = require('../stockService');
const V = require('../validate');
const O = require('../orderValidation');
const P = require('../salePayments');

const router = express.Router();
router.param('id', require('../validate').idParam);

const orderInclude = {
  items: true,
  payments: { orderBy: [{ date: 'asc' }, { id: 'asc' }] },
};
const REF_TYPE = 'sale';
const SETTLED = new Set(['Delivered', 'Cancelled']);

/// Validates the whole body and returns what to store: the order columns plus
/// its lines. Throws ValidationError (-> 400) for anything not acceptable.
function parseOrder(body, actor, { requireSoNumber }) {
  if (!body || typeof body !== 'object') V.fail('request body is required');
  const items = O.orderLines(body.items);
  const { amount, paidAmount } = O.money(body, items);

  const date = V.date(body.date, 'date', { required: true });
  const invoiceDate = V.date(body.invoiceDate, 'invoiceDate');
  const expectedDelivery = V.date(body.expectedDelivery, 'expectedDelivery');
  O.notBefore(expectedDelivery, date, 'expectedDelivery', 'the order date');

  const soNumber = V.text(body.soNumber, 'soNumber', { required: requireSoNumber, max: 60 });
  const fields = {
    client: V.text(body.client, 'client', { required: true, max: 200 }),
    clientBadge: V.text(body.clientBadge, 'clientBadge', { max: 10 }),
    date,
    amount,
    status: V.oneOf(body.status, 'status', O.SALE_STATUSES, { fallback: 'Confirmed' }),
    paymentStatus: V.oneOf(body.paymentStatus, 'paymentStatus', O.PAYMENT_STATUSES, {
      fallback: 'Pending',
    }),
    modifiedBy: actor,
    modifiedAt: new Date(),
    clientAddress: V.text(body.clientAddress, 'clientAddress', { max: 500 }),
    buyerGstin: V.text(body.buyerGstin, 'buyerGstin', { max: 20 }),
    pan: V.text(body.pan, 'pan', { max: 20 }),
    invoiceNo: V.text(body.invoiceNo, 'invoiceNo', { max: 60 }),
    invoiceDate,
    despatchedThrough: V.text(body.despatchedThrough, 'despatchedThrough', { max: 100 }),
    destination: V.text(body.destination, 'destination', { max: 100 }),
    expectedDelivery,
    paymentType: V.oneOf(body.paymentType, 'paymentType', O.PAYMENT_TYPES, { fallback: '' }),
    // Buyer in another state: the order carries IGST, not CGST + SGST.
    interState: body.interState === true,
    paidAmount,
  };
  // Sent with its payments (the form does): those decide what was paid, and
  // the Payment column follows. Without them (an older client) paidAmount and
  // paymentStatus are taken as sent.
  const parsed = P.parsePayments(body.payments, amount);
  if (parsed) Object.assign(fields, P.paymentFields(amount, parsed.total, fields.paymentStatus));
  return { fields, items, soNumber, payments: parsed && parsed.payments };
}

// GET /api/sales-orders/next-number — what a new order would be numbered,
// for the form's "Invoice No." prefill. Declared before any /:id route.
router.get('/next-number', async (req, res, next) => {
  try {
    res.json({ number: await nextNumber(prisma.salesOrder, 'soNumber', SO_PREFIX) });
  } catch (err) {
    next(err);
  }
});

// GET /api/sales-orders
router.get('/', async (req, res, next) => {
  try {
    // Last added / modified first — not the order date, so a freshly entered
    // or edited order tops the list even if it is back-dated.
    res.json(await listResponse({
      query: req.query,
      findMany: (page) => prisma.salesOrder.findMany({
        orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
        include: orderInclude,
        ...page,
      }),
      count: () => prisma.salesOrder.count(),
    }));
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
    const { fields, items, soNumber: given, payments } = parseOrder(req.body, actorName(req), {
      requireSoNumber: false,
    });
    // Left blank, the server numbers the order (see docNumber.js).
    const order = await createNumbered({
      given,
      next: (skip) => nextNumber(prisma.salesOrder, 'soNumber', SO_PREFIX, { skip }),
      create: (soNumber) => prisma.$transaction(async (tx) => {
      // Decimals only for products measured in kg / m / … (units.js).
      await assertUnitQuantities(tx, items);
      // An open order holds its stock back from everyone else — refuse it now
      // rather than letting it fail at delivery.
      await assertSaleCoverable(tx, { lines: toStockLines(items), status: fields.status });
      const created = await tx.salesOrder.create({
        // No invoice number typed: the order's own number stands in.
        data: { ...fields, invoiceNo: fields.invoiceNo || soNumber, soNumber, deliveredAt: stampDone('Delivered', fields.status), items: { create: items } },
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
      if (payments) await P.writePayments(tx, created, payments);
      return tx.salesOrder.findUnique({ where: { id: created.id }, include: orderInclude });
    }),
    });
    res.status(201).json(order);
  } catch (err) {
    if (err.code === 'P2002') return res.status(409).json({ error: 'SO number already exists' });
    next(err);
  }
});

/// An invoice is a document the customer holds: once one is issued the sale
/// behind it must not change underneath it (a bill for ₹5,000 over a sale that
/// now says ₹9,000), and deleting the sale would silently take the bill with
/// it. Status and payment changes still go through PATCH.
async function assertNotBilled(tx, id, verb) {
  const bill = await tx.bill.findUnique({ where: { salesOrderId: id }, select: { invoiceNo: true } });
  if (bill) {
    const e = new Error(
      `This sale already has invoice ${bill.invoiceNo}, so it cannot be ${verb}. Cancel the sale instead.`,
    );
    e.status = 409;
    throw e;
  }
}

// PUT /api/sales-orders/:id — replaces the order and its items. Anything the
// old version had booked is reversed, and the new lines are booked again only
// if the order is (still) "Delivered".
router.put('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const { fields, items, soNumber, payments } = parseOrder(req.body, actorName(req), {
      requireSoNumber: false,
    });
    const order = await prisma.$transaction(async (tx) => {
      const existing = await tx.salesOrder.findUnique({ where: { id } });
      if (!existing) {
        const e = new Error('not found');
        e.code = 'P2025';
        throw e;
      }
      await assertNotBilled(tx, id, 'edited');
      await assertUnitQuantities(tx, items);
      await reverseStockFor(tx, REF_TYPE, id);
      await tx.saleItem.deleteMany({ where: { salesOrderId: id } });
      // The order being edited must not count against itself.
      await assertSaleCoverable(tx, {
        lines: toStockLines(items),
        status: fields.status,
        excludeSalesOrderId: id,
      });

      const data = { ...fields };
      if (soNumber) data.soNumber = soNumber;
      data.deliveredAt = stampDone('Delivered', fields.status, existing.status, existing.deliveredAt);

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
      if (payments) await P.writePayments(tx, updated, payments);
      else await P.refreshPaymentRows(tx, updated);
      return tx.salesOrder.findUnique({ where: { id }, include: orderInclude });
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
    const status = V.oneOf(req.body.status, 'status', O.SALE_STATUSES);
    const paymentStatus = V.oneOf(req.body.paymentStatus, 'paymentStatus', O.PAYMENT_STATUSES);
    if (!status && !paymentStatus) {
      return res.status(400).json({ error: 'status or paymentStatus is required' });
    }
    const order = await prisma.$transaction(async (tx) => {
      const before = await tx.salesOrder.findUnique({ where: { id }, include: orderInclude });
      if (!before) {
        const e = new Error('not found');
        e.code = 'P2025';
        throw e;
      }
      // Credited to whoever changed it, like every other write.
      const data = { modifiedBy: actorName(req), modifiedAt: new Date() };
      if (status) {
        data.status = status;
        data.deliveredAt = stampDone('Delivered', status, before.status, before.deliveredAt);
      }
      if (paymentStatus) {
        data.paymentStatus = paymentStatus;
        // Keep the money in step with the label: "Paid" means the whole amount
        // came in, "Pending" that none did. Receivables are worked out from
        // paidAmount, so a "Paid" order left at 0 paid still looked owed.
        if (paymentStatus === 'Paid') data.paidAmount = before.amount;
        if (paymentStatus === 'Pending') data.paidAmount = 0;
        // ...and the payment rows with it, so they still add up to paidAmount:
        // "Paid" books whatever was still due as one more payment, "Pending"
        // clears them.
        if (paymentStatus === 'Paid' && before.paymentStatus !== 'Paid') {
          const recorded = before.payments.reduce((sum, p) => sum + Number(p.amount), 0);
          data.paymentType = 'Full Payment';
          await P.recordBalance(tx, before, Number(before.amount) - recorded);
        }
        if (paymentStatus === 'Pending') {
          data.paymentType = '';
          await tx.transaction.deleteMany({ where: { salesOrderId: id } });
        }
      }
      // Re-opening a cancelled/delivered sale puts it back among the open ones,
      // so it has to fit in what is free like any new order.
      if (status && !SETTLED.has(status) && SETTLED.has(before.status) && status !== before.status) {
        await assertSaleCoverable(tx, {
          lines: toStockLines(before.items),
          status,
          excludeSalesOrderId: id,
        });
      }
      // Reaching "Delivered" is what takes the goods out of stock; leaving it
      // puts them back.
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
      return tx.salesOrder.findUnique({ where: { id }, include: orderInclude });
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
      await assertNotBilled(tx, id, 'deleted');
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

const express = require('express');
const prisma = require('../prismaClient');
const { actorName } = require('../auth/middleware');
const { listResponse } = require('../pagination');
const {
  InsufficientStockError,
  toStockLines,
  reverseStockFor,
  syncStockForStatus,
  assertUnitQuantities,
} = require('../stockService');
const V = require('../validate');
const O = require('../orderValidation');

const router = express.Router();
router.param('id', require('../validate').idParam);

const orderInclude = { items: true };
const { syncPurchaseTransaction, removePurchaseTransaction } = require('../paymentTransaction');
const { stampDone } = require('../doneDate');
const { nextNumber, createNumbered } = require('../docNumber');

/// Purchase order series: PO/0001/26-27.
const PO_PREFIX = 'PO';
const REF_TYPE = 'purchase';

/// Validates the whole body and returns what to store: the order columns plus
/// its lines. Throws ValidationError (-> 400) for anything not acceptable.
function parseOrder(body, actor, { requirePoNumber }) {
  if (!body || typeof body !== 'object') V.fail('request body is required');
  const items = O.orderLines(body.items, { extra: ['grade', 'density'] });
  const freight = V.money(body.freight, 'freight');
  const { amount, paidAmount } = O.money(body, items, { allowance: freight });

  const date = V.date(body.date, 'date', { required: true });
  const invoiceDate = V.date(body.invoiceDate, 'invoiceDate');
  const lrDate = V.date(body.lrDate, 'lrDate');
  const dueDate = V.date(body.dueDate, 'dueDate');
  const expectedDelivery = V.date(body.expectedDelivery, 'expectedDelivery');
  O.notBefore(expectedDelivery, date, 'expectedDelivery', 'the order date');
  O.notBefore(dueDate, invoiceDate || date, 'dueDate', 'the invoice date');

  const poNumber = V.text(body.poNumber, 'poNumber', { required: requirePoNumber, max: 60 });
  const fields = {
    supplier: V.text(body.supplier, 'supplier', { required: true, max: 200 }),
    supplierIcon: V.text(body.supplierIcon, 'supplierIcon', { max: 10 }),
    date,
    amount,
    status: V.oneOf(body.status, 'status', O.PURCHASE_STATUSES, { fallback: 'Pending' }),
    modifiedBy: actor,
    modifiedAt: new Date(),
    supplierAddress: V.text(body.supplierAddress, 'supplierAddress', { max: 500 }),
    buyerGst: V.text(body.buyerGst, 'buyerGst', { max: 20 }),
    pan: V.text(body.pan, 'pan', { max: 20 }),
    invoiceNo: V.text(body.invoiceNo, 'invoiceNo', { max: 60 }),
    invoiceDate,
    despatchThrough: V.text(body.despatchThrough, 'despatchThrough', { max: 100 }),
    lrNo: V.text(body.lrNo, 'lrNo', { max: 60 }),
    lrDate,
    vehicleNo: V.text(body.vehicleNo, 'vehicleNo', { max: 30 }),
    freight,
    placeOfSupply: V.text(body.placeOfSupply, 'placeOfSupply', { max: 100 }),
    dueDate,
    expectedDelivery,
    paymentType: V.oneOf(body.paymentType, 'paymentType', O.PAYMENT_TYPES, { fallback: '' }),
    // Supplier in another state: the order carries IGST, not CGST + SGST.
    interState: body.interState === true,
    paidAmount,
  };
  return { fields, items, poNumber };
}

// GET /api/purchase-orders/next-number — what a new order would be numbered,
// for the form's "Invoice No." prefill. Declared before any /:id route.
router.get('/next-number', async (req, res, next) => {
  try {
    res.json({ number: await nextNumber(prisma.purchaseOrder, 'poNumber', PO_PREFIX) });
  } catch (err) {
    next(err);
  }
});

// GET /api/purchase-orders
router.get('/', async (req, res, next) => {
  try {
    // Last added / modified first — not the order date, so a freshly entered
    // or edited PO tops the list even if it is back-dated.
    res.json(await listResponse({
      query: req.query,
      findMany: (page) => prisma.purchaseOrder.findMany({
        orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
        include: orderInclude,
        ...page,
      }),
      count: () => prisma.purchaseOrder.count(),
    }));
  } catch (err) {
    next(err);
  }
});

// POST /api/purchase-orders — the stock IN is booked only if the order is
// already marked "Received"; otherwise it waits for delivery (a manual status
// change, or the expectedDelivery sweep).
router.post('/', async (req, res, next) => {
  try {
    const { fields, items, poNumber: given } = parseOrder(req.body, actorName(req), {
      requirePoNumber: false,
    });
    // Left blank, the server numbers the order (see docNumber.js).
    const order = await createNumbered({
      given,
      next: (skip) => nextNumber(prisma.purchaseOrder, 'poNumber', PO_PREFIX, { skip }),
      create: (poNumber) => prisma.$transaction(async (tx) => {
      // Decimals only for products measured in kg / m / … (units.js).
      await assertUnitQuantities(tx, items);
      const created = await tx.purchaseOrder.create({
        // No invoice number typed: the order's own number stands in.
        data: { ...fields, invoiceNo: fields.invoiceNo || poNumber, poNumber, receivedAt: stampDone('Received', fields.status), items: { create: items } },
        include: orderInclude,
      });
      await syncStockForStatus(tx, {
        refType: REF_TYPE,
        refId: created.id,
        status: created.status,
        lines: toStockLines(items),
        reference: created.poNumber,
        note: `Purchase ${created.poNumber}`,
        createdBy: created.modifiedBy,
      });
      await syncPurchaseTransaction(tx, created);
      return created;
    }),
    });
    res.status(201).json(order);
  } catch (err) {
    if (err.code === 'P2002') return res.status(409).json({ error: 'PO number already exists' });
    next(err);
  }
});

// PUT /api/purchase-orders/:id — replaces the order and its items. Anything the
// old version had booked is reversed, and the new lines are booked again only
// if the order is (still) "Received".
router.put('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const { fields, items, poNumber } = parseOrder(req.body, actorName(req), {
      requirePoNumber: false,
    });
    const order = await prisma.$transaction(async (tx) => {
      const existing = await tx.purchaseOrder.findUnique({ where: { id } });
      if (!existing) {
        const e = new Error('not found');
        e.code = 'P2025';
        throw e;
      }
      await assertUnitQuantities(tx, items);
      await reverseStockFor(tx, REF_TYPE, id);
      await tx.purchaseItem.deleteMany({ where: { purchaseOrderId: id } });

      const data = { ...fields };
      if (poNumber) data.poNumber = poNumber;
      data.receivedAt = stampDone('Received', fields.status, existing.status, existing.receivedAt);

      const updated = await tx.purchaseOrder.update({
        where: { id },
        data: { ...data, items: { create: items } },
        include: orderInclude,
      });
      await syncStockForStatus(tx, {
        refType: REF_TYPE,
        refId: id,
        status: updated.status,
        lines: toStockLines(items),
        reference: updated.poNumber,
        note: `Purchase ${updated.poNumber} (edited)`,
        createdBy: updated.modifiedBy,
        force: true,
      });
      await syncPurchaseTransaction(tx, updated);
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
//
// This is the moment the goods arrive, so it is also the moment the stock is
// booked — and moving the order back off "Received" takes it out again.
router.patch('/:id/status', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const status = V.oneOf(req.body.status, 'status', O.PURCHASE_STATUSES, { required: true });
    const order = await prisma.$transaction(async (tx) => {
      const before = await tx.purchaseOrder.findUnique({ where: { id } });
      if (!before) {
        const e = new Error('not found');
        e.code = 'P2025';
        throw e;
      }
      const updated = await tx.purchaseOrder.update({
        where: { id },
        data: {
          status,
          modifiedAt: new Date(),
          receivedAt: stampDone('Received', status, before.status, before.receivedAt),
        },
        include: orderInclude,
      });
      await syncStockForStatus(tx, {
        refType: REF_TYPE,
        refId: id,
        status: updated.status,
        lines: toStockLines(updated.items),
        reference: updated.poNumber,
        note: `Purchase ${updated.poNumber} (${status})`,
        createdBy: updated.modifiedBy,
      });
      await syncPurchaseTransaction(tx, updated);
      return updated;
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
      await removePurchaseTransaction(tx, id);
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

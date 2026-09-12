const express = require('express');
const prisma = require('../prismaClient');

const router = express.Router();

// ─────────────────────────────────────────────────────────────────────────────
// Bills.
//
// A bill is the document raised against a sale. It holds the invoice number,
// the per-invoice display toggles, the e-Invoice registration (when there is
// one) and an append-only audit trail. Everything else the invoice prints —
// buyer, line items, amounts — is read from the sales order, so a corrected
// sale corrects its bill instead of leaving two versions of the truth.
// ─────────────────────────────────────────────────────────────────────────────

const str = (v, fallback = '') =>
  v === undefined || v === null ? fallback : String(v).trim();

const withRelations = {
  events: { orderBy: { at: 'asc' } },
};

/// Serialises a bill for the app. `salesOrderId` stays a number; dates go out
/// as ISO strings like every other route.
function shape(bill) {
  return {
    id: bill.id,
    salesOrderId: bill.salesOrderId,
    invoiceNo: bill.invoiceNo,
    issuedOn: bill.issuedOn,
    options: {
      showHsnSummary: bill.showHsnSummary,
      showBankDetails: bill.showBankDetails,
      showUpiQr: bill.showUpiQr,
      showEInvoice: bill.showEInvoice,
      showDeclaration: bill.showDeclaration,
    },
    eInvoice: {
      irn: bill.irn,
      ackNo: bill.ackNo,
      ackDate: bill.ackDate,
    },
    generatedBy: bill.generatedBy,
    events: (bill.events ?? []).map((e) => ({
      id: e.id,
      type: e.type,
      note: e.note,
      actor: e.actor,
      at: e.at,
    })),
  };
}

/// Next number in the billing series.
///
/// Format: `<PREFIX>/<seq>/<FY>` — "ST/0248/26-27". The sequence restarts each
/// financial year, which is what the year suffix is for, so the highest
/// existing number *within this year* is what gets incremented.
function financialYearLabel(date) {
  const startYear = date.getMonth() >= 3 ? date.getFullYear() : date.getFullYear() - 1;
  const a = String(startYear % 100).padStart(2, '0');
  const b = String((startYear + 1) % 100).padStart(2, '0');
  return `${a}-${b}`;
}

async function nextInvoiceNo(prefix, date) {
  const fy = financialYearLabel(date);
  const suffix = `/${fy}`;
  const existing = await prisma.bill.findMany({
    where: { invoiceNo: { endsWith: suffix } },
    select: { invoiceNo: true },
  });

  let max = 0;
  for (const row of existing) {
    // The middle group is the sequence: PREFIX/0248/26-27
    const parts = row.invoiceNo.split('/');
    if (parts.length < 3) continue;
    const n = parseInt(parts[parts.length - 2], 10);
    if (Number.isInteger(n) && n > max) max = n;
  }
  return `${prefix}/${String(max + 1).padStart(4, '0')}/${fy}`;
}

// ── GET /api/bills/summary — the Sale page's Billing card ──────────────────
// Declared before /:id so "summary" isn't read as an id.
router.get('/summary', async (req, res, next) => {
  try {
    const [totalSales, generated, withIrn] = await Promise.all([
      prisma.salesOrder.count(),
      prisma.bill.count(),
      prisma.bill.count({ where: { NOT: { irn: null } } }),
    ]);
    const latest = await prisma.bill.findFirst({
      orderBy: { issuedOn: 'desc' },
      select: { id: true, invoiceNo: true, salesOrderId: true },
    });
    res.json({
      generated,
      pending: Math.max(totalSales - generated, 0),
      irnRegistered: withIrn,
      irnTotal: generated,
      latest,
    });
  } catch (err) {
    next(err);
  }
});

// ── GET /api/bills/sale/:salesOrderId ──────────────────────────────────────
// Null (not 404) when the sale has never been billed — "no bill yet" is an
// ordinary state the bill screen handles, not an error.
router.get('/sale/:salesOrderId', async (req, res, next) => {
  try {
    const salesOrderId = Number(req.params.salesOrderId);
    if (!Number.isInteger(salesOrderId)) {
      return res.status(400).json({ error: 'salesOrderId must be a number' });
    }
    const bill = await prisma.bill.findUnique({
      where: { salesOrderId },
      include: withRelations,
    });
    res.json(bill ? shape(bill) : null);
  } catch (err) {
    next(err);
  }
});

// ── POST /api/bills  { salesOrderId, prefix?, actor? } ─────────────────────
// Generates the bill, or returns the existing one. Billing twice must not mint
// a second invoice number for the same sale.
router.post('/', async (req, res, next) => {
  try {
    const salesOrderId = Number(req.body.salesOrderId);
    if (!Number.isInteger(salesOrderId)) {
      return res.status(400).json({ error: 'salesOrderId is required' });
    }
    const order = await prisma.salesOrder.findUnique({
      where: { id: salesOrderId },
    });
    if (!order) return res.status(404).json({ error: 'Sales order not found' });

    const existing = await prisma.bill.findUnique({
      where: { salesOrderId },
      include: withRelations,
    });
    if (existing) return res.json(shape(existing));

    const prefix = str(req.body.prefix, 'INV').toUpperCase() || 'INV';
    const actor = str(req.body.actor, 'Admin') || 'Admin';
    const issuedOn = order.invoiceDate ?? new Date();

    // The sale may already carry an invoice number typed into the Add Sale
    // form; honour it rather than issuing a competing one.
    const invoiceNo = str(order.invoiceNo) || (await nextInvoiceNo(prefix, issuedOn));

    const bill = await prisma.bill.create({
      data: {
        salesOrderId,
        invoiceNo,
        issuedOn,
        generatedBy: actor,
        events: {
          create: [{ type: 'generated', actor, note: '' }],
        },
      },
      include: withRelations,
    });

    // Keep the sale's own invoice fields in step, so the sales list and the
    // exports show the number the bill was issued under.
    await prisma.salesOrder.update({
      where: { id: salesOrderId },
      data: { invoiceNo, invoiceDate: issuedOn },
    });

    res.status(201).json(shape(bill));
  } catch (err) {
    // Two clicks racing on the same sale: the unique constraint wins and we
    // hand back the bill that got there first.
    if (err.code === 'P2002') {
      const bill = await prisma.bill.findUnique({
        where: { salesOrderId: Number(req.body.salesOrderId) },
        include: withRelations,
      });
      if (bill) return res.json(shape(bill));
    }
    next(err);
  }
});

// ── PUT /api/bills/:id/options ─────────────────────────────────────────────
router.put('/:id/options', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id)) {
      return res.status(400).json({ error: 'id must be a number' });
    }
    const data = {};
    for (const key of [
      'showHsnSummary',
      'showBankDetails',
      'showUpiQr',
      'showEInvoice',
      'showDeclaration',
    ]) {
      if (req.body[key] !== undefined) data[key] = req.body[key] === true;
    }
    if (Object.keys(data).length === 0) {
      return res.status(400).json({ error: 'no option fields supplied' });
    }
    const bill = await prisma.bill.update({
      where: { id },
      data,
      include: withRelations,
    });
    res.json(shape(bill));
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Bill not found' });
    next(err);
  }
});

// ── POST /api/bills/:id/events  { type, note?, actor? } ────────────────────
const eventTypes = new Set([
  'generated',
  'irn_received',
  'sent_whatsapp',
  'sent_email',
  'payment_received',
  'printed',
  'downloaded',
]);

router.post('/:id/events', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id)) {
      return res.status(400).json({ error: 'id must be a number' });
    }
    const type = str(req.body.type);
    if (!eventTypes.has(type)) {
      return res.status(400).json({ error: `unknown event type "${type}"` });
    }
    await prisma.billEvent.create({
      data: {
        billId: id,
        type,
        note: str(req.body.note),
        actor: str(req.body.actor, 'Admin') || 'Admin',
      },
    });
    const bill = await prisma.bill.findUnique({
      where: { id },
      include: withRelations,
    });
    if (!bill) return res.status(404).json({ error: 'Bill not found' });
    res.status(201).json(shape(bill));
  } catch (err) {
    if (err.code === 'P2003') return res.status(404).json({ error: 'Bill not found' });
    next(err);
  }
});

// ── PUT /api/bills/:id/e-invoice  { irn, ackNo, ackDate } ──────────────────
// The hook an IRP integration would call. Nothing writes to it today, which is
// exactly why the invoice prints "Not registered" instead of inventing an IRN.
router.put('/:id/e-invoice', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const irn = str(req.body.irn);
    if (!irn) return res.status(400).json({ error: 'irn is required' });
    const ackDate = req.body.ackDate ? new Date(req.body.ackDate) : new Date();
    const bill = await prisma.bill.update({
      where: { id },
      data: { irn, ackNo: str(req.body.ackNo), ackDate },
      include: withRelations,
    });
    await prisma.billEvent.create({
      data: {
        billId: id,
        type: 'irn_received',
        actor: 'System',
        note: str(req.body.ackNo),
      },
    });
    res.json(shape(bill));
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Bill not found' });
    next(err);
  }
});

module.exports = router;

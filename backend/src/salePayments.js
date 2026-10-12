// ─────────────────────────────────────────────────────────────────────────────
// Payments on a sale.
//
// A sale can be paid in several goes (₹500 cash today, ₹700 by UPI next week).
// Each payment is one row in the Transactions list, linked to the sale by
// salesOrderId and showing the SO number, so the list reads as a ledger of
// what came in against which order.
//
// The payments are the truth: when a sale is saved with its `payments`, the
// order's paidAmount is their sum and its paymentStatus / paymentType follow
// from that sum. Everything that reports money (stats, reports, statements)
// keeps reading paidAmount, so it cannot disagree with the rows.
// ─────────────────────────────────────────────────────────────────────────────
const V = require('./validate');
const { describeItems } = require('./paymentTransaction');

const REF_TYPE = 'sale';
const PAYMENT_MODES = ['Cash', 'UPI', 'Bank Transfer', 'Cheque', 'Card', 'Other'];
const MAX_PAYMENTS = 100;

/// Rupees of slack for the sum against the order amount (GST is rounded to
/// whole rupees on screen) — the same allowance orderValidation.money() gives.
const TOLERANCE = 1;

const round2 = (n) => Math.round(n * 100) / 100;

/// Validates the `payments` list of a sale body. Returns null when the body
/// carries no list (an older client: the order's paidAmount is used as sent),
/// otherwise `{ payments, total }`. A row with neither an amount nor a note —
/// the empty row a form leaves at the bottom — is dropped.
function parsePayments(raw, orderAmount) {
  if (raw === undefined || raw === null) return null;
  if (!Array.isArray(raw)) V.fail('payments must be a list');
  if (raw.length > MAX_PAYMENTS) V.fail(`A sale can have at most ${MAX_PAYMENTS} payments`);

  const payments = [];
  raw.forEach((p, i) => {
    const n = i + 1;
    if (!p || typeof p !== 'object') V.fail(`Payment ${n} is not valid`);
    if (V.isBlank(p.amount) && V.isBlank(p.notes)) return;
    const amount = V.money(p.amount, `Payment ${n} amount`, { required: true });
    if (amount <= 0) V.fail(`Payment ${n} amount must be more than 0`);
    payments.push({
      amount,
      date: V.date(p.date, `Payment ${n} date`, { required: true }),
      mode: V.oneOf(p.mode, `Payment ${n} mode`, PAYMENT_MODES, { fallback: '' }),
      notes: V.text(p.notes, `Payment ${n} notes`, { max: 300 }),
    });
  });

  const total = round2(payments.reduce((s, p) => s + p.amount, 0));
  if (total > orderAmount + TOLERANCE) {
    V.fail(`Payments add up to ${total}, more than the sale amount (${orderAmount})`);
  }
  return { payments, total };
}

/// What the order columns become for [paid] out of [amount]. A sale marked
/// Refunded keeps that label — the money went back, whatever was received.
function paymentFields(amount, paid, requestedStatus) {
  const full = amount > 0 && paid + TOLERANCE >= amount;
  return {
    paidAmount: paid,
    paymentType: full ? 'Full Payment' : paid > 0 ? 'Other' : '',
    paymentStatus:
      requestedStatus === 'Refunded' ? 'Refunded' : full ? 'Paid' : paid > 0 ? 'Partial' : 'Pending',
  };
}

/// The Transactions columns a payment row copies from its sale.
function rowFromOrder(order) {
  return {
    item: describeItems(order.items, 'Sale').slice(0, 200),
    type: 'Outbound',
    party: order.client,
    poNumber: order.soNumber,
    status: 'Received',
    refType: REF_TYPE,
    refId: order.id,
    modifiedBy: order.modifiedBy || 'Admin',
    modifiedAt: new Date(),
  };
}

/// Replaces the payment rows of [order] (loaded with its items) by [payments].
async function writePayments(tx, order, payments) {
  await tx.transaction.deleteMany({ where: { salesOrderId: order.id } });
  if (!payments.length) return;
  const base = rowFromOrder(order);
  await tx.transaction.createMany({
    data: payments.map((p) => ({
      ...base,
      salesOrderId: order.id,
      amount: p.amount,
      date: p.date,
      mode: p.mode,
      notes: p.notes,
    })),
  });
}

/// After an edit that did not resend the payments: the rows keep their money
/// but follow the order's client, number and items.
function refreshPaymentRows(tx, order) {
  const { item, party, poNumber, modifiedBy } = rowFromOrder(order);
  return tx.transaction.updateMany({
    where: { salesOrderId: order.id },
    data: { item, party, poNumber, modifiedBy, modifiedAt: new Date() },
  });
}

/// "Mark as Paid" from the list: records whatever was still due as one more
/// payment, so the rows still add up to paidAmount.
async function recordBalance(tx, order, due, when = new Date()) {
  if (due <= 0) return;
  await tx.transaction.create({
    data: {
      ...rowFromOrder(order),
      salesOrderId: order.id,
      amount: round2(due),
      date: when,
      mode: '',
      notes: 'Balance — marked as paid',
    },
  });
}

module.exports = {
  REF_TYPE,
  PAYMENT_MODES,
  parsePayments,
  paymentFields,
  writePayments,
  refreshPaymentRows,
  recordBalance,
};

// ─────────────────────────────────────────────────────────────────────────────
// What a sales or purchase order has to look like to be saved.
//
// Both order types shared the same hole: every field was cast with
// `Number(x) || 0` / `x || ''`, so an order with a negative amount, no items, a
// status of "Banana" and ₹5,00,000 paid was accepted. The rules live here once
// and both routes use them.
// ─────────────────────────────────────────────────────────────────────────────
const V = require('./validate');

const SALE_STATUSES = ['Confirmed', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];
const PAYMENT_STATUSES = ['Pending', 'Partial', 'Paid', 'Refunded'];
const PURCHASE_STATUSES = ['Pending', 'Partial', 'Received', 'Cancelled'];
const PAYMENT_TYPES = ['', 'Full Payment', 'Half Payment', 'Other'];

/// Rupees of slack between what the form adds up to and what it sends —
/// GST is rounded to whole rupees on screen.
const AMOUNT_TOLERANCE = 1;

/// The order lines, validated. A line with nothing in it (no name, no quantity,
/// no rate — the empty row a form leaves at the bottom) is dropped; every
/// other line must be complete.
///
/// [extra] copies the type-specific text columns (grade, density…).
function orderLines(rawItems, { extra = [] } = {}) {
  if (rawItems === undefined || rawItems === null) V.fail('items are required');
  if (!Array.isArray(rawItems)) V.fail('items must be a list');
  if (rawItems.length > 500) V.fail('An order can have at most 500 lines');

  const lines = [];
  rawItems.forEach((raw, i) => {
    const n = i + 1;
    if (!raw || typeof raw !== 'object') V.fail(`Item ${n} is not valid`);
    const blank =
      V.isBlank(raw.product) &&
      V.isBlank(raw.productId) &&
      !Number(raw.qty) &&
      !Number(raw.rate);
    if (blank) return;

    const productId = V.optionalId(raw.productId, `Item ${n} productId`);
    const name = V.text(raw.product, `Item ${n} name`, { required: true, max: 200 });
    const line = {
      productId,
      product: name,
      hsn: V.text(raw.hsn, `Item ${n} HSN`, { max: 20 }),
      qty: V.lineQty(raw.qty, `Item ${n} (${name}) quantity`),
      unit: V.text(raw.unit, `Item ${n} unit`, { max: 40 }),
      rate: V.money(raw.rate, `Item ${n} (${name}) rate`),
      // GST percent on this line; a line sent without one is the usual 18%.
      taxPercent: V.number(raw.taxPercent, `Item ${n} (${name}) GST %`, {
        min: 0,
        max: 100,
        fallback: 18,
      }),
    };
    for (const k of extra) line[k] = V.text(raw[k], `Item ${n} ${k}`, { max: 100 });
    lines.push(line);
  });

  if (!lines.length) V.fail('Add at least one item to the order');
  return lines;
}

/// Sum of qty x rate across [lines].
const subtotal = (lines) =>
  Math.round(lines.reduce((s, l) => s + l.qty * l.rate, 0) * 100) / 100;

/// amount (tax included) and paidAmount, checked against the lines. [allowance]
/// is anything besides the lines that rides on the total (a purchase's freight).
///
///  * amount can't be below what the lines add up to — a negative or
///    understated total is a typo or a tampered request,
///  * nor wildly above it (GST alone can't double the bill),
///  * paid can't exceed the amount: an overpayment made the receivable
///    negative and still marked the order "Paid".
function money(body, lines, { allowance = 0 } = {}) {
  const base = subtotal(lines);
  const amount = V.money(body.amount, 'amount', { required: true });
  if (amount + AMOUNT_TOLERANCE < base) {
    V.fail(`amount (${amount}) is less than the items add up to (${base})`);
  }
  if (amount > base * 2 + allowance + AMOUNT_TOLERANCE) {
    V.fail(`amount (${amount}) is far more than the items add up to (${base})`);
  }
  const paidAmount = V.money(body.paidAmount, 'paidAmount');
  if (paidAmount > amount + AMOUNT_TOLERANCE) {
    V.fail(`paidAmount (${paidAmount}) is more than the order amount (${amount})`);
  }
  return { amount, paidAmount };
}

/// The calendar day of [d], for comparing dates without the time of day.
const day = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();

/// A later date field must not fall before [from].
function notBefore(later, from, laterName, fromName) {
  if (later && from && day(later) < day(from)) {
    V.fail(`${laterName} cannot be before ${fromName}`);
  }
}

module.exports = {
  SALE_STATUSES,
  PAYMENT_STATUSES,
  PURCHASE_STATUSES,
  PAYMENT_TYPES,
  orderLines,
  money,
  subtotal,
  notBefore,
};

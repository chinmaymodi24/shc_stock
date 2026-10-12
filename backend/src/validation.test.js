/* eslint-disable no-console */
// Request validation and the money maths. Run with:
//   node src/validation.test.js
// (No test runner in this project — plain asserts, non-zero exit on failure.)

const assert = require('assert');
const V = require('./validate');
const O = require('./orderValidation');
const M = require('./orderMath');

let passed = 0;
function test(name, fn) {
  try {
    fn();
    passed += 1;
  } catch (err) {
    console.error(`FAIL  ${name}\n      ${err.message}`);
    process.exitCode = 1;
  }
}

const rejects = (fn, pattern) =>
  assert.throws(fn, (e) => e instanceof V.ValidationError && pattern.test(e.message), `expected ${pattern}`);

// ── primitives ──────────────────────────────────────────────────────────────
test('money: rejects words, negatives, NaN, objects and absurd sizes', () => {
  rejects(() => V.money('abc', 'price'), /price must be a number/);
  rejects(() => V.money(-5, 'price'), /at least 0/);
  rejects(() => V.money({}, 'price'), /must be a number/);
  rejects(() => V.money([1], 'price'), /must be a number/);
  rejects(() => V.money(true, 'price'), /must be a number/);
  rejects(() => V.money(1e15, 'price'), /too large/);
  rejects(() => V.money('', 'price', { required: true }), /required/);
});

test('money: keeps two decimals and accepts numeric strings', () => {
  assert.strictEqual(V.money('12.345', 'p'), 12.35);
  assert.strictEqual(V.money(0, 'p'), 0);
  assert.strictEqual(V.money('', 'p'), 0);
});

test('date: rejects garbage and silly years, accepts ISO dates', () => {
  rejects(() => V.date('notadate', 'date'), /not a valid date/);
  rejects(() => V.date('1850-01-01', 'date'), /between the years/);
  rejects(() => V.date('', 'date', { required: true }), /required/);
  assert.strictEqual(V.date('', 'date'), null);
  assert.ok(V.date('2026-10-05T10:00:00.000Z', 'date') instanceof Date);
});

test('oneOf: case-insensitive, returns the canonical spelling, rejects strangers', () => {
  assert.strictEqual(V.oneOf('delivered', 'status', ['Delivered']), 'Delivered');
  rejects(() => V.oneOf('Banana', 'status', ['Delivered']), /status must be one of/);
  assert.strictEqual(V.oneOf('', 'status', ['A'], { fallback: 'A' }), 'A');
});

test('id: positive whole numbers only', () => {
  assert.strictEqual(V.id('7'), 7);
  rejects(() => V.id('abc'), /positive whole number/);
  rejects(() => V.id(0), /positive whole number/);
  rejects(() => V.id(1.5), /positive whole number/);
  assert.strictEqual(V.optionalId(''), null);
});

test('text: required, length-capped, no objects', () => {
  rejects(() => V.text('  ', 'name', { required: true }), /name is required/);
  rejects(() => V.text('x'.repeat(11), 'name', { max: 10 }), /at most 10/);
  rejects(() => V.text({ a: 1 }, 'name'), /must be text/);
  assert.strictEqual(V.text('  hi  ', 'name'), 'hi');
});

test('lineQty: positive, up to 3 decimals (the unit decides about fractions)', () => {
  rejects(() => V.lineQty(0, 'qty'), /greater than 0/);
  rejects(() => V.lineQty(-3, 'qty'), /at least 0/);
  assert.strictEqual(V.lineQty(2.5, 'qty'), 2.5);
  assert.strictEqual(V.lineQty(12.3456, 'qty'), 12.346);
  rejects(() => V.lineQty(1e9, 'qty'), /too large/);
});

test('units: measured units split, counted ones stay whole', () => {
  const { unitAllowsFraction } = require('./units');
  for (const u of ['Kilogram (kg)', 'Meter (m)', 'Square Meter (sqm)', 'Cubic Meter (m³)', 'Litre', '']) {
    assert.strictEqual(unitAllowsFraction(u), true, u);
  }
  for (const u of ['Piece (pcs)', 'Roll', 'Bag', 'Box', 'Set', 'NOS', 'PCS']) {
    assert.strictEqual(unitAllowsFraction(u), false, u);
  }
});

test('stockQty: 0 or more, 3 decimals', () => {
  assert.strictEqual(V.stockQty(12.5, 'min'), 12.5);
  assert.strictEqual(V.stockQty('', 'min', { fallback: 0 }), 0);
  rejects(() => V.stockQty(-1, 'min'), /at least 0/);
});

test('idParam: stops a non-numeric :id before it reaches the database', () => {
  let status = null;
  const res = { status: (s) => { status = s; return { json: () => {} }; } };
  let called = false;
  V.idParam({}, res, () => { called = true; }, 'abc');
  assert.strictEqual(status, 400);
  assert.strictEqual(called, false);
  V.idParam({}, res, () => { called = true; }, '12');
  assert.strictEqual(called, true);
});

// ── order lines + amounts ───────────────────────────────────────────────────
const line = (over = {}) => ({ productId: 1, product: 'Brick', qty: 2, rate: 100, unit: 'PCS', ...over });

test('orderLines: needs at least one real line', () => {
  rejects(() => O.orderLines([]), /at least one item/);
  rejects(() => O.orderLines(undefined), /items are required/);
  rejects(() => O.orderLines('x'), /must be a list/);
});

test('orderLines: drops the empty row a form leaves at the bottom', () => {
  const out = O.orderLines([line(), { product: '', qty: 0, rate: 0 }]);
  assert.strictEqual(out.length, 1);
});

test('orderLines: a half-filled line is an error, not silently dropped', () => {
  rejects(() => O.orderLines([line({ qty: 0 })]), /greater than 0/);
  rejects(() => O.orderLines([line({ product: '' })]), /name is required/);
  rejects(() => O.orderLines([line({ rate: -1 })]), /at least 0/);
});

test('orderLines: fractions pass here; the product unit is checked against the DB', () => {
  assert.strictEqual(O.orderLines([line({ qty: 2.5 })])[0].qty, 2.5);
  assert.strictEqual(O.orderLines([line({ productId: null, qty: 2.5 })])[0].qty, 2.5);
  assert.strictEqual(O.orderLines([line({ taxPercent: 5 })])[0].taxPercent, 5);
  assert.strictEqual(O.orderLines([line()])[0].taxPercent, 18, 'default 18%');
  rejects(() => O.orderLines([line({ taxPercent: 150 })]), /too large/);
});

test('money: amount may not undercut or wildly exceed the items', () => {
  const lines = O.orderLines([line()]); // 200
  assert.deepStrictEqual(O.money({ amount: 236, paidAmount: 0 }, lines), { amount: 236, paidAmount: 0 });
  rejects(() => O.money({ amount: -999 }, lines), /at least 0/);
  rejects(() => O.money({ amount: 100 }, lines), /less than the items/);
  rejects(() => O.money({ amount: 9000 }, lines), /far more/);
});

test('money: paid cannot exceed the amount', () => {
  const lines = O.orderLines([line()]);
  rejects(() => O.money({ amount: 236, paidAmount: 500000 }, lines), /more than the order amount/);
  assert.strictEqual(O.money({ amount: 236, paidAmount: 236 }, lines).paidAmount, 236);
});

test('money: a purchase freight allowance lifts the ceiling', () => {
  const lines = O.orderLines([line()]);
  assert.ok(O.money({ amount: 700, paidAmount: 0 }, lines, { allowance: 400 }));
  rejects(() => O.money({ amount: 700, paidAmount: 0 }, lines), /far more/);
});

test('notBefore: a due date before the order date is refused', () => {
  rejects(() => O.notBefore(new Date('2026-01-01'), new Date('2026-02-01'), 'dueDate', 'the invoice date'), /cannot be before/);
  O.notBefore(new Date('2026-02-01'), new Date('2026-02-01'), 'dueDate', 'x');
  O.notBefore(null, new Date(), 'a', 'b');
});

test('status lists match what the apps send', () => {
  assert.deepStrictEqual(O.SALE_STATUSES, ['Confirmed', 'Processing', 'Shipped', 'Delivered', 'Cancelled']);
  assert.deepStrictEqual(O.PURCHASE_STATUSES, ['Pending', 'Partial', 'Received', 'Cancelled']);
  assert.ok(O.PAYMENT_STATUSES.includes('Refunded'));
  assert.deepStrictEqual(O.PAYMENT_TYPES, ['', 'Full Payment', 'Half Payment', 'Other']);
});

// ── money maths ─────────────────────────────────────────────────────────────
test('owedOn: a part-paid order owes only the rest', () => {
  assert.strictEqual(M.owedOn({ amount: 50000, paidAmount: 25000, paymentStatus: 'Partial', status: 'Confirmed' }), 25000);
  assert.strictEqual(M.owedOn({ amount: 50000, paidAmount: 0, paymentStatus: 'Pending', status: 'Confirmed' }), 50000);
});

test('owedOn: Paid, Refunded and Cancelled orders owe nothing', () => {
  assert.strictEqual(M.owedOn({ amount: 50000, paidAmount: 0, paymentStatus: 'Paid', status: 'Delivered' }), 0);
  assert.strictEqual(M.owedOn({ amount: 50000, paymentStatus: 'Refunded', status: 'Delivered' }), 0);
  assert.strictEqual(M.owedOn({ amount: 50000, paymentStatus: 'Pending', status: 'Cancelled' }), 0);
});

test('receivedOn: a Paid order counts in full even if paidAmount was never filled', () => {
  assert.strictEqual(M.receivedOn({ amount: 900, paidAmount: 0, paymentStatus: 'Paid', status: 'Delivered' }), 900);
  assert.strictEqual(M.receivedOn({ amount: 900, paidAmount: 300, paymentStatus: 'Partial', status: 'Confirmed' }), 300);
  assert.strictEqual(M.receivedOn({ amount: 900, paidAmount: 5000, paymentStatus: 'Partial', status: 'Confirmed' }), 900);
});

test('payableOn: follows what was paid, not whether the goods arrived', () => {
  assert.strictEqual(M.payableOn({ amount: 1000, paidAmount: 400, status: 'Received' }), 600);
  assert.strictEqual(M.payableOn({ amount: 1000, paidAmount: 1000, status: 'Pending' }), 0);
  assert.strictEqual(M.payableOn({ amount: 1000, paidAmount: 0, status: 'Cancelled' }), 0);
});

test('sumBy adds with a function', () => {
  assert.strictEqual(M.sumBy([{ a: 1 }, { a: 2 }], (r) => r.a), 3);
});

console.log(`${passed} validation tests passed${process.exitCode ? ' (with failures)' : ''}`);

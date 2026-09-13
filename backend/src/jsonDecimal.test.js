const test = require('node:test');
const assert = require('node:assert');
const { Prisma } = require('@prisma/client');
const { decimalsToNumbers } = require('./decimalToNumber');
const { decimalJson } = require('./jsonDecimal');

const D = (v) => new Prisma.Decimal(v);

test('a bare Decimal becomes a number', () => {
  assert.strictEqual(decimalsToNumbers(D('2800.55')), 2800.55);
});

test('without this, JSON.stringify would have produced a string', () => {
  assert.equal(JSON.stringify({ amount: D('2800.55') }), '{"amount":"2800.55"}');
  assert.equal(JSON.stringify(decimalsToNumbers({ amount: D('2800.55') })), '{"amount":2800.55}');
});

test('Decimals nested in objects and arrays are all converted', () => {
  const payload = {
    amount: D('100.10'),
    items: [{ rate: D('1.5'), qty: D('2.000') }, { rate: D('0.25'), qty: D('4') }],
    meta: { nested: { deep: D('9.99') } },
  };
  assert.deepStrictEqual(decimalsToNumbers(payload), {
    amount: 100.1,
    items: [{ rate: 1.5, qty: 2 }, { rate: 0.25, qty: 4 }],
    meta: { nested: { deep: 9.99 } },
  });
});

test('the paged envelope is walked too', () => {
  const out = decimalsToNumbers({ items: [{ amount: D('5.5') }], page: 1, total: 1 });
  assert.strictEqual(out.items[0].amount, 5.5);
  assert.strictEqual(out.page, 1);
});

test('dates keep serializing as ISO strings, not numbers', () => {
  const d = new Date('2026-01-02T03:04:05.000Z');
  const out = decimalsToNumbers({ when: d });
  assert.strictEqual(out.when, d);
  assert.equal(JSON.stringify(out), '{"when":"2026-01-02T03:04:05.000Z"}');
});

test('null, primitives and empty containers survive untouched', () => {
  assert.strictEqual(decimalsToNumbers(null), null);
  assert.strictEqual(decimalsToNumbers(undefined), undefined);
  assert.strictEqual(decimalsToNumbers('x'), 'x');
  assert.strictEqual(decimalsToNumbers(7), 7);
  assert.deepStrictEqual(decimalsToNumbers([]), []);
});

test('a payload with no Decimal is handed back by identity, not rebuilt', () => {
  const payload = { a: 1, b: { c: 'two' }, d: [3] };
  assert.strictEqual(decimalsToNumbers(payload), payload);
});

test('the middleware converts whatever a route passes to res.json', () => {
  let sent;
  const res = { json: (b) => { sent = b; } };
  decimalJson({}, res, () => {});
  res.json({ total: D('12.34') });
  assert.deepStrictEqual(sent, { total: 12.34 });
});

test('Decimal arithmetic is exact where Float was not', () => {
  assert.equal(D('0.1').plus('0.2').toString(), '0.3');
  assert.notEqual(0.1 + 0.2, 0.3);
});

test('an aggregate payload converts, which is where a wrong total came from', () => {
  // groupBy/aggregate results are not model rows, so a per-field extension
  // never saw them: `0 + decimal` concatenated and the screen showed
  // 10000333833.33 where the answer was 1533.33.
  const groups = [
    { client: 'A', _sum: { amount: D('3000') }, _count: { _all: 1 } },
    { client: 'B', _sum: { amount: D('1500') }, _count: { _all: 1 } },
    { client: 'C', _sum: { amount: D('100') }, _count: { _all: 1 } },
  ];
  const clean = decimalsToNumbers(groups);
  const total = clean.reduce((s, g) => s + (g._sum.amount || 0), 0);
  assert.strictEqual(total, 4600);
  assert.strictEqual(typeof total, 'number');

  // What it did before the fix, for the record.
  const broken = groups.reduce((s, g) => s + (g._sum.amount || 0), 0);
  assert.strictEqual(typeof broken, 'string');
});

test('_avg and _count shapes survive too', () => {
  const agg = { _sum: { amount: D('4600') }, _avg: { amount: D('1533.33') }, _count: 3 };
  assert.deepStrictEqual(decimalsToNumbers(agg), {
    _sum: { amount: 4600 }, _avg: { amount: 1533.33 }, _count: 3,
  });
});

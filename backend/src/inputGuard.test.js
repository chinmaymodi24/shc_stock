/* eslint-disable no-console */
// Run with: node src/inputGuard.test.js
const assert = require('assert');
const { inputGuard, clean, InputError, MAX_TEXT } = require('./inputGuard');

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

test('NUL characters are removed from every string, however deep', () => {
  const out = clean({ name: 'a\u0000b', items: [{ note: '\u0000x' }], n: 5, ok: null });
  assert.deepStrictEqual(out, { name: 'ab', items: [{ note: 'x' }], n: 5, ok: null });
});

test('an over-long text value is refused', () => {
  assert.throws(() => clean({ note: 'x'.repeat(MAX_TEXT + 1) }), InputError);
  assert.doesNotThrow(() => clean({ note: 'x'.repeat(MAX_TEXT) }));
});

test('a base64 logo / signature may exceed the text limit', () => {
  const big = 'A'.repeat(MAX_TEXT * 5);
  assert.doesNotThrow(() => clean({ logoBase64: big, signatureBase64: big }));
  assert.throws(() => clean({ other: big }), InputError);
});

test('a deeply nested body is refused', () => {
  let deep = { v: 1 };
  for (let i = 0; i < 12; i += 1) deep = { child: deep };
  assert.throws(() => clean(deep), InputError);
});

test('middleware cleans body and query and passes errors to next()', () => {
  const req = { body: { name: 'a\u0000' }, query: { search: 'b\u0000c' } };
  let err = 'unset';
  inputGuard(req, {}, (e) => { err = e; });
  assert.strictEqual(err, undefined);
  assert.strictEqual(req.body.name, 'a');
  assert.strictEqual(req.query.search, 'bc');

  const bad = { body: { x: 'y'.repeat(MAX_TEXT + 5) }, query: {} };
  inputGuard(bad, {}, (e) => { err = e; });
  assert.ok(err instanceof InputError);
  assert.strictEqual(err.status, 400);
});

console.log(`inputGuard: ${passed} passed`);

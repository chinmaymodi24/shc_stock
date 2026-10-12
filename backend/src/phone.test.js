const test = require('node:test');
const assert = require('node:assert');
const { normalisePhone } = require('./phone');

// Phones are stored as a bare 10-digit number. What arrives may not be: the
// old seed data wrote "+91 98765 00001", and the forms that later loaded such
// a row rejected it against their own 10-digit rule.
test('a plain 10-digit number is left alone', () => {
  assert.strictEqual(normalisePhone('9714888466'), '9714888466');
});

test('separators and the country code are stripped', () => {
  for (const input of [
    '+91 97148 88466',
    '+91-97148-88466',
    '+919714888466',
    '91 9714888466',
    '(+91) 97148 88466',
  ]) {
    assert.strictEqual(normalisePhone(input), '9714888466', input);
  }
});

test('a trunk prefix is stripped too', () => {
  assert.strictEqual(normalisePhone('09714888466'), '9714888466');
  assert.strictEqual(normalisePhone('+91 0 9714888466'), '9714888466');
});

test('empty and nullish come back empty, not "null"', () => {
  assert.strictEqual(normalisePhone(''), '');
  assert.strictEqual(normalisePhone(null), '');
  assert.strictEqual(normalisePhone(undefined), '');
  assert.strictEqual(normalisePhone('   '), '');
});

test('a short number is returned as its digits, not padded or invented', () => {
  assert.strictEqual(normalisePhone('98765'), '98765');
  assert.strictEqual(normalisePhone('abc'), '');
});

test('prefixes are stripped repeatedly, then the first ten are kept', () => {
  assert.strictEqual(normalisePhone('00919714888466'), '9714888466');
  // Nothing left to strip: an eleventh digit is dropped rather than shifting
  // the number, which is what makes the same rule safe on every keystroke.
  assert.strictEqual(normalisePhone('97148884669'), '9714888466');
});

test('a 10-digit number that happens to start with 91 survives', () => {
  // The country-code strip only applies when there are digits to spare.
  assert.strictEqual(normalisePhone('9198765432'), '9198765432');
});

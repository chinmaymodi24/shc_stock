/* eslint-disable no-console */
// Run with: node src/timezone.test.js
// A UTC host must still see the business day in Indian time.
process.env.TZ = 'UTC';
delete process.env.BUSINESS_TZ;
const assert = require('assert');
const { BUSINESS_TZ } = require('./timezone');

assert.strictEqual(BUSINESS_TZ, 'Asia/Kolkata');
assert.strictEqual(process.env.TZ, 'Asia/Kolkata');

// 20:00 UTC on 9 Oct is 01:30 IST on 10 Oct.
const d = new Date('2026-10-09T20:00:00Z');
assert.strictEqual(d.getDate(), 10);
assert.strictEqual(d.getHours(), 1);
assert.strictEqual(d.getMinutes(), 30);

// End of the business day is 23:59:59.999 IST = 18:29:59.999 UTC.
const end = new Date(2026, 9, 10);
end.setHours(23, 59, 59, 999);
assert.strictEqual(end.toISOString(), '2026-10-10T18:29:59.999Z');

console.log('timezone: 4 passed');

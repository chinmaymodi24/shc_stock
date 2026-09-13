const test = require('node:test');
const assert = require('node:assert');
const {
  retryAfterMs, recordFailure, recordSuccess, reset, MAX_FAILURES, WINDOW_MS, LOCK_MS,
} = require('./rateLimit');

const IP = ['ip:1.2.3.4'];
const BOTH = ['ip:1.2.3.4', 'account:a@b.com'];

test.beforeEach(reset);

test('a caller under the limit is never delayed', () => {
  for (let i = 0; i < MAX_FAILURES - 1; i++) recordFailure(IP);
  assert.equal(retryAfterMs(IP), 0);
});

test('the bucket locks on the failure that reaches the limit', () => {
  for (let i = 0; i < MAX_FAILURES; i++) recordFailure(IP);
  const wait = retryAfterMs(IP);
  assert.ok(wait > 0, 'should be locked');
  assert.ok(wait <= LOCK_MS);
});

test('a successful sign-in clears the counters', () => {
  for (let i = 0; i < MAX_FAILURES; i++) recordFailure(BOTH);
  assert.ok(retryAfterMs(BOTH) > 0);
  recordSuccess(BOTH);
  assert.equal(retryAfterMs(BOTH), 0);
});

test('failures older than the window stop counting', () => {
  const old = Date.now() - WINDOW_MS - 1000;
  for (let i = 0; i < MAX_FAILURES; i++) recordFailure(IP, old);
  // Those are all outside the window now, so nothing has accumulated.
  assert.equal(retryAfterMs(IP), 0);
});

test('the lock lifts once it expires', () => {
  const then = Date.now() - LOCK_MS - 1000;
  for (let i = 0; i < MAX_FAILURES; i++) recordFailure(IP, then);
  assert.equal(retryAfterMs(IP), 0);
});

test('one account is locked across callers, and one caller across accounts', () => {
  // A botnet: many IPs, all pushing at the same inbox.
  for (let i = 0; i < MAX_FAILURES; i++) recordFailure([`ip:10.0.0.${i}`, 'account:victim@x.com']);
  assert.ok(retryAfterMs(['ip:10.0.0.99', 'account:victim@x.com']) > 0, 'account should lock');

  reset();
  // One host walking a list of accounts.
  for (let i = 0; i < MAX_FAILURES; i++) recordFailure(['ip:9.9.9.9', `account:u${i}@x.com`]);
  assert.ok(retryAfterMs(['ip:9.9.9.9', 'account:fresh@x.com']) > 0, 'ip should lock');
});

test('locking one key leaves unrelated keys alone', () => {
  for (let i = 0; i < MAX_FAILURES; i++) recordFailure(IP);
  assert.ok(retryAfterMs(IP) > 0);
  assert.equal(retryAfterMs(['ip:5.6.7.8']), 0);
});

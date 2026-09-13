// ─────────────────────────────────────────────────────────────────────────────
// Brute-force brake for the sign-in endpoint.
//
// Sign-in was the one unauthenticated write in the app, and it had no brake at
// all: a script could try passwords as fast as the network allowed.
//
// Counting happens per IP *and* per account, because the two attacks look
// different. One host grinding through a password list is caught by the IP
// bucket; a botnet spread across many hosts all pushing at one inbox is caught
// by the account bucket. A successful sign-in clears both.
//
// State lives in memory, so it resets when the server restarts and is per
// process. That is the right trade for a single-node deployment and no new
// dependency; a multi-node one would move these buckets into the database or
// a shared cache.
// ─────────────────────────────────────────────────────────────────────────────

/// How many failures a bucket tolerates before it locks.
const MAX_FAILURES = 8;
/// Failures older than this stop counting, so an honest typo years apart never
/// accumulates into a lockout.
const WINDOW_MS = 15 * 60 * 1000;
/// How long a tripped bucket stays locked.
const LOCK_MS = 15 * 60 * 1000;
/// Buckets untouched for this long are dropped, so the map cannot grow without
/// bound on a long-running server.
const IDLE_MS = 60 * 60 * 1000;

const buckets = new Map(); // key -> { failures: number[], lockedUntil: number }

function sweep(now) {
  for (const [key, b] of buckets) {
    const last = Math.max(b.lockedUntil, b.failures[b.failures.length - 1] || 0);
    if (now - last > IDLE_MS) buckets.delete(key);
  }
}

let lastSweep = 0;

function bucketFor(key, now) {
  let b = buckets.get(key);
  if (!b) {
    b = { failures: [], lockedUntil: 0 };
    buckets.set(key, b);
  }
  b.failures = b.failures.filter((t) => now - t < WINDOW_MS);
  return b;
}

/// Milliseconds until `keys` are allowed to try again, or 0 when they may.
function retryAfterMs(keys, now = Date.now()) {
  if (now - lastSweep > IDLE_MS) {
    sweep(now);
    lastSweep = now;
  }
  let wait = 0;
  for (const key of keys) {
    const b = bucketFor(key, now);
    if (b.lockedUntil > now) wait = Math.max(wait, b.lockedUntil - now);
  }
  return wait;
}

/// Records one failed attempt against every key, locking those that tip over.
function recordFailure(keys, now = Date.now()) {
  for (const key of keys) {
    const b = bucketFor(key, now);
    b.failures.push(now);
    if (b.failures.length >= MAX_FAILURES) {
      b.lockedUntil = now + LOCK_MS;
      b.failures = [];
    }
  }
}

/// Clears the keys after a genuine sign-in.
function recordSuccess(keys) {
  for (const key of keys) buckets.delete(key);
}

/// Test seam.
function reset() {
  buckets.clear();
  lastSweep = 0;
}

module.exports = {
  retryAfterMs,
  recordFailure,
  recordSuccess,
  reset,
  MAX_FAILURES,
  WINDOW_MS,
  LOCK_MS,
};

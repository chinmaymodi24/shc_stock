const crypto = require('crypto');

// ─────────────────────────────────────────────────────────────────────────────
// Signed session tokens — HMAC-SHA256 over a small JSON payload, built on
// Node's crypto so no new dependency is needed.
//
// The token only proves WHO is calling. What they may do is looked up fresh
// from the database on each request (see middleware.js), so revoking a
// permission takes effect without waiting for the token to expire.
// ─────────────────────────────────────────────────────────────────────────────

/// 30 days — long enough that "Remember me" means something, short enough
/// that a lost device doesn't hold a session forever. /api/auth/me hands out a
/// fresh token each time the app starts.
const TTL_MS = 30 * 24 * 60 * 60 * 1000;

/// AUTH_SECRET should be set in production. The fallback is derived from the
/// database URL so a dev machine gets a stable secret (tokens survive a
/// nodemon restart) without committing one to the repo.
function secret() {
  if (process.env.AUTH_SECRET) return process.env.AUTH_SECRET;
  return crypto
    .createHash('sha256')
    .update(`shc-stock:${process.env.DATABASE_URL || 'local'}`)
    .digest('hex');
}

const b64url = (buf) => Buffer.from(buf).toString('base64url');

function sign(userId) {
  const payload = b64url(JSON.stringify({ uid: userId, exp: Date.now() + TTL_MS }));
  const mac = crypto.createHmac('sha256', secret()).update(payload).digest('base64url');
  return `${payload}.${mac}`;
}

/// The user id inside a valid, unexpired token — or null.
function verify(token) {
  if (typeof token !== 'string') return null;
  const [payload, mac] = token.split('.');
  if (!payload || !mac) return null;

  const expected = crypto.createHmac('sha256', secret()).update(payload).digest();
  const given = Buffer.from(mac, 'base64url');
  if (given.length !== expected.length || !crypto.timingSafeEqual(given, expected)) {
    return null;
  }

  try {
    const { uid, exp } = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
    if (!Number.isInteger(uid) || typeof exp !== 'number' || exp < Date.now()) return null;
    return uid;
  } catch (_) {
    return null;
  }
}

module.exports = { sign, verify };

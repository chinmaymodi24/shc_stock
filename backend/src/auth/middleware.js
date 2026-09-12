const prisma = require('../prismaClient');
const { verify } = require('./token');
const { allows } = require('../permissions');
const { isPublic, requirementFor } = require('./policy');

// ─────────────────────────────────────────────────────────────────────────────
// Request guard for everything under /api.
//
// 1. Resolves the Bearer token to an active employee (req.auth).
// 2. Checks the permission the request needs (see policy.js).
//
// The employee is re-read from the database rather than trusted from the
// token, so a permission revoked or an account deactivated takes effect
// within [CACHE_MS] — not whenever the token happens to expire.
// ─────────────────────────────────────────────────────────────────────────────

const CACHE_MS = 10 * 1000;
const cache = new Map(); // userId → { principal, at }

/// Drops cached employees — call after changing a user or a role.
function invalidatePrincipal(userId) {
  if (userId === undefined) cache.clear();
  else cache.delete(Number(userId));
}

function toPrincipal(user) {
  const isSuperAdmin = !!(user.roleRef && user.roleRef.isSuperAdmin);
  const permissions = user.permissions && typeof user.permissions === 'object'
    ? user.permissions
    : {};
  return {
    id: user.id,
    name: user.name,
    isSuperAdmin,
    permissions,
    can: (key, action) => isSuperAdmin || allows(permissions, key, action),
  };
}

async function loadPrincipal(userId) {
  const hit = cache.get(userId);
  if (hit && Date.now() - hit.at < CACHE_MS) return hit.principal;

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      name: true,
      isActive: true,
      permissions: true,
      roleRef: { select: { isSuperAdmin: true } },
    },
  });
  const principal = user && user.isActive ? toPrincipal(user) : null;
  cache.set(userId, { principal, at: Date.now() });
  return principal;
}

const ACTION_WORDS = { read: 'view', write: 'change', summary: 'view the summary of' };

async function guard(req, res, next) {
  try {
    if (isPublic(req.method, req.path)) return next();

    const header = req.get('authorization') || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    const userId = verify(token);
    const principal = userId ? await loadPrincipal(userId) : null;
    if (!principal) {
      return res.status(401).json({ error: 'Your session has ended. Please sign in again.' });
    }
    req.auth = principal;

    const need = requirementFor(req.method, req.path);
    if (need && !principal.can(need.key, need.action)) {
      return res.status(403).json({
        error: `You don't have permission to ${ACTION_WORDS[need.action]} ${need.key}.`,
      });
    }
    next();
  } catch (err) {
    next(err);
  }
}

module.exports = { guard, invalidatePrincipal, toPrincipal };

const prisma = require('../prismaClient');
const { decode } = require('./token');
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
    mustChangePassword: user.mustChangePassword === true,
    // Tokens signed before this moment are refused (see guard).
    passwordChangedAtMs: user.passwordChangedAt ? user.passwordChangedAt.getTime() : 0,
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
      mustChangePassword: true,
      passwordChangedAt: true,
      roleRef: { select: { isSuperAdmin: true } },
    },
  });
  const principal = user && user.isActive ? toPrincipal(user) : null;
  cache.set(userId, { principal, at: Date.now() });
  return principal;
}

/// What an account that still has to choose its password may call.
const PASSWORD_SETUP_PATHS = ['/auth/me', '/settings/password'];

const ACTION_WORDS = { read: 'view', write: 'change', summary: 'view the summary of' };

async function guard(req, res, next) {
  try {
    if (isPublic(req.method, req.path)) return next();

    const header = req.get('authorization') || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    const claims = decode(token);
    const principal = claims ? await loadPrincipal(claims.uid) : null;
    // A password changed or reset after this token was signed ends the session
    // (a lost phone must not stay signed in through a reset).
    if (!principal || claims.iat < principal.passwordChangedAtMs) {
      return res.status(401).json({ error: 'Your session has ended. Please sign in again.' });
    }
    req.auth = principal;

    // A password somebody else chose must be replaced before anything else.
    // The two calls below are what the "set your own password" screen needs.
    if (principal.mustChangePassword && !PASSWORD_SETUP_PATHS.includes(req.path)) {
      return res.status(403).json({
        error: 'Set your own password before continuing.',
        code: 'PASSWORD_CHANGE_REQUIRED',
      });
    }

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

/// The employee a write should be credited to.
///
/// Always the signed-in account. It used to come off `body.modifiedBy`, which
/// meant the audit trail was whatever the caller typed - every module except
/// Employees and Roles simply fell back to "Admin", so a signed-in employee's
/// work was filed under someone else.
function actorName(req) {
  return (req.auth && req.auth.name) || 'Admin';
}

module.exports = { guard, invalidatePrincipal, toPrincipal, actorName };

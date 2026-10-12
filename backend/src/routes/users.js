const express = require('express');
const bcrypt = require('bcryptjs');
const prisma = require('../prismaClient');
const { normalisePhone } = require('../phone');
const { sanitizePermissions, clampToGranter } = require('../permissions');
const { invalidatePrincipal } = require('../auth/middleware');
const { listResponse } = require('../pagination');
const { ValidationError } = require('../validate');

const router = express.Router();
router.param('id', require('../validate').idParam);

/// passwordHash must never leave the API.
const publicFields = {
  id: true,
  code: true,
  name: true,
  email: true,
  role: true,
  roleId: true,
  roleRef: { select: { id: true, key: true, name: true, icon: true, isSuperAdmin: true } },
  phone: true,
  department: true,
  isActive: true,
  permissions: true,
  lastLoginAt: true,
  modifiedBy: true,
  modifiedAt: true,
  createdAt: true,
};

/// Trimmed text; anything over 200 characters is refused rather than stored.
const str = (v, fallback = '') => {
  if (v === undefined || v === null) return fallback;
  const s = String(v).trim();
  if (s.length > 200) throw new ValidationError('A field must be at most 200 characters');
  return s;
};

class ForbiddenError extends Error {}

/// The role an employee is being given — by id, or by name for older clients.
async function resolveRole(body) {
  const id = Number(body.roleId);
  if (Number.isInteger(id) && id > 0) {
    return prisma.role.findUnique({ where: { id } });
  }
  const name = str(body.role);
  if (!name) return null;
  return prisma.role.findFirst({ where: { name: { equals: name, mode: 'insensitive' } } });
}

/// Only a Super Admin may create, change or remove a Super Admin.
function assertCanTouch(auth, isSuperAdminTarget) {
  if (isSuperAdminTarget && !auth.isSuperAdmin) {
    throw new ForbiddenError('Only a Super Admin can manage Super Admin accounts');
  }
}

async function userData(body, auth) {
  const data = {
    name: str(body.name),
    email: str(body.email).toLowerCase(),
    phone: normalisePhone(body.phone),
    department: str(body.department),
    modifiedBy: auth.name || 'Admin',
    modifiedAt: new Date(),
  };
  if (body.isActive !== undefined) data.isActive = body.isActive === true;

  const role = await resolveRole(body);
  if (role) {
    assertCanTouch(auth, role.isSuperAdmin);
    data.roleId = role.id;
    data.role = role.name;
  }

  // Never more than the person saving holds themselves.
  const permissions = clampToGranter(sanitizePermissions(body.permissions), auth);
  if (permissions !== undefined) data.permissions = permissions;
  return data;
}

async function isSuperAdminUser(id) {
  const user = await prisma.user.findUnique({
    where: { id },
    select: { roleRef: { select: { isSuperAdmin: true } } },
  });
  if (!user) return null;
  return !!(user.roleRef && user.roleRef.isSuperAdmin);
}

function validate(body) {
  if (!str(body.name)) return 'name is required';
  const email = str(body.email);
  if (!email) return 'email is required';
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return 'email is not valid';
  return null;
}

/// Only an ACTIVE Super Admin can still sign in, so only those count as
/// "somebody who can manage the portal".
const superAdminCount = () =>
  prisma.user.count({ where: { isActive: true, roleRef: { isSuperAdmin: true } } });

/// True when [id] is an active Super Admin and nobody else active is left, so
/// deactivating, demoting or deleting them would lock everyone out.
async function isLastActiveSuperAdmin(id) {
  const user = await prisma.user.findUnique({
    where: { id },
    select: { isActive: true, roleRef: { select: { isSuperAdmin: true } } },
  });
  if (!user || !user.isActive || !(user.roleRef && user.roleRef.isSuperAdmin)) return false;
  return (await superAdminCount()) <= 1;
}

const MIN_PASSWORD = 6;
const MAX_PASSWORD = 100;

/// Null when [password] is acceptable, otherwise the reason it is not.
function passwordProblem(password) {
  if (password.length < MIN_PASSWORD) return `password must be at least ${MIN_PASSWORD} characters`;
  if (password.length > MAX_PASSWORD) return `password must be at most ${MAX_PASSWORD} characters`;
  return null;
}

async function roleIsSuperAdmin(roleId) {
  const role = await prisma.role.findUnique({ where: { id: roleId }, select: { isSuperAdmin: true } });
  return !!(role && role.isSuperAdmin);
}

/// Next free USR-#### code.
async function nextUserCode() {
  const last = await prisma.user.findFirst({
    where: { code: { startsWith: 'USR-' } },
    orderBy: { code: 'desc' },
    select: { code: true },
  });
  const n = last ? Number(last.code.slice(4)) : 0;
  return `USR-${String((Number.isFinite(n) ? n : 0) + 1).padStart(4, '0')}`;
}

// GET /api/users
router.get('/', async (req, res, next) => {
  try {
    // Last added / modified first (updatedAt covers both).
    res.json(await listResponse({
      query: req.query,
      findMany: (page) => prisma.user.findMany({
        orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
        select: publicFields,
        ...page,
      }),
      count: () => prisma.user.count(),
    }));
  } catch (err) {
    next(err);
  }
});

// POST /api/users
router.post('/', async (req, res, next) => {
  try {
    const invalid = validate(req.body);
    if (invalid) return res.status(400).json({ error: invalid });

    // The password the admin typed is the one the employee signs in with.
    // There is no built-in starter password: one that sits in the repo is a
    // password everybody knows. It is hashed and never echoed back.
    const password = typeof req.body.password === 'string' ? req.body.password.trim() : '';
    if (!password) return res.status(400).json({ error: 'password is required' });
    const weak = passwordProblem(password);
    if (weak) return res.status(400).json({ error: weak });
    const user = await prisma.user.create({
      data: {
        ...(await userData(req.body, req.auth)),
        code: str(req.body.code) || (await nextUserCode()),
        passwordHash: await bcrypt.hash(password, 10),
        // The admin chose it, so the employee must replace it on first sign-in.
        mustChangePassword: true,
      },
      select: publicFields,
    });
    res.status(201).json(user);
  } catch (err) {
    if (err instanceof ForbiddenError) return res.status(403).json({ error: err.message });
    if (err.code === 'P2002') {
      const field = err.meta?.target?.includes('email') ? 'email' : 'code';
      return res.status(409).json({ error: `That ${field} is already in use` });
    }
    next(err);
  }
});

// PUT /api/users/:id
router.put('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const invalid = validate(req.body);
    if (invalid) return res.status(400).json({ error: invalid });

    const targetIsSuperAdmin = await isSuperAdminUser(id);
    if (targetIsSuperAdmin === null) return res.status(404).json({ error: 'User not found' });
    assertCanTouch(req.auth, targetIsSuperAdmin);

    const data = await userData(req.body, req.auth);
    const code = str(req.body.code);
    if (code) data.code = code;
    // Only rehash when a new password was actually supplied.
    const password = typeof req.body.password === 'string' ? req.body.password.trim() : '';
    if (password) {
      const weak = passwordProblem(password);
      if (weak) return res.status(400).json({ error: weak });
      data.passwordHash = await bcrypt.hash(password, 10);
      // Changing your own password is a choice; resetting somebody else's is
      // not, so they are asked to pick their own at next sign-in.
      data.mustChangePassword = id !== req.auth.id;
      // Resetting somebody else's password also signs out their old sessions.
      // (Your own is left alone here: this call has no way to hand you the
      // fresh token, so Settings › Security is where you change that one.)
      if (id !== req.auth.id) data.passwordChangedAt = new Date();
    }

    // Moving the last active Super Admin to another role, or switching them
    // off, would leave nobody able to manage the portal.
    if (await isLastActiveSuperAdmin(id)) {
      if (data.roleId !== undefined && !(await roleIsSuperAdmin(data.roleId))) {
        return res.status(409).json({ error: 'Cannot change the role of the last Super Admin' });
      }
      if (data.isActive === false) {
        return res.status(409).json({ error: 'Cannot deactivate the last active Super Admin' });
      }
    }

    const user = await prisma.user.update({
      where: { id },
      data,
      select: publicFields,
    });
    invalidatePrincipal(id);
    res.json(user);
  } catch (err) {
    if (err instanceof ForbiddenError) return res.status(403).json({ error: err.message });
    if (err.code === 'P2025') return res.status(404).json({ error: 'User not found' });
    if (err.code === 'P2002') {
      const field = err.meta?.target?.includes('email') ? 'email' : 'code';
      return res.status(409).json({ error: `That ${field} is already in use` });
    }
    next(err);
  }
});

// PATCH /api/users/:id/status  { isActive: false }
router.patch('/:id/status', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    if (req.body.isActive === undefined) {
      return res.status(400).json({ error: 'isActive is required' });
    }
    const targetIsSuperAdmin = await isSuperAdminUser(id);
    if (targetIsSuperAdmin === null) return res.status(404).json({ error: 'User not found' });
    assertCanTouch(req.auth, targetIsSuperAdmin);
    if (id === req.auth.id && req.body.isActive !== true) {
      return res.status(409).json({ error: 'You cannot deactivate your own account' });
    }
    if (req.body.isActive !== true && (await isLastActiveSuperAdmin(id))) {
      return res.status(409).json({ error: 'Cannot deactivate the last active Super Admin' });
    }

    const user = await prisma.user.update({
      where: { id },
      data: { isActive: req.body.isActive === true, modifiedAt: new Date() },
      select: publicFields,
    });
    invalidatePrincipal(id);
    res.json(user);
  } catch (err) {
    if (err instanceof ForbiddenError) return res.status(403).json({ error: err.message });
    if (err.code === 'P2025') return res.status(404).json({ error: 'User not found' });
    next(err);
  }
});

// DELETE /api/users/:id
router.delete('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const targetIsSuperAdmin = await isSuperAdminUser(id);
    if (targetIsSuperAdmin === null) return res.status(404).json({ error: 'User not found' });
    assertCanTouch(req.auth, targetIsSuperAdmin);
    if (id === req.auth.id) {
      return res.status(409).json({ error: 'You cannot delete your own account' });
    }
    // Refuse to delete the last Super Admin — that would lock everyone out.
    if (await isLastActiveSuperAdmin(id)) {
      return res.status(409).json({ error: 'Cannot delete the last Super Admin account' });
    }
    await prisma.user.delete({ where: { id } });
    invalidatePrincipal(id);
    res.status(204).send();
  } catch (err) {
    if (err instanceof ForbiddenError) return res.status(403).json({ error: err.message });
    if (err.code === 'P2025') return res.status(404).json({ error: 'User not found' });
    next(err);
  }
});

module.exports = router;

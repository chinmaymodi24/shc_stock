const express = require('express');
const bcrypt = require('bcryptjs');
const prisma = require('../prismaClient');
const { sanitizePermissions, clampToGranter } = require('../permissions');
const { invalidatePrincipal } = require('../auth/middleware');

const router = express.Router();

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

const str = (v, fallback = '') =>
  v === undefined || v === null ? fallback : String(v).trim();

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
    phone: str(body.phone),
    department: str(body.department),
    modifiedBy: auth.name || str(body.modifiedBy, 'Admin') || 'Admin',
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

const superAdminCount = () =>
  prisma.user.count({ where: { roleRef: { isSuperAdmin: true } } });

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
    const users = await prisma.user.findMany({
      orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
      select: publicFields,
    });
    res.json(users);
  } catch (err) {
    next(err);
  }
});

// POST /api/users
router.post('/', async (req, res, next) => {
  try {
    const invalid = validate(req.body);
    if (invalid) return res.status(400).json({ error: invalid });

    // New employees get a starter password they're expected to change; the
    // caller may supply one instead. It is hashed and never echoed back.
    const password = str(req.body.password) || 'shc@12345';
    const user = await prisma.user.create({
      data: {
        ...(await userData(req.body, req.auth)),
        code: str(req.body.code) || (await nextUserCode()),
        passwordHash: await bcrypt.hash(password, 10),
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
    const password = str(req.body.password);
    if (password) data.passwordHash = await bcrypt.hash(password, 10);

    // Moving the last Super Admin to another role would leave nobody able to
    // manage the portal.
    if (targetIsSuperAdmin && data.roleId !== undefined && !(await roleIsSuperAdmin(data.roleId))) {
      if ((await superAdminCount()) <= 1) {
        return res.status(409).json({ error: 'Cannot change the role of the last Super Admin' });
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
    if (targetIsSuperAdmin && (await superAdminCount()) <= 1) {
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

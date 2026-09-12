const express = require('express');
const prisma = require('../prismaClient');
const { sanitizePermissions, clampToGranter } = require('../permissions');
const { invalidatePrincipal } = require('../auth/middleware');

const router = express.Router();

// ─────────────────────────────────────────────────────────────────────────────
// Roles — the ready-made presets plus custom roles built in the Add Employee
// wizard. Reading needs Employee read; any change needs Employee write (see
// auth/policy.js). Presets are rebuilt from src/permissions.js on start-up, so
// they are read-only here.
// ─────────────────────────────────────────────────────────────────────────────

const str = (v) => (v === undefined || v === null ? '' : String(v).trim());

const ICONS = ['stars', 'admin', 'manager', 'sales', 'store', 'custom'];

function toJson(role) {
  const { _count, ...rest } = role;
  return { ...rest, userCount: _count ? _count.users : 0 };
}

const withCount = { _count: { select: { users: true } } };

// GET /api/roles — presets first (in catalog order), then custom roles A–Z.
router.get('/', async (req, res, next) => {
  try {
    const roles = await prisma.role.findMany({
      orderBy: [{ isSystem: 'desc' }, { id: 'asc' }],
      include: withCount,
    });
    const presets = roles.filter((r) => r.isSystem);
    const custom = roles
      .filter((r) => !r.isSystem)
      .sort((a, b) => a.name.localeCompare(b.name));
    res.json([...presets, ...custom].map(toJson));
  } catch (err) {
    next(err);
  }
});

async function nameTaken(name, exceptId) {
  const clash = await prisma.role.findFirst({
    where: {
      name: { equals: name, mode: 'insensitive' },
      ...(exceptId ? { NOT: { id: exceptId } } : {}),
    },
    select: { id: true },
  });
  return !!clash;
}

function roleData(body, granter) {
  const permissions = clampToGranter(sanitizePermissions(body.permissions) || {}, granter);
  const icon = ICONS.includes(str(body.icon)) ? str(body.icon) : 'custom';
  return {
    name: str(body.name),
    description: str(body.description),
    icon,
    permissions,
    modifiedBy: granter.name || 'Admin',
  };
}

// POST /api/roles  { name, description, icon, permissions }
router.post('/', async (req, res, next) => {
  try {
    const data = roleData(req.body, req.auth);
    if (!data.name) return res.status(400).json({ error: 'Role name is required' });
    if (await nameTaken(data.name)) {
      return res.status(409).json({ error: `A role named "${data.name}" already exists` });
    }
    const role = await prisma.role.create({ data, include: withCount });
    res.status(201).json(toJson(role));
  } catch (err) {
    next(err);
  }
});

// PUT /api/roles/:id — custom roles only.
router.put('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const existing = await prisma.role.findUnique({ where: { id } });
    if (!existing) return res.status(404).json({ error: 'Role not found' });
    if (existing.isSystem) {
      return res.status(400).json({ error: 'Ready-made roles cannot be edited — create a custom role instead' });
    }

    const data = roleData(req.body, req.auth);
    if (!data.name) return res.status(400).json({ error: 'Role name is required' });
    if (await nameTaken(data.name, id)) {
      return res.status(409).json({ error: `A role named "${data.name}" already exists` });
    }

    const role = await prisma.$transaction(async (tx) => {
      const updated = await tx.role.update({ where: { id }, data, include: withCount });
      // Employees show their role by name; keep that label in step.
      await tx.user.updateMany({ where: { roleId: id }, data: { role: updated.name } });
      return updated;
    });
    res.json(toJson(role));
  } catch (err) {
    next(err);
  }
});

// DELETE /api/roles/:id — custom roles nobody is using.
router.delete('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const role = await prisma.role.findUnique({ where: { id }, include: withCount });
    if (!role) return res.status(404).json({ error: 'Role not found' });
    if (role.isSystem) {
      return res.status(400).json({ error: 'Ready-made roles cannot be deleted' });
    }
    if (role._count.users > 0) {
      return res.status(409).json({
        error: `${role._count.users} employee(s) still use "${role.name}" — assign them another role first`,
      });
    }
    await prisma.role.delete({ where: { id } });
    invalidatePrincipal();
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

module.exports = router;

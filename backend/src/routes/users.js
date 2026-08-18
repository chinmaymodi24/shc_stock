const express = require('express');
const bcrypt = require('bcryptjs');
const prisma = require('../prismaClient');

const router = express.Router();

const ROLES = ['Admin', 'Manager', 'Salesman', 'Stock Manager', 'Accountant'];

/// passwordHash must never leave the API.
const publicFields = {
  id: true,
  code: true,
  name: true,
  email: true,
  role: true,
  phone: true,
  department: true,
  isActive: true,
  lastLoginAt: true,
  modifiedBy: true,
  modifiedAt: true,
  createdAt: true,
};

const str = (v, fallback = '') =>
  v === undefined || v === null ? fallback : String(v).trim();

function userData(body) {
  const data = {
    name: str(body.name),
    email: str(body.email).toLowerCase(),
    role: ROLES.includes(str(body.role)) ? str(body.role) : 'Salesman',
    phone: str(body.phone),
    department: str(body.department),
    modifiedBy: str(body.modifiedBy, 'Admin') || 'Admin',
    modifiedAt: new Date(),
  };
  if (body.isActive !== undefined) data.isActive = body.isActive === true;
  return data;
}

function validate(body) {
  if (!str(body.name)) return 'name is required';
  const email = str(body.email);
  if (!email) return 'email is required';
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) return 'email is not valid';
  return null;
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
        ...userData(req.body),
        code: str(req.body.code) || (await nextUserCode()),
        passwordHash: await bcrypt.hash(password, 10),
      },
      select: publicFields,
    });
    res.status(201).json(user);
  } catch (err) {
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

    const data = userData(req.body);
    const code = str(req.body.code);
    if (code) data.code = code;
    // Only rehash when a new password was actually supplied.
    const password = str(req.body.password);
    if (password) data.passwordHash = await bcrypt.hash(password, 10);

    const user = await prisma.user.update({
      where: { id },
      data,
      select: publicFields,
    });
    res.json(user);
  } catch (err) {
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
    const user = await prisma.user.update({
      where: { id },
      data: { isActive: req.body.isActive === true, modifiedAt: new Date() },
      select: publicFields,
    });
    res.json(user);
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'User not found' });
    next(err);
  }
});

// DELETE /api/users/:id
router.delete('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    // Refuse to delete the last remaining Admin — that would lock everyone out.
    const target = await prisma.user.findUnique({ where: { id } });
    if (!target) return res.status(404).json({ error: 'User not found' });
    if (target.role === 'Admin') {
      const admins = await prisma.user.count({ where: { role: 'Admin' } });
      if (admins <= 1) {
        return res
          .status(409)
          .json({ error: 'Cannot delete the last Admin account' });
      }
    }
    await prisma.user.delete({ where: { id } });
    res.status(204).send();
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'User not found' });
    next(err);
  }
});

module.exports = router;

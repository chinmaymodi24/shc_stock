const express = require('express');
const bcrypt = require('bcryptjs');
const prisma = require('../prismaClient');
const { getAppSettings, updateAppSettings } = require('../appSettings');

const router = express.Router();

// ── Business-wide settings (not per-user) ──────────────────────────────────
// GET /api/settings/app
router.get('/app', async (req, res, next) => {
  try {
    const { lowStockThreshold } = await getAppSettings();
    res.json({ lowStockThreshold });
  } catch (err) {
    next(err);
  }
});

// PUT /api/settings/app  { lowStockThreshold }
router.put('/app', async (req, res, next) => {
  try {
    const data = {};
    if (req.body.lowStockThreshold !== undefined) {
      const n = Number(req.body.lowStockThreshold);
      if (!Number.isInteger(n) || n < 0 || n > 100000) {
        return res.status(400).json({ error: 'lowStockThreshold must be a whole number between 0 and 100000' });
      }
      data.lowStockThreshold = n;
    }
    const { lowStockThreshold } = await updateAppSettings(data);
    res.json({ lowStockThreshold });
  } catch (err) {
    next(err);
  }
});

/// Same rule as /api/users — the hash never leaves the API.
const publicFields = {
  id: true,
  code: true,
  name: true,
  email: true,
  role: true,
  phone: true,
  department: true,
  notifyLowStock: true,
  notifyDelivery: true,
  notifyPayment: true,
  notifyWeekly: true,
  twoFactor: true,
  rowsPerPage: true,
  dateFormat: true,
  autoNumberDocs: true,
};

const str = (v, fallback = '') =>
  v === undefined || v === null ? fallback : String(v).trim();

/// Which user these settings belong to. The app passes the signed-in id;
/// without one there's nothing to load, so say so rather than guessing.
function resolveUserId(req) {
  const id = Number(req.query.userId ?? req.body.userId);
  return Number.isInteger(id) && id > 0 ? id : null;
}

// GET /api/settings?userId=
router.get('/', async (req, res, next) => {
  try {
    const userId = resolveUserId(req);
    if (!userId) return res.status(400).json({ error: 'userId is required' });
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: publicFields,
    });
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (err) {
    next(err);
  }
});

// PUT /api/settings — profile fields and preferences for the signed-in user.
router.put('/', async (req, res, next) => {
  try {
    const userId = resolveUserId(req);
    if (!userId) return res.status(400).json({ error: 'userId is required' });

    const data = {};
    if (req.body.name !== undefined) {
      const name = str(req.body.name);
      if (!name) return res.status(400).json({ error: 'name cannot be empty' });
      data.name = name;
    }
    if (req.body.email !== undefined) {
      const email = str(req.body.email).toLowerCase();
      if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
        return res.status(400).json({ error: 'email is not valid' });
      }
      data.email = email;
    }
    if (req.body.phone !== undefined) data.phone = str(req.body.phone);

    for (const key of [
      'notifyLowStock', 'notifyDelivery', 'notifyPayment',
      'notifyWeekly', 'twoFactor', 'autoNumberDocs',
    ]) {
      if (req.body[key] !== undefined) data[key] = req.body[key] === true;
    }

    if (req.body.rowsPerPage !== undefined) {
      const n = Number(req.body.rowsPerPage);
      if (![5, 10, 20, 50, 100].includes(n)) {
        return res.status(400).json({ error: 'rowsPerPage must be 5, 10, 20, 50 or 100' });
      }
      data.rowsPerPage = n;
    }
    if (req.body.dateFormat !== undefined) {
      data.dateFormat = str(req.body.dateFormat) || 'MMM D, YYYY (Jul 18, 2026)';
    }

    data.modifiedAt = new Date();

    const user = await prisma.user.update({
      where: { id: userId },
      data,
      select: publicFields,
    });
    res.json(user);
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'User not found' });
    if (err.code === 'P2002') {
      return res.status(409).json({ error: 'That email is already in use' });
    }
    next(err);
  }
});

// POST /api/settings/password  { userId, currentPassword, newPassword }
router.post('/password', async (req, res, next) => {
  try {
    const userId = resolveUserId(req);
    if (!userId) return res.status(400).json({ error: 'userId is required' });

    const current = String(req.body.currentPassword || '');
    const next_ = String(req.body.newPassword || '');
    if (!current) return res.status(400).json({ error: 'currentPassword is required' });
    if (next_.length < 6) {
      return res.status(400).json({ error: 'newPassword must be at least 6 characters' });
    }

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return res.status(404).json({ error: 'User not found' });

    // Verify the current password before allowing a change — otherwise anyone
    // with the page open could reset it.
    const matches = await bcrypt.compare(current, user.passwordHash);
    if (!matches) return res.status(401).json({ error: 'Current password is incorrect' });

    await prisma.user.update({
      where: { id: userId },
      data: { passwordHash: await bcrypt.hash(next_, 10), modifiedAt: new Date() },
    });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

module.exports = router;

const express = require('express');
const bcrypt = require('bcryptjs');
const prisma = require('../prismaClient');
const { getAppSettings, updateAppSettings } = require('../appSettings');
const { settingsKey } = require('../permissions');

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

// ── The white-label brand ──────────────────────────────────────────────────
// Portal-wide, not per-user: an admin sets the brand once and every employee
// on every device sees it. Storing it only in the browser would have meant a
// different-looking app for each person.
//
// GET /api/settings/brand
router.get('/brand', async (req, res, next) => {
  try {
    const { brandTheme } = await getAppSettings();
    // An empty object means "never configured" — the app then falls back to
    // its shipped brand.
    res.json(brandTheme ?? {});
  } catch (err) {
    next(err);
  }
});

// PUT /api/settings/brand  { ...theme }
router.put('/brand', async (req, res, next) => {
  try {
    const theme = req.body;
    if (!theme || typeof theme !== 'object' || Array.isArray(theme)) {
      return res.status(400).json({ error: 'brand theme must be an object' });
    }
    // Guard against a runaway logo filling the row: base64 of a ~1MB image.
    const logo = theme.logoBase64;
    if (logo !== undefined && logo !== null) {
      if (typeof logo !== 'string') {
        return res.status(400).json({ error: 'logoBase64 must be a string' });
      }
      if (logo.length > 2 * 1024 * 1024) {
        return res.status(413).json({ error: 'Logo is too large — use an image under 1.5 MB' });
      }
    }
    const { brandTheme } = await updateAppSettings({ brandTheme: theme });
    res.json(brandTheme ?? {});
  } catch (err) {
    next(err);
  }
});

// ── The billing profile ────────────────────────────────────────────────────
// Seller identity, bank details, declaration text and the default "what
// appears on the bill" toggles. Portal-wide, same as the brand: an invoice is
// the company's document, not one employee's.
//
// GET /api/settings/billing
router.get('/billing', async (req, res, next) => {
  try {
    const { billingProfile } = await getAppSettings();
    // An empty object means "never configured" — the app falls back to its
    // shipped defaults and the Billing settings tab shows them as placeholders.
    res.json(billingProfile ?? {});
  } catch (err) {
    next(err);
  }
});

// PUT /api/settings/billing  { ...profile }
router.put('/billing', async (req, res, next) => {
  try {
    const profile = req.body;
    if (!profile || typeof profile !== 'object' || Array.isArray(profile)) {
      return res.status(400).json({ error: 'billing profile must be an object' });
    }
    // Same guard the brand logo gets: a runaway upload would bloat the
    // settings row every request reads.
    const signature = profile.signatureBase64;
    if (signature !== undefined && signature !== null) {
      if (typeof signature !== 'string') {
        return res.status(400).json({ error: 'signatureBase64 must be a string' });
      }
      if (signature.length > 2 * 1024 * 1024) {
        return res.status(413).json({ error: 'Signature is too large — use an image under 1.5 MB' });
      }
    }
    const gst = profile.gstPercent;
    if (gst !== undefined && gst !== null) {
      const n = Number(gst);
      if (!Number.isFinite(n) || n < 0 || n > 100) {
        return res.status(400).json({ error: 'gstPercent must be between 0 and 100' });
      }
    }
    const { billingProfile } = await updateAppSettings({ billingProfile: profile });
    res.json(billingProfile ?? {});
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

/// Which user these settings belong to: always the signed-in employee. A
/// passed userId is honoured only when it is theirs (or they are a Super
/// Admin) — otherwise anyone could rename someone else or change their
/// password by editing one number.
function resolveUserId(req) {
  const asked = Number(req.query.userId ?? req.body.userId);
  if (!Number.isInteger(asked) || asked <= 0) return req.auth.id;
  return asked === req.auth.id || req.auth.isSuperAdmin ? asked : null;
}

/// Fields of PUT /api/settings grouped by the Settings tab that owns them.
/// Profile (name/email/phone) and Security (twoFactor) are the employee's own
/// account and always allowed; the rest need write on their tab.
const GATED_FIELDS = {
  [settingsKey('Notifications')]: ['notifyLowStock', 'notifyDelivery', 'notifyPayment', 'notifyWeekly'],
  [settingsKey('Preferences')]: ['rowsPerPage', 'dateFormat', 'autoNumberDocs'],
};

// GET /api/settings?userId=
router.get('/', async (req, res, next) => {
  try {
    const userId = resolveUserId(req);
    if (!userId) return res.status(403).json({ error: 'You can only change your own settings' });
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
    if (!userId) return res.status(403).json({ error: 'You can only change your own settings' });

    // The app saves every field in one request; drop the ones this employee
    // may not change instead of failing the whole save.
    const body = { ...req.body };
    for (const [key, fields] of Object.entries(GATED_FIELDS)) {
      if (!req.auth.can(key, 'write')) fields.forEach((f) => delete body[f]);
    }
    req.body = body;

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
    if (!userId) return res.status(403).json({ error: 'You can only change your own settings' });

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

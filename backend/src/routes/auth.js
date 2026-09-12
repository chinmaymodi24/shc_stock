const express = require('express');
const bcrypt = require('bcryptjs');
const prisma = require('../prismaClient');
const { sign } = require('../auth/token');

const router = express.Router();

const sessionSelect = {
  id: true,
  code: true,
  name: true,
  email: true,
  role: true,
  roleId: true,
  phone: true,
  department: true,
  isActive: true,
  permissions: true,
  roleRef: { select: { isSuperAdmin: true } },
};

/// What the app keeps as its session: the employee, what they may do, and the
/// token every later request carries. permissions rides along so the app can
/// gate the sidebar and routes without a second call; a Super Admin ignores
/// the map but it is still sent so the client has one shape to read.
function sessionPayload(user) {
  return {
    id: user.id,
    code: user.code,
    name: user.name,
    email: user.email,
    role: user.role,
    roleId: user.roleId,
    isSuperAdmin: !!(user.roleRef && user.roleRef.isSuperAdmin),
    phone: user.phone,
    department: user.department,
    permissions: user.permissions ?? {},
    token: sign(user.id),
  };
}

// POST /api/auth/login
router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body;
    if (!email || !email.trim()) {
      return res.status(400).json({ error: 'email is required' });
    }
    if (!password) {
      return res.status(400).json({ error: 'password is required' });
    }

    const user = await prisma.user.findUnique({
      where: { email: email.trim().toLowerCase() },
      select: { ...sessionSelect, passwordHash: true },
    });
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const matches = await bcrypt.compare(password, user.passwordHash);
    if (!matches) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    if (!user.isActive) {
      return res.status(403).json({
        error: 'This account has been deactivated. Contact your administrator.',
      });
    }

    await prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    res.json(sessionPayload(user));
  } catch (err) {
    next(err);
  }
});

// GET /api/auth/me — the signed-in employee as they are NOW.
//
// The app calls this on start-up so a remembered session picks up permission
// changes made since the last sign-in, and gets a fresh token. The guard has
// already rejected a deactivated account or a bad token by the time we get
// here.
router.get('/me', async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.auth.id },
      select: sessionSelect,
    });
    if (!user || !user.isActive) {
      return res.status(401).json({ error: 'Your session has ended. Please sign in again.' });
    }
    res.json(sessionPayload(user));
  } catch (err) {
    next(err);
  }
});

module.exports = router;

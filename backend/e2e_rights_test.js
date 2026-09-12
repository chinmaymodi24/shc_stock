// End-to-end check of employee rights against a RUNNING backend.
//
//   cd backend && node e2e_rights_test.js            (defaults to localhost:4000)
//   API_URL=http://host:4000 node e2e_rights_test.js
//
// Creates temporary roles and employees (names start with "E2E "), exercises
// every guarded endpoint as each of them, and removes everything it created —
// also when a check fails. Probes never create data: every write is sent with
// an invalid body or a missing id, so an allowed request ends in 400/404.
require('dotenv').config();
const prisma = require('./src/prismaClient');
const { sign } = require('./src/auth/token');

const API = `${process.env.API_URL || 'http://localhost:4000'}/api`;
const results = { pass: 0, fail: 0, failures: [] };

function check(name, ok, detail = '') {
  if (ok) {
    results.pass += 1;
  } else {
    results.fail += 1;
    results.failures.push(`${name}${detail ? ` — ${detail}` : ''}`);
  }
}

async function call(method, path, { token, body, headers = {} } = {}) {
  const res = await fetch(`${API}${path}`, {
    method,
    headers: {
      ...(body !== undefined ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...headers,
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  let json = null;
  try {
    json = await res.json();
  } catch (_) { /* 204 or non-JSON */ }
  return { status: res.status, json, headers: res.headers };
}

// ── The probe table: request → the permission it needs (null = signed in) ──
const S = (section) => `Settings: ${section}`;
const PROBES = [
  ['GET', '/products', null, null],
  ['GET', '/clients', null, null],
  ['GET', '/categories', null, null],
  ['GET', '/settings/app', null, null],
  ['GET', '/settings/billing', null, null],
  ['GET', '/purchase-orders', 'Purchase', 'read'],
  ['GET', '/sales-orders', 'Sales', 'read'],
  ['GET', '/bills/summary', 'Sales', 'read'],
  ['GET', '/transactions', 'Transactions', 'read'],
  ['GET', '/inventory', 'Inventory', 'read'],
  ['GET', '/inventory/movements', 'Inventory', 'read'],
  ['GET', '/users', 'Employee', 'read'],
  ['GET', '/roles', 'Employee', 'read'],
  ['GET', '/statements/profit-and-loss', 'Reports', 'read'],
  ['GET', '/dashboard', 'Dashboard', 'read'],
  ['GET', '/dashboard/notes', 'Dashboard', 'read'],
  ['GET', '/stats/categories', 'Categories', 'summary'],
  ['GET', '/stats/products', 'Products', 'summary'],
  ['GET', '/stats/purchase', 'Purchase', 'summary'],
  ['GET', '/stats/sales', 'Sales', 'summary'],
  ['GET', '/stats/inventory', 'Inventory', 'summary'],
  ['GET', '/stats/clients', 'Clients', 'summary'],
  ['GET', '/stats/transactions', 'Transactions', 'summary'],
  ['GET', '/stats/users', 'Employee', 'summary'],
  ['GET', '/stats/reports', 'Reports', 'summary'],
  ['GET', '/stats/analytics', 'Reports', 'summary'],
  ['GET', '/stats/profit-loss', 'Reports', 'summary'],
  ['POST', '/products', 'Products', 'write', {}],
  ['DELETE', '/products/99999999', 'Products', 'write'],
  ['POST', '/categories', 'Categories', 'write', {}],
  ['PUT', '/sub-categories/99999999', 'Categories', 'write', {}],
  ['POST', '/purchase-orders', 'Purchase', 'write', {}],
  ['PATCH', '/purchase-orders/99999999/status', 'Purchase', 'write', {}],
  ['POST', '/sales-orders', 'Sales', 'write', {}],
  ['POST', '/bills', 'Sales', 'write', {}],
  ['POST', '/bills/99999999/events', 'Sales', 'read', {}],
  ['POST', '/clients', 'Clients', 'write', {}],
  ['POST', '/inventory/adjust', 'Inventory', 'write', {}],
  ['PUT', '/inventory/99999999', 'Inventory', 'write', { minimumStock: -1 }],
  ['POST', '/transactions', 'Transactions', 'write', {}],
  ['POST', '/users', 'Employee', 'write', {}],
  ['POST', '/roles', 'Employee', 'write', {}],
  ['PUT', '/settings/brand', S('Appearance'), 'write', []],
  ['PUT', '/settings/billing', S('Billing'), 'write', []],
  ['PUT', '/settings/app', S('Preferences'), 'write', { lowStockThreshold: -1 }],
  ['POST', '/dashboard/notes', 'Dashboard', 'read', {}],
];

const allows = (perms, key, action) =>
  key === null || !!(perms[key] && perms[key][action] === true);

async function main() {
  const superAdmin = await prisma.user.findFirst({
    where: { roleRef: { isSuperAdmin: true }, isActive: true },
    select: { id: true, name: true },
  });
  if (!superAdmin) throw new Error('No active Super Admin to run the checks as');
  const SA = sign(superAdmin.id);

  const createdUsers = [];
  const createdRoles = [];
  const mkUser = async (label, roleId, permissions, extra = {}, token = SA) => {
    const email = `e2e.${label.toLowerCase().replace(/\W+/g, '.')}.${Date.now()}@example.com`;
    const r = await call('POST', '/users', {
      token,
      body: { name: `E2E ${label}`, email, roleId, permissions, password: 'e2e-pass-123', ...extra },
    });
    if (r.status === 201) createdUsers.push(r.json.id);
    return { ...r, email };
  };
  const mkRole = async (name, permissions, token = SA) => {
    const r = await call('POST', '/roles', { token, body: { name, description: 'e2e', permissions } });
    if (r.status === 201) createdRoles.push(r.json.id);
    return r;
  };

  try {
    // ── 1. Signing in ───────────────────────────────────────────────────
    check('no token → 401', (await call('GET', '/products')).status === 401);
    check('garbage token → 401', (await call('GET', '/products', { token: 'abc.def' })).status === 401);
    check('login page brand is public', (await call('GET', '/settings/brand')).status === 200);
    check('brand cannot be saved without a token', (await call('PUT', '/settings/brand', { body: {} })).status === 401);
    check('wrong password → 401', (await call('POST', '/auth/login', { body: { email: 'nobody@example.com', password: 'x' } })).status === 401);

    const roles = (await call('GET', '/roles', { token: SA })).json;
    const byKey = Object.fromEntries(roles.map((r) => [r.key, r]));
    check('five ready-made roles exist', ['super_admin', 'admin', 'manager', 'sales', 'store_staff'].every((k) => byKey[k]));
    check('presets cover the Settings tabs', Object.keys(byKey.admin.permissions).includes(S('Billing')));
    check('Store Staff holds no summary anywhere', Object.values(byKey.store_staff.permissions).every((a) => !a.summary));

    // ── 2. Role × endpoint matrix ───────────────────────────────────────
    const custom = await mkRole('E2E Stock Clerk', {
      Inventory: { read: true, write: true },
      Products: { read: true },
      [S('Billing')]: { read: true },
    });
    check('custom role saved', custom.status === 201, JSON.stringify(custom.json));

    const subjects = [
      ['Admin', byKey.admin],
      ['Manager', byKey.manager],
      ['Sales', byKey.sales],
      ['Store Staff', byKey.store_staff],
      ['Stock Clerk', custom.json],
    ];
    const tokens = {};
    for (const [label, role] of subjects) {
      const u = await mkUser(label, role.id, role.permissions);
      check(`${label}: employee created`, u.status === 201, JSON.stringify(u.json));
      if (u.status !== 201) continue;
      check(`${label}: role linked`, u.json.roleId === role.id && u.json.role === role.name);
      const token = sign(u.json.id);
      tokens[label] = { token, id: u.json.id, perms: u.json.permissions, email: u.email };

      for (const [method, path, key, action, body] of PROBES) {
        const r = await call(method, path, { token, body });
        const expected = allows(u.json.permissions, key, action);
        const name = `${label}: ${method} ${path}`;
        if (expected) {
          check(`${name} allowed`, r.status !== 401 && r.status !== 403, `got ${r.status}`);
          if (method !== 'GET') check(`${name} changed nothing`, r.status >= 400, `got ${r.status}`);
        } else {
          check(`${name} refused`, r.status === 403, `got ${r.status}`);
        }
      }
    }

    // ── 3. Real sign-in hands out a working token ───────────────────────
    const clerk = tokens['Stock Clerk'];
    const login = await call('POST', '/auth/login', { body: { email: clerk.email, password: 'e2e-pass-123' } });
    check('login returns a token', login.status === 200 && typeof login.json.token === 'string');
    check('login is not a Super Admin', login.json.isSuperAdmin === false);
    const me = await call('GET', '/auth/me', { token: login.json.token });
    check('/auth/me works with it', me.status === 200 && me.json.id === clerk.id);

    // ── 4. Dashboard hides what the caller may not see ──────────────────
    const staffDash = (await call('GET', '/dashboard', { token: tokens['Store Staff'].token })).json;
    check('Store Staff dashboard: no KPIs', Object.keys(staffDash.summary).length === 0);
    check('Store Staff dashboard: no charts', Object.keys(staffDash.charts).length === 0 && staffDash.categorySlices.length === 0);
    check('Store Staff dashboard: no transactions', staffDash.recentTransactions.length === 0);
    const mgrDash = (await call('GET', '/dashboard', { token: tokens.Manager.token })).json;
    check('Manager dashboard: KPIs present', 'totalStockItems' in mgrDash.summary);

    // ── 5. Settings belong to their owner; gated fields are ignored ─────
    const sales = tokens.Sales;
    check('cannot read another employee\'s settings', (await call('GET', `/settings?userId=${superAdmin.id}`, { token: sales.token })).status === 403);
    check('cannot change another employee\'s password', (await call('POST', '/settings/password', { token: sales.token, body: { userId: superAdmin.id, currentPassword: 'x', newPassword: 'yyyyyyy' } })).status === 403);
    const before = (await call('GET', '/settings', { token: clerk.token })).json;
    await call('PUT', '/settings', { token: clerk.token, body: { notifyWeekly: !before.notifyWeekly, rowsPerPage: before.rowsPerPage === 20 ? 50 : 20, phone: '12345' } });
    const after = (await call('GET', '/settings', { token: clerk.token })).json;
    check('no Notifications write → notification left alone', after.notifyWeekly === before.notifyWeekly);
    check('no Preferences write → preference left alone', after.rowsPerPage === before.rowsPerPage);
    check('own profile still saves', after.phone === '12345');
    const sBefore = (await call('GET', '/settings', { token: sales.token })).json;
    await call('PUT', '/settings', { token: sales.token, body: { notifyWeekly: !sBefore.notifyWeekly } });
    const sAfter = (await call('GET', '/settings', { token: sales.token })).json;
    check('Notifications write → notification saved', sAfter.notifyWeekly !== sBefore.notifyWeekly);

    // ── 6. Nobody grants more than they hold ────────────────────────────
    const hrRole = await mkRole('E2E HR', {
      Employee: { read: true, write: true },
      Products: { read: true },
    });
    const hr = await mkUser('HR', hrRole.json.id, hrRole.json.permissions);
    const hrToken = sign(hr.json.id);
    const escalated = await mkUser('Escalated', byKey.sales.id, {
      Products: { read: true, write: true, summary: true },
      Sales: { read: true, write: true, summary: true },
    }, {}, hrToken);
    check('HR can create an employee', escalated.status === 201, JSON.stringify(escalated.json));
    if (escalated.status === 201) {
      const p = escalated.json.permissions;
      check('grant clipped to read on Products', p.Products && p.Products.read && !p.Products.write && !p.Products.summary);
      check('grant clipped: no Sales at all', !p.Sales || (!p.Sales.read && !p.Sales.write));
    }
    const hrRoleEsc = await mkRole('E2E Too Much', { Sales: { read: true, write: true } }, hrToken);
    check('custom role clipped to the creator', hrRoleEsc.status === 201 && (!hrRoleEsc.json.permissions.Sales || !hrRoleEsc.json.permissions.Sales.read));
    check('HR cannot hand out Super Admin', (await mkUser('Sneaky', byKey.super_admin.id, {}, {}, hrToken)).status === 403);
    check('HR cannot edit the Super Admin', (await call('PUT', `/users/${superAdmin.id}`, { token: hrToken, body: { name: 'x', email: 'x@example.com' } })).status === 403);
    check('HR cannot deactivate the Super Admin', (await call('PATCH', `/users/${superAdmin.id}/status`, { token: hrToken, body: { isActive: false } })).status === 403);
    check('HR cannot delete the Super Admin', (await call('DELETE', `/users/${superAdmin.id}`, { token: hrToken })).status === 403);
    check('cannot deactivate yourself', (await call('PATCH', `/users/${hr.json.id}/status`, { token: hrToken, body: { isActive: false } })).status === 409);
    check('cannot delete yourself', (await call('DELETE', `/users/${hr.json.id}`, { token: hrToken })).status === 409);

    // ── 7. Revoking takes effect at once ────────────────────────────────
    const writer = await mkUser('Writer', byKey.sales.id, { Products: { read: true, write: true } });
    const wToken = sign(writer.json.id);
    check('before revoke: write allowed', (await call('POST', '/products', { token: wToken, body: {} })).status === 400);
    await call('PUT', `/users/${writer.json.id}`, { token: SA, body: { name: 'E2E Writer', email: writer.email, permissions: { Products: { read: true } } } });
    check('after revoke: write refused immediately', (await call('POST', '/products', { token: wToken, body: {} })).status === 403);
    await call('PATCH', `/users/${writer.json.id}/status`, { token: SA, body: { isActive: false } });
    check('deactivated employee is signed out', (await call('GET', '/products', { token: wToken })).status === 401);

    // ── 8. Notes are private ────────────────────────────────────────────
    const note = await call('POST', '/dashboard/notes', { token: tokens.Manager.token, body: { text: 'E2E private note' } });
    check('note created', note.status === 201);
    const otherNotes = (await call('GET', '/dashboard/notes', { token: tokens.Sales.token })).json;
    check('another employee cannot see it', !otherNotes.some((n) => n.id === note.json.id));
    check('…nor edit it', (await call('PUT', `/dashboard/notes/${note.json.id}`, { token: tokens.Sales.token, body: { done: true } })).status === 404);
    check('…nor delete it', (await call('DELETE', `/dashboard/notes/${note.json.id}`, { token: tokens.Sales.token })).status === 404);
    check('owner deletes it', (await call('DELETE', `/dashboard/notes/${note.json.id}`, { token: tokens.Manager.token })).status === 204);

    // ── 9. Role management rules ────────────────────────────────────────
    check('duplicate role name (any case) → 409', (await mkRole('e2e stock CLERK', {})).status === 409);
    check('ready-made role cannot be edited', (await call('PUT', `/roles/${byKey.sales.id}`, { token: SA, body: { name: 'Sales', permissions: {} } })).status === 400);
    check('ready-made role cannot be deleted', (await call('DELETE', `/roles/${byKey.sales.id}`, { token: SA })).status === 400);
    check('role in use cannot be deleted', (await call('DELETE', `/roles/${custom.json.id}`, { token: SA })).status === 409);
    await call('PUT', `/roles/${custom.json.id}`, { token: SA, body: { name: 'E2E Store Clerk', permissions: custom.json.permissions } });
    const renamed = (await call('GET', '/users', { token: SA })).json.find((u) => u.id === clerk.id);
    check('renaming a role renames it on its employees', renamed && renamed.role === 'E2E Store Clerk');

    // ── 10. The last Super Admin stays ──────────────────────────────────
    const sa2 = await mkUser('Second Super', byKey.super_admin.id, {});
    check('a Super Admin can create another', sa2.status === 201);
    const demote2 = await call('PUT', `/users/${sa2.json.id}`, { token: SA, body: { name: 'E2E Second Super', email: sa2.email, roleId: byKey.admin.id } });
    check('demoting one of two Super Admins works', demote2.status === 200 && demote2.json.roleId === byKey.admin.id);
    const self = await prisma.user.findUnique({ where: { id: superAdmin.id } });
    const demoteLast = await call('PUT', `/users/${superAdmin.id}`, { token: SA, body: { name: self.name, email: self.email, roleId: byKey.admin.id } });
    check('demoting the last Super Admin → 409', demoteLast.status === 409, `got ${demoteLast.status}`);

    // ── 11. Browser pre-flight lets the Authorization header through ────
    const pre = await fetch(`${API}/products`, {
      method: 'OPTIONS',
      headers: {
        Origin: 'http://localhost:49309',
        'Access-Control-Request-Method': 'GET',
        'Access-Control-Request-Headers': 'authorization',
      },
    });
    check('CORS pre-flight allows Authorization', pre.status === 204 && (pre.headers.get('access-control-allow-headers') || '').toLowerCase().includes('authorization'));
  } finally {
    // Safety net for check 10: whatever happened, the real Super Admin keeps
    // the Super Admin role.
    const saRole = await prisma.role.findUnique({ where: { key: 'super_admin' } });
    await prisma.user.update({
      where: { id: superAdmin.id },
      data: { roleId: saRole.id, role: saRole.name },
    });
    await prisma.dashboardNote.deleteMany({ where: { text: { startsWith: 'E2E ' } } });
    await prisma.user.deleteMany({ where: { OR: [{ id: { in: createdUsers } }, { name: { startsWith: 'E2E ' } }] } });
    await prisma.role.deleteMany({ where: { OR: [{ id: { in: createdRoles } }, { name: { startsWith: 'E2E ' } }] } });
    await prisma.$disconnect();
  }

  console.log(`\n${results.pass} passed, ${results.fail} failed`);
  for (const f of results.failures) console.log(`  ✗ ${f}`);
  process.exitCode = results.fail ? 1 : 0;
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});

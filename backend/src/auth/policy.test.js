const test = require('node:test');
const assert = require('node:assert');
const { isPublic, requirementFor } = require('./policy');
const { sanitizePermissions, clampToGranter, SYSTEM_ROLES } = require('../permissions');
const { sign, verify } = require('./token');

test('only sign-in, the brand and health are public', () => {
  assert.ok(isPublic('POST', '/auth/login'));
  assert.ok(isPublic('GET', '/settings/brand'));
  assert.ok(!isPublic('PUT', '/settings/brand'));
  assert.ok(!isPublic('GET', '/products'));
});

test('a change needs write on the module that owns it', () => {
  assert.deepStrictEqual(requirementFor('POST', '/products'), { key: 'Products', action: 'write' });
  assert.deepStrictEqual(requirementFor('POST', '/inventory/adjust'), { key: 'Inventory', action: 'write' });
  assert.deepStrictEqual(requirementFor('POST', '/bills'), { key: 'Sales', action: 'write' });
  assert.deepStrictEqual(requirementFor('PUT', '/settings/billing'), { key: 'Settings: Billing', action: 'write' });
});

test('summary endpoints need the summary right, lookups only a session', () => {
  assert.deepStrictEqual(requirementFor('GET', '/stats/inventory'), { key: 'Inventory', action: 'summary' });
  assert.deepStrictEqual(requirementFor('GET', '/stats/profit-loss'), { key: 'Reports', action: 'summary' });
  // Add Sale picks products and clients without needing those modules.
  assert.strictEqual(requirementFor('GET', '/products'), null);
  assert.strictEqual(requirementFor('GET', '/clients'), null);
  assert.deepStrictEqual(requirementFor('GET', '/purchase-orders'), { key: 'Purchase', action: 'read' });
});

test('sharing a bill is a read action, changing one is a write', () => {
  assert.deepStrictEqual(requirementFor('POST', '/bills/12/events'), { key: 'Sales', action: 'read' });
  assert.deepStrictEqual(requirementFor('PUT', '/bills/12/options'), { key: 'Sales', action: 'write' });
});

test('notes are the owner\'s even without dashboard write', () => {
  assert.deepStrictEqual(requirementFor('POST', '/dashboard/notes'), { key: 'Dashboard', action: 'read' });
});

test('a stored map is cleaned and internally consistent', () => {
  const clean = sanitizePermissions({
    Inventory: { write: true },
    Sales: { summary: true },
    'Settings: Billing': { read: true, summary: true },
    Hacked: { read: true, write: true },
  });
  assert.deepStrictEqual(clean.Inventory, { read: true, write: true, summary: false });
  assert.deepStrictEqual(clean.Sales, { read: true, write: false, summary: true });
  assert.deepStrictEqual(clean['Settings: Billing'], { read: true, write: false });
  assert.strictEqual(clean.Hacked, undefined);
});

test('nobody grants more than they hold, except a Super Admin', () => {
  const asked = sanitizePermissions({ Employee: { read: true, write: true, summary: true } });
  const manager = { isSuperAdmin: false, permissions: { Employee: { read: true, write: true } } };
  assert.deepStrictEqual(clampToGranter(asked, manager).Employee, { read: true, write: true, summary: false });
  assert.deepStrictEqual(clampToGranter(asked, { isSuperAdmin: true, permissions: {} }), asked);
});

test('store staff enter stock without seeing summaries', () => {
  const store = SYSTEM_ROLES.find((r) => r.key === 'store_staff');
  assert.strictEqual(store.permissions.Inventory.write, true);
  for (const access of Object.values(store.permissions)) {
    assert.notStrictEqual(access.summary, true);
  }
});

test('tokens verify, and a tampered one does not', () => {
  const token = sign(42);
  assert.strictEqual(verify(token), 42);
  const [payload, mac] = token.split('.');
  const forged = Buffer.from(JSON.stringify({ uid: 1, exp: Date.now() + 1e9 })).toString('base64url');
  assert.strictEqual(verify(`${forged}.${mac}`), null);
  assert.strictEqual(verify(`${payload}.x`), null);
  assert.strictEqual(verify(undefined), null);
});

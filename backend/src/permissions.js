// ─────────────────────────────────────────────────────────────────────────────
// The permission catalog — the one list of everything an employee can be
// granted, shared by the users/roles routes and the request guard.
//
// Mirrored in the app by lib/app/core/session/app_modules.dart. The two lists
// must name things identically: a permission is stored by its key, and the
// sidebar, the route guard and this file all read it back by that same key.
//
// Shape stored on users.permissions and roles.permissions:
//   {
//     "Products":            { "read": true, "write": false, "summary": true },
//     "Settings: Billing":   { "read": true, "write": false },
//     …
//   }
// ─────────────────────────────────────────────────────────────────────────────

/// Gateable modules. Every one has summary cards at the top of its page.
const MODULES = [
  'Dashboard',
  'Categories',
  'Products',
  'Purchase',
  'Sales',
  'Inventory',
  'Clients',
  'Transactions',
  'Employee',
  'Reports',
];

/// Settings tabs that change something beyond the signed-in person's own
/// account. Profile and Security are deliberately absent: they are where
/// someone reads their profile and changes their own password, so they are
/// always open.
const SETTINGS_SECTIONS = ['Notifications', 'Preferences', 'Billing', 'Appearance'];

const settingsKey = (section) => `Settings: ${section}`;

const SETTINGS_KEYS = SETTINGS_SECTIONS.map(settingsKey);

/// Every key a permission map may hold.
const ALL_KEYS = [...MODULES, ...SETTINGS_KEYS];

const isModuleKey = (key) => MODULES.includes(key);

/// Cleans a permission map from a request body.
///
/// Unknown keys are dropped and every flag is coerced to a strict boolean, so a
/// malformed body can never widen access. The dependencies are applied here
/// too — write and summary both mean nothing without read — so a stored map
/// is always internally consistent.
function sanitizePermissions(raw) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return undefined;
  const clean = {};
  for (const key of ALL_KEYS) {
    const value = raw[key];
    if (!value || typeof value !== 'object') continue;
    const write = value.write === true;
    const summary = isModuleKey(key) && value.summary === true;
    const read = value.read === true || write || summary;
    clean[key] = isModuleKey(key) ? { read, write, summary } : { read, write };
  }
  return clean;
}

/// Limits [requested] to what [granter] holds themselves.
///
/// Stops privilege escalation: an employee allowed to manage other employees
/// could otherwise hand someone (or a new role) more access than they have.
/// A Super Admin holds everything, so nothing is clipped for them.
function clampToGranter(requested, granter) {
  if (!requested || granter.isSuperAdmin) return requested;
  const out = {};
  for (const [key, access] of Object.entries(requested)) {
    const mine = granter.permissions[key] || {};
    out[key] = { read: access.read && mine.read === true, write: access.write && mine.write === true };
    if (isModuleKey(key)) out[key].summary = access.summary && mine.summary === true;
  }
  return sanitizePermissions(out);
}

/// Whether a permission map allows [action] ('read' | 'write' | 'summary') on
/// [key].
function allows(permissions, key, action) {
  const access = permissions && permissions[key];
  return !!access && access[action] === true;
}

// ── Ready-made roles ────────────────────────────────────────────────────────
// Rebuilt from this file on every server start (see roles.js), so adding a
// module here updates every preset without a migration. Presets are not
// editable in the app — a business that wants something different creates a
// custom role.

const R = { read: true, write: false, summary: false };
const RS = { read: true, write: false, summary: true };
const RW = { read: true, write: true, summary: false };
const RWS = { read: true, write: true, summary: true };
const SR = { read: true, write: false };
const SRW = { read: true, write: true };

function fullAccess() {
  const map = {};
  for (const m of MODULES) map[m] = { ...RWS };
  for (const k of SETTINGS_KEYS) map[k] = { ...SRW };
  return map;
}

const SYSTEM_ROLES = [
  {
    key: 'super_admin',
    name: 'Super Admin',
    description: 'Full access to all modules and settings',
    icon: 'stars',
    isSuperAdmin: true,
    permissions: fullAccess(),
  },
  {
    key: 'admin',
    name: 'Admin',
    description: 'Manage most modules and system settings',
    icon: 'admin',
    isSuperAdmin: false,
    // Everything except creating or editing employees, so an Admin can never
    // grant themselves (or anyone) more than they were given.
    permissions: { ...fullAccess(), Employee: { ...RS } },
  },
  {
    key: 'manager',
    name: 'Manager',
    description: 'Manage stock, purchases, sales and reports',
    icon: 'manager',
    isSuperAdmin: false,
    permissions: {
      Dashboard: { ...RS },
      Categories: { ...RWS },
      Products: { ...RWS },
      Purchase: { ...RWS },
      Sales: { ...RWS },
      Inventory: { ...RWS },
      Clients: { ...RWS },
      Transactions: { ...RS },
      Reports: { ...RS },
      [settingsKey('Notifications')]: { ...SRW },
      [settingsKey('Preferences')]: { ...SR },
      [settingsKey('Billing')]: { ...SR },
    },
  },
  {
    key: 'sales',
    name: 'Sales',
    description: 'Access to sales, customers and invoices',
    icon: 'sales',
    isSuperAdmin: false,
    permissions: {
      Dashboard: { ...R },
      Products: { ...R },
      Inventory: { ...R },
      Sales: { ...RW },
      Clients: { ...RW },
      [settingsKey('Notifications')]: { ...SRW },
    },
  },
  {
    key: 'store_staff',
    name: 'Store Staff',
    description: 'Access to stock and warehouse operations',
    icon: 'store',
    isSuperAdmin: false,
    // Stock entry without the business figures: no summary cards anywhere.
    permissions: {
      Dashboard: { ...R },
      Categories: { ...R },
      Products: { ...R },
      Purchase: { ...R },
      Inventory: { ...RW },
      [settingsKey('Notifications')]: { ...SRW },
    },
  },
];

/// Legacy users.role labels → the preset that replaces them.
const LEGACY_ROLE_KEYS = {
  Admin: 'super_admin',
  Manager: 'manager',
  Salesman: 'sales',
  'Stock Manager': 'store_staff',
};

module.exports = {
  MODULES,
  SETTINGS_SECTIONS,
  SETTINGS_KEYS,
  ALL_KEYS,
  settingsKey,
  sanitizePermissions,
  clampToGranter,
  allows,
  SYSTEM_ROLES,
  LEGACY_ROLE_KEYS,
};

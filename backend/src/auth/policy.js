const { settingsKey } = require('../permissions');

// ─────────────────────────────────────────────────────────────────────────────
// What each API request needs, by method and path (relative to /api).
//
// Returns null when being signed in is enough, otherwise
// { key, action } where action is 'read' | 'write' | 'summary'.
//
// The rules follow the screens:
//   * any change (POST/PUT/PATCH/DELETE) needs WRITE on the module that owns
//     the data;
//   * a module's own list needs READ on it — except the shared lookups
//     (products, categories, clients, settings/app) that other modules' forms
//     depend on, e.g. Add Sale picking a product and a client;
//   * the summary-card endpoints (/stats/*) need SUMMARY.
// ─────────────────────────────────────────────────────────────────────────────

/// Longest prefix first, so '/inventory/movements' is matched before
/// '/inventory'.
const byLength = (rules) => [...rules].sort((a, b) => b[0].length - a[0].length);

const WRITE_OWNERS = byLength([
  ['/categories', 'Categories'],
  ['/sub-categories', 'Categories'],
  ['/products', 'Products'],
  ['/purchase-orders', 'Purchase'],
  ['/sales-orders', 'Sales'],
  ['/bills', 'Sales'],
  ['/clients', 'Clients'],
  ['/inventory', 'Inventory'],
  ['/transactions', 'Transactions'],
  ['/users', 'Employee'],
  ['/roles', 'Employee'],
  ['/dashboard', 'Dashboard'],
  ['/settings/brand', settingsKey('Appearance')],
  ['/settings/billing', settingsKey('Billing')],
  ['/settings/app', settingsKey('Preferences')],
]);

const READ_OWNERS = byLength([
  ['/purchase-orders', 'Purchase'],
  ['/sales-orders', 'Sales'],
  ['/bills', 'Sales'],
  ['/transactions', 'Transactions'],
  ['/inventory', 'Inventory'],
  ['/users', 'Employee'],
  ['/roles', 'Employee'],
  ['/statements', 'Reports'],
  ['/dashboard', 'Dashboard'],
]);

/// /stats/<name> → the module whose summary cards it feeds.
const STATS_OWNERS = {
  categories: 'Categories',
  products: 'Products',
  purchase: 'Purchase',
  sales: 'Sales',
  inventory: 'Inventory',
  clients: 'Clients',
  transactions: 'Transactions',
  users: 'Employee',
  reports: 'Reports',
  analytics: 'Reports',
  'profit-loss': 'Reports',
};

const matches = (path, prefix) => path === prefix || path.startsWith(`${prefix}/`);

function ownerOf(rules, path) {
  const hit = rules.find(([prefix]) => matches(path, prefix));
  return hit ? hit[1] : null;
}

/// Requests anyone may make without signing in.
function isPublic(method, path) {
  if (method === 'POST' && path === '/auth/login') return true;
  // The login page is branded before anyone signs in.
  if (method === 'GET' && path === '/settings/brand') return true;
  return path === '/health';
}

function requirementFor(method, path) {
  if (matches(path, '/stats')) {
    const name = path.split('/')[2];
    const key = STATS_OWNERS[name];
    return key ? { key, action: 'summary' } : null;
  }

  // Notes are each person's own to-do list, so opening the dashboard is
  // enough to keep them — write access to it guards nothing else.
  if (matches(path, '/dashboard/notes')) return { key: 'Dashboard', action: 'read' };

  // Logging that a bill was shared (WhatsApp, email, payment link) records a
  // read action, not a change to the sale.
  if (method === 'POST' && /^\/bills\/\d+\/events$/.test(path)) {
    return { key: 'Sales', action: 'read' };
  }

  if (method === 'GET' || method === 'HEAD') {
    const key = ownerOf(READ_OWNERS, path);
    return key ? { key, action: 'read' } : null;
  }

  // /settings itself (profile, notifications, preferences, password) acts on
  // the caller's own account — checked field by field in routes/settings.js.
  const key = ownerOf(WRITE_OWNERS, path);
  return key ? { key, action: 'write' } : null;
}

module.exports = { isPublic, requirementFor };

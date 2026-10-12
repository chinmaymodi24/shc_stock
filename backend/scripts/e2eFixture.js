// Test data for integration_test/app_flow_test.dart.
//
//   node scripts/e2eFixture.js setup      create the user, client and product
//   node scripts/e2eFixture.js teardown   remove them and everything the test made
//
// Everything is named "ZZ-E2E…" so it can never be mistaken for real data, and
// teardown deletes only rows with that name. Run against a LOCAL backend that is
// already running on PORT (default 4000).
require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const { sign } = require('../src/auth/token');
const prisma = require('../src/prismaClient');

const BASE = `http://localhost:${process.env.PORT || 4000}/api`;
const EMAIL = 'zz-e2e@example.com';
const PASSWORD = 'E2eTest#1';
const TAG = 'ZZ-E2E';

async function api(method, route, body) {
  const admin = await prisma.user.findFirst({
    where: { isActive: true, roleRef: { isSuperAdmin: true } },
    select: { id: true },
  });
  const res = await fetch(BASE + route, {
    method,
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${sign(admin.id)}` },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  let json = null;
  try { json = JSON.parse(text); } catch (_) { /* not JSON */ }
  return { status: res.status, json, text };
}

async function teardown() {
  const sales = await prisma.salesOrder.findMany({ where: { client: { startsWith: TAG } }, select: { id: true } });
  for (const s of sales) await api('DELETE', `/sales-orders/${s.id}`).catch(() => {});
  await prisma.bill.deleteMany({ where: { salesOrder: { client: { startsWith: TAG } } } });
  await prisma.saleItem.deleteMany({ where: { product: { startsWith: TAG } } });
  await prisma.salesOrder.deleteMany({ where: { client: { startsWith: TAG } } });
  await prisma.stockMovement.deleteMany({ where: { product: { name: { startsWith: TAG } } } });
  const p = await prisma.product.deleteMany({ where: { name: { startsWith: TAG } } });
  const c = await prisma.client.deleteMany({ where: { name: { startsWith: TAG } } });
  const u = await prisma.user.deleteMany({ where: { email: EMAIL } });
  console.log(`removed ${p.count} product(s), ${c.count} client(s), ${u.count} user(s), ${sales.length} sale(s)`);
}

async function setup() {
  await teardown();
  const user = await api('POST', '/users', { name: `${TAG} Tester`, email: EMAIL, password: PASSWORD, roleId: 1 });
  if (user.status !== 201) throw new Error(`could not create the user: ${user.text}`);
  // A fixed password for the test: skip the "choose your own" screen.
  await prisma.user.update({ where: { id: user.json.id }, data: { mustChangePassword: false } });
  const client = await api('POST', '/clients', { name: `${TAG} Client`, gstin: '24AAACZ1234Z1Z5', regState: 'Gujarat' });
  if (client.status !== 201) throw new Error(`could not create the client: ${client.text}`);
  const cats = await api('GET', '/categories');
  const cat = (cats.json.items || cats.json)[0];
  const product = await api('POST', '/products', {
    name: `${TAG} Item`, sku: `${TAG}-1`, categoryId: cat.id, sellingPrice: 100, costPrice: 60,
    unit: 'Piece (pcs)', currentStock: 50, taxPercent: 18, hsnCode: '6806',
  });
  if (product.status !== 201) throw new Error(`could not create the product: ${product.text}`);
  console.log(`ready: sign in as ${EMAIL} / ${PASSWORD}`);
}

(async () => {
  const cmd = process.argv[2];
  try {
    if (cmd === 'setup') await setup();
    else if (cmd === 'teardown') await teardown();
    else throw new Error('usage: node scripts/e2eFixture.js setup|teardown');
  } catch (err) {
    console.error(err.message);
    process.exitCode = 1;
  } finally {
    await prisma.$disconnect();
  }
})();

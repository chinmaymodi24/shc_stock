/* eslint-disable no-console */
// Two sales for the same product sent at the same instant: only one may win.
//   node race_audit_test.js   (backend on :4000; creates and removes "ZZ-AUDIT" data)
require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const { sign } = require('./src/auth/token');
const prisma = new PrismaClient();
const BASE = process.env.BASE || 'http://localhost:4000/api';
const token = sign(48);
const call = async (m, p, b) => {
  const r = await fetch(BASE + p, { method: m, headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token }, body: b ? JSON.stringify(b) : undefined });
  const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; }
  return { s: r.status, j };
};
const body = (so, pid, qty) => ({ soNumber: so, client: 'ZZ-AUDIT c', date: new Date().toISOString(), amount: Math.round(qty * 100 * 1.18), status: 'Confirmed', paymentStatus: 'Pending', paidAmount: 0, items: [{ productId: pid, product: 'ZZ-AUDIT Race', qty, rate: 100, unit: 'PCS' }] });
(async () => {
  let ok = true;
  try {
    const cat = (await call('POST', '/categories', { name: 'ZZ-AUDIT race cat' })).j;
    const prod = (await call('POST', '/products', { name: 'ZZ-AUDIT Race', sku: 'ZZ-AUDIT-RACE', categoryId: cat.id, sellingPrice: 100, costPrice: 50, unit: 'PCS', currentStock: 5 })).j;
    for (let round = 1; round <= 5; round++) {
      // clear previous round's winners
      const old = await prisma.salesOrder.findMany({ where: { soNumber: { startsWith: 'ZZ-AUDIT-R' } }, select: { id: true } });
      for (const o of old) await call('DELETE', '/sales-orders/' + o.id);
      const results = await Promise.all([1, 2, 3, 4].map((i) => call('POST', '/sales-orders', body(`ZZ-AUDIT-R${round}-${i}`, prod.id, 4))));
      const wins = results.filter((r) => r.s === 201).length;
      const refused = results.filter((r) => r.s === 409).length;
      console.log(`round ${round}: 4 simultaneous sales of 4 (stock 5) -> ${wins} saved, ${refused} refused, other ${4 - wins - refused}`);
      if (wins !== 1) ok = false;
    }
    // Same for delivery: two open sales of 3 each against stock 5 can't exist
    // (reservation), so test two parallel DELIVERIES of one order + a manual OUT.
  } finally {
    const sos = await prisma.salesOrder.findMany({ where: { soNumber: { startsWith: 'ZZ-AUDIT' } }, select: { id: true } });
    for (const o of sos) await call('DELETE', '/sales-orders/' + o.id);
    await prisma.stockMovement.deleteMany({ where: { product: { name: { startsWith: 'ZZ-AUDIT' } } } });
    await prisma.product.deleteMany({ where: { name: { startsWith: 'ZZ-AUDIT' } } });
    await prisma.category.deleteMany({ where: { name: { startsWith: 'ZZ-AUDIT' } } });
    console.log('cleanup left:', await prisma.salesOrder.count({ where: { soNumber: { startsWith: 'ZZ-AUDIT' } } }), await prisma.product.count({ where: { name: { startsWith: 'ZZ-AUDIT' } } }));
    await prisma.$disconnect();
  }
  console.log(ok ? 'RACE: OK' : 'RACE: PROBLEM — more than one sale got through');
  process.exit(ok ? 0 : 1);
})();

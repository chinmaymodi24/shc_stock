/* eslint-disable no-console */
// End-to-end checks for the validation / stock-reservation / money-maths work.
//
//   BASE=http://localhost:4100/api node e2e_audit_test.js
//
// Talks to a running backend (start a second one on another port so the one
// you are using isn't disturbed:  PORT=4100 node src/server.js) and to the real
// database. Everything it creates is named "ZZ-AUDIT ..." and is removed in the
// `finally` block, whether the checks pass or not.
require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const { sign } = require('./src/auth/token');
const { runDeliverySweep } = require('./src/deliverySweep');

const BASE = process.env.BASE || 'http://localhost:4100/api';
const prisma = new PrismaClient();

let passed = 0;
let failed = 0;
const failures = [];
function check(name, cond, detail = '') {
  if (cond) {
    passed += 1;
  } else {
    failed += 1;
    failures.push(`${name}${detail ? ` — ${detail}` : ''}`);
    console.error(`FAIL  ${name}${detail ? `\n      ${detail}` : ''}`);
  }
}

let token;
async function call(method, path, body) {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const raw = await res.text();
  let json = null;
  try {
    json = raw ? JSON.parse(raw) : null;
  } catch (_) {
    json = raw;
  }
  return { status: res.status, json, raw };
}

const TAG = 'ZZ-AUDIT';
const today = () => new Date().toISOString();
const daysFromNow = (n) => new Date(Date.now() + n * 86400000).toISOString();

/// A sale body that passes validation. Totals add 18% GST like the app does.
function saleBody(soNumber, lines, over = {}) {
  const base = lines.reduce((s, l) => s + l.qty * l.rate, 0);
  return {
    soNumber,
    client: `${TAG} client`,
    date: today(),
    amount: Math.round(base * 1.18),
    status: 'Confirmed',
    paymentStatus: 'Pending',
    paidAmount: 0,
    items: lines,
    ...over,
  };
}

function poBody(poNumber, lines, over = {}) {
  const base = lines.reduce((s, l) => s + l.qty * l.rate, 0);
  return {
    poNumber,
    supplier: `${TAG} supplier`,
    date: today(),
    amount: Math.round(base * 1.18),
    status: 'Pending',
    paidAmount: 0,
    items: lines,
    ...over,
  };
}

/// A product with its stock columns as plain numbers (this script's own
/// PrismaClient returns DECIMAL columns as Decimal objects).
const product = async (id) => {
  const p = await prisma.product.findUnique({ where: { id } });
  return p && { ...p, currentStock: Number(p.currentStock), minimumStock: Number(p.minimumStock) };
};

async function stats(path) {
  const r = await call('GET', `/stats/${path}`);
  return r.json;
}

async function main() {
  token = sign(48); // the real Super Admin
  const health = await fetch(BASE.replace(/\/api$/, '/health'));
  if (!health.ok) throw new Error(`backend not reachable at ${BASE}`);

  // ── fixtures ──────────────────────────────────────────────────────────────
  const cat = (await call('POST', '/categories', { name: `${TAG} cat`, description: null })).json;
  check('category with description:null saves (was a 500)', !!cat.id, JSON.stringify(cat));
  const otherCat = (await call('POST', '/categories', { name: `${TAG} other cat` })).json;
  const sub = (await call('POST', `/categories/${otherCat.id}/sub-categories`, { name: `${TAG} sub` })).json;

  // ═══ #3  product edit must not touch stock ════════════════════════════════
  console.log('· products');
  const bad = async (body) => call('POST', '/products', { name: `${TAG} p`, sku: `${TAG}-X`, categoryId: cat.id, sellingPrice: 100, costPrice: 60, unit: 'PCS', ...body });
  let r = await bad({ sellingPrice: 'abc' });
  check('price "abc" -> 400, not 500', r.status === 400, `${r.status} ${r.raw.slice(0, 80)}`);
  check('400 does not leak a Prisma query or a file path', !/prisma|\\\\|src[\\/]/i.test(r.raw), r.raw.slice(0, 120));
  r = await bad({ costPrice: -1 });
  check('negative cost price -> 400', r.status === 400);
  r = await bad({ name: '   ' });
  check('blank name -> 400', r.status === 400);
  r = await bad({ taxPercent: 500 });
  check('tax 500% -> 400', r.status === 400);
  r = await bad({ subCategoryId: sub.id });
  check('sub-category from another category -> 400', r.status === 400 && /does not belong/.test(r.raw), r.raw);
  r = await bad({ currentStock: 2.5 });
  check('fractional opening stock -> 400', r.status === 400);

  const brick = (await call('POST', '/products', {
    name: `${TAG} Brick`, sku: `${TAG}-BRICK`, categoryId: cat.id, sellingPrice: 100, costPrice: 60, unit: 'PCS', currentStock: 10,
  })).json;
  check('product created', !!brick.id, JSON.stringify(brick).slice(0, 150));
  check('opening stock 10 is on the product', brick.currentStock === 10);
  let moves = await prisma.stockMovement.findMany({ where: { productId: brick.id } });
  check('opening stock was booked in the ledger', moves.length === 1 && moves[0].type === 'IN' && Number(moves[0].qty) === 10 && moves[0].reference === 'Opening stock', JSON.stringify(moves));

  r = await call('PUT', `/products/${brick.id}`, { name: `${TAG} Brick renamed`, currentStock: 999 });
  check('PUT accepted', r.status === 200, r.raw.slice(0, 100));
  check('PUT with currentStock:999 leaves stock at 10', (await product(brick.id)).currentStock === 10);
  moves = await prisma.stockMovement.findMany({ where: { productId: brick.id } });
  check('PUT wrote nothing to the ledger', moves.length === 1);
  const afterPut = await product(brick.id);
  check('PUT sent only name: sku/unit/prices untouched', afterPut.sku === `${TAG}-BRICK` && afterPut.unit === 'PCS' && Number(afterPut.sellingPrice) === 100 && Number(afterPut.costPrice) === 60);
  r = await call('PUT', `/products/${brick.id}`, { sellingPrice: 120 });
  const afterPrice = await product(brick.id);
  check('partial PUT changes only the price', Number(afterPrice.sellingPrice) === 120 && afterPrice.name === `${TAG} Brick renamed` && afterPrice.currentStock === 10);
  r = await call('PUT', `/products/${brick.id}`, { sellingPrice: 'oops' });
  check('PUT with a bad price -> 400', r.status === 400);
  r = await call('PUT', '/products/abc', { name: 'x' });
  check('PUT /products/abc -> 400', r.status === 400);

  const free = (await call('POST', '/products', {
    name: `${TAG} Free`, sku: `${TAG}-FREE`, categoryId: cat.id, sellingPrice: 10, costPrice: 5, unit: 'PCS',
  })).json;
  check('a product without stock starts at 0 with no ledger rows', free.currentStock === 0 && (await prisma.stockMovement.count({ where: { productId: free.id } })) === 0);

  // ═══ #5  order validation (was: accepted anything) ═════════════════════════
  console.log('· order validation');
  const okLines = [{ productId: brick.id, product: `${TAG} Brick`, qty: 1, rate: 100, unit: 'PCS' }];
  const expectBad = async (label, body, rx) => {
    const res = await call('POST', '/sales-orders', body);
    check(`sale rejected: ${label}`, res.status === 400 && (!rx || rx.test(res.raw)), `${res.status} ${res.raw.slice(0, 140)}`);
    if (res.status === 201) await call('DELETE', `/sales-orders/${res.json.id}`);
  };
  await expectBad('invalid date', saleBody(`${TAG}-V1`, okLines, { date: 'notadate' }), /not a valid date/);
  await expectBad('negative amount', saleBody(`${TAG}-V2`, okLines, { amount: -999 }));
  await expectBad('amount below the items', saleBody(`${TAG}-V3`, okLines, { amount: 10 }), /less than the items/);
  await expectBad('no items', saleBody(`${TAG}-V4`, [], { amount: 0 }), /at least one item/);
  await expectBad('only an empty row', saleBody(`${TAG}-V5`, [{ product: '', qty: 0, rate: 0 }], { amount: 0 }), /at least one item/);
  await expectBad('status "Banana"', saleBody(`${TAG}-V6`, okLines, { status: 'Banana' }), /status must be one of/);
  await expectBad('paymentStatus "Whatever"', saleBody(`${TAG}-V7`, okLines, { paymentStatus: 'Whatever' }), /paymentStatus must be one of/);
  await expectBad('paid more than the amount', saleBody(`${TAG}-V8`, okLines, { paidAmount: 500000 }), /more than the order amount/);
  await expectBad('negative quantity', saleBody(`${TAG}-V9`, [{ ...okLines[0], qty: -5 }], { amount: 0 }));
  await expectBad('zero quantity', saleBody(`${TAG}-V10`, [{ ...okLines[0], qty: 0 }], { amount: 0 }), /greater than 0/);
  await expectBad('negative rate', saleBody(`${TAG}-V11`, [{ ...okLines[0], rate: -100 }], { amount: 0 }));
  await expectBad('missing client', saleBody(`${TAG}-V12`, okLines, { client: '' }), /client is required/);
  await expectBad('expected delivery before the order date', saleBody(`${TAG}-V13`, okLines, { expectedDelivery: daysFromNow(-30) }), /cannot be before/);
  await expectBad('bad paymentType', saleBody(`${TAG}-V14`, okLines, { paymentType: 'Bitcoin' }), /paymentType must be one of/);
  // #6 whole units
  await expectBad('fractional qty on a product-linked line', saleBody(`${TAG}-V15`, [{ ...okLines[0], qty: 2.5 }], { amount: 300 }), /whole number/);

  let res = await call('POST', '/sales-orders', saleBody(`${TAG}-V16`, [{ product: `${TAG} loose item`, qty: 2.5, rate: 40, unit: 'kg' }]));
  check('a free-typed line may carry a fractional quantity', res.status === 201, `${res.status} ${res.raw.slice(0, 100)}`);
  if (res.status === 201) await call('DELETE', `/sales-orders/${res.json.id}`);

  res = await call('POST', '/sales-orders', { soNumber: `${TAG}-V17`, client: 'c', date: 'notadate' });
  check('the old crashing request (bad date, no items) is a 400, not a 500', res.status === 400);
  res = await call('PATCH', '/sales-orders/abc/status', { status: 'Delivered' });
  check('PATCH /sales-orders/abc/status -> 400', res.status === 400);

  const poBad = async (label, body, rx) => {
    const x = await call('POST', '/purchase-orders', body);
    check(`purchase rejected: ${label}`, x.status === 400 && (!rx || rx.test(x.raw)), `${x.status} ${x.raw.slice(0, 120)}`);
    if (x.status === 201) await call('DELETE', `/purchase-orders/${x.json.id}`);
  };
  await poBad('no items', poBody(`${TAG}-P1`, [], { amount: 0 }), /at least one item/);
  await poBad('status "Banana"', poBody(`${TAG}-P2`, okLines, { status: 'Banana' }), /status must be one of/);
  await poBad('blank supplier', poBody(`${TAG}-P3`, okLines, { supplier: '' }), /supplier is required/);
  await poBad('paid more than the amount', poBody(`${TAG}-P4`, okLines, { paidAmount: 999999 }), /more than the order amount/);
  await poBad('due date before invoice date', poBody(`${TAG}-P5`, okLines, { invoiceDate: today(), dueDate: daysFromNow(-10) }), /cannot be before/);
  await poBad('fractional product-linked qty', poBody(`${TAG}-P6`, [{ ...okLines[0], qty: 1.5 }], { amount: 200 }), /whole number/);
  res = await call('PATCH', '/purchase-orders/1/status', { status: 'Banana' });
  check('purchase status PATCH with an unknown status -> 400', res.status === 400);

  // ═══ #6  manual adjustment must be whole units ════════════════════════════
  console.log('· whole-unit quantities');
  res = await call('POST', '/inventory/adjust', { productId: brick.id, type: 'IN', qty: 2.5 });
  check('fractional manual adjustment -> 400', res.status === 400 && /whole number/.test(res.raw), res.raw);
  res = await call('POST', '/inventory/adjust', { productId: brick.id, type: 'SIDEWAYS', qty: 1 });
  check('adjustment with a bad type -> 400', res.status === 400);
  res = await call('POST', '/inventory/adjust', { productId: brick.id, type: 'IN', qty: -3 });
  check('negative adjustment -> 400', res.status === 400);
  check('none of those changed the stock', (await product(brick.id)).currentStock === 10);

  // ═══ #2  open orders reserve stock ════════════════════════════════════════
  console.log('· stock reservation');
  const line = (qty) => [{ productId: brick.id, product: `${TAG} Brick`, qty, rate: 100, unit: 'PCS' }];
  const A = await call('POST', '/sales-orders', saleBody(`${TAG}-A`, line(6)));
  check('sale A (6 of 10) saved', A.status === 201, A.raw.slice(0, 150));
  check('an open sale does not touch the stock yet', (await product(brick.id)).currentStock === 10);

  let list = (await call('GET', '/products?limit=500')).json;
  let rows = Array.isArray(list) ? list : (list.items || list.data || []);
  let mine = rows.find((p) => p.id === brick.id);
  check('/products reports 6 committed', mine && mine.committedStock === 6, JSON.stringify(mine && { c: mine.committedStock, a: mine.availableStock }));
  check('/products reports 4 available', mine && mine.availableStock === 4);
  const inv = (await call('GET', '/inventory?limit=500')).json;
  const invRows = Array.isArray(inv) ? inv : (inv.items || inv.data || []);
  const invMine = invRows.find((p) => p.productId === brick.id);
  check('/inventory availableStock = 4 (stock less what open sales hold)', invMine && invMine.availableStock === 4 && invMine.stockInHand === 10, JSON.stringify(invMine && { a: invMine.availableStock, h: invMine.stockInHand }));

  let B = await call('POST', '/sales-orders', saleBody(`${TAG}-B`, line(5)));
  check('sale B (5) is refused: only 4 are free', B.status === 409, `${B.status} ${B.raw.slice(0, 150)}`);
  check('the 409 names the product and the free quantity', /Brick/.test(B.raw) && /only 4 available/.test(B.raw) && Array.isArray(B.json && B.json.details), B.raw.slice(0, 200));
  check('the refused sale left no order behind', (await prisma.salesOrder.count({ where: { soNumber: `${TAG}-B` } })) === 0);
  B = await call('POST', '/sales-orders', saleBody(`${TAG}-B`, line(4)));
  check('sale B (4) fits exactly', B.status === 201, B.raw.slice(0, 150));
  let C = await call('POST', '/sales-orders', saleBody(`${TAG}-C`, line(1)));
  check('sale C (1) is refused: nothing is free any more', C.status === 409, `${C.status}`);

  res = await call('PUT', `/sales-orders/${A.json.id}`, saleBody(`${TAG}-A`, line(6)));
  check('re-saving A at the same 6 works (it does not count against itself)', res.status === 200, `${res.status} ${res.raw.slice(0, 120)}`);
  res = await call('PUT', `/sales-orders/${A.json.id}`, saleBody(`${TAG}-A`, line(7)));
  check('raising A to 7 is refused (7 + B\'s 4 > 10)', res.status === 409, `${res.status}`);
  res = await call('PUT', `/sales-orders/${A.json.id}`, saleBody(`${TAG}-A`, line(5)));
  check('lowering A to 5 works', res.status === 200);

  res = await call('PATCH', `/sales-orders/${B.json.id}/status`, { status: 'Cancelled' });
  check('cancelling B', res.status === 200);
  C = await call('POST', '/sales-orders', saleBody(`${TAG}-C`, line(5)));
  check('after cancelling B its 4 are free again: C (5) fits', C.status === 201, `${C.status} ${C.raw.slice(0, 120)}`);
  res = await call('PATCH', `/sales-orders/${B.json.id}/status`, { status: 'Confirmed' });
  check('re-opening cancelled B (4) is refused: no room', res.status === 409, `${res.status}`);

  res = await call('PATCH', `/sales-orders/${A.json.id}/status`, { status: 'Delivered' });
  check('delivering A (5)', res.status === 200, res.raw.slice(0, 120));
  check('delivering took 5 out of stock', (await product(brick.id)).currentStock === 5);
  const Dsale = await call('POST', '/sales-orders', saleBody(`${TAG}-D`, line(1)));
  check('stock 5, C holds 5 -> a new sale of 1 is refused', Dsale.status === 409, `${Dsale.status}`);

  // The manual write-off leaves C promised more than exists. Delivery must fail
  // loudly, and the sweep must leave a to-do rather than only a log line.
  res = await call('POST', '/inventory/adjust', { productId: brick.id, type: 'OUT', qty: 2, note: 'audit write-off' });
  check('manual OUT of 2 (stock 5 -> 3)', res.status === 201, res.raw.slice(0, 100));
  res = await call('PATCH', `/sales-orders/${C.json.id}/status`, { status: 'Delivered' });
  check('delivering C (5) with 3 left -> 409 naming the product', res.status === 409 && /Brick/.test(res.raw) && /3 available/.test(res.raw), `${res.status} ${res.raw.slice(0, 160)}`);
  check('C is still open after the failed delivery', (await prisma.salesOrder.findUnique({ where: { id: C.json.id } })).status === 'Confirmed');

  await prisma.salesOrder.update({ where: { id: C.json.id }, data: { expectedDelivery: new Date(Date.now() - 86400000) } });
  await runDeliverySweep();
  let notes = await prisma.dashboardNote.findMany({ where: { text: { contains: `${TAG}-C` } } });
  check('the sweep left ONE to-do about the stuck sale', notes.length === 1 && !notes[0].done && /could not be delivered/.test(notes[0].text), JSON.stringify(notes));
  check('the to-do names the product and the shortfall', notes[0] && /Brick/.test(notes[0].text) && /3 available/.test(notes[0].text), notes[0] && notes[0].text);
  await runDeliverySweep();
  notes = await prisma.dashboardNote.findMany({ where: { text: { contains: `${TAG}-C` } } });
  check('a second sweep does not add a duplicate', notes.length === 1, `${notes.length}`);
  res = await call('POST', '/inventory/adjust', { productId: brick.id, type: 'IN', qty: 5, note: 'audit restock' });
  await runDeliverySweep();
  check('once restocked the sweep delivers C', (await prisma.salesOrder.findUnique({ where: { id: C.json.id } })).status === 'Delivered');
  notes = await prisma.dashboardNote.findMany({ where: { text: { contains: `${TAG}-C` } } });
  check('…and ticks the to-do off', notes.length === 1 && notes[0].done === true);
  check('stock is now 3 + 5 - 5 = 3', (await product(brick.id)).currentStock === 3);

  // ═══ #4  receivables / payables / cancelled ═══════════════════════════════
  console.log('· money maths');
  const s0 = await stats('sales');
  const p0 = await stats('purchase');
  const r0 = await stats('reports');
  const loose = (qty, rate) => [{ product: `${TAG} loose`, qty, rate, unit: 'PCS' }];

  // 1000 + 18% = 1180; 400 paid -> 780 owed
  const E = await call('POST', '/sales-orders', saleBody(`${TAG}-E`, loose(10, 100), { amount: 1180, paymentStatus: 'Partial', paymentType: 'Other', paidAmount: 400 }));
  check('part-paid sale saved', E.status === 201, `${E.status} ${E.raw.slice(0, 120)}`);
  let s1 = await stats('sales');
  check('amount due rises by what is LEFT (780), not 1180', Math.abs((s1.amountDue - s0.amountDue) - 780) < 0.01, `delta ${s1.amountDue - s0.amountDue}`);
  check('total sales rises by 1180', Math.abs((s1.totalSales - s0.totalSales) - 1180) < 0.01);
  check('total received rises by the 400 paid', Math.abs((s1.totalReceived - s0.totalReceived) - 400) < 0.01, `delta ${s1.totalReceived - s0.totalReceived}`);
  let r1 = await stats('reports');
  check('Reports receivable agrees (+780)', r1 && r0 && Math.abs((r1.sales.receivable - r0.sales.receivable) - 780) < 0.01, JSON.stringify(r1 && r1.sales));

  res = await call('PATCH', `/sales-orders/${E.json.id}/status`, { paymentStatus: 'Paid' });
  check('marking Paid', res.status === 200);
  check('"Paid" sets paidAmount to the full amount', Number(res.json.paidAmount) === 1180, String(res.json && res.json.paidAmount));
  s1 = await stats('sales');
  check('once Paid, nothing is due (delta 0)', Math.abs(s1.amountDue - s0.amountDue) < 0.01, `delta ${s1.amountDue - s0.amountDue}`);
  res = await call('PATCH', `/sales-orders/${E.json.id}/status`, { paymentStatus: 'Pending' });
  check('back to Pending resets paidAmount to 0', Number(res.json.paidAmount) === 0);
  s1 = await stats('sales');
  check('Pending: the whole 1180 is owed again', Math.abs((s1.amountDue - s0.amountDue) - 1180) < 0.01, `delta ${s1.amountDue - s0.amountDue}`);

  res = await call('PATCH', `/sales-orders/${E.json.id}/status`, { status: 'Cancelled' });
  check('cancelling E', res.status === 200);
  s1 = await stats('sales');
  check('a CANCELLED sale is out of Total Sales', Math.abs(s1.totalSales - s0.totalSales) < 0.01, `delta ${s1.totalSales - s0.totalSales}`);
  check('…out of what is due', Math.abs(s1.amountDue - s0.amountDue) < 0.01);
  check('…and out of the order count', s1.totalOrders === s0.totalOrders, `${s1.totalOrders} vs ${s0.totalOrders}`);
  r1 = await stats('reports');
  check('…and out of Reports sales total + receivable', Math.abs(r1.sales.total - r0.sales.total) < 0.01 && Math.abs(r1.sales.receivable - r0.sales.receivable) < 0.01, JSON.stringify(r1.sales));

  // Purchase: Received but only 300 of 1180 paid -> payable 880 (it used to be 0).
  const PO = await call('POST', '/purchase-orders', poBody(`${TAG}-PO`, loose(10, 100), { amount: 1180, status: 'Received', paymentType: 'Other', paidAmount: 300 }));
  check('purchase saved', PO.status === 201, `${PO.status} ${PO.raw.slice(0, 120)}`);
  let p1 = await stats('purchase');
  check('a RECEIVED but part-paid purchase still owes the rest (+880 due)', Math.abs((p1.amountDue - p0.amountDue) - 880) < 0.01, `delta ${p1.amountDue - p0.amountDue}`);
  check('amount paid rises by the 300 actually paid (not 1180 for "received")', Math.abs((p1.amountPaid - p0.amountPaid) - 300) < 0.01, `delta ${p1.amountPaid - p0.amountPaid}`);
  r1 = await stats('reports');
  check('Reports payable agrees (+880)', Math.abs((r1.purchase.payable - r0.purchase.payable) - 880) < 0.01, JSON.stringify(r1.purchase));
  const bs = (await call('GET', '/statements/balance-sheet')).json;
  check('balance sheet payables include it', bs && bs.liabilities && bs.liabilities.tradePayables >= 880 - 0.01, JSON.stringify(bs && bs.liabilities));
  res = await call('PATCH', `/purchase-orders/${PO.json.id}/status`, { status: 'Cancelled' });
  p1 = await stats('purchase');
  check('a CANCELLED purchase leaves the figures', Math.abs(p1.amountDue - p0.amountDue) < 0.01 && Math.abs(p1.amountPaid - p0.amountPaid) < 0.01 && p1.totalOrders === p0.totalOrders);


  // ═══ #11 bills, #12 clients, #13 users ════════════════════════════════════
  console.log('· clients');
  const cl = (over) => ({ name: `${TAG} Client`, phone: '9876543210', ...over });
  r = await call('POST', '/clients', cl({ gstin: 'hello' }));
  check('GSTIN "hello" -> 400', r.status === 400 && /GSTIN/.test(r.raw), `${r.status} ${r.raw.slice(0, 100)}`);
  r = await call('POST', '/clients', cl({ pan: '123' }));
  check('PAN "123" -> 400', r.status === 400 && /PAN/.test(r.raw));
  r = await call('POST', '/clients', cl({ regPin: '12' }));
  check('PIN "12" -> 400', r.status === 400 && /PIN/.test(r.raw));
  r = await call('POST', '/clients', cl({ email: 'nope' }));
  check('email "nope" -> 400', r.status === 400 && /Email/.test(r.raw));
  const goodGst = '24ABCDE1234F1Z5';
  r = await call('POST', '/clients', cl({ gstin: goodGst.toLowerCase(), pan: 'abcde1234f', regPin: '380001', email: 'a@b.co' }));
  check('a valid client saves (GSTIN/PAN upper-cased)', r.status === 201 && r.json.gstin === goodGst && r.json.pan === 'ABCDE1234F', `${r.status} ${r.raw.slice(0, 120)}`);
  const c1 = r.json;
  r = await call('POST', '/clients', cl({ name: `${TAG} client`.toUpperCase() }));
  check('same name in another case -> 409', r.status === 409, `${r.status} ${r.raw.slice(0, 100)}`);
  r = await call('POST', '/clients', cl({ name: `${TAG} Client Two`, gstin: goodGst }));
  check('same GSTIN under another name -> 409', r.status === 409 && /GSTIN/.test(r.raw), `${r.status} ${r.raw.slice(0, 100)}`);
  r = await call('PUT', `/clients/${c1.id}`, cl({ gstin: goodGst, regPin: '380001', email: 'a@b.co', pan: 'ABCDE1234F' }));
  check('editing a client does not clash with itself', r.status === 200, `${r.status} ${r.raw.slice(0, 100)}`);
  r = await call('PUT', `/clients/${c1.id}`, cl({ gstin: 'garbage' }));
  check('PUT with a bad GSTIN -> 400', r.status === 400);
  r = await call('PUT', '/clients/99999999', cl({ name: `${TAG} nobody` }));
  check('PUT on a missing client -> 404', r.status === 404);

  // A client that has orders cannot be deleted.
  const cOrder = await call('POST', '/sales-orders', saleBody(`${TAG}-CL1`, loose(1, 100), { client: c1.name }));
  check('sale for the client saved', cOrder.status === 201, `${cOrder.status} ${cOrder.raw.slice(0, 100)}`);
  r = await call('DELETE', `/clients/${c1.id}`);
  check('deleting a client with orders -> 409', r.status === 409 && /sales order/.test(r.raw), `${r.status} ${r.raw.slice(0, 100)}`);

  console.log('· bills');
  const sold = cOrder.json;
  r = await call('POST', '/bills', { salesOrderId: sold.id });
  check('a bill can be raised for a live sale', r.status === 201 || r.status === 200, `${r.status} ${r.raw.slice(0, 100)}`);
  const billNo = r.json && r.json.invoiceNo;
  r = await call('PUT', `/sales-orders/${sold.id}`, saleBody(`${TAG}-CL1`, loose(1, 100), { client: c1.name }));
  check('a billed sale cannot be edited -> 409', r.status === 409 && /invoice/i.test(r.raw), `${r.status} ${r.raw.slice(0, 120)}`);
  r = await call('DELETE', `/sales-orders/${sold.id}`);
  check('a billed sale cannot be deleted -> 409', r.status === 409, `${r.status} ${r.raw.slice(0, 100)}`);
  r = await call('PATCH', `/sales-orders/${sold.id}/status`, { status: 'Cancelled' });
  check('a billed sale can still be cancelled', r.status === 200, `${r.status} ${r.raw.slice(0, 100)}`);
  const cOrder2 = await call('POST', '/sales-orders', saleBody(`${TAG}-CL2`, loose(1, 100), { client: `${TAG} client`, status: 'Cancelled' }));
  r = await call('POST', '/bills', { salesOrderId: cOrder2.json.id });
  check('a CANCELLED sale cannot be invoiced -> 409', r.status === 409, `${r.status} ${r.raw.slice(0, 100)}`);
  const cOrder3 = await call('POST', '/sales-orders', saleBody(`${TAG}-CL3`, loose(1, 100), { client: `${TAG} client`, invoiceNo: billNo }));
  r = await call('POST', '/bills', { salesOrderId: cOrder3.json.id });
  check('an invoice number already used -> 409, not a 500', r.status === 409 && /already used/.test(r.raw), `${r.status} ${r.raw.slice(0, 120)}`);

  console.log('· users');
  const role = await prisma.role.findFirst({ where: { isSuperAdmin: false } });
  const emp = (over) => ({ name: `${TAG} Emp`, email: 'zz-audit-emp@example.com', roleId: role.id, ...over });
  r = await call('POST', '/users', emp({}));
  check('employee with no password -> 400 (no built-in default)', r.status === 400 && /password/.test(r.raw), `${r.status} ${r.raw.slice(0, 100)}`);
  r = await call('POST', '/users', emp({ password: '123' }));
  check('3-character password -> 400', r.status === 400 && /at least 6/.test(r.raw));
  r = await call('POST', '/users', emp({ password: 'goodpass1' }));
  check('employee with a real password saves', r.status === 201, `${r.status} ${r.raw.slice(0, 100)}`);
  const empId = r.json && r.json.id;
  let lg = await fetch(`${BASE}/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: 'zz-audit-emp@example.com', password: 'shc@12345' }) });
  check('the old default password does NOT log in', lg.status === 401, String(lg.status));
  lg = await fetch(`${BASE}/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: 'zz-audit-emp@example.com', password: 'goodpass1' }) });
  check('the typed password logs in', lg.status === 200, String(lg.status));
  const empLogin = await lg.json();
  check('a new employee is flagged mustChangePassword', empLogin.mustChangePassword === true, JSON.stringify(empLogin).slice(0, 80));
  let empToken = empLogin.token;
  const asEmp = async (method, path, body) => {
    const res = await fetch(`${BASE}${path}`, { method, headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${empToken}` }, body: body === undefined ? undefined : JSON.stringify(body) });
    const raw = await res.text();
    let json = null; try { json = raw ? JSON.parse(raw) : null; } catch (_) { json = raw; }
    return { status: res.status, json, raw };
  };
  r = await asEmp('GET', '/products');
  check('until they set their own, other calls are refused (403 + code)', r.status === 403 && r.json && r.json.code === 'PASSWORD_CHANGE_REQUIRED', `${r.status} ${r.raw.slice(0, 100)}`);
  r = await asEmp('GET', '/auth/me');
  check('…but /auth/me still works', r.status === 200 && r.json.mustChangePassword === true, `${r.status}`);
  r = await asEmp('POST', '/settings/password', { currentPassword: 'goodpass1', newPassword: 'goodpass1' });
  check('the new password must differ from the old one', r.status === 400, `${r.status} ${r.raw.slice(0, 100)}`);
  r = await asEmp('POST', '/settings/password', { currentPassword: 'goodpass1', newPassword: 'abc' });
  check('a 3-character new password -> 400', r.status === 400);
  r = await asEmp('POST', '/settings/password', { currentPassword: 'goodpass1', newPassword: 'MyOwn#Pass9' });
  check('choosing their own password works', r.status === 200, `${r.status} ${r.raw.slice(0, 100)}`);
  check('…and hands back a fresh token', r.status === 200 && typeof (r.json || {}).token === 'string' && r.json.token !== empToken, r.raw.slice(0, 80));
  const staleToken = empToken;
  empToken = (r.json || {}).token;
  await new Promise((ok) => setTimeout(ok, 100));
  r = await fetch(`${BASE}/auth/me`, { headers: { Authorization: `Bearer ${staleToken}` } });
  check('the token from before the change is refused (401)', r.status === 401, String(r.status));
  r = await asEmp('GET', '/auth/me');
  check('the flag is cleared afterwards', r.status === 200 && r.json.mustChangePassword === false, JSON.stringify(r.json).slice(0, 80));
  r = await asEmp('GET', '/products');
  check('…and normal calls work again', r.status === 200, `${r.status} ${r.raw.slice(0, 80)}`);
  r = await call('PUT', `/users/${empId}`, emp({ password: 'ResetByAdmin1' }));
  check('an admin resetting a password sets the flag again', r.status === 200, `${r.status}`);
  r = await asEmp('GET', '/products');
  check('…and their session from before the reset is ended (401)', r.status === 401, `${r.status}`);
  lg = await fetch(`${BASE}/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: 'zz-audit-emp@example.com', password: 'ResetByAdmin1' }) });
  empToken = (await lg.json()).token;
  r = await asEmp('GET', '/products');
  check('…signing in with the reset password holds them until they choose again', r.status === 403 && r.json && r.json.code === 'PASSWORD_CHANGE_REQUIRED', `${r.status}`);
  r = await call('PUT', `/users/${empId}`, emp({ password: 'abc' }));
  check('PUT with a 3-character password -> 400', r.status === 400);
  r = await call('PATCH', `/users/${empId}/status`, { isActive: false });
  check('an ordinary employee can be deactivated', r.status === 200);
  const sa = await prisma.user.findMany({ where: { isActive: true, roleRef: { isSuperAdmin: true } }, select: { id: true } });
  if (sa.length === 1) {
    r = await call('PUT', `/users/${sa[0].id}`, { name: 'x', email: 'x@y.co', isActive: false });
    check('the last ACTIVE Super Admin cannot be switched off via PUT', r.status === 409, `${r.status} ${r.raw.slice(0, 100)}`);
  }

  // ═══ remaining audit items ═══════════════════════════════════════════════
  console.log('· duplicates');
  r = await call('POST', '/categories', { name: `  ${TAG.toLowerCase()} CAT ` });
  check('a category with the same name (any case, spaces) -> 409', r.status === 409 && /already exists/.test(r.raw), `${r.status} ${r.raw.slice(0, 100)}`);
  r = await call('PUT', `/categories/${otherCat.id}`, { name: `${TAG} cat` });
  check('renaming a category onto another one -> 409', r.status === 409, `${r.status}`);
  r = await call('PUT', `/categories/${cat.id}`, { name: `${TAG} cat` });
  check('saving a category under its own name is fine', r.status === 200, `${r.status}`);
  r = await call('POST', `/categories/${otherCat.id}/sub-categories`, { name: `${TAG.toUpperCase()} SUB` });
  check('a duplicate sub-category in the same category -> 409', r.status === 409, `${r.status} ${r.raw.slice(0, 100)}`);
  const sub2 = (await call('POST', `/categories/${cat.id}/sub-categories`, { name: `${TAG} sub` })).json;
  check('the same sub-category name under ANOTHER category is fine', !!(sub2 && sub2.id), JSON.stringify(sub2));
  r = await call('PUT', `/sub-categories/${sub2.id}`, { name: `${TAG} sub` });
  check('editing a sub-category under its own name is fine', r.status === 200, `${r.status}`);
  const sub3 = (await call('POST', `/categories/${cat.id}/sub-categories`, { name: `${TAG} sub three` })).json;
  r = await call('PUT', `/sub-categories/${sub3.id}`, { name: `${TAG} SUB` });
  check('renaming a sub-category onto a sibling -> 409', r.status === 409, `${r.status}`);

  const pbody = (over) => ({ name: `${TAG} Dup Prod`, sku: `${TAG}-DUP1`, categoryId: cat.id, sellingPrice: 10, costPrice: 5, unit: 'PCS', ...over });
  r = await call('POST', '/products', pbody({}));
  check('product created', r.status === 201, `${r.status} ${r.raw.slice(0, 80)}`);
  const dupProd = r.json;
  r = await call('POST', '/products', pbody({ sku: `${TAG}-DUP2`, name: `${TAG} DUP prod` }));
  check('same product name in the same category -> 409', r.status === 409 && /already exists/.test(r.raw), `${r.status} ${r.raw.slice(0, 100)}`);
  r = await call('POST', '/products', pbody({ sku: `${TAG}-DUP3`, categoryId: otherCat.id }));
  check('same name in a different category is fine', r.status === 201, `${r.status} ${r.raw.slice(0, 100)}`);
  const otherCatProd = r.json;
  r = await call('PUT', `/products/${otherCatProd.id}`, { name: `${TAG} Dup Prod`, categoryId: cat.id });
  check('moving/renaming a product onto an existing one -> 409', r.status === 409, `${r.status}`);
  r = await call('PUT', `/products/${dupProd.id}`, { name: `${TAG} Dup Prod`, sellingPrice: 11 });
  check('editing a product under its own name is fine', r.status === 200, `${r.status}`);

  console.log('· product delete keeps history');
  const histProd = (await call('POST', '/products', pbody({ sku: `${TAG}-HIST`, name: `${TAG} History`, currentStock: 4 }))).json;
  r = await call('DELETE', `/products/${histProd.id}`);
  check('a product with stock history cannot be deleted -> 409', r.status === 409 && /history/.test(r.raw), `${r.status} ${r.raw.slice(0, 120)}`);
  check('…and its ledger is still there', (await prisma.stockMovement.count({ where: { productId: histProd.id } })) === 1);
  r = await call('PUT', `/products/${histProd.id}`, { isActive: false });
  check('it can be switched to Inactive instead', r.status === 200 && r.json.isActive === false, `${r.status}`);
  r = await call('DELETE', `/products/${dupProd.id}`);
  check('a product with no history can still be deleted', r.status === 204, `${r.status}`);

  console.log('· uploads');
  const up = async (bytes, name, type) => {
    const fd = new FormData();
    fd.append('image', new Blob([bytes], { type }), name);
    const res = await fetch(`${BASE}/upload`, { method: 'POST', headers: { Authorization: `Bearer ${token}` }, body: fd });
    const raw = await res.text();
    let json = null; try { json = JSON.parse(raw); } catch (_) {}
    return { status: res.status, json, raw };
  };
  const PNG = Buffer.from('89504e470d0a1a0a0000000d49484452', 'hex');
  r = await up(Buffer.from('<script>alert(1)</script>'), 'evil.png', 'image/png');
  check('a script renamed to .png is refused', r.status === 400 && /not a valid/.test(r.raw), `${r.status} ${r.raw.slice(0, 100)}`);
  r = await up(Buffer.from('<svg xmlns="http://www.w3.org/2000/svg"></svg>'), 'a.svg', 'image/svg+xml');
  check('SVG is still refused', r.status === 400, `${r.status}`);
  r = await up(Buffer.from('GIF89a......'), 'a.png', 'image/png');
  check('a GIF declared as PNG is refused (type mismatch)', r.status === 400, `${r.status}`);
  r = await up(PNG, 'real.png', 'image/png');
  check('a real PNG is accepted', r.status === 201 && /^\/uploads\//.test((r.json || {}).url || ''), `${r.status} ${r.raw.slice(0, 100)}`);
  if (r.json && r.json.url) {
    const fs = require('fs'); const path = require('path');
    try { fs.unlinkSync(path.join(__dirname, 'uploads', path.basename(r.json.url))); } catch (_) {}
  }

  console.log('· database CHECK constraints');
  const raw = async (fn) => { try { await fn(); return 'accepted'; } catch (e) { return /check constraint|violates/i.test(String(e.message)) ? 'refused' : `other: ${String(e.message).slice(0, 80)}`; } };
  check('negative stock is refused by the database', (await raw(() => prisma.$executeRawUnsafe(`UPDATE products SET "currentStock" = -1 WHERE id = ${histProd.id}`))) === 'refused');
  check('a negative price is refused by the database', (await raw(() => prisma.$executeRawUnsafe(`UPDATE products SET "sellingPrice" = -5 WHERE id = ${histProd.id}`))) === 'refused');
  check('a zero-quantity ledger row is refused by the database', (await raw(() => prisma.$executeRawUnsafe(`INSERT INTO stock_movements ("productId", type, qty) VALUES (${histProd.id}, 'IN', 0)`))) === 'refused');
  check('a negative order total is refused by the database', (await raw(() => prisma.$executeRawUnsafe(`UPDATE sales_orders SET amount = -1 WHERE "soNumber" = '${TAG}-CL3'`))) === 'refused');

  // ═══ paid purchase -> Transactions, incoming deliveries ══════════════════
  console.log('· paid purchase leaves a transaction');
  const payLine = { productId: histProd.id, product: histProd.name, qty: 2, rate: 100, unit: 'PCS' };
  const paidBody = poBody(`${TAG}-PAY1`, [payLine], { expectedDelivery: daysFromNow(3), date: today() });
  const total = paidBody.amount;
  const txFor = (ref) => prisma.transaction.findMany({ where: { refType: 'purchase', refId: ref } });
  r = await call('POST', '/purchase-orders', { ...paidBody, paymentType: 'Full Payment', paidAmount: total });
  const payPo = r.json;
  check('a fully paid purchase saves', r.status === 201, `${r.status} ${r.raw.slice(0, 100)}`);
  let txRows = await txFor(payPo.id);
  check('…and leaves ONE Inbound transaction for it', txRows.length === 1 && txRows[0].type === 'Inbound' && txRows[0].poNumber === `${TAG}-PAY1` && txRows[0].party === `${TAG} supplier`, JSON.stringify(txRows).slice(0, 160));
  check('…Pending while the goods have not arrived', txRows[0] && txRows[0].status === 'Pending');
  r = await call('GET', '/transactions');
  check('…and it shows in the Transactions list', (r.json.items || r.json).some((t) => t.poNumber === `${TAG}-PAY1`));
  r = await call('GET', '/dashboard');
  check('the order shows under Incoming deliveries with its expected date', (r.json.incomingDeliveries || []).some((d) => d.poRef === `${TAG}-PAY1` && d.dueDate), JSON.stringify(r.json.incomingDeliveries).slice(0, 160));
  r = await call('PATCH', `/purchase-orders/${payPo.id}/status`, { status: 'Received' });
  txRows = await txFor(payPo.id);
  check('marking it Received updates the transaction (no duplicate)', r.status === 200 && txRows.length === 1 && txRows[0].status === 'Received', JSON.stringify(txRows.map((x) => x.status)));
  r = await call('PUT', `/purchase-orders/${payPo.id}`, { ...paidBody, status: 'Received', paymentType: 'Half Payment', paidAmount: Math.round(total / 2) });
  check('a part payment removes the transaction', r.status === 200 && (await txFor(payPo.id)).length === 0, `${r.status}`);
  r = await call('PUT', `/purchase-orders/${payPo.id}`, { ...paidBody, status: 'Received', paymentType: 'Full Payment', paidAmount: total });
  check('paying in full again brings it back', r.status === 200 && (await txFor(payPo.id)).length === 1);
  r = await call('DELETE', `/purchase-orders/${payPo.id}`);
  check('deleting the purchase removes its transaction', r.status === 204 && (await txFor(payPo.id)).length === 0, `${r.status}`);
  r = await call('POST', '/purchase-orders', poBody(`${TAG}-PAY2`, [payLine], { paymentType: 'Other', paidAmount: 0 }));
  check('an unpaid purchase leaves no transaction', r.status === 201 && (await txFor(r.json.id)).length === 0);

  // ═══ received / delivered dates ═════════════════════════════════════════
  console.log('· received / delivered dates');
  const dl = { productId: histProd.id, product: histProd.name, qty: 1, rate: 100, unit: 'PCS' };
  r = await call('POST', '/purchase-orders', poBody(`${TAG}-DT1`, [dl]));
  const dtPo = r.json;
  check('a new Pending purchase has no received date', r.status === 201 && dtPo.receivedAt === null, JSON.stringify(dtPo.receivedAt));
  r = await call('PATCH', `/purchase-orders/${dtPo.id}/status`, { status: 'Received' });
  const firstStamp = r.json && r.json.receivedAt;
  check('marking it Received stamps the date', r.status === 200 && !!firstStamp, `${r.status} ${firstStamp}`);
  await new Promise((ok) => setTimeout(ok, 30));
  r = await call('PUT', `/purchase-orders/${dtPo.id}`, { ...poBody(`${TAG}-DT1`, [dl]), status: 'Received', notes: 'x' });
  check('re-saving a Received order keeps the ORIGINAL date', r.status === 200 && r.json.receivedAt === firstStamp, `${r.json && r.json.receivedAt} vs ${firstStamp}`);
  r = await call('PATCH', `/purchase-orders/${dtPo.id}/status`, { status: 'Pending' });
  check('moving it off Received clears the date', r.status === 200 && r.json.receivedAt === null);
  r = await call('PATCH', `/purchase-orders/${dtPo.id}/status`, { status: 'Received' });
  check('receiving it again stamps a fresh date', r.status === 200 && !!r.json.receivedAt && r.json.receivedAt !== firstStamp);
  r = await call('POST', '/sales-orders', saleBody(`${TAG}-DT2`, [dl], { status: 'Confirmed' }));
  const dtSo = r.json;
  check('a Confirmed sale has no delivered date', r.status === 201 && dtSo.deliveredAt === null);
  r = await call('PATCH', `/sales-orders/${dtSo.id}/status`, { status: 'Delivered' });
  const soStamp = r.json && r.json.deliveredAt;
  check('marking a sale Delivered stamps the date', r.status === 200 && !!soStamp, `${r.status}`);
  r = await call('PATCH', `/sales-orders/${dtSo.id}/status`, { paymentStatus: 'Paid' });
  check('a payment change keeps the delivered date', r.status === 200 && r.json.deliveredAt === soStamp);

  // ═══ server-side order numbers + GST fields ═════════════════════════════════
  console.log('· order numbers and GST');
  const fyNow = new Date();
  const fyStart = fyNow.getMonth() >= 3 ? fyNow.getFullYear() : fyNow.getFullYear() - 1;
  const fy = String(fyStart % 100).padStart(2, '0') + '-' + String((fyStart + 1) % 100).padStart(2, '0');
  const numbered = (prefix) => new RegExp('^' + prefix + '/\\d{4}/' + fy + '$');
  const nl = { productId: histProd.id, product: histProd.name, qty: 1, rate: 100, unit: 'PCS', taxPercent: 5 };
  r = await call('GET', '/purchase-orders/next-number');
  const expectedPo = r.json.number;
  check('next purchase number is PO/<seq>/<FY>', r.status === 200 && numbered('PO').test(expectedPo), JSON.stringify(r.json));
  const unnumbered = { ...poBody('', [nl]), poNumber: '', interState: true };
  const a = await call('POST', '/purchase-orders', unnumbered);
  const b = await call('POST', '/purchase-orders', unnumbered);
  check('a purchase sent without a number gets the next one', a.status === 201 && a.json.poNumber === expectedPo, a.status + ' ' + (a.json && a.json.poNumber));
  check('the next save gets the one after', b.status === 201 && b.json.poNumber !== a.json.poNumber, String(b.json && b.json.poNumber));
  check('…and its invoice no. defaults to that number', a.json.invoiceNo === a.json.poNumber);
  check('interState is stored', a.json.interState === true);
  check('the line GST rate is stored', Number(a.json.items[0].taxPercent) === 5, JSON.stringify(a.json.items[0]));
  // Deleting the newest must not hand its number to two orders.
  await call('DELETE', '/purchase-orders/' + b.json.id);
  const c = await call('POST', '/purchase-orders', unnumbered);
  const d = await call('POST', '/purchase-orders', unnumbered);
  check('after a delete, new orders still get distinct numbers', c.status === 201 && d.status === 201 && c.json.poNumber !== d.json.poNumber && c.json.poNumber !== a.json.poNumber, (c.json && c.json.poNumber) + ' ' + (d.json && d.json.poNumber));
  // Two saves at the same moment.
  const [e1, e2] = await Promise.all([call('POST', '/purchase-orders', unnumbered), call('POST', '/purchase-orders', unnumbered)]);
  check('two simultaneous saves both succeed with different numbers', e1.status === 201 && e2.status === 201 && e1.json.poNumber !== e2.json.poNumber, e1.status + ' ' + e2.status);
  for (const o of [a, c, d, e1, e2]) if (o.json && o.json.id) await call('DELETE', '/purchase-orders/' + o.json.id);
  r = await call('GET', '/sales-orders/next-number');
  check('next sale number is SO/<seq>/<FY>', r.status === 200 && numbered('SO').test(r.json.number), JSON.stringify(r.json));
  const so = await call('POST', '/sales-orders', { ...saleBody('', [{ ...nl, product: TAG + ' typed', productId: null }]), soNumber: '' });
  check('a sale sent without a number gets SO/…', so.status === 201 && /^SO\//.test(so.json.soNumber), so.status + ' ' + so.raw.slice(0, 100));
  if (so.json && so.json.id) await call('DELETE', '/sales-orders/' + so.json.id);

  // ═══ input hardening ═══════════════════════════════════════════════════
  console.log('· input hardening');
  r = await call('GET', '/clients?search=%00');
  check('a NUL in a search box does not 500', r.status === 200, `${r.status}`);
  r = await call('POST', '/clients', { name: `${TAG} nul\u0000client` });
  check('a NUL in a client name is stripped, not a 500', r.status === 201 && r.json.name === `${TAG} nulclient`, `${r.status} ${r.raw.slice(0, 80)}`);
  r = await call('POST', '/clients', { name: `${TAG} big credit`, creditLimit: 1e30 });
  check('an absurd credit limit -> 400', r.status === 400 && /too large/.test(r.raw), `${r.status} ${r.raw.slice(0, 80)}`);
  r = await call('POST', '/clients', { name: `${TAG} big opening`, openingBalance: 1e30 });
  check('an absurd opening balance -> 400', r.status === 400, `${r.status}`);
  r = await call('POST', '/clients', { name: `${TAG} bad date`, clientSince: 'garbage' });
  check('a garbage clientSince -> 400 with a clear message', r.status === 400 && /clientSince/.test(r.raw), `${r.status} ${r.raw.slice(0, 80)}`);
  r = await call('POST', '/clients', { name: `${TAG} long`, address: 'a'.repeat(20000) });
  check('a 20,000-character field -> 400', r.status === 400, `${r.status}`);
  r = await call('POST', '/clients', { name: `${TAG}${'x'.repeat(300)}` });
  check('a 300-character client name -> 400', r.status === 400 && /200/.test(r.raw), `${r.status} ${r.raw.slice(0, 80)}`);
  r = await call('POST', '/transactions', { item: `${TAG} t`, date: 'garbage' });
  check('a transaction with a garbage date -> 400', r.status === 400 && /date/.test(r.raw), `${r.status} ${r.raw.slice(0, 80)}`);
  r = await call('POST', '/transactions', { item: 'x'.repeat(300), date: today() });
  check('a 300-character transaction item -> 400', r.status === 400, `${r.status}`);
  r = await call('POST', '/roles', { name: 'y'.repeat(100) });
  check('a 100-character role name -> 400', r.status === 400, `${r.status}`);
  r = await call('PUT', '/settings', { name: 'n'.repeat(500) });
  check('a 500-character profile name -> 400', r.status === 400, `${r.status}`);
  r = await call('PUT', `/inventory/${histProd.id}`, { minimumStock: 99999999999 });
  check('an absurd minimumStock -> 400, not a 500', r.status === 400, `${r.status}`);
  r = await call('PUT', `/inventory/${histProd.id}`, { minimumStock: 2.5 });
  check('a fractional reorder point is kept (stock is decimal now)', r.status === 200 && Number(r.json.minimumStock) === 2.5, `${r.status}`);

  // ═══ decimal stock for measured units ═════════════════════════════════════
  console.log('· decimal stock');
  const kg = (await call('POST', '/products', {
    name: `${TAG} Bulk Fibre`, sku: `${TAG}-KG`, categoryId: cat.id, sellingPrice: 100, costPrice: 60, unit: 'Kilogram (kg)', currentStock: 12.5,
  }));
  check('a kg product opens with 12.5 kg', kg.status === 201 && Number(kg.json.currentStock) === 12.5, `${kg.status} ${kg.raw.slice(0, 120)}`);
  r = await call('POST', '/products', { name: `${TAG} Bolt`, sku: `${TAG}-PCS`, categoryId: cat.id, sellingPrice: 10, costPrice: 5, unit: 'Piece (pcs)', currentStock: 2.5 });
  check('a pcs product refuses 2.5 opening stock', r.status === 400 && /whole number/.test(r.raw), `${r.status} ${r.raw.slice(0, 100)}`);
  const kgLine = (qty) => ({ productId: kg.json.id, product: `${TAG} Bulk Fibre`, qty, rate: 60, unit: 'Kilogram (kg)' });
  r = await call('POST', '/purchase-orders', poBody(`${TAG}-KG1`, [kgLine(2.25)], { status: 'Received' }));
  check('receiving 2.25 kg works', r.status === 201, `${r.status} ${r.raw.slice(0, 120)}`);
  check('…stock is 12.5 + 2.25 = 14.75', (await product(kg.json.id)).currentStock === 14.75, String((await product(kg.json.id)).currentStock));
  r = await call('POST', '/sales-orders', saleBody(`${TAG}-KG2`, [kgLine(0.75)], { status: 'Delivered' }));
  check('delivering 0.75 kg works', r.status === 201, `${r.status} ${r.raw.slice(0, 120)}`);
  check('…stock is 14.75 - 0.75 = 14', (await product(kg.json.id)).currentStock === 14);
  r = await call('POST', '/inventory/adjust', { productId: kg.json.id, type: 'OUT', qty: 0.125, note: 'sample' });
  check('a 0.125 kg adjustment works', r.status === 201 && Number(r.json.item.stockInHand) === 13.875, `${r.status} ${r.raw.slice(0, 120)}`);
  r = await call('DELETE', `/inventory/movements/${r.json.movementId}`);
  check('undoing it puts exactly 0.125 back', r.status === 200 && (await product(kg.json.id)).currentStock === 14, `${r.status}`);
  r = await call('GET', '/products');
  const listed = (r.json.items || r.json).find((p) => p.id === kg.json.id);
  check('the list reports 14 kg, available 14', listed && listed.currentStock === 14 && listed.availableStock === 14, JSON.stringify(listed && { c: listed.currentStock, a: listed.availableStock }));


  // ═══ several payments on one sale ═════════════════════════════════════════
  console.log('· sale payments');
  const payProd = (await call('POST', '/products', pbody({ sku: `${TAG}-SPAY`, name: `${TAG} SalePay`, currentStock: 50 }))).json;
  const spLine = { productId: payProd.id, product: payProd.name, qty: 10, rate: 100, unit: 'PCS' };
  const spBody = saleBody(`${TAG}-SP1`, [spLine]); // amount 1180
  const payRows = (soId) => prisma.transaction.findMany({ where: { salesOrderId: soId }, orderBy: { id: 'asc' } });
  r = await call('POST', '/sales-orders', {
    ...spBody,
    paymentStatus: 'Pending',
    payments: [
      { date: today(), amount: 500, mode: 'Cash', notes: 'advance' },
      { date: daysFromNow(1), amount: 300, mode: 'UPI' },
      { amount: '', notes: '' }, // the empty row a form leaves
    ],
  });
  const sp = r.json;
  check('a sale with two payments saves', r.status === 201, `${r.status} ${r.raw.slice(0, 160)}`);
  check('…paidAmount is their sum (800), Partial, type Other', sp.paidAmount === 800 && sp.paymentStatus === 'Partial' && sp.paymentType === 'Other', JSON.stringify({ p: sp.paidAmount, s: sp.paymentStatus, t: sp.paymentType }));
  check('…and the response lists both payments, oldest first', Array.isArray(sp.payments) && sp.payments.length === 2 && sp.payments[0].amount === 500 && sp.payments[1].mode === 'UPI', JSON.stringify(sp.payments).slice(0, 200));
  let spRows = await payRows(sp.id);
  check('two Transactions spRows, each with the SO number, client, amount and mode', spRows.length === 2 && spRows.every((t) => t.poNumber === `${TAG}-SP1` && t.party === `${TAG} client` && t.type === 'Outbound' && t.refType === 'sale') && Number(spRows[0].amount) === 500 && spRows[0].mode === 'Cash', JSON.stringify(spRows).slice(0, 200));
  r = await call('GET', '/transactions');
  check('…and both show in the Transactions list', (r.json.items || r.json).filter((t) => t.poNumber === `${TAG}-SP1`).length === 2);
  r = await call('GET', `/stats/sales`);
  check('stats read the summed paidAmount', r.status === 200);

  r = await call('PUT', `/transactions/${spRows[0].id}`, { item: 'x', date: today() });
  check('a payment row cannot be edited from Transactions (409)', r.status === 409 && /SP1/.test(r.raw), `${r.status} ${r.raw.slice(0, 120)}`);
  r = await call('DELETE', `/transactions/${spRows[0].id}`);
  check('…nor deleted there (409)', r.status === 409);
  r = await call('PATCH', `/transactions/${spRows[0].id}/status`, { status: 'Pending' });
  check('…nor have its status changed there (409)', r.status === 409);

  r = await call('POST', '/sales-orders', { ...saleBody(`${TAG}-SP2`, [spLine]), payments: [{ date: today(), amount: 1000 }, { date: today(), amount: 500 }] });
  check('payments above the sale amount -> 400', r.status === 400 && /more than the sale amount/.test(r.raw), `${r.status} ${r.raw.slice(0, 120)}`);
  r = await call('POST', '/sales-orders', { ...saleBody(`${TAG}-SP2`, [spLine]), payments: [{ date: today(), amount: -5 }] });
  check('a negative payment -> 400', r.status === 400);
  r = await call('POST', '/sales-orders', { ...saleBody(`${TAG}-SP2`, [spLine]), payments: [{ amount: 100 }] });
  check('a payment without a date -> 400', r.status === 400 && /date/.test(r.raw), r.raw.slice(0, 100));
  r = await call('POST', '/sales-orders', { ...saleBody(`${TAG}-SP2`, [spLine]), payments: [{ date: today(), amount: 10, mode: 'Bitcoin' }] });
  check('an unknown payment mode -> 400', r.status === 400);
  r = await call('POST', '/sales-orders', { ...saleBody(`${TAG}-SP2`, [spLine]), payments: 'lots' });
  check('payments that are not a list -> 400', r.status === 400);

  r = await call('PUT', `/sales-orders/${sp.id}`, { ...spBody, client: `${TAG} client B`, payments: [{ date: today(), amount: 1180, mode: 'Bank Transfer' }] });
  spRows = await payRows(sp.id);
  check('editing replaces the payments: one full payment -> Paid / Full Payment', r.status === 200 && r.json.paidAmount === 1180 && r.json.paymentStatus === 'Paid' && r.json.paymentType === 'Full Payment' && spRows.length === 1, `${r.status} ${JSON.stringify(spRows.map((x) => Number(x.amount)))}`);
  check('…and the row follows the new client', spRows[0] && spRows[0].party === `${TAG} client B`);
  r = await call('PUT', `/sales-orders/${sp.id}`, { ...spBody, client: `${TAG} client C` }); // an older client: no payments key
  spRows = await payRows(sp.id);
  check('an edit without `payments` keeps the spRows and renames them', r.status === 200 && spRows.length === 1 && spRows[0].party === `${TAG} client C`, JSON.stringify(spRows.map((x) => x.party)));
  r = await call('PUT', `/sales-orders/${sp.id}`, { ...spBody, payments: [] });
  spRows = await payRows(sp.id);
  check('an empty list clears them: Pending, paid 0', r.status === 200 && spRows.length === 0 && r.json.paidAmount === 0 && r.json.paymentStatus === 'Pending', JSON.stringify({ s: r.status, p: r.json.paidAmount }));
  r = await call('PUT', `/sales-orders/${sp.id}`, { ...spBody, payments: [{ date: today(), amount: 180, mode: 'Cash' }] });
  r = await call('PATCH', `/sales-orders/${sp.id}/status`, { paymentStatus: 'Paid' });
  spRows = await payRows(sp.id);
  check('"Mark as Paid" books the 1000 still due as one more payment', r.status === 200 && spRows.length === 2 && Number(spRows[1].amount) === 1000 && r.json.paidAmount === 1180, JSON.stringify(spRows.map((x) => Number(x.amount))));
  r = await call('PATCH', `/sales-orders/${sp.id}/status`, { paymentStatus: 'Pending' });
  check('"Pending" clears the payments', r.status === 200 && (await payRows(sp.id)).length === 0 && r.json.paidAmount === 0);
  await call('PUT', `/sales-orders/${sp.id}`, { ...spBody, payments: [{ date: today(), amount: 100 }] });
  r = await call('DELETE', `/sales-orders/${sp.id}`);
  check('deleting the sale deletes its payments', r.status === 204 && (await payRows(sp.id)).length === 0, `${r.status}`);

  // ═══ error hygiene & auth input ═══════════════════════════════════════════
  console.log('· error hygiene');
  const login = await fetch(`${BASE}/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email: 123, password: 'x' }) });
  check('login with a numeric email -> 400, not a 500', login.status === 400, String(login.status));
  r = await call('GET', '/sales-orders?limit=abc');
  check('a junk ?limit does not 500', r.status < 500, `${r.status}`);
}

async function cleanup() {
  // Billed sales refuse the API delete, so clear their bills first.
  await prisma.bill.deleteMany({ where: { salesOrder: { soNumber: { startsWith: TAG } } } });
  await prisma.user.deleteMany({ where: { email: 'zz-audit-emp@example.com' } });
  await prisma.client.deleteMany({ where: { name: { startsWith: TAG } } });
  await prisma.transaction.deleteMany({ where: { OR: [{ item: { startsWith: TAG } }, { poNumber: { startsWith: TAG } }] } });
  // Orders first (deleting one puts its stock back), then products (their
  // ledger cascades), categories, and any to-do the sweep left.
  const sales = await prisma.salesOrder.findMany({ where: { soNumber: { startsWith: TAG } }, select: { id: true } });
  for (const s of sales) await call('DELETE', `/sales-orders/${s.id}`).catch(() => {});
  const pos = await prisma.purchaseOrder.findMany({ where: { poNumber: { startsWith: TAG } }, select: { id: true } });
  for (const p of pos) await call('DELETE', `/purchase-orders/${p.id}`).catch(() => {});
  await prisma.saleItem.deleteMany({ where: { OR: [{ product: { startsWith: TAG } }] } });
  await prisma.purchaseItem.deleteMany({ where: { product: { startsWith: TAG } } });
  await prisma.stockMovement.deleteMany({ where: { product: { name: { startsWith: TAG } } } });
  await prisma.product.deleteMany({ where: { name: { startsWith: TAG } } });
  await prisma.subCategory.deleteMany({ where: { name: { startsWith: TAG } } });
  await prisma.category.deleteMany({ where: { name: { startsWith: TAG } } });
  await prisma.dashboardNote.deleteMany({ where: { text: { contains: TAG } } });
}

(async () => {
  try {
    await main();
  } catch (err) {
    failed += 1;
    failures.push(`crashed: ${err.stack || err.message}`);
    console.error(err);
  } finally {
    try {
      await cleanup();
      const left = {
        salesOrders: await prisma.salesOrder.count({ where: { soNumber: { startsWith: TAG } } }),
        purchaseOrders: await prisma.purchaseOrder.count({ where: { poNumber: { startsWith: TAG } } }),
        products: await prisma.product.count({ where: { name: { startsWith: TAG } } }),
        categories: await prisma.category.count({ where: { name: { startsWith: TAG } } }),
        notes: await prisma.dashboardNote.count({ where: { text: { contains: TAG } } }),
        movements: await prisma.stockMovement.count({ where: { reference: { contains: TAG } } }),
      };
      const leftover = Object.values(left).reduce((a, b) => a + b, 0);
      console.log(`cleanup: ${leftover === 0 ? 'all test data removed' : `LEFT BEHIND ${JSON.stringify(left)}`}`);
      if (leftover) failed += 1;
    } catch (e) {
      console.error('cleanup failed:', e.message);
      failed += 1;
    }
    await prisma.$disconnect();
    console.log(`\n${passed} passed, ${failed} failed`);
    if (failures.length) console.log(failures.map((f) => `  ✗ ${f}`).join('\n'));
    process.exit(failed ? 1 : 0);
  }
})();

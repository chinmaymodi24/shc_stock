// ─────────────────────────────────────────────────────────────────────────────
// Money maths shared by the figures on Reports, Analytics, the list-page cards
// and the dashboard — so they cannot disagree.
//
// Three things were wrong before:
//  * receivables counted the FULL amount of every Pending/Partial order and
//    ignored paidAmount, so ₹25,000 received on a ₹50,000 order still showed
//    ₹50,000 owed;
//  * payables were worked out from the goods-receipt status (Pending/Partial/
//    Received), which says nothing about whether the supplier was paid;
//  * Cancelled orders were added into Total Sales / Total Purchases.
// ─────────────────────────────────────────────────────────────────────────────

/// Prisma `where` that leaves cancelled orders out of any total.
const NOT_CANCELLED = { status: { not: 'Cancelled' } };

const num = (v) => Number(v) || 0;
const round2 = (n) => Math.round(n * 100) / 100;

/// Money actually received for a sale. A "Paid" order counts in full even when
/// an older row never recorded paidAmount.
function receivedOn(order) {
  if (order.status === 'Cancelled' || order.paymentStatus === 'Refunded') return 0;
  const amount = num(order.amount);
  if (order.paymentStatus === 'Paid') return amount;
  return Math.min(Math.max(num(order.paidAmount), 0), amount);
}

/// Money still owed by the customer on a sale.
function owedOn(order) {
  if (order.status === 'Cancelled' || order.paymentStatus === 'Refunded') return 0;
  return Math.max(num(order.amount) - receivedOn(order), 0);
}

/// Money paid to the supplier on a purchase (a cancelled one paid nothing).
function paidOn(purchase) {
  if (purchase.status === 'Cancelled') return 0;
  return Math.min(Math.max(num(purchase.paidAmount), 0), num(purchase.amount));
}

/// Money still owed to the supplier on a purchase.
function payableOn(purchase) {
  if (purchase.status === 'Cancelled') return 0;
  return Math.max(num(purchase.amount) - paidOn(purchase), 0);
}

const sumBy = (rows, fn) => rows.reduce((s, r) => s + fn(r), 0);

module.exports = {
  NOT_CANCELLED,
  round2,
  receivedOn,
  owedOn,
  paidOn,
  payableOn,
  sumBy,
};

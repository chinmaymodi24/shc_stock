// ─────────────────────────────────────────────────────────────────────────────
// A fully-paid purchase leaves a row in the Transactions list.
//
// The row is kept in step with the order, not copied once: edit the order and
// it follows (supplier, date, items, status); take the payment back below the
// total, or delete the order, and the row goes. It is found by (refType,
// refId), so it can never be duplicated, and hand-entered transactions
// (refType null) are never touched.
// ─────────────────────────────────────────────────────────────────────────────

const REF_TYPE = 'purchase';

const num = (v) => Number(v) || 0;

/// True when the order carries a payment that covers its whole amount.
function isFullyPaid(order) {
  const amount = num(order.amount);
  return amount > 0 && num(order.paidAmount) >= amount;
}

function describeItems(items, fallback = 'Purchase') {
  const lines = (items || []).filter((i) => i && i.product);
  if (lines.length === 0) return fallback;
  const first = lines[0].product;
  return lines.length > 1 ? `${first} +${lines.length - 1} more` : first;
}

/// Creates, updates or removes the transaction for [order] (a purchase order
/// loaded with its items). Safe to call after any change to the order.
async function syncPurchaseTransaction(tx, order) {
  const existing = await tx.transaction.findFirst({
    where: { refType: REF_TYPE, refId: order.id },
  });
  if (!isFullyPaid(order)) {
    if (existing) await tx.transaction.delete({ where: { id: existing.id } });
    return null;
  }
  const data = {
    item: describeItems(order.items).slice(0, 200),
    type: 'Inbound',
    party: order.supplier,
    poNumber: order.poNumber,
    date: order.date,
    status: order.status === 'Received' ? 'Received' : 'Pending',
    amount: num(order.paidAmount),
    notes: `Paid in full — ₹${num(order.paidAmount).toLocaleString('en-IN')}`,
    modifiedBy: order.modifiedBy || 'Admin',
    modifiedAt: new Date(),
  };
  if (existing) return tx.transaction.update({ where: { id: existing.id }, data });
  return tx.transaction.create({ data: { ...data, refType: REF_TYPE, refId: order.id } });
}

/// Drops the transaction of a purchase that is being deleted.
function removePurchaseTransaction(tx, orderId) {
  return tx.transaction.deleteMany({ where: { refType: REF_TYPE, refId: orderId } });
}

module.exports = { syncPurchaseTransaction, removePurchaseTransaction, isFullyPaid, describeItems, REF_TYPE };

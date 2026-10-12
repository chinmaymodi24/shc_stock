// ─────────────────────────────────────────────────────────────────────────────
// Expected-delivery sweep.
//
// An order can carry an optional `expectedDelivery` date. On that day the order
// is treated as delivered: a purchase becomes "Received", a sale becomes
// "Delivered" — which is also what books the stock movement (see
// stockService.syncStockForStatus). Orders without the date are never touched,
// so their status stays exactly where whoever entered them left it.
//
// The sweep runs once at boot and then on an interval, so a date that passed
// while the server was down is still picked up the next time it starts.
// ─────────────────────────────────────────────────────────────────────────────

require('./timezone');
const prisma = require('./prismaClient');
const { syncPurchaseTransaction } = require('./paymentTransaction');
const {
  InsufficientStockError,
  toStockLines,
  syncStockForStatus,
} = require('./stockService');

/// Statuses the sweep is allowed to move away from. A cancelled order — or one
/// already delivered — is left alone.
const PURCHASE_OPEN = ['Pending', 'Partial'];
const SALE_OPEN = ['Confirmed', 'Processing', 'Shipped'];

const SWEEP_INTERVAL_MS = 15 * 60 * 1000;

/// End of today (business time — see timezone.js), so an order due today is
/// delivered from the moment the date arrives rather than at midnight the
/// following night.
function endOfToday() {
  const d = new Date();
  d.setHours(23, 59, 59, 999);
  return d;
}

async function sweepPurchases(due) {
  const orders = await prisma.purchaseOrder.findMany({
    where: {
      expectedDelivery: { not: null, lte: due },
      status: { in: PURCHASE_OPEN },
    },
    select: { id: true, expectedDelivery: true },
  });

  let moved = 0;
  for (const { id, expectedDelivery } of orders) {
    try {
      await prisma.$transaction(async (tx) => {
        const updated = await tx.purchaseOrder.update({
          where: { id },
          // Received on the day it was due — not whenever this pass ran (the
          // server may have been off that day).
          data: { status: 'Received', modifiedAt: new Date(), receivedAt: expectedDelivery || new Date() },
          include: { items: true },
        });
        await syncStockForStatus(tx, {
          refType: 'purchase',
          refId: id,
          status: updated.status,
          lines: toStockLines(updated.items),
          reference: updated.poNumber,
          note: `Purchase ${updated.poNumber} (expected delivery)`,
          createdBy: updated.modifiedBy,
        });
        await syncPurchaseTransaction(tx, updated);
      });
      moved += 1;
    } catch (err) {
      console.error(`[delivery-sweep] purchase ${id} failed:`, err.message);
    }
  }
  return moved;
}

/// The text of the to-do shown to Super Admins when a due sale can't ship.
const issueText = (soNumber, why) => `Sale ${soNumber} is due but could not be delivered — ${why}`;
const issuePrefix = (soNumber) => `Sale ${soNumber} is due but could not be delivered`;

/// Leaves one open to-do per stuck sale (userId null = Super Admins' notes), so
/// the 15-minute retry doesn't pile up duplicates and a failure is no longer
/// something only the server log knows about.
async function raiseDeliveryIssue(soNumber, why) {
  const text = issueText(soNumber, why);
  const existing = await prisma.dashboardNote.findFirst({
    where: { userId: null, done: false, text: { startsWith: issuePrefix(soNumber) } },
  });
  if (existing) {
    if (existing.text !== text) {
      await prisma.dashboardNote.update({ where: { id: existing.id }, data: { text } });
    }
    return;
  }
  const max = await prisma.dashboardNote.aggregate({ _max: { sortOrder: true } });
  await prisma.dashboardNote.create({
    data: { text, userId: null, sortOrder: (max._max.sortOrder ?? -1) + 1 },
  });
}

/// Ticks the to-do off once the sale did go out.
async function clearDeliveryIssue(soNumber) {
  await prisma.dashboardNote.updateMany({
    where: { userId: null, done: false, text: { startsWith: issuePrefix(soNumber) } },
    data: { done: true },
  });
}

async function sweepSales(due) {
  const orders = await prisma.salesOrder.findMany({
    where: {
      expectedDelivery: { not: null, lte: due },
      status: { in: SALE_OPEN },
    },
    select: { id: true, soNumber: true, expectedDelivery: true },
  });

  let moved = 0;
  for (const { id, soNumber, expectedDelivery } of orders) {
    try {
      await prisma.$transaction(async (tx) => {
        const updated = await tx.salesOrder.update({
          where: { id },
          data: { status: 'Delivered', modifiedAt: new Date(), deliveredAt: expectedDelivery || new Date() },
          include: { items: true },
        });
        await syncStockForStatus(tx, {
          refType: 'sale',
          refId: id,
          status: updated.status,
          lines: toStockLines(updated.items),
          reference: updated.soNumber,
          note: `Sale ${updated.soNumber} (expected delivery)`,
          createdBy: updated.modifiedBy,
        });
      });
      moved += 1;
      await clearDeliveryIssue(soNumber).catch(() => {});
    } catch (err) {
      // A sale that would take a product below zero keeps its old status —
      // the whole transaction rolls back — and is retried on the next sweep.
      if (err instanceof InsufficientStockError) {
        console.error(`[delivery-sweep] sale ${id} failed: ${err.message}`);
        await raiseDeliveryIssue(soNumber, err.message).catch((e) =>
          console.error('[delivery-sweep] could not leave a to-do:', e.message)
        );
      } else {
        console.error(`[delivery-sweep] sale ${id} failed: ${err.message}`);
      }
    }
  }
  return moved;
}

/// One pass over both tables. Exported so it can be run by hand or from a test.
async function runDeliverySweep() {
  const due = endOfToday();
  const purchases = await sweepPurchases(due);
  const sales = await sweepSales(due);
  if (purchases || sales) {
    console.log(
      `[delivery-sweep] marked ${purchases} purchase(s) received and ${sales} sale(s) delivered`
    );
  }
  return { purchases, sales };
}

/// Runs the sweep now and every [SWEEP_INTERVAL_MS] after that. `unref()` keeps
/// the timer from holding the process open on shutdown.
function startDeliverySweep() {
  runDeliverySweep().catch((err) =>
    console.error('[delivery-sweep] initial run failed:', err)
  );
  const timer = setInterval(() => {
    runDeliverySweep().catch((err) =>
      console.error('[delivery-sweep] run failed:', err)
    );
  }, SWEEP_INTERVAL_MS);
  timer.unref();
  return timer;
}

module.exports = { runDeliverySweep, startDeliverySweep, raiseDeliveryIssue, clearDeliveryIssue };

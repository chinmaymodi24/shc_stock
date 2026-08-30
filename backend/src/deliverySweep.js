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

const prisma = require('./prismaClient');
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

/// End of today, so an order due today is delivered from the moment the date
/// arrives rather than at midnight the following night.
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
    select: { id: true },
  });

  let moved = 0;
  for (const { id } of orders) {
    try {
      await prisma.$transaction(async (tx) => {
        const updated = await tx.purchaseOrder.update({
          where: { id },
          data: { status: 'Received', modifiedAt: new Date() },
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
      });
      moved += 1;
    } catch (err) {
      console.error(`[delivery-sweep] purchase ${id} failed:`, err.message);
    }
  }
  return moved;
}

async function sweepSales(due) {
  const orders = await prisma.salesOrder.findMany({
    where: {
      expectedDelivery: { not: null, lte: due },
      status: { in: SALE_OPEN },
    },
    select: { id: true },
  });

  let moved = 0;
  for (const { id } of orders) {
    try {
      await prisma.$transaction(async (tx) => {
        const updated = await tx.salesOrder.update({
          where: { id },
          data: { status: 'Delivered', modifiedAt: new Date() },
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
    } catch (err) {
      // A sale that would take a product below zero keeps its old status —
      // the whole transaction rolls back — and is retried on the next sweep.
      const why = err instanceof InsufficientStockError
        ? `insufficient stock (${JSON.stringify(err.details)})`
        : err.message;
      console.error(`[delivery-sweep] sale ${id} failed: ${why}`);
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

module.exports = { runDeliverySweep, startDeliverySweep };

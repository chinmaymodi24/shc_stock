const express = require('express');
const prisma = require('../prismaClient');

const router = express.Router();

// ─────────────────────────────────────────────────────────────────────────────
// Formatted financial statements — Profit & Loss and Balance Sheet.
//
// Every figure here is derived from data the system actually records: sale
// lines, purchase orders, the stock ledger and what has been paid on each
// order. Where a conventional statement line has no source in this system
// (other income, salaries, rent, fixed assets, loans), the endpoint reports it
// as unmodelled rather than sending a zero the app would print as fact.
// ─────────────────────────────────────────────────────────────────────────────

const round2 = (n) => Number((n || 0).toFixed(2));

/// Parses ?from / ?to, falling back to the Indian financial year (1 Apr —
/// 31 Mar) that contains today.
function resolvePeriod(query) {
  const from = query.from ? new Date(query.from) : null;
  const to = query.to ? new Date(query.to) : null;
  if (from && to && !Number.isNaN(from.valueOf()) && !Number.isNaN(to.valueOf())) {
    return { from, to };
  }
  const now = new Date();
  const startYear = now.getMonth() >= 3 ? now.getFullYear() : now.getFullYear() - 1;
  return {
    from: new Date(startYear, 3, 1),
    to: new Date(startYear + 1, 2, 31, 23, 59, 59, 999),
  };
}

function resolveAsOn(query) {
  const asOn = query.asOn ? new Date(query.asOn) : null;
  if (asOn && !Number.isNaN(asOn.valueOf())) return asOn;
  return resolvePeriod(query).to;
}

/// Stock value at a point in time, valued at each product's current cost.
///
/// Walks the ledger backwards from today: today's quantity minus everything
/// that moved after [at]. That is the only way to get an opening figure out of
/// a schema that stores a running `currentStock` rather than dated snapshots.
async function stockValueAt(at, products, movements) {
  const costById = new Map(products.map((p) => [p.id, p.costPrice]));
  const qtyById = new Map(products.map((p) => [p.id, p.currentStock]));

  for (const m of movements) {
    if (m.createdAt <= at) continue;
    const current = qtyById.get(m.productId);
    if (current == null) continue;
    // Undo the movement: an IN after `at` was not yet there, an OUT was.
    qtyById.set(m.productId, m.type === 'OUT' ? current + m.qty : current - m.qty);
  }

  let total = 0;
  for (const [id, qty] of qtyById) {
    total += Math.max(qty, 0) * (costById.get(id) || 0);
  }
  return round2(total);
}

// ── Profit & Loss ───────────────────────────────────────────────────────────
router.get('/profit-and-loss', async (req, res, next) => {
  try {
    const { from, to } = resolvePeriod(req.query);

    const [saleItems, purchases, products, movements] = await Promise.all([
      prisma.saleItem.findMany({
        select: {
          qty: true,
          rate: true,
          productId: true,
          salesOrder: { select: { date: true } },
        },
      }),
      prisma.purchaseOrder.findMany({
        where: { date: { gte: from, lte: to } },
        select: { amount: true },
      }),
      prisma.product.findMany({
        select: { id: true, currentStock: true, costPrice: true },
      }),
      prisma.stockMovement.findMany({
        select: { productId: true, type: true, qty: true, createdAt: true },
      }),
    ]);

    let revenue = 0;
    for (const line of saleItems) {
      const date = line.salesOrder?.date;
      if (!date || date < from || date > to) continue;
      revenue += line.qty * line.rate;
    }

    const purchaseTotal = purchases.reduce((s, o) => s + o.amount, 0);
    const openingStock = await stockValueAt(from, products, movements);
    const closingStock = await stockValueAt(to, products, movements);
    const cogs = openingStock + purchaseTotal - closingStock;
    const grossProfit = revenue - cogs;

    res.json({
      period: { from, to },
      income: {
        salesRevenue: round2(revenue),
        // No ledger for non-sales income exists in this system.
        otherIncomeModelled: false,
        total: round2(revenue),
      },
      cogs: {
        openingStock,
        purchases: round2(purchaseTotal),
        closingStock,
        total: round2(cogs),
      },
      grossProfit: round2(grossProfit),
      // Salaries, freight, rent and the rest are not recorded anywhere in the
      // schema, so the statement says so instead of printing zeros.
      operatingExpenses: { modelled: false, total: 0 },
      netProfit: round2(grossProfit),
    });
  } catch (err) {
    next(err);
  }
});

// ── Balance Sheet ───────────────────────────────────────────────────────────
router.get('/balance-sheet', async (req, res, next) => {
  try {
    const asOn = resolveAsOn(req.query);

    const [sales, purchases, products, movements] = await Promise.all([
      prisma.salesOrder.findMany({
        where: { date: { lte: asOn } },
        select: { amount: true, paidAmount: true },
      }),
      prisma.purchaseOrder.findMany({
        where: { date: { lte: asOn } },
        select: { amount: true, paidAmount: true },
      }),
      prisma.product.findMany({
        select: { id: true, currentStock: true, costPrice: true },
      }),
      prisma.stockMovement.findMany({
        select: { productId: true, type: true, qty: true, createdAt: true },
      }),
    ]);

    const outstanding = (rows) =>
      rows.reduce((s, o) => s + Math.max(o.amount - o.paidAmount, 0), 0);

    const receivables = outstanding(sales);
    const payables = outstanding(purchases);
    const closingStock = await stockValueAt(asOn, products, movements);

    // Cash movement the system can actually see: money collected on sales
    // less money paid out on purchases. It is not a bank balance — there is
    // no opening cash figure anywhere — so the app labels it as such.
    const collected = sales.reduce((s, o) => s + o.paidAmount, 0);
    const paidOut = purchases.reduce((s, o) => s + o.paidAmount, 0);
    const cashMovement = collected - paidOut;

    const assets = closingStock + receivables + cashMovement;
    const liabilities = payables;
    // Owner's funds as the balancing figure: net worth is what is left of the
    // assets once outside claims are met. Derived, not invented — which is
    // why this sheet always balances.
    const ownersFunds = assets - liabilities;

    res.json({
      asOn,
      assets: {
        closingStock,
        tradeReceivables: round2(receivables),
        cashMovement: round2(cashMovement),
        total: round2(assets),
      },
      liabilities: {
        tradePayables: round2(payables),
        ownersFunds: round2(ownersFunds),
        total: round2(liabilities + ownersFunds),
      },
      // Fixed assets, loans and share capital have no table in this schema.
      fixedAssetsModelled: false,
      balanced: Math.abs(assets - (liabilities + ownersFunds)) < 0.01,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;

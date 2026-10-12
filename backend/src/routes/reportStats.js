// /api/stats/reports, /analytics and /profit-loss — the Reports module's data.
const express = require('express');
const prisma = require('../prismaClient');
const { stockStatus } = require('../stockService');
const { getAppSettings } = require('../appSettings');
const { monthWindows, pctChange, growthPct, round2 } = require('./statsHelpers');

const M = require('../orderMath');
const router = express.Router();

// ── Reports ─────────────────────────────────────────────────────────────────
// One consolidated snapshot for the Reports page, optionally scoped to a date
// range (?from=&to=, ISO dates). Everything is derived from the real tables.
router.get('/reports', async (req, res, next) => {
  try {
    const from = req.query.from ? new Date(req.query.from) : null;
    const to = req.query.to ? new Date(req.query.to) : null;
    const range = {};
    if (from && !Number.isNaN(from.valueOf())) range.gte = from;
    if (to && !Number.isNaN(to.valueOf())) range.lte = to;
    const dateWhere = Object.keys(range).length ? { date: range } : {};

    const { lowStockThreshold } = await getAppSettings();
    const [sales, purchases, products, clients, topProducts, topClients] =
      await Promise.all([
        prisma.salesOrder.findMany({
          where: { ...dateWhere, ...M.NOT_CANCELLED },
          select: { amount: true, paymentStatus: true, paidAmount: true, status: true },
        }),
        prisma.purchaseOrder.findMany({
          where: { ...dateWhere, ...M.NOT_CANCELLED },
          select: { amount: true, paidAmount: true, status: true },
        }),
        prisma.product.findMany({
          select: {
            name: true, sku: true, currentStock: true, minimumStock: true,
            costPrice: true, isActive: true,
          },
        }),
        prisma.client.count(),
        prisma.saleItem.groupBy({
          by: ['product'],
          where: { salesOrder: { ...dateWhere, ...M.NOT_CANCELLED } },
          _sum: { qty: true },
          orderBy: { _sum: { qty: 'desc' } },
          take: 5,
        }),
        prisma.salesOrder.groupBy({
          by: ['client'],
          where: { ...dateWhere, ...M.NOT_CANCELLED },
          _sum: { amount: true },
          _count: { _all: true },
          orderBy: { _sum: { amount: 'desc' } },
          take: 5,
        }),
      ]);

    const sum = (rows, pick) => rows.reduce((s, r) => s + pick(r), 0);
    const salesTotal = sum(sales, (o) => o.amount);
    const purchaseTotal = sum(purchases, (o) => o.amount);
    // What is still owed, not the full face value of every unsettled order.
    const receivable = sum(sales, M.owedOn);
    const payable = sum(purchases, M.payableOn);
    const stockValue = sum(products, (p) => p.currentStock * p.costPrice);

    res.json({
      range: {
        from: range.gte ?? null,
        to: range.lte ?? null,
      },
      sales: {
        orders: sales.length,
        total: round2(salesTotal),
        receivable: round2(receivable),
        averageOrderValue: sales.length ? round2(salesTotal / sales.length) : 0,
      },
      purchase: {
        orders: purchases.length,
        total: round2(purchaseTotal),
        payable: round2(payable),
      },
      // Sales minus purchases over the range — a cash-movement view, not
      // accounting profit (no COGS or expenses are modelled yet).
      netMovement: round2(salesTotal - purchaseTotal),
      stock: {
        products: products.length,
        totalValue: round2(stockValue),
        lowStock: products.filter((p) => stockStatus(p, lowStockThreshold) === 'lowStock').length,
        outOfStock: products.filter((p) => stockStatus(p, lowStockThreshold) === 'outOfStock').length,
      },
      clients: { total: clients },
      topProducts: topProducts.map((p) => ({
        product: p.product,
        qty: round2(p._sum.qty || 0),
      })),
      topClients: topClients.map((c) => ({
        client: c.client,
        orders: c._count._all,
        total: round2(c._sum.amount || 0),
      })),
    });
  } catch (err) {
    next(err);
  }
});

// ── Analytics ───────────────────────────────────────────────────────────────
// Everything the Reports → Analytics tab draws, in a single round trip.
//
// Every figure below is derived from the real tables — sales orders, sale
// items, purchase orders, products, categories, clients and the stock ledger.
// Nothing here is a placeholder, and anything without an honest baseline comes
// back as null so the app can render nothing rather than a made-up number.
const MONTH_LABELS = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "2026-7" — groups a date into the month bucket it belongs to.
const monthKey = (d) => `${d.getFullYear()}-${d.getMonth()}`;

/// The last `count` months ending with the current one, oldest first.
function trailingMonths(now, count) {
  const out = [];
  for (let i = count - 1; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    out.push({ key: monthKey(d), label: MONTH_LABELS[d.getMonth()] });
  }
  return out;
}

const DAY_MS = 24 * 60 * 60 * 1000;

/// Revenue and COGS over a set of sale lines. COGS only counts lines that
/// resolved to a real product — free-typed legacy rows have no cost price to
/// charge against.
function marginOf(lines, costOf) {
  let revenue = 0;
  let cogs = 0;
  for (const l of lines) {
    revenue += l.qty * l.rate;
    const cost = costOf(l.productId);
    if (cost != null) cogs += l.qty * cost;
  }
  return { revenue, cogs };
}

router.get('/analytics', async (req, res, next) => {
  try {
    const now = new Date();
    const { startOfThis, startOfLast } = monthWindows(now);
    const quarterMonth = Math.floor(now.getMonth() / 3) * 3;
    const startOfQuarter = new Date(now.getFullYear(), quarterMonth, 1);
    const startOfLastQuarter = new Date(now.getFullYear(), quarterMonth - 3, 1);
    const startOf12 = new Date(now.getFullYear(), now.getMonth() - 11, 1);
    const startOf6 = new Date(now.getFullYear(), now.getMonth() - 5, 1);

    const [sales, purchases, products, categories, saleItems, clients, movements] =
      await Promise.all([
        prisma.salesOrder.findMany({
          where: M.NOT_CANCELLED,
          select: {
            client: true, amount: true, date: true, status: true,
            paymentStatus: true, paidAmount: true, invoiceNo: true,
          },
        }),
        prisma.purchaseOrder.findMany({
          where: M.NOT_CANCELLED,
          select: {
            amount: true, date: true, status: true, dueDate: true, paidAmount: true,
          },
        }),
        prisma.product.findMany({
          select: {
            id: true, name: true, categoryId: true, currentStock: true,
            minimumStock: true, costPrice: true, isActive: true,
          },
        }),
        prisma.category.findMany({ select: { id: true, name: true } }),
        prisma.saleItem.findMany({
          where: { salesOrder: M.NOT_CANCELLED },
          select: {
            product: true, productId: true, qty: true, rate: true,
            salesOrder: { select: { date: true } },
          },
        }),
        prisma.client.findMany({ select: { createdAt: true } }),
        prisma.stockMovement.findMany({
          where: { createdAt: { gte: startOf6 } },
          select: { type: true, qty: true, createdAt: true },
        }),
      ]);

    const productById = new Map(products.map((p) => [p.id, p]));
    const categoryById = new Map(categories.map((c) => [c.id, c.name]));
    const costOf = (id) =>
      (id != null && productById.has(id) ? productById.get(id).costPrice : null);

    const inWindow = (d, gte, lt) => d >= gte && (lt == null || d < lt);

    // ── Top cards ───────────────────────────────────────────────────────────
    const totalSales = sales.reduce((s, o) => s + o.amount, 0);
    const totalPurchases = purchases.reduce((s, o) => s + o.amount, 0);

    const salesThisMonthRows = sales.filter((o) => inWindow(o.date, startOfThis));
    const salesLastMonthRows = sales.filter((o) =>
      inWindow(o.date, startOfLast, startOfThis));
    const salesThisMonth = salesThisMonthRows.reduce((s, o) => s + o.amount, 0);
    const salesLastMonth = salesLastMonthRows.reduce((s, o) => s + o.amount, 0);

    const purchasesThisMonth = purchases
      .filter((o) => inWindow(o.date, startOfThis))
      .reduce((s, o) => s + o.amount, 0);
    const purchasesLastMonth = purchases
      .filter((o) => inWindow(o.date, startOfLast, startOfThis))
      .reduce((s, o) => s + o.amount, 0);

    const clientsThisMonth = clients.filter((c) => c.createdAt >= startOfThis).length;
    const clientsLastMonth = clients
      .filter((c) => inWindow(c.createdAt, startOfLast, startOfThis)).length;

    const invoiced = sales.filter((o) => (o.invoiceNo || '').trim() !== '');
    const invoicesThisQuarter = invoiced.filter((o) => o.date >= startOfQuarter).length;
    const invoicesLastQuarter = invoiced
      .filter((o) => inWindow(o.date, startOfLastQuarter, startOfQuarter)).length;

    // ── Sales vs Purchases, 12 months ───────────────────────────────────────
    const months12 = trailingMonths(now, 12);
    const salesByMonth = new Map();
    const purchasesByMonth = new Map();
    for (const o of sales) {
      if (o.date < startOf12) continue;
      const k = monthKey(o.date);
      salesByMonth.set(k, (salesByMonth.get(k) || 0) + o.amount);
    }
    for (const o of purchases) {
      if (o.date < startOf12) continue;
      const k = monthKey(o.date);
      purchasesByMonth.set(k, (purchasesByMonth.get(k) || 0) + o.amount);
    }

    // ── Stock movement, 6 months ────────────────────────────────────────────
    const months6 = trailingMonths(now, 6);
    const inflowByMonth = new Map();
    const outflowByMonth = new Map();
    for (const m of movements) {
      const k = monthKey(m.createdAt);
      if (m.type === 'IN') {
        inflowByMonth.set(k, (inflowByMonth.get(k) || 0) + m.qty);
      } else if (m.type === 'OUT') {
        outflowByMonth.set(k, (outflowByMonth.get(k) || 0) + m.qty);
      }
    }

    // ── Top selling products / top clients ──────────────────────────────────
    const qtyByProduct = new Map();
    for (const l of saleItems) {
      qtyByProduct.set(l.product, (qtyByProduct.get(l.product) || 0) + l.qty);
    }
    const topProducts = [...qtyByProduct.entries()]
      .map(([product, qty]) => ({ product, qty: round2(qty) }))
      .sort((a, b) => b.qty - a.qty)
      .slice(0, 4);

    const revenueByClient = new Map();
    for (const o of sales) {
      revenueByClient.set(o.client, (revenueByClient.get(o.client) || 0) + o.amount);
    }
    const topClients = [...revenueByClient.entries()]
      .map(([client, total]) => ({ client, total: round2(total) }))
      .sort((a, b) => b.total - a.total)
      .slice(0, 4);

    // ── Inventory health ────────────────────────────────────────────────────
    const { lowStockThreshold } = await getAppSettings();
    const health = { inStock: 0, lowStock: 0, outOfStock: 0, inactive: 0 };
    for (const p of products) health[stockStatus(p, lowStockThreshold)]++;

    // ── Payment collection + receivables aging ──────────────────────────────
    const collected = M.sumBy(sales, M.receivedOn);
    const openSales = sales.filter((o) => M.owedOn(o) > 0);
    const outstanding = M.sumBy(openSales, M.owedOn);
    const billed = collected + outstanding;

    // Each bucket holds what is still owed on its orders, by how old they are.
    const aging = { d0_30: 0, d31_60: 0, d61_90: 0, d90plus: 0 };
    for (const o of openSales) {
      const owed = M.owedOn(o);
      const days = Math.max(0, Math.floor((now - o.date) / DAY_MS));
      if (days <= 30) aging.d0_30 += owed;
      else if (days <= 60) aging.d31_60 += owed;
      else if (days <= 90) aging.d61_90 += owed;
      else aging.d90plus += owed;
    }

    // ── Revenue by category ─────────────────────────────────────────────────
    const revenueByCategory = new Map();
    let categorisedRevenue = 0;
    for (const l of saleItems) {
      const product = l.productId != null ? productById.get(l.productId) : null;
      const name = product
        ? categoryById.get(product.categoryId) || 'Uncategorised'
        : 'Uncategorised';
      const amount = l.qty * l.rate;
      categorisedRevenue += amount;
      revenueByCategory.set(name, (revenueByCategory.get(name) || 0) + amount);
    }
    const categoryRows = [...revenueByCategory.entries()]
      .map(([category, amount]) => ({
        category,
        amount: round2(amount),
        percent: categorisedRevenue
          ? Number(((amount / categorisedRevenue) * 100).toFixed(1))
          : 0,
      }))
      .sort((a, b) => b.amount - a.amount)
      .slice(0, 6);

    // ── Business health indicators ──────────────────────────────────────────
    const linesIn = (gte, lt) =>
      saleItems.filter((l) => l.salesOrder && inWindow(l.salesOrder.date, gte, lt));

    const allMargin = marginOf(saleItems, costOf);
    const thisMonthMargin = marginOf(linesIn(startOfThis), costOf);
    const lastMonthMargin = marginOf(linesIn(startOfLast, startOfThis), costOf);
    const marginPct = (m) => (m.revenue ? ((m.revenue - m.cogs) / m.revenue) * 100 : 0);

    const cogs12 = marginOf(linesIn(startOf12), costOf).cogs;
    const stockValue = products.reduce((s, p) => s + p.currentStock * p.costPrice, 0);

    const ordersPerClient = new Map();
    for (const o of sales) {
      ordersPerClient.set(o.client, (ordersPerClient.get(o.client) || 0) + 1);
    }
    const orderingClients = ordersPerClient.size;
    const repeatClients = [...ordersPerClient.values()].filter((n) => n > 1).length;

    // Owed to suppliers = what is left unpaid, whether or not the goods came.
    const openPurchases = purchases.filter((o) => M.payableOn(o) > 0);
    const payablesDue = M.sumBy(openPurchases, M.payableOn);
    const payablesOverdue = openPurchases
      .filter((o) => o.dueDate && o.dueDate < now)
      .reduce((s, o) => s + M.payableOn(o), 0);

    const avgOrderValue = sales.length ? totalSales / sales.length : 0;
    const avgThisMonth = salesThisMonthRows.length
      ? salesThisMonth / salesThisMonthRows.length : 0;
    const avgLastMonth = salesLastMonthRows.length
      ? salesLastMonth / salesLastMonthRows.length : 0;

    res.json({
      cards: {
        totalSales: round2(totalSales),
        totalPurchases: round2(totalPurchases),
        activeClients: clients.length,
        invoicesRaised: invoiced.length,
        trends: {
          totalSales: pctChange(salesThisMonth, salesLastMonth),
          totalPurchases: pctChange(purchasesThisMonth, purchasesLastMonth),
          activeClients: growthPct(clients.length, clientsThisMonth),
          invoicesRaised: pctChange(invoicesThisQuarter, invoicesLastQuarter),
        },
      },
      salesVsPurchases: months12.map((m) => ({
        label: m.label,
        sales: round2(salesByMonth.get(m.key) || 0),
        purchases: round2(purchasesByMonth.get(m.key) || 0),
      })),
      topProducts,
      topClients,
      stockMovement: months6.map((m) => ({
        label: m.label,
        inflow: round2(inflowByMonth.get(m.key) || 0),
        outflow: round2(outflowByMonth.get(m.key) || 0),
      })),
      inventoryHealth: {
        inStock: health.inStock,
        lowStock: health.lowStock,
        outOfStock: health.outOfStock,
      },
      paymentCollection: {
        collected: round2(collected),
        outstanding: round2(outstanding),
        ratePct: billed ? Number(((collected / billed) * 100).toFixed(0)) : 0,
      },
      receivablesAging: {
        total: round2(outstanding),
        buckets: [
          { label: '0-30 days', amount: round2(aging.d0_30) },
          { label: '31-60 days', amount: round2(aging.d31_60) },
          { label: '61-90 days', amount: round2(aging.d61_90) },
          { label: '90+ days', amount: round2(aging.d90plus) },
        ],
      },
      revenueByCategory: {
        total: round2(categorisedRevenue),
        rows: categoryRows,
      },
      monthComparison: {
        thisMonth: round2(salesThisMonth),
        lastMonth: round2(salesLastMonth),
        growthPct: pctChange(salesThisMonth, salesLastMonth),
        ordersThisMonth: salesThisMonthRows.length,
        avgOrderValue: round2(avgThisMonth),
      },
      healthIndicators: {
        grossMarginPct: Number(marginPct(allMargin).toFixed(1)),
        grossMarginTrend: lastMonthMargin.revenue
          ? Number((marginPct(thisMonthMargin) - marginPct(lastMonthMargin)).toFixed(1))
          : null,
        // Only a snapshot of stock value exists, so this is COGS over the last
        // 12 months against inventory as it stands today.
        inventoryTurnover: stockValue ? Number((cogs12 / stockValue).toFixed(1)) : null,
        avgOrderValue: round2(avgOrderValue),
        avgOrderValueTrend: pctChange(avgThisMonth, avgLastMonth),
        repeatClientPct: orderingClients
          ? Number(((repeatClients / orderingClients) * 100).toFixed(0)) : 0,
        payablesDue: round2(payablesDue),
        payablesOverdue: round2(payablesOverdue),
        newClientsMTD: clientsThisMonth,
        newClientsDelta: clientsThisMonth - clientsLastMonth,
      },
    });
  } catch (err) {
    next(err);
  }
});

// ── Profit & Loss ───────────────────────────────────────────────────────────
// A gross-profit statement over the last 12 months. Revenue and COGS both come
// off the sale lines (qty × rate vs qty × the product's cost price), so the
// margin is real wherever a line resolved to a product. Operating expenses are
// not modelled anywhere in the system, so this stops at gross profit.
router.get('/profit-loss', async (req, res, next) => {
  try {
    const now = new Date();
    const startOf12 = new Date(now.getFullYear(), now.getMonth() - 11, 1);

    const [saleItems, products, purchases] = await Promise.all([
      prisma.saleItem.findMany({
        where: { salesOrder: M.NOT_CANCELLED },
        select: {
          product: true, productId: true, qty: true, rate: true,
          salesOrder: { select: { date: true } },
        },
      }),
      prisma.product.findMany({ select: { id: true, costPrice: true } }),
      prisma.purchaseOrder.findMany({
        where: M.NOT_CANCELLED,
        select: { amount: true, date: true },
      }),
    ]);

    const costById = new Map(products.map((p) => [p.id, p.costPrice]));
    const costOf = (id) => (id != null && costById.has(id) ? costById.get(id) : null);

    const months = trailingMonths(now, 12);
    const perMonth = new Map(
      months.map((m) => [m.key, { revenue: 0, cogs: 0, purchases: 0 }])
    );

    for (const l of saleItems) {
      if (!l.salesOrder || l.salesOrder.date < startOf12) continue;
      const bucket = perMonth.get(monthKey(l.salesOrder.date));
      if (!bucket) continue;
      bucket.revenue += l.qty * l.rate;
      const cost = costOf(l.productId);
      if (cost != null) bucket.cogs += l.qty * cost;
    }
    for (const o of purchases) {
      if (o.date < startOf12) continue;
      const bucket = perMonth.get(monthKey(o.date));
      if (bucket) bucket.purchases += o.amount;
    }

    const rows = months.map((m) => {
      const b = perMonth.get(m.key);
      const gross = b.revenue - b.cogs;
      return {
        label: m.label,
        revenue: round2(b.revenue),
        cogs: round2(b.cogs),
        grossProfit: round2(gross),
        marginPct: b.revenue ? Number(((gross / b.revenue) * 100).toFixed(1)) : 0,
        purchases: round2(b.purchases),
      };
    });

    const totals = rows.reduce(
      (t, r) => ({
        revenue: t.revenue + r.revenue,
        cogs: t.cogs + r.cogs,
        grossProfit: t.grossProfit + r.grossProfit,
        purchases: t.purchases + r.purchases,
      }),
      { revenue: 0, cogs: 0, grossProfit: 0, purchases: 0 }
    );

    // Per-product contribution, biggest contributor first — where the profit
    // actually comes from.
    const byProduct = new Map();
    for (const l of saleItems) {
      const entry = byProduct.get(l.product) || { revenue: 0, cogs: 0 };
      entry.revenue += l.qty * l.rate;
      const cost = costOf(l.productId);
      if (cost != null) entry.cogs += l.qty * cost;
      byProduct.set(l.product, entry);
    }
    const topProducts = [...byProduct.entries()]
      .map(([product, e]) => ({
        product,
        revenue: round2(e.revenue),
        cogs: round2(e.cogs),
        grossProfit: round2(e.revenue - e.cogs),
        marginPct: e.revenue
          ? Number((((e.revenue - e.cogs) / e.revenue) * 100).toFixed(1)) : 0,
      }))
      .sort((a, b) => b.grossProfit - a.grossProfit)
      .slice(0, 6);

    res.json({
      months: rows,
      totals: {
        revenue: round2(totals.revenue),
        cogs: round2(totals.cogs),
        grossProfit: round2(totals.grossProfit),
        purchases: round2(totals.purchases),
        marginPct: totals.revenue
          ? Number(((totals.grossProfit / totals.revenue) * 100).toFixed(1)) : 0,
      },
      topProducts,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;

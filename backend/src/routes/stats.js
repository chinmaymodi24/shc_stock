const express = require('express');
const prisma = require('../prismaClient');
const { stockStatus } = require('../stockService');

const router = express.Router();

// ─────────────────────────────────────────────────────────────────────────────
// Summary cards for every module list page.
//
// Each endpoint returns the real value for each card plus a `trends` block, so
// nothing on those cards is computed in the app (and nothing is hardcoded).
//
// Trend convention:
//   - count metrics  → growth of the total vs where it stood at the start of
//                      this month:  createdThisMonth / (total - createdThisMonth)
//   - money metrics  → this calendar month vs the whole of last month
// Both return null when there's no baseline to compare against, and the app
// renders nothing rather than a fake percentage.
// ─────────────────────────────────────────────────────────────────────────────

function monthWindows(now = new Date()) {
  const startOfThis = new Date(now.getFullYear(), now.getMonth(), 1);
  const startOfLast = new Date(now.getFullYear(), now.getMonth() - 1, 1);
  return { startOfThis, startOfLast };
}

/// Percent change, or null when the baseline is zero/missing.
function pctChange(current, previous) {
  if (!Number.isFinite(current) || !Number.isFinite(previous)) return null;
  if (previous === 0) return null;
  return Number((((current - previous) / previous) * 100).toFixed(1));
}

/// Growth of a running total: how much bigger it is than it was on the 1st.
function growthPct(total, addedThisMonth) {
  const baseline = total - addedThisMonth;
  if (baseline <= 0) return null;
  return Number(((addedThisMonth / baseline) * 100).toFixed(1));
}

const round2 = (n) => Number((n || 0).toFixed(2));

// ── Clients ─────────────────────────────────────────────────────────────────
router.get('/clients', async (req, res, next) => {
  try {
    const { startOfThis } = monthWindows();

    const [clients, createdThisMonth, newRows, salesGroups] = await Promise.all([
      prisma.client.findMany({
        select: { registrationType: true, regState: true },
      }),
      prisma.client.count({ where: { createdAt: { gte: startOfThis } } }),
      prisma.client.findMany({
        where: { createdAt: { gte: startOfThis } },
        orderBy: { createdAt: 'desc' },
        take: 5,
        select: { id: true, code: true, name: true, regState: true },
      }),
      // Per-client order counts drive avg order value + repeat rate.
      prisma.salesOrder.groupBy({
        by: ['client'],
        _count: { _all: true },
        _sum: { amount: true },
      }),
    ]);

    const total = clients.length;
    const gstRegistered = clients.filter((c) => c.registrationType === 'Regular').length;
    const states = new Set(clients.map((c) => c.regState).filter(Boolean));

    const byState = {};
    for (const c of clients) {
      if (!c.regState) continue;
      byState[c.regState] = (byState[c.regState] || 0) + 1;
    }
    const topStates = Object.entries(byState)
      .map(([state, count]) => ({ state, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);

    const orderingClients = salesGroups.length;
    const repeatClients = salesGroups.filter((g) => g._count._all > 1).length;
    const totalOrders = salesGroups.reduce((s, g) => s + g._count._all, 0);
    const totalRevenue = salesGroups.reduce((s, g) => s + (g._sum.amount || 0), 0);

    res.json({
      totalClients: total,
      gstRegistered,
      unregistered: total - gstRegistered,
      statesCovered: states.size,
      trends: {
        totalClients: growthPct(total, createdThisMonth),
        // Registered/unregistered/states have no per-month breakdown of their
        // own; they track overall client growth.
        gstRegistered: growthPct(total, createdThisMonth),
        unregistered: growthPct(total, createdThisMonth),
        statesCovered: null,
      },
      topStates,
      quickStats: {
        avgOrderValue: totalOrders ? round2(totalRevenue / totalOrders) : 0,
        repeatClientsPct: orderingClients
          ? Number(((repeatClients / orderingClients) * 100).toFixed(0))
          : 0,
      },
      newThisMonth: newRows.map((c) => ({
        id: c.id,
        code: c.code,
        name: c.name,
        state: c.regState,
      })),
    });
  } catch (err) {
    next(err);
  }
});

// ── Products ────────────────────────────────────────────────────────────────
router.get('/products', async (req, res, next) => {
  try {
    const { startOfThis } = monthWindows();
    const [products, createdThisMonth] = await Promise.all([
      prisma.product.findMany({
        select: {
          currentStock: true, minimumStock: true, costPrice: true, isActive: true,
        },
      }),
      prisma.product.count({ where: { createdAt: { gte: startOfThis } } }),
    ]);

    const total = products.length;
    const lowStock = products.filter((p) => stockStatus(p) === 'lowStock').length;
    const outOfStock = products.filter((p) => stockStatus(p) === 'outOfStock').length;
    const totalValue = products.reduce((s, p) => s + p.currentStock * p.costPrice, 0);

    res.json({
      totalProducts: total,
      lowStock,
      outOfStock,
      totalValue: round2(totalValue),
      trends: {
        totalProducts: growthPct(total, createdThisMonth),
        lowStock: null,
        outOfStock: null,
        totalValue: null,
      },
    });
  } catch (err) {
    next(err);
  }
});

// ── Inventory ───────────────────────────────────────────────────────────────
router.get('/inventory', async (req, res, next) => {
  try {
    const { startOfThis, startOfLast } = monthWindows();
    const [products, movedThis, movedLast] = await Promise.all([
      prisma.product.findMany({
        select: {
          currentStock: true, minimumStock: true, costPrice: true, isActive: true,
        },
      }),
      prisma.stockMovement.aggregate({
        _sum: { qty: true },
        where: { createdAt: { gte: startOfThis } },
      }),
      prisma.stockMovement.aggregate({
        _sum: { qty: true },
        where: { createdAt: { gte: startOfLast, lt: startOfThis } },
      }),
    ]);

    const counts = { inStock: 0, lowStock: 0, outOfStock: 0, inactive: 0 };
    let totalQty = 0;
    let totalValue = 0;
    for (const p of products) {
      counts[stockStatus(p)]++;
      totalQty += p.currentStock;
      totalValue += p.currentStock * p.costPrice;
    }

    res.json({
      totalItems: products.length,
      inStock: counts.inStock,
      lowStock: counts.lowStock,
      outOfStock: counts.outOfStock,
      inactive: counts.inactive,
      totalQty,
      totalValue: round2(totalValue),
      trends: {
        totalItems: null,
        // How much stock movement this month vs last — the closest honest
        // month-over-month signal inventory has.
        movement: pctChange(movedThis._sum.qty || 0, movedLast._sum.qty || 0),
      },
    });
  } catch (err) {
    next(err);
  }
});

// ── Purchase ────────────────────────────────────────────────────────────────
router.get('/purchase', async (req, res, next) => {
  try {
    const { startOfThis, startOfLast } = monthWindows();
    const [orders, thisMonth, lastMonth, ordersThisMonth] = await Promise.all([
      prisma.purchaseOrder.findMany({ select: { amount: true, status: true } }),
      prisma.purchaseOrder.aggregate({
        _sum: { amount: true },
        where: { date: { gte: startOfThis } },
      }),
      prisma.purchaseOrder.aggregate({
        _sum: { amount: true },
        where: { date: { gte: startOfLast, lt: startOfThis } },
      }),
      prisma.purchaseOrder.count({ where: { createdAt: { gte: startOfThis } } }),
    ]);

    const amountPaid = orders
      .filter((o) => o.status === 'Received')
      .reduce((s, o) => s + o.amount, 0);
    const amountDue = orders
      .filter((o) => o.status === 'Pending' || o.status === 'Partial')
      .reduce((s, o) => s + o.amount, 0);

    res.json({
      totalOrders: orders.length,
      purchaseMTD: round2(thisMonth._sum.amount || 0),
      amountPaid: round2(amountPaid),
      amountDue: round2(amountDue),
      trends: {
        totalOrders: growthPct(orders.length, ordersThisMonth),
        purchaseMTD: pctChange(thisMonth._sum.amount || 0, lastMonth._sum.amount || 0),
        amountPaid: null,
        amountDue: null,
      },
    });
  } catch (err) {
    next(err);
  }
});

// ── Sales ───────────────────────────────────────────────────────────────────
router.get('/sales', async (req, res, next) => {
  try {
    const { startOfThis, startOfLast } = monthWindows();
    const [orders, thisMonth, lastMonth, ordersThisMonth, receivedThis, receivedLast] =
      await Promise.all([
        prisma.salesOrder.findMany({ select: { amount: true, paymentStatus: true } }),
        prisma.salesOrder.aggregate({
          _sum: { amount: true },
          where: { date: { gte: startOfThis } },
        }),
        prisma.salesOrder.aggregate({
          _sum: { amount: true },
          where: { date: { gte: startOfLast, lt: startOfThis } },
        }),
        prisma.salesOrder.count({ where: { createdAt: { gte: startOfThis } } }),
        prisma.salesOrder.aggregate({
          _sum: { amount: true },
          where: { date: { gte: startOfThis }, paymentStatus: 'Paid' },
        }),
        prisma.salesOrder.aggregate({
          _sum: { amount: true },
          where: {
            date: { gte: startOfLast, lt: startOfThis },
            paymentStatus: 'Paid',
          },
        }),
      ]);

    const amountDue = orders
      .filter((o) => o.paymentStatus === 'Pending' || o.paymentStatus === 'Partial')
      .reduce((s, o) => s + o.amount, 0);
    const totalSales = orders.reduce((s, o) => s + o.amount, 0);
    const totalReceived = orders
      .filter((o) => o.paymentStatus === 'Paid')
      .reduce((s, o) => s + o.amount, 0);

    res.json({
      salesMTD: round2(thisMonth._sum.amount || 0),
      totalOrders: orders.length,
      amountDue: round2(amountDue),
      receivedMTD: round2(receivedThis._sum.amount || 0),
      // All-time figures for the Sales Summary side panel.
      totalSales: round2(totalSales),
      totalReceived: round2(totalReceived),
      avgOrderValue: orders.length ? round2(totalSales / orders.length) : 0,
      trends: {
        salesMTD: pctChange(thisMonth._sum.amount || 0, lastMonth._sum.amount || 0),
        totalOrders: growthPct(orders.length, ordersThisMonth),
        amountDue: null,
        receivedMTD: pctChange(receivedThis._sum.amount || 0, receivedLast._sum.amount || 0),
      },
    });
  } catch (err) {
    next(err);
  }
});

// ── Transactions ────────────────────────────────────────────────────────────
router.get('/transactions', async (req, res, next) => {
  try {
    const { startOfThis, startOfLast } = monthWindows();
    const [rows, thisMonth, lastMonth] = await Promise.all([
      prisma.transaction.findMany({ select: { type: true, status: true } }),
      prisma.transaction.count({ where: { date: { gte: startOfThis } } }),
      prisma.transaction.count({
        where: { date: { gte: startOfLast, lt: startOfThis } },
      }),
    ]);

    const count = (fn) => rows.filter(fn).length;
    res.json({
      totalTransactions: rows.length,
      inbound: count((t) => t.type === 'Inbound'),
      outbound: count((t) => t.type === 'Outbound'),
      pending: count((t) => t.status === 'Pending'),
      delivered: count((t) => t.status === 'Delivered'),
      trends: {
        totalTransactions: pctChange(thisMonth, lastMonth),
        inbound: null,
        outbound: null,
        pending: null,
      },
    });
  } catch (err) {
    next(err);
  }
});

// ── Users / Employees ───────────────────────────────────────────────────────
router.get('/users', async (req, res, next) => {
  try {
    const { startOfThis } = monthWindows();
    const [users, createdThisMonth] = await Promise.all([
      prisma.user.findMany({
        select: { role: true, isActive: true, lastLoginAt: true },
      }),
      prisma.user.count({ where: { createdAt: { gte: startOfThis } } }),
    ]);

    const total = users.length;
    const active = users.filter((u) => u.isActive).length;

    const byRole = {};
    for (const u of users) byRole[u.role] = (byRole[u.role] || 0) + 1;

    res.json({
      totalUsers: total,
      activeUsers: active,
      inactiveUsers: total - active,
      adminCount: users.filter((u) => u.role === 'Admin').length,
      roleBreakdown: Object.entries(byRole)
        .map(([role, count]) => ({ role, count }))
        .sort((a, b) => b.count - a.count),
      trends: {
        totalUsers: growthPct(total, createdThisMonth),
        activeUsers: null,
        inactiveUsers: null,
        adminCount: null,
      },
    });
  } catch (err) {
    next(err);
  }
});

// ── Categories ──────────────────────────────────────────────────────────────
router.get('/categories', async (req, res, next) => {
  try {
    const { startOfThis } = monthWindows();
    const [categories, createdThisMonth] = await Promise.all([
      prisma.category.findMany({
        include: { _count: { select: { subCategories: true, products: true } } },
      }),
      prisma.category.count({ where: { createdAt: { gte: startOfThis } } }),
    ]);

    const totalSub = categories.reduce((s, c) => s + c._count.subCategories, 0);
    const largest = categories
      .slice()
      .sort((a, b) => b._count.products - a._count.products)[0];

    res.json({
      totalCategories: categories.length,
      totalSubCategories: totalSub,
      largest: largest
        ? { name: largest.name, productCount: largest._count.products }
        : null,
      trends: {
        totalCategories: growthPct(categories.length, createdThisMonth),
        totalSubCategories: null,
      },
    });
  } catch (err) {
    next(err);
  }
});

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

    const [sales, purchases, products, clients, topProducts, topClients] =
      await Promise.all([
        prisma.salesOrder.findMany({
          where: dateWhere,
          select: { amount: true, paymentStatus: true, status: true },
        }),
        prisma.purchaseOrder.findMany({
          where: dateWhere,
          select: { amount: true, status: true },
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
          _sum: { qty: true },
          orderBy: { _sum: { qty: 'desc' } },
          take: 5,
        }),
        prisma.salesOrder.groupBy({
          by: ['client'],
          _sum: { amount: true },
          _count: { _all: true },
          orderBy: { _sum: { amount: 'desc' } },
          take: 5,
        }),
      ]);

    const sum = (rows, pick) => rows.reduce((s, r) => s + pick(r), 0);
    const salesTotal = sum(sales, (o) => o.amount);
    const purchaseTotal = sum(purchases, (o) => o.amount);
    const receivable = sum(
      sales.filter((o) => o.paymentStatus === 'Pending' || o.paymentStatus === 'Partial'),
      (o) => o.amount
    );
    const payable = sum(
      purchases.filter((o) => o.status === 'Pending' || o.status === 'Partial'),
      (o) => o.amount
    );
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
        lowStock: products.filter((p) => stockStatus(p) === 'lowStock').length,
        outOfStock: products.filter((p) => stockStatus(p) === 'outOfStock').length,
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

module.exports = router;

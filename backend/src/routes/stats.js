const express = require('express');
const prisma = require('../prismaClient');
const { stockStatus } = require('../stockService');
const { getAppSettings } = require('../appSettings');

const M = require('../orderMath');
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

const { monthWindows, pctChange, growthPct, round2 } = require('./statsHelpers');

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
        where: M.NOT_CANCELLED,
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

    const { lowStockThreshold } = await getAppSettings();
    const total = products.length;
    const lowStock = products.filter((p) => stockStatus(p, lowStockThreshold) === 'lowStock').length;
    const outOfStock = products.filter((p) => stockStatus(p, lowStockThreshold) === 'outOfStock').length;
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

    const { lowStockThreshold } = await getAppSettings();
    const counts = { inStock: 0, lowStock: 0, outOfStock: 0, inactive: 0 };
    let totalQty = 0;
    let totalValue = 0;
    for (const p of products) {
      counts[stockStatus(p, lowStockThreshold)]++;
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
      prisma.purchaseOrder.findMany({
        where: M.NOT_CANCELLED,
        select: { amount: true, status: true, paidAmount: true },
      }),
      prisma.purchaseOrder.aggregate({
        _sum: { amount: true },
        where: { date: { gte: startOfThis }, ...M.NOT_CANCELLED },
      }),
      prisma.purchaseOrder.aggregate({
        _sum: { amount: true },
        where: { date: { gte: startOfLast, lt: startOfThis }, ...M.NOT_CANCELLED },
      }),
      prisma.purchaseOrder.count({
        where: { createdAt: { gte: startOfThis }, ...M.NOT_CANCELLED },
      }),
    ]);

    // Paid / due follow what was actually paid to suppliers, not whether the
    // goods have arrived (a received order can still be unpaid).
    const amountPaid = M.sumBy(orders, M.paidOn);
    const amountDue = M.sumBy(orders, M.payableOn);

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
        prisma.salesOrder.findMany({
          where: M.NOT_CANCELLED,
          select: { amount: true, paymentStatus: true, paidAmount: true, status: true, date: true },
        }),
        prisma.salesOrder.aggregate({
          _sum: { amount: true },
          where: { date: { gte: startOfThis }, ...M.NOT_CANCELLED },
        }),
        prisma.salesOrder.aggregate({
          _sum: { amount: true },
          where: { date: { gte: startOfLast, lt: startOfThis }, ...M.NOT_CANCELLED },
        }),
        prisma.salesOrder.count({
          where: { createdAt: { gte: startOfThis }, ...M.NOT_CANCELLED },
        }),
        prisma.salesOrder.findMany({
          where: { date: { gte: startOfThis }, ...M.NOT_CANCELLED },
          select: { amount: true, paymentStatus: true, paidAmount: true, status: true },
        }),
        prisma.salesOrder.findMany({
          where: { date: { gte: startOfLast, lt: startOfThis }, ...M.NOT_CANCELLED },
          select: { amount: true, paymentStatus: true, paidAmount: true, status: true },
        }),
      ]);

    // Due and received are worked out from what was actually paid, so a
    // part-paid order owes only the rest, and Cancelled ones count for nothing.
    const amountDue = M.sumBy(orders, M.owedOn);
    const totalSales = M.sumBy(orders, (o) => Number(o.amount));
    const totalReceived = M.sumBy(orders, M.receivedOn);
    const receivedThisSum = M.sumBy(receivedThis, M.receivedOn);
    const receivedLastSum = M.sumBy(receivedLast, M.receivedOn);

    res.json({
      salesMTD: round2(thisMonth._sum.amount || 0),
      totalOrders: orders.length,
      amountDue: round2(amountDue),
      receivedMTD: round2(receivedThisSum),
      // All-time figures for the Sales Summary side panel.
      totalSales: round2(totalSales),
      totalReceived: round2(totalReceived),
      avgOrderValue: orders.length ? round2(totalSales / orders.length) : 0,
      trends: {
        salesMTD: pctChange(thisMonth._sum.amount || 0, lastMonth._sum.amount || 0),
        totalOrders: growthPct(orders.length, ordersThisMonth),
        amountDue: null,
        receivedMTD: pctChange(receivedThisSum, receivedLastSum),
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
        select: {
          role: true,
          isActive: true,
          lastLoginAt: true,
          roleRef: { select: { key: true } },
        },
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
      // Super Admins and Admins — the two ready-made roles that run the portal.
      adminCount: users.filter(
        (u) => u.roleRef && ['super_admin', 'admin'].includes(u.roleRef.key),
      ).length,
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

// Reports, analytics and profit & loss live in reportStats.js.
router.use('/', require('./reportStats'));

module.exports = router;

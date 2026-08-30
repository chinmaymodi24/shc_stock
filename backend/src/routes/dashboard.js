const express = require('express');
const prisma = require('../prismaClient');
const { stockStatus } = require('../stockService');
const { getAppSettings } = require('../appSettings');

const router = express.Router();

// ─────────────────────────────────────────────────────────────────────────────
// Everything the dashboard renders, derived from the real tables. Nothing here
// is invented — where a figure genuinely has no source yet the field comes back
// as 0/null and the widget shows nothing rather than a placeholder.
// ─────────────────────────────────────────────────────────────────────────────

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

const round2 = (n) => Number((n || 0).toFixed(2));

function pctChange(current, previous) {
  if (previous === 0) return null;
  return Number((((current - previous) / previous) * 100).toFixed(1));
}

/// Start of each of the last [count] months, oldest first.
function lastMonths(count, now = new Date()) {
  const out = [];
  for (let i = count - 1; i >= 0; i--) {
    const start = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const end = new Date(now.getFullYear(), now.getMonth() - i + 1, 1);
    out.push({ label: MONTHS[start.getMonth()], start, end });
  }
  return out;
}

/// Buckets rows into the given month windows, summing `valueOf` (or counting).
function bucket(rows, dateKey, windows, valueOf) {
  return windows.map((w) => {
    const inWindow = rows.filter((r) => {
      const d = new Date(r[dateKey]);
      return d >= w.start && d < w.end;
    });
    const value = valueOf
      ? inWindow.reduce((s, r) => s + valueOf(r), 0)
      : inWindow.length;
    return { label: w.label, value: round2(value) };
  });
}

// GET /api/dashboard
router.get('/', async (req, res, next) => {
  try {
    const now = new Date();
    const windows = lastMonths(6, now);
    const since = windows[0].start;
    const startOfThis = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    const [products, purchases, sales, clients, transactions, saleItems] =
      await Promise.all([
        prisma.product.findMany({
          include: { category: { select: { name: true } } },
        }),
        prisma.purchaseOrder.findMany({
          where: { date: { gte: since } },
          select: { date: true, amount: true, status: true, poNumber: true, supplier: true },
        }),
        prisma.salesOrder.findMany({
          where: { date: { gte: since } },
          select: { date: true, amount: true, paymentStatus: true },
        }),
        prisma.client.findMany({
          where: { createdAt: { gte: since } },
          select: { createdAt: true },
        }),
        prisma.transaction.findMany({
          orderBy: [{ date: 'desc' }, { id: 'desc' }],
          take: 6,
        }),
        // Units sold per product drives "Top Selling Product".
        prisma.saleItem.groupBy({
          by: ['product'],
          _sum: { qty: true },
          orderBy: { _sum: { qty: 'desc' } },
          take: 1,
        }),
      ]);

    // ── Summary tiles ────────────────────────────────────────────────────
    const { lowStockThreshold } = await getAppSettings();
    const totalStockItems = products.reduce((s, p) => s + p.currentStock, 0);
    const outOfStock = products.filter((p) => stockStatus(p, lowStockThreshold) === 'outOfStock').length;
    const lowStock = products.filter((p) => stockStatus(p, lowStockThreshold) === 'lowStock').length;

    const allSales = await prisma.salesOrder.findMany({
      select: { amount: true, paymentStatus: true, date: true },
    });
    const duesFromClients = allSales
      .filter((o) => o.paymentStatus === 'Pending' || o.paymentStatus === 'Partial')
      .reduce((s, o) => s + o.amount, 0);

    const todaysSales = allSales
      .filter((o) => new Date(o.date) >= startOfToday)
      .reduce((s, o) => s + o.amount, 0);
    const monthSales = allSales
      .filter((o) => new Date(o.date) >= startOfThis)
      .reduce((s, o) => s + o.amount, 0);

    // ── Charts ───────────────────────────────────────────────────────────
    const purchasesSeries = bucket(purchases, 'date', windows, (r) => r.amount);
    const salesSeries = bucket(sales, 'date', windows, (r) => r.amount);
    const clientsSeries = bucket(clients, 'createdAt', windows, null);

    const seriesChange = (series) => {
      if (series.length < 2) return null;
      return pctChange(series.at(-1).value, series.at(-2).value);
    };

    // ── Category mix, by stock value ─────────────────────────────────────
    const byCategory = {};
    for (const p of products) {
      const name = p.category ? p.category.name : 'Uncategorised';
      byCategory[name] = (byCategory[name] || 0) + p.currentStock * p.costPrice;
    }
    const catTotal = Object.values(byCategory).reduce((s, v) => s + v, 0);
    const pct = (v) => (catTotal ? Number(((v / catTotal) * 100).toFixed(1)) : 0);
    const ranked = Object.entries(byCategory)
      .map(([label, value]) => ({ label, value }))
      .sort((a, b) => b.value - a.value);

    // Top 5 plus an "Other" bucket, so the donut always accounts for the whole
    // stock value instead of leaving an unexplained gap.
    const top = ranked.slice(0, 5);
    const rest = ranked.slice(5);
    const categorySlices = top.map((c) => ({
      label: c.label,
      value: round2(c.value),
      percent: pct(c.value),
    }));
    if (rest.length) {
      const otherValue = rest.reduce((s, c) => s + c.value, 0);
      categorySlices.push({
        label: `Other (${rest.length})`,
        value: round2(otherValue),
        percent: pct(otherValue),
      });
    }

    // ── Incoming deliveries: purchase orders not yet received ────────────
    const pendingPOs = await prisma.purchaseOrder.findMany({
      where: { status: { in: ['Pending', 'Partial'] } },
      orderBy: { dueDate: 'asc' },
      take: 5,
      include: { items: { select: { product: true }, take: 1 } },
    });
    const incomingDeliveries = pendingPOs.map((po) => ({
      item: po.items[0] ? po.items[0].product : po.supplier,
      poRef: po.poNumber,
      supplier: po.supplier,
      placeOfSupply: po.placeOfSupply,
      dueDate: po.dueDate,
      status: po.status,
    }));

    // ── Low stock alerts ─────────────────────────────────────────────────
    const lowStockAlerts = products
      .filter((p) => ['lowStock', 'outOfStock'].includes(stockStatus(p, lowStockThreshold)))
      .sort((a, b) => a.currentStock - b.currentStock)
      .slice(0, 5)
      .map((p) => ({
        product: p.name,
        sku: p.sku,
        current: p.currentStock,
        minimum: p.minimumStock,
        unit: p.unit,
      }));

    res.json({
      summary: {
        totalStockItems,
        outOfStock,
        lowStock,
        duesFromClients: round2(duesFromClients),
        topSellingProduct: saleItems[0] ? saleItems[0].product : null,
        todaysSales: round2(todaysSales),
        monthSales: round2(monthSales),
      },
      charts: {
        purchases: { series: purchasesSeries, changePct: seriesChange(purchasesSeries) },
        sales: { series: salesSeries, changePct: seriesChange(salesSeries) },
        newClients: { series: clientsSeries, changePct: seriesChange(clientsSeries) },
      },
      categorySlices,
      recentTransactions: transactions,
      incomingDeliveries,
      lowStockAlerts,
    });
  } catch (err) {
    next(err);
  }
});

// ── Notes / to-do ───────────────────────────────────────────────────────────

// GET /api/dashboard/notes?userId=
router.get('/notes', async (req, res, next) => {
  try {
    const userId = Number(req.query.userId);
    const notes = await prisma.dashboardNote.findMany({
      where: Number.isInteger(userId) && userId > 0 ? { userId } : {},
      orderBy: [{ sortOrder: 'asc' }, { id: 'asc' }],
    });
    res.json(notes);
  } catch (err) {
    next(err);
  }
});

// POST /api/dashboard/notes  { text, userId? }
router.post('/notes', async (req, res, next) => {
  try {
    const text = String(req.body.text || '').trim();
    if (!text) return res.status(400).json({ error: 'text is required' });
    const userId = Number(req.body.userId);
    const max = await prisma.dashboardNote.aggregate({ _max: { sortOrder: true } });
    const note = await prisma.dashboardNote.create({
      data: {
        text,
        done: req.body.done === true,
        userId: Number.isInteger(userId) && userId > 0 ? userId : null,
        sortOrder: (max._max.sortOrder ?? -1) + 1,
      },
    });
    res.status(201).json(note);
  } catch (err) {
    next(err);
  }
});

// PUT /api/dashboard/notes/:id  { text?, done? }
router.put('/notes/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    const data = {};
    if (req.body.text !== undefined) {
      const text = String(req.body.text).trim();
      if (!text) return res.status(400).json({ error: 'text cannot be empty' });
      data.text = text;
    }
    if (req.body.done !== undefined) data.done = req.body.done === true;
    const note = await prisma.dashboardNote.update({ where: { id }, data });
    res.json(note);
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Note not found' });
    next(err);
  }
});

// DELETE /api/dashboard/notes/:id
router.delete('/notes/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    await prisma.dashboardNote.delete({ where: { id } });
    res.status(204).send();
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Note not found' });
    next(err);
  }
});

module.exports = router;

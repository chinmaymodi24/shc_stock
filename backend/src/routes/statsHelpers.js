// Month-window and trend helpers shared by the stats routes.

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

module.exports = { monthWindows, pctChange, growthPct, round2 };

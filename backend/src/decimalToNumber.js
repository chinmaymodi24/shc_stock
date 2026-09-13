const { Prisma } = require('@prisma/client');

// ─────────────────────────────────────────────────────────────────────────────
// Turns Prisma Decimal values into plain numbers, wherever they sit.
//
// Money is NUMERIC in the database so stored values and SQL-side sums are
// exact. Prisma returns those columns as Decimal objects, and that shape does
// not survive ordinary JS arithmetic: `0 + decimal` concatenates rather than
// adds, because JS falls back to the string form. So
//
//     rows.reduce((sum, r) => sum + r.amount, 0)
//
// produced "030001001500" instead of 4600 - no error, just a wrong number on
// the screen. Roughly forty expressions across the routes are shaped that way.
//
// Rather than rewrite each one in Decimal arithmetic and depend on nobody
// forgetting next time, every result is converted once on the way out of
// Prisma (see prismaClient.js). Exactness is kept where it counts - in
// storage, and in aggregates the database itself computes.
// ─────────────────────────────────────────────────────────────────────────────

/// A Decimal anywhere inside [value] becomes a number; everything else is
/// returned untouched. Dates and Buffers are left alone so they still
/// serialize as themselves, and an object containing no Decimal is returned by
/// identity rather than rebuilt.
function decimalsToNumbers(value) {
  if (value === null || typeof value !== 'object') return value;
  if (value instanceof Prisma.Decimal) return value.toNumber();
  if (value instanceof Date) return value;
  if (Buffer.isBuffer(value)) return value;

  if (Array.isArray(value)) {
    let changed = false;
    const out = value.map((v) => {
      const next = decimalsToNumbers(v);
      if (next !== v) changed = true;
      return next;
    });
    return changed ? out : value;
  }

  let changed = false;
  const out = {};
  for (const [k, v] of Object.entries(value)) {
    const next = decimalsToNumbers(v);
    if (next !== v) changed = true;
    out[k] = next;
  }
  return changed ? out : value;
}

module.exports = { decimalsToNumbers };

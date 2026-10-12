// ─────────────────────────────────────────────────────────────────────────────
// Running document numbers per financial year: "PO/0001/26-27", "SO/0012/26-27".
//
// Order numbers used to be made in the app from `orders.length` with a fixed
// "PO-2024-" / "SO-2024-" prefix: the year never moved, and deleting an order
// made the next new one reuse a number that still existed (a 409 on save). The
// server now hands them out. The sequence restarts each financial year
// (April–March, Indian time — see timezone.js), the same scheme the bills use.
// ─────────────────────────────────────────────────────────────────────────────

/// "26-27" for any date between 1 Apr 2026 and 31 Mar 2027.
function financialYearLabel(date = new Date()) {
  const startYear = date.getMonth() >= 3 ? date.getFullYear() : date.getFullYear() - 1;
  const a = String(startYear % 100).padStart(2, '0');
  const b = String((startYear + 1) % 100).padStart(2, '0');
  return `${a}-${b}`;
}

/// The highest sequence among [numbers] that belong to `<prefix>/<seq>/<fy>`.
function maxSequence(numbers, prefix, fy) {
  let max = 0;
  const head = `${prefix}/`;
  const tail = `/${fy}`;
  for (const n of numbers) {
    if (typeof n !== 'string' || !n.startsWith(head) || !n.endsWith(tail)) continue;
    const seq = parseInt(n.slice(head.length, n.length - tail.length), 10);
    if (Number.isInteger(seq) && seq > max) max = seq;
  }
  return max;
}

function format(prefix, seq, fy) {
  return `${prefix}/${String(seq).padStart(4, '0')}/${fy}`;
}

/// Next number in a series stored in [field] of the Prisma [model] delegate
/// (e.g. `tx.purchaseOrder`, 'poNumber'). Pass [skip] to look further along —
/// used to step past a number another request has just taken.
async function nextNumber(model, field, prefix, { date = new Date(), skip = 0 } = {}) {
  const fy = financialYearLabel(date);
  const rows = await model.findMany({
    where: { [field]: { startsWith: `${prefix}/`, endsWith: `/${fy}` } },
    select: { [field]: true },
  });
  const max = maxSequence(rows.map((r) => r[field]), prefix, fy);
  return format(prefix, max + 1 + skip, fy);
}

/// Runs [create] with [given] when the caller chose a number, otherwise with
/// the next free one. Two saves at the same moment can be handed the same
/// number; the unique index refuses the second (P2002) and it simply takes the
/// one after. A number the caller typed is never changed — that 409 stands.
async function createNumbered({ given, next, create, attempts = 5 }) {
  if (given) return create(given);
  for (let i = 0; ; i += 1) {
    const number = await next(i);
    try {
      return await create(number);
    } catch (err) {
      if (err.code !== 'P2002' || i >= attempts - 1) throw err;
    }
  }
}

module.exports = { financialYearLabel, maxSequence, nextNumber, format, createNumbered };

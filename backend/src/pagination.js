// ─────────────────────────────────────────────────────────────────────────────
// Opt-in paging for the list endpoints.
//
// Every list route used to answer with the whole table. That was fine while
// the tables were small, but /api/clients had grown to 1049 rows - roughly a
// megabyte of JSON on each load, most of it the 46 field names repeated once
// per row - and it would only grow.
//
// Paging is opt-in because the app fetches each list once and then searches,
// filters and pages it in memory; silently truncating the response would have
// made search quietly miss rows. So:
//
//   GET /api/clients              -> the whole array, exactly as before
//   GET /api/clients?page=2&limit=50
//         -> { items, page, limit, total, totalPages, hasMore }
//
// A caller opts in by sending `page` or `limit`. Nothing else changes shape.
// ─────────────────────────────────────────────────────────────────────────────

const DEFAULT_LIMIT = 50;
const MAX_LIMIT = 500;

/// True when the caller asked for a page.
function wantsPage(query) {
  return query.page !== undefined || query.limit !== undefined;
}

/// { skip, take } for Prisma, or null when the caller wants everything.
function pageArgs(query) {
  if (!wantsPage(query)) return null;

  const rawLimit = Number.parseInt(query.limit, 10);
  const limit = Number.isFinite(rawLimit) && rawLimit > 0
    ? Math.min(rawLimit, MAX_LIMIT)
    : DEFAULT_LIMIT;

  const rawPage = Number.parseInt(query.page, 10);
  const page = Number.isFinite(rawPage) && rawPage > 0 ? rawPage : 1;

  return { page, limit, skip: (page - 1) * limit, take: limit };
}

/// Wraps rows in the paged envelope, or hands them back untouched.
function paged(query, rows, total) {
  const args = pageArgs(query);
  if (!args) return rows;
  const { page, limit } = args;
  return {
    items: rows,
    page,
    limit,
    total,
    totalPages: Math.max(1, Math.ceil(total / limit)),
    hasMore: page * limit < total,
  };
}

/// Runs a list query with or without paging, and returns what the route should
/// send. `find` receives the Prisma args to spread into findMany.
async function listResponse({ query, model, findMany, count, transform }) {
  const args = pageArgs(query);
  const [rows, total] = await Promise.all([
    findMany(args ? { skip: args.skip, take: args.take } : {}),
    args ? count() : Promise.resolve(0),
  ]);
  const shaped = transform ? await transform(rows) : rows;
  return paged(query, shaped, total);
}

module.exports = { wantsPage, pageArgs, paged, listResponse, DEFAULT_LIMIT, MAX_LIMIT };

const test = require('node:test');
const assert = require('node:assert');
const { wantsPage, pageArgs, paged, listResponse, DEFAULT_LIMIT, MAX_LIMIT } = require('./pagination');

test('a caller that asks for nothing still gets the plain array', () => {
  assert.equal(wantsPage({}), false);
  assert.equal(pageArgs({}), null);
  const rows = [1, 2, 3];
  assert.deepEqual(paged({}, rows, 3), rows);
});

test('page or limit alone opts in', () => {
  assert.equal(wantsPage({ page: '2' }), true);
  assert.equal(wantsPage({ limit: '10' }), true);
});

test('defaults fill in the half the caller left out', () => {
  assert.deepEqual(pageArgs({ page: '3' }), { page: 3, limit: DEFAULT_LIMIT, skip: 2 * DEFAULT_LIMIT, take: DEFAULT_LIMIT });
  assert.deepEqual(pageArgs({ limit: '10' }), { page: 1, limit: 10, skip: 0, take: 10 });
});

test('limit is capped so one request cannot ask for the whole table', () => {
  assert.equal(pageArgs({ limit: String(MAX_LIMIT * 10) }).limit, MAX_LIMIT);
});

test('nonsense page and limit fall back instead of throwing', () => {
  for (const bad of ['0', '-5', 'abc', '']) {
    const a = pageArgs({ page: bad, limit: bad });
    assert.equal(a.page, 1, `page for ${JSON.stringify(bad)}`);
    assert.equal(a.limit, DEFAULT_LIMIT, `limit for ${JSON.stringify(bad)}`);
  }
});

test('the envelope reports where the caller is', () => {
  const env = paged({ page: '2', limit: '10' }, [1, 2, 3], 25);
  assert.deepEqual(env, {
    items: [1, 2, 3], page: 2, limit: 10, total: 25, totalPages: 3, hasMore: true,
  });
});

test('the last page says there is no more', () => {
  assert.equal(paged({ page: '3', limit: '10' }, [], 25).hasMore, false);
});

test('an empty table still reports one page', () => {
  assert.equal(paged({ limit: '10' }, [], 0).totalPages, 1);
});

test('listResponse skips the count query when not paging', async () => {
  let counted = 0;
  const out = await listResponse({
    query: {},
    findMany: async (page) => { assert.deepEqual(page, {}); return [1, 2]; },
    count: async () => { counted++; return 2; },
  });
  assert.deepEqual(out, [1, 2]);
  assert.equal(counted, 0, 'counting a table nobody is paging is wasted work');
});

test('listResponse passes skip/take through and applies transform', async () => {
  const out = await listResponse({
    query: { page: '2', limit: '5' },
    findMany: async (page) => { assert.deepEqual(page, { skip: 5, take: 5 }); return [1, 2]; },
    count: async () => 12,
    transform: (rows) => rows.map((n) => n * 10),
  });
  assert.deepEqual(out.items, [10, 20]);
  assert.equal(out.total, 12);
  assert.equal(out.totalPages, 3);
});

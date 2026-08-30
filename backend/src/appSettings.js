const prisma = require('./prismaClient');

/// Business-wide settings live in a single `app_settings` row (id = 1).
/// Read a lot (every stats/inventory request) so the row is cached in memory
/// and the cache is dropped whenever it is written.

const DEFAULTS = { lowStockThreshold: 0 };

let cache = null;

async function getAppSettings() {
  if (cache) return cache;
  const row = await prisma.appSetting.upsert({
    where: { id: 1 },
    update: {},
    create: { id: 1, ...DEFAULTS },
  });
  cache = row;
  return row;
}

async function updateAppSettings(data) {
  const row = await prisma.appSetting.upsert({
    where: { id: 1 },
    update: data,
    create: { id: 1, ...DEFAULTS, ...data },
  });
  cache = row;
  return row;
}

module.exports = { getAppSettings, updateAppSettings };

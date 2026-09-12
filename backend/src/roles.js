const prisma = require('./prismaClient');
const { SYSTEM_ROLES, LEGACY_ROLE_KEYS } = require('./permissions');

/// Brings the ready-made roles in the database up to date with
/// src/permissions.js, then attaches legacy employees to them.
///
/// Runs on every server start and is idempotent, so a module added to the
/// catalog reaches every preset on the next restart — no migration, no seed
/// script to remember.
async function syncSystemRoles() {
  for (const r of SYSTEM_ROLES) {
    const data = {
      name: r.name,
      description: r.description,
      icon: r.icon,
      permissions: r.permissions,
      isSystem: true,
      isSuperAdmin: r.isSuperAdmin,
    };
    try {
      await prisma.role.upsert({
        where: { key: r.key },
        update: data,
        create: { key: r.key, ...data, modifiedBy: 'System' },
      });
    } catch (err) {
      // Most likely a custom role already took this name. Keep the server up;
      // the preset is simply missing until that role is renamed.
      console.error(`Could not sync the "${r.name}" role:`, err.message);
    }
  }

  // Employees saved before roles existed carry only a text label. Point them
  // at the preset that replaces it. Their own permission map is left alone —
  // it is what they were actually granted.
  const presets = await prisma.role.findMany({
    where: { key: { in: Object.values(LEGACY_ROLE_KEYS) } },
    select: { id: true, key: true, name: true },
  });
  const byKey = Object.fromEntries(presets.map((p) => [p.key, p]));
  for (const [label, key] of Object.entries(LEGACY_ROLE_KEYS)) {
    const preset = byKey[key];
    if (!preset) continue;
    await prisma.user.updateMany({
      where: { roleId: null, role: label },
      data: { roleId: preset.id, role: preset.name },
    });
  }
}

module.exports = { syncSystemRoles };

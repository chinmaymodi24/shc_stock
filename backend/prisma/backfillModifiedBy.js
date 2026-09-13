/* eslint-disable no-console */
// Repairs the "Modified By" column on rows that predate a real portal user.
//
// Two problems, both left by the demo seeds and the one-off client import:
//
//   1. A handful of rows name employees who do not exist — 'Chinmay Modi',
//      'Riya Patel'. The portal has one account, the admin, so those rows read
//      as history from staff the buyer never hired.
//   2. Most seeded/imported rows carry `modifiedBy: 'Admin'` but no
//      `modifiedAt`, and the table renders a bare dash when the date is
//      missing. The row was in fact put there by the admin doing the setup, so
//      falling back to `createdAt` states what actually happened instead of
//      inventing a time.
//
// Run `node prisma/backfillModifiedBy.js` for a dry run (prints what it would
// do, changes nothing), and `--apply` to write.

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Names the demo seeds invented. Anything here becomes the admin.
const GHOST_NAMES = ['Chinmay Modi', 'Riya Patel'];

// Every model that carries the modifiedBy/modifiedAt pair.
const MODELS = ['user', 'product', 'purchaseOrder', 'salesOrder', 'client', 'transaction'];

async function main() {
  const apply = process.argv.includes('--apply');
  console.log(apply ? 'APPLYING changes\n' : 'DRY RUN — nothing is written\n');

  let ghostTotal = 0;
  let dateTotal = 0;

  for (const model of MODELS) {
    const table = prisma[model];
    if (!table) continue;

    const ghosts = await table.count({ where: { modifiedBy: { in: GHOST_NAMES } } });
    // `modifiedAt` is non-nullable on some models; those simply match nothing.
    let undated = 0;
    try {
      undated = await table.count({ where: { modifiedAt: null } });
    } catch {
      undated = 0;
    }

    if (!ghosts && !undated) {
      console.log(`${model.padEnd(15)} nothing to do`);
      continue;
    }
    console.log(`${model.padEnd(15)} ${ghosts} named a ghost, ${undated} missing a date`);
    ghostTotal += ghosts;
    dateTotal += undated;

    if (!apply) continue;

    if (ghosts) {
      await table.updateMany({
        where: { modifiedBy: { in: GHOST_NAMES } },
        data: { modifiedBy: 'Admin' },
      });
    }

    if (undated) {
      // Prisma cannot copy one column into another in a single updateMany, so
      // the rows are walked. There are ~1k of them, once.
      const rows = await table.findMany({
        where: { modifiedAt: null },
        select: { id: true, createdAt: true },
      });
      for (const row of rows) {
        await table.update({
          where: { id: row.id },
          data: { modifiedAt: row.createdAt },
        });
      }
    }
  }

  console.log(
    `\n${ghostTotal} row(s) credited to Admin, ${dateTotal} row(s) dated from createdAt.`,
  );
  if (!apply) console.log('Re-run with --apply to write.');
}

main()
  .catch((err) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());

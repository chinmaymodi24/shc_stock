/* eslint-disable no-console */
// Before/after proof of the contact split, straight from the database.
//   node prisma/showClientContactSplit.js [howMany]
//
// "Before" is reconstructed as the row read originally: address + the person
// and phone that were pulled out of it.

const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();
const LIMIT = Number(process.argv[2]) || 10;

const pad = (s, n) => (s.length > n ? `${s.slice(0, n - 1)}…` : s.padEnd(n));

async function main() {
  const clients = await prisma.client.findMany({
    where: { OR: [{ contactPerson: { not: '' } }, { contactPhone: { not: '' } }] },
    select: {
      code: true,
      name: true,
      address: true,
      contactPerson: true,
      contactPhone: true,
    },
    orderBy: { id: 'asc' },
    take: LIMIT,
  });

  for (const c of clients) {
    const tail = [c.contactPerson, c.contactPhone].filter(Boolean).join(' - ');
    console.log(`\n${c.code}  ${c.name}`);
    console.log(`  BEFORE  address : ${c.address}${tail ? `, ${tail}` : ''}`);
    console.log(`  AFTER   address : ${c.address}`);
    console.log(`          person  : ${c.contactPerson || '—'}`);
    console.log(`          phone   : ${c.contactPhone || '—'}`);
  }

  const [total, withPerson, withPhone] = await Promise.all([
    prisma.client.count(),
    prisma.client.count({ where: { contactPerson: { not: '' } } }),
    prisma.client.count({ where: { contactPhone: { not: '' } } }),
  ]);

  console.log(`\n${'─'.repeat(64)}`);
  console.log(`clients ${total} · contactPerson ${withPerson} · contactPhone ${withPhone}`);

  // Column-by-column proof that nothing is left behind in `address`.
  const stillGlued = await prisma.client.count({
    where: {
      OR: [
        { address: { contains: ', mo.', mode: 'insensitive' } },
        { address: { contains: ', Mo.', mode: 'insensitive' } },
      ],
    },
  });
  console.log(`addresses still ending in a "mo." contact: ${stillGlued}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());

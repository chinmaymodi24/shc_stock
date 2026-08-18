/* eslint-disable no-console */
// Reports what is still sitting inside the clients' `address` column: any
// phone-like number, or any leftover "Shri / Mr. …" contact name.
//   node prisma/auditClientAddresses.js

const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

// 7+ digits (a 6-digit run is a PIN code and belongs to the address).
const PHONE_LEFT = /(?<!\d)(\d[\d\s-]{5,}\d)(?!\d)/g;
const NAME_LEFT = /\b(shri|smt|mr|mrs|miss)\b\.?\s+[A-Z]/i;

const digits = (s) => s.replace(/\D/g, '');

function leftoverPhones(address) {
  const hits = [];
  for (const m of (address || '').matchAll(PHONE_LEFT)) {
    const d = digits(m[1]);
    if (d.length >= 7 && d.length <= 14) hits.push(m[1].trim());
  }
  return hits;
}

async function main() {
  const clients = await prisma.client.findMany({
    select: {
      code: true,
      name: true,
      address: true,
      contactPerson: true,
      contactPhone: true,
    },
    orderBy: { id: 'asc' },
  });

  const phoneLeft = [];
  const nameLeft = [];
  for (const c of clients) {
    if (leftoverPhones(c.address).length) phoneLeft.push(c);
    if (NAME_LEFT.test(c.address || '')) nameLeft.push(c);
  }

  console.log('─'.repeat(72));
  console.log(`clients                      : ${clients.length}`);
  console.log(`contactPerson filled         : ${clients.filter((c) => c.contactPerson).length}`);
  console.log(`contactPhone  filled         : ${clients.filter((c) => c.contactPhone).length}`);
  console.log(`address still has a phone    : ${phoneLeft.length}`);
  console.log(`address still has a name     : ${nameLeft.length}`);
  console.log('─'.repeat(72));

  const show = (label, rows) => {
    if (!rows.length) return;
    console.log(`\n${label}`);
    for (const c of rows.slice(0, 15)) {
      console.log(`  ${c.code}  ${c.name}`);
      console.log(`     address: ${c.address}`);
      console.log(`     person : ${c.contactPerson || '—'}   phone: ${c.contactPhone || '—'}`);
    }
    if (rows.length > 15) console.log(`  …and ${rows.length - 15} more`);
  };

  show('ADDRESSES THAT STILL CONTAIN A PHONE:', phoneLeft);
  show('ADDRESSES THAT STILL CONTAIN A NAME:', nameLeft);

  console.log('\nFirst 8 rows as they now stand:');
  for (const c of clients.slice(0, 8)) {
    console.log(`  ${c.code}  ${c.name}`);
    console.log(`     address : ${c.address}`);
    console.log(`     person  : ${c.contactPerson || '—'}`);
    console.log(`     phone   : ${c.contactPhone || '—'}`);
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());

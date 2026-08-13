// Seeds the `transactions` table with the goods-movement rows that used to
// live hardcoded in lib/app/modules/transactions/controllers/
// transactions_controller.dart, now commented out there.
//
// Idempotent: clears and re-inserts, so re-running gives the same six rows.
//   node prisma/seedTransactions.js
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const transactions = [
  {
    item: 'Copper Pipe 15mm',
    type: 'Inbound',
    party: 'Ashoka Metals',
    poNumber: '#4421',
    date: new Date(2026, 6, 10),
    status: 'Received',
    modifiedBy: 'Chinmay Modi',
    modifiedAt: new Date(2026, 6, 10, 14, 40),
  },
  {
    item: 'PEX Fitting Kit',
    type: 'Outbound',
    party: 'Patel Plumbing Co.',
    poNumber: '#4419',
    date: new Date(2026, 6, 10),
    status: 'Shipped',
    modifiedBy: 'Riya Patel',
    modifiedAt: new Date(2026, 6, 10, 11, 5),
  },
  {
    item: 'Water Heater Coil',
    type: 'Inbound',
    party: 'ThermoTech Industries',
    poNumber: '#4425',
    date: new Date(2026, 6, 9),
    status: 'Pending',
    modifiedBy: 'Chinmay Modi',
    modifiedAt: new Date(2026, 6, 9, 9, 30),
  },
  {
    item: 'Brass Valve 3/4"',
    type: 'Outbound',
    party: 'Shah Hardware',
    poNumber: '#4408',
    date: new Date(2026, 6, 8),
    status: 'Delivered',
    modifiedBy: 'Riya Patel',
    modifiedAt: new Date(2026, 6, 8, 16, 12),
  },
  {
    item: 'Insulation Tape',
    type: 'Inbound',
    party: 'Gujarat Polymers',
    poNumber: '#4402',
    date: new Date(2026, 6, 6),
    status: 'Received',
    modifiedBy: 'Chinmay Modi',
    modifiedAt: new Date(2026, 6, 6, 13, 47),
  },
  {
    item: 'Ball Valve 1"',
    type: 'Outbound',
    party: 'Mehta Constructions',
    poNumber: '#4396',
    date: new Date(2026, 6, 4),
    status: 'Delivered',
    modifiedBy: 'Riya Patel',
    modifiedAt: new Date(2026, 6, 4, 10, 58),
  },
];

async function main() {
  await prisma.transaction.deleteMany({});
  await prisma.transaction.createMany({ data: transactions });
  console.log(`Transactions seeded - ${transactions.length} rows.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());

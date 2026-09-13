/* eslint-disable no-console */
// Fills the `regCity` column for the clients imported from the accounting
// export, which arrived with a free-text `address` and no city of their own.
//
// Until now the city was never stored: ClientModel.city in the Flutter app
// parsed it out of the address on every read, which was fine while the whole
// table sat in memory. Now that the list is searched and filtered by the
// server, the City filter needs a real column to query - so the parse runs
// once, here, and the result is written down.
//
// The rules below are a direct port of ClientModel.city
// (lib/app/modules/clients/models/client_model.dart), so a backfilled row
// shows exactly the city the app was already displaying. The Dart getter still
// prefers regCity when it is set, so nothing on screen changes.
//
// Run `node prisma/backfillClientCity.js` for a dry run (prints a sample and
// the totals, changes nothing), and `--apply` to write.

const prisma = require('../src/prismaClient');

const CITY_IN_ADDRESS = /([A-Za-z][A-Za-z .]{1,30}?)\s*[-,]\s*(\d{6}|\d{3}\s?\d{3})/;
const LEADING_QUALIFIER = /^(Dist\.?|Tal\.?|Ta\.?|Nr\.?|Vill\.?)\s+/i;

/// The city for a client row, or '' when the address yields none.
function cityOf({ regCity, address }) {
  if (regCity && regCity.trim()) return regCity.trim();
  const match = CITY_IN_ADDRESS.exec(address || '');
  if (!match) return '';
  const name = match[1].trim().replace(LEADING_QUALIFIER, '');
  return name.split(',').pop().trim();
}

async function main() {
  const apply = process.argv.includes('--apply');
  console.log(apply ? 'APPLYING changes\n' : 'DRY RUN - nothing is written\n');

  const rows = await prisma.client.findMany({
    where: { regCity: '' },
    select: { id: true, name: true, address: true, regCity: true },
  });

  const resolved = rows
    .map((r) => ({ ...r, city: cityOf(r) }))
    .filter((r) => r.city);

  console.log(`${rows.length} client(s) without a city, ${resolved.length} parsed from the address.`);

  const tally = {};
  for (const r of resolved) tally[r.city] = (tally[r.city] || 0) + 1;
  const top = Object.entries(tally).sort((a, b) => b[1] - a[1]);
  console.log(`${top.length} distinct cities. Most common:`);
  top.slice(0, 10).forEach(([c, n]) => console.log(`  ${String(n).padStart(4)}  ${c}`));

  console.log('\nSample rows:');
  resolved.slice(0, 5).forEach((r) => {
    console.log(`  ${r.city.padEnd(18)} <- ${(r.address || '').slice(0, 70)}`);
  });

  const unparsed = rows.length - resolved.length;
  if (unparsed) {
    console.log(`\n${unparsed} address(es) matched nothing; those rows keep an empty city,`);
    console.log('which is what the app already showed for them.');
  }

  if (!apply) {
    console.log('\nRe-run with --apply to write.');
    return;
  }

  let done = 0;
  for (const r of resolved) {
    await prisma.client.update({ where: { id: r.id }, data: { regCity: r.city } });
    done++;
  }
  console.log(`\nWrote regCity on ${done} client(s).`);
}

main()
  .catch((err) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());

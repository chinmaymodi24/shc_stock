/* eslint-disable no-console */
// Splits the contact person and phone out of the free-text `address` blob the
// clients were imported with, into the `contactPerson` / `contactPhone`
// columns, and leaves `address` holding only the address.
//
// The import glued them together in a handful of shapes:
//   "…, Ahmedabad - 380005, Shri Shreyashbhai - 9428421959"
//   "…, Dist. Pune - 411062, mo. 9923908368"          (phone, no name)
//   "…, Ahmedabad., Shri Manojbhai"                   (name, no phone)
//   "…, Vatva - 382445, Mr. Jayesh Mali - 9662900358, 9714445487"  (two phones)
//   "…, Chandkheda - 382470, Mr. A/ Mr. B, Mo. 9978278666/ 9558489339"
//
// Run `node prisma/backfillClientContacts.js` for a dry run (prints what it
// would do, changes nothing), and `--apply` to write. `--apply` first dumps
// every original address to prisma/backup-client-addresses.json so the split
// can be undone.

const fs = require('fs');
const path = require('path');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();
const APPLY = process.argv.includes('--apply');
// Timestamped: a second run must not overwrite the first run's originals.
const BACKUP = path.join(
  __dirname,
  `backup-client-addresses-${new Date().toISOString().slice(0, 19).replace(/[:T]/g, '')}.json`,
);

// Phones come in three shapes in this data, and each needs its own pattern:
//   plain / space-split  "9428421959", "97250 33951"
//   STD landline         "0341-2258800"
//   international        "+977 9702625922"
// A single greedy pattern with hyphens in it would swallow "Ahmedabad -
// 380005, Shri X - 9428421959" whole, so they stay separate and the matches
// are merged below. Six-digit runs are PIN codes and never match.
const PHONE_PATTERNS = [
  /(?<!\d)(\+\d[\d\s]{7,}\d)(?!\d)/g,
  /(?<!\d)(\d{3,5}-\d{6,8})(?!\d)/g,
  // Same, but typed with spaces around the hyphen: "Ph. 02692 - 249370".
  /(?<!\d)(\d{2,5}\s*-\s*\d{6,8})(?!\d)/g,
  /(?<!\d)(\d[\d\s]{5,}\d)(?!\d)/g,
];
const PHONE_MARKER = /^(m|mo|mob|mobile|ph|phone|cell|contact)\.?\s*[:\-]?$/i;
// Tokens that mean the text is still part of the address, not a person.
const ADDRESS_WORD =
  /\b(road|nagar|gidc|midc|plot|survey|dist|distt|taluka|tal|opp|nr|near|floor|estate|society|complex|industrial|area|park|phase|sector|village|vill|state|highway|n\.h|market|chowk|bhavan|tower|apartment|flats?|shop|block|lane|marg|colony|compound|scheme|zone|gate|refinery|pin)\b/i;

const digitsOf = (s) => s.replace(/\D/g, '');

/** All phone numbers in [text], longest match wins, in order of appearance. */
function phonesIn(text) {
  const found = [];
  for (const re of PHONE_PATTERNS) {
    for (const m of text.matchAll(re)) {
      const digits = digitsOf(m[1]);
      if (digits.length < 7 || digits.length > 14) continue;
      const start = m.index;
      const end = start + m[1].length;
      const clash = found.findIndex((f) => start < f.end && end > f.start);
      if (clash === -1) {
        found.push({ raw: m[1], index: start, start, end, digits });
      } else if (m[1].length > found[clash].raw.length) {
        found[clash] = { raw: m[1], index: start, start, end, digits };
      }
    }
  }
  return found.sort((a, b) => a.index - b.index);
}

/**
 * Splits one imported address into { address, contactPerson, contactPhone }.
 * Anything it cannot confidently split is left in `address` untouched.
 */
function splitContact(original) {
  const input = (original || '').trim();
  if (!input) return { address: '', contactPerson: '', contactPhone: '' };

  const phones = phonesIn(input);
  const tailPhones = phones.filter((p) => p.index > input.length * 0.45);

  let cutAt = -1; // where the contact tail starts
  let person = '';
  let phone = '';

  if (tailPhones.length) {
    const first = tailPhones[0];
    // Drop the dash that joins the name to the number ("Shri X - 94284…"),
    // then the text after the previous comma is the name or a "Mo." marker.
    const before = input.slice(0, first.index).replace(/[\s\-–—:]+$/, '');
    const sep = before.lastIndexOf(',');
    const candidate = before
      .slice(sep + 1)
      .replace(/^[,\s]+/, '')
      .trim();

    const isMarker = PHONE_MARKER.test(candidate);
    const titled = /^(shri|smt|mr|mrs|miss|m\/s)\b\.?/i.test(candidate);
    const looksLikeAddress =
      candidate.length > 45 ||
      ADDRESS_WORD.test(candidate) ||
      /\d/.test(candidate);

    // A 10-digit number is unmistakably a phone. A shorter one (landline, or
    // a mangled PIN like "Bangalore - 5621232") only counts when something
    // says so: a "Mo."/"Ph." marker, or a titled name in front of it.
    const digits = first.digits.length;
    const isPhone = digits >= 10 || isMarker || titled;

    if (isPhone) {
      phone = tailPhones.map((p) => p.digits).join(' / ');
      if (isMarker || !candidate) {
        person = '';
        cutAt = sep >= 0 ? sep : first.index;
      } else if (looksLikeAddress && !titled) {
        // The number trails the address itself — take the phone, keep the
        // address whole.
        person = '';
        cutAt = first.index;
      } else {
        person = candidate;
        cutAt = sep >= 0 ? sep : first.index;
      }
    }
  }

  if (cutAt < 0 && !phone) {
    // No phone: a trailing "…, Shri Manojbhai" is still a contact.
    const lastComma = input.lastIndexOf(',');
    const tail = input
      .slice(lastComma + 1)
      .trim()
      .replace(/\.$/, '');
    if (
      lastComma > 0 &&
      /^(shri|smt|mr|mrs|miss|m\/s)\b\.?/i.test(tail) &&
      !ADDRESS_WORD.test(tail)
    ) {
      person = tail;
      cutAt = lastComma;
    }
  }

  if (cutAt < 0) return { address: input, contactPerson: '', contactPhone: '' };

  const address = input
    .slice(0, cutAt)
    // Also drops the half-typed remains of a marker — "Mo. 977-" is what
    // is left once the numbers behind it have been taken.
    .replace(/[\s,]*\b(mo|mob|m|ph|cell|contact)\.?\s*[\d+\-\s]*$/i, '')
    .replace(/[\s,]+$/, '')
    .trim();

  return { address, contactPerson: person, contactPhone: phone };
}

async function main() {
  const clients = await prisma.client.findMany({
    select: { id: true, code: true, name: true, address: true },
    orderBy: { id: 'asc' },
  });

  const changes = [];
  for (const c of clients) {
    const split = splitContact(c.address);
    if (
      split.contactPerson ||
      split.contactPhone ||
      split.address !== (c.address || '').trim()
    ) {
      changes.push({ ...c, ...split });
    }
  }

  const withPerson = changes.filter((c) => c.contactPerson).length;
  const withPhone = changes.filter((c) => c.contactPhone).length;
  console.log(`clients:        ${clients.length}`);
  console.log(`rows to update: ${changes.length}`);
  console.log(`  with person:  ${withPerson}`);
  console.log(`  with phone:   ${withPhone}`);
  console.log('\nsample:');
  for (const c of changes.slice(0, 12)) {
    console.log(`  ${c.code} ${c.name}`);
    console.log(`     address: ${c.address}`);
    console.log(`     person : ${c.contactPerson || '—'}   phone: ${c.contactPhone || '—'}`);
  }

  if (!APPLY) {
    console.log('\nDry run — nothing written. Re-run with --apply to save.');
    return;
  }

  fs.writeFileSync(
    BACKUP,
    JSON.stringify(
      clients.map((c) => ({ id: c.id, address: c.address })),
      null,
      2,
    ),
  );
  console.log(`\nOriginal addresses backed up to ${BACKUP}`);

  let done = 0;
  for (const c of changes) {
    await prisma.client.update({
      where: { id: c.id },
      data: {
        address: c.address,
        contactPerson: c.contactPerson,
        contactPhone: c.contactPhone,
      },
    });
    done++;
  }
  console.log(`Updated ${done} clients.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());

module.exports = { splitContact };

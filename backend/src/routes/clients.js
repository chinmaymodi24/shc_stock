const express = require('express');
const prisma = require('../prismaClient');
const { normalisePhone } = require('../phone');
const { actorName } = require('../auth/middleware');
const { listResponse } = require('../pagination');
const V = require('../validate');
const { ValidationError } = V;

const router = express.Router();
router.param('id', require('../validate').idParam);

/// Trimmed text; anything longer than [max] is refused (it would only break the
/// list and the printed bill).
const str = (v, fallback = '', max = 500) => {
  if (v === undefined || v === null) return fallback;
  const s = String(v).trim();
  if (s.length > max) throw new ValidationError(`A client field must be at most ${max} characters`);
  return s;
};
const num = (v, fallback = 0) => {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
};
/// A money amount the NUMERIC column can hold (an opening balance may be negative).
const amount = (v, field) => V.number(v, field, { min: -V.MAX_MONEY, max: V.MAX_MONEY });

/// Builds the free-text display address the clients list renders. Legacy rows
/// imported from the accounting export carry their own blob; rows created here
/// compose one from the structured registered-address fields.
function composeAddress(body) {
  const explicit = str(body.address);
  if (explicit) return explicit;
  const cityPin = [str(body.regCity), str(body.regPin)].filter(Boolean).join(' - ');
  return [str(body.regAddr1), str(body.regAddr2), cityPin, str(body.regState)]
    .filter(Boolean)
    .join(', ');
}

function clientData(body, actor) {
  return {
    name: str(body.name, '', 200),
    clientType: str(body.clientType),
    registrationType: str(body.registrationType, 'Regular') || 'Regular',
    email: str(body.email),
    phone: normalisePhone(body.phone),
    altPhone: normalisePhone(body.altPhone),
    gstin: str(body.gstin),
    pan: str(body.pan),
    clientSince: V.date(body.clientSince, 'clientSince'),

    address: composeAddress(body),
    regAddr1: str(body.regAddr1),
    regAddr2: str(body.regAddr2),
    regCity: str(body.regCity),
    regState: str(body.regState),
    regPin: str(body.regPin),
    regCountry: str(body.regCountry, 'India') || 'India',

    shipSameAsRegistered: body.shipSameAsRegistered !== false,
    shipSameAsBilling: body.shipSameAsBilling === true,
    shipAddr1: str(body.shipAddr1),
    shipAddr2: str(body.shipAddr2),
    shipCity: str(body.shipCity),
    shipState: str(body.shipState),
    shipPin: str(body.shipPin),
    shipCountry: str(body.shipCountry, 'India') || 'India',

    billingMode: str(body.billingMode, 'shipping') || 'shipping',
    billAddr1: str(body.billAddr1),
    billAddr2: str(body.billAddr2),
    billCity: str(body.billCity),
    billState: str(body.billState),
    billPin: str(body.billPin),
    billCountry: str(body.billCountry, 'India') || 'India',

    paymentTerms: str(body.paymentTerms),
    priceList: str(body.priceList),
    openingBalance: amount(body.openingBalance, 'Opening balance'),
    creditLimit: amount(body.creditLimit, 'Credit limit'),
    creditDays: Math.trunc(num(body.creditDays)),

    contactPerson: str(body.contactPerson),
    contactDesignation: str(body.contactDesignation),
    contactPhone: normalisePhone(body.contactPhone),
    contactEmail: str(body.contactEmail),

    modifiedBy: actor,
    modifiedAt: new Date(),
  };
}

const GSTIN_RE = /^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$/;
const PAN_RE = /^[A-Z]{5}\d{4}[A-Z]$/;
const PIN_RE = /^\d{6}$/;
const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

/// Format rules for the tax and contact fields. A field is only checked when it
/// is non-empty and differs from what is already stored, so a legacy row
/// imported from the accounting export can still be edited without tripping
/// over a value that was never validated.
function checkFormats(data, existing) {
  const rules = [
    ['gstin', 'GSTIN', (v) => GSTIN_RE.test(v), 'must be 15 characters like 24ABCDE1234F1Z5'],
    ['pan', 'PAN', (v) => PAN_RE.test(v), 'must be 10 characters like ABCDE1234F'],
    ['regPin', 'PIN code', (v) => PIN_RE.test(v), 'must be 6 digits'],
    ['shipPin', 'Shipping PIN code', (v) => PIN_RE.test(v), 'must be 6 digits'],
    ['billPin', 'Billing PIN code', (v) => PIN_RE.test(v), 'must be 6 digits'],
    ['email', 'Email', (v) => EMAIL_RE.test(v), 'is not valid'],
    ['contactEmail', 'Contact email', (v) => EMAIL_RE.test(v), 'is not valid'],
  ];
  for (const [field, label, ok, why] of rules) {
    const value = data[field];
    if (!value || (existing && existing[field] === value)) continue;
    if (!ok(value)) throw new ValidationError(`${label} ${why}`);
  }
  if (data.creditLimit < 0) throw new ValidationError('Credit limit cannot be negative');
  if (data.creditDays < 0 || data.creditDays > 3650) {
    throw new ValidationError('Credit days must be between 0 and 3650');
  }
}

/// Another client already using this name or GSTIN, or null. Only what changed
/// is compared, for the same reason as [checkFormats].
async function findDuplicate(data, existing, selfId) {
  const notSelf = selfId ? { id: { not: selfId } } : {};
  if (data.name && (!existing || existing.name.toLowerCase() !== data.name.toLowerCase())) {
    const clash = await prisma.client.findFirst({
      where: { ...notSelf, name: { equals: data.name, mode: 'insensitive' } },
      select: { code: true },
    });
    if (clash) return `A client named "${data.name}" already exists (${clash.code})`;
  }
  if (data.gstin && (!existing || existing.gstin !== data.gstin)) {
    const clash = await prisma.client.findFirst({
      where: { ...notSelf, gstin: data.gstin },
      select: { code: true, name: true },
    });
    if (clash) return `GSTIN ${data.gstin} already belongs to ${clash.name} (${clash.code})`;
  }
  return null;
}

/// Next free CLT-#### code, used when the client didn't supply one.
async function nextClientCode() {
  const last = await prisma.client.findFirst({
    where: { code: { startsWith: 'CLT-' } },
    orderBy: { code: 'desc' },
    select: { code: true },
  });
  const n = last ? Number(last.code.slice(4)) : 0;
  return `CLT-${String((Number.isFinite(n) ? n : 0) + 1).padStart(4, '0')}`;
}

/// One or many values for a repeatable query parameter: ?state=A&state=B or
/// ?state=A,B both arrive here as ['A', 'B'].
function asList(raw) {
  if (raw === undefined || raw === null) return [];
  const parts = Array.isArray(raw) ? raw : String(raw).split(',');
  return parts.map((v) => String(v).trim()).filter(Boolean);
}

/// The WHERE the list, the count and the filter options all share, so the
/// "Showing 1-50 of 231" line can never disagree with the rows above it.
function clientWhere(query) {
  const where = {};

  const search = str(query.search);
  if (search) {
    // The same four columns the list page used to search in memory.
    where.OR = ['name', 'code', 'address', 'gstin'].map((field) => ({
      [field]: { contains: search, mode: 'insensitive' },
    }));
  }

  // The app calls these "state" and "city"; the columns behind them are the
  // registered-address pair. regCity was empty on every imported row until
  // prisma/backfillClientCity.js wrote the value the app had been parsing out
  // of the free-text address on each read.
  const states = asList(query.state);
  if (states.length) where.regState = { in: states };

  const cities = asList(query.city);
  if (cities.length) where.regCity = { in: cities };

  return where;
}

// GET /api/clients?search=&state=&city=&page=&limit=
//
// Search and the state/city filters moved to the server when this table passed
// a thousand rows: the page used to load every client just to filter them in
// memory, which cost about a megabyte of JSON on each start.
router.get('/', async (req, res, next) => {
  try {
    const where = clientWhere(req.query);
    // Last added / modified first (updatedAt covers both).
    res.json(await listResponse({
      query: req.query,
      findMany: (page) => prisma.client.findMany({
        where,
        orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
        ...page,
      }),
      count: () => prisma.client.count({ where }),
    }));
  } catch (err) {
    next(err);
  }
});

// GET /api/clients/options?state=
//
// Values for the State and City filter pills. They cannot be derived from a
// page of rows, and City cascades: pick a state and only its cities are
// offered, matching how the filter behaved when the whole list was in memory.
router.get('/options', async (req, res, next) => {
  try {
    const selectedStates = asList(req.query.state);
    const [stateRows, cityRows] = await Promise.all([
      prisma.client.findMany({
        where: { regState: { not: '' } },
        distinct: ['regState'],
        select: { regState: true },
        orderBy: { regState: 'asc' },
      }),
      prisma.client.findMany({
        where: {
          regCity: { not: '' },
          ...(selectedStates.length ? { regState: { in: selectedStates } } : {}),
        },
        distinct: ['regCity'],
        select: { regCity: true },
        orderBy: { regCity: 'asc' },
      }),
    ]);
    res.json({
      states: stateRows.map((r) => r.regState).filter(Boolean),
      cities: cityRows.map((r) => r.regCity).filter(Boolean),
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/clients/directory
//
// Just enough of every client to drive the "type to search" field on Add Sale,
// which needs names the current page does not contain. The state and GSTIN are
// what that dropdown prints under each name. Five columns instead of forty-six
// keeps this a small download even at several thousand rows.
router.get('/directory', async (req, res, next) => {
  try {
    const rows = await prisma.client.findMany({
      select: { id: true, code: true, name: true, regState: true, gstin: true },
      orderBy: { name: 'asc' },
    });
    res.json(rows);
  } catch (err) {
    next(err);
  }
});

// POST /api/clients
router.post('/', async (req, res, next) => {
  try {
    if (!str(req.body.name)) {
      return res.status(400).json({ error: 'name is required' });
    }
    const data = clientData(req.body, actorName(req));
    data.gstin = data.gstin.toUpperCase();
    data.pan = data.pan.toUpperCase();
    checkFormats(data, null);
    const clash = await findDuplicate(data, null, null);
    if (clash) return res.status(409).json({ error: clash });
    const code = str(req.body.code) || (await nextClientCode());
    const client = await prisma.client.create({ data: { ...data, code } });
    res.status(201).json(client);
  } catch (err) {
    if (err.code === 'P2002') {
      return res.status(409).json({ error: 'A client with that code already exists' });
    }
    next(err);
  }
});

// PUT /api/clients/:id
router.put('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    if (!str(req.body.name)) {
      return res.status(400).json({ error: 'name is required' });
    }
    const existing = await prisma.client.findUnique({ where: { id } });
    if (!existing) return res.status(404).json({ error: 'Client not found' });
    const data = clientData(req.body, actorName(req));
    data.gstin = data.gstin.toUpperCase();
    data.pan = data.pan.toUpperCase();
    checkFormats(data, existing);
    const clash = await findDuplicate(data, existing, id);
    if (clash) return res.status(409).json({ error: clash });
    const code = str(req.body.code);
    if (code) data.code = code;
    const client = await prisma.client.update({ where: { id }, data });
    res.json(client);
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Client not found' });
    if (err.code === 'P2002') {
      return res.status(409).json({ error: 'A client with that code already exists' });
    }
    next(err);
  }
});

// DELETE /api/clients/:id
router.delete('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    // Orders keep the client as a name, not a link, so deleting a client that
    // has orders would leave those orders pointing at nobody.
    const client = await prisma.client.findUnique({ where: { id }, select: { name: true } });
    if (!client) return res.status(404).json({ error: 'Client not found' });
    const orders = await prisma.salesOrder.count({
      where: { client: { equals: client.name, mode: 'insensitive' } },
    });
    if (orders > 0) {
      return res.status(409).json({
        error: `${client.name} has ${orders} sales order${orders === 1 ? '' : 's'}, so it cannot be deleted`,
      });
    }
    await prisma.client.delete({ where: { id } });
    res.status(204).send();
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Client not found' });
    next(err);
  }
});

module.exports = router;

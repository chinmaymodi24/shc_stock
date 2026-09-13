const express = require('express');
const prisma = require('../prismaClient');
const { actorName } = require('../auth/middleware');
const { listResponse } = require('../pagination');

const router = express.Router();

const str = (v, fallback = '') => (v === undefined || v === null ? fallback : String(v).trim());
const num = (v, fallback = 0) => {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
};

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
    name: str(body.name),
    clientType: str(body.clientType),
    registrationType: str(body.registrationType, 'Regular') || 'Regular',
    email: str(body.email),
    phone: str(body.phone),
    altPhone: str(body.altPhone),
    gstin: str(body.gstin),
    pan: str(body.pan),
    clientSince: body.clientSince ? new Date(body.clientSince) : null,

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
    openingBalance: num(body.openingBalance),
    creditLimit: num(body.creditLimit),
    creditDays: Math.trunc(num(body.creditDays)),

    contactPerson: str(body.contactPerson),
    contactDesignation: str(body.contactDesignation),
    contactPhone: str(body.contactPhone),
    contactEmail: str(body.contactEmail),

    modifiedBy: actor,
    modifiedAt: new Date(),
  };
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
    const code = str(req.body.code) || (await nextClientCode());
    const client = await prisma.client.create({
      data: { ...clientData(req.body, actorName(req)), code },
    });
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
    const data = clientData(req.body, actorName(req));
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
    await prisma.client.delete({ where: { id } });
    res.status(204).send();
  } catch (err) {
    if (err.code === 'P2025') return res.status(404).json({ error: 'Client not found' });
    next(err);
  }
});

module.exports = router;

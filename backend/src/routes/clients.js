const express = require('express');
const prisma = require('../prismaClient');

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

function clientData(body) {
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

    modifiedBy: str(body.modifiedBy, 'Admin') || 'Admin',
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

// GET /api/clients
router.get('/', async (req, res, next) => {
  try {
    const clients = await prisma.client.findMany({ orderBy: { name: 'asc' } });
    res.json(clients);
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
      data: { ...clientData(req.body), code },
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
    const data = clientData(req.body);
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

// ─────────────────────────────────────────────────────────────────────────────
// Request validation shared by every route.
//
// Before this, each route cast with `Number(x) || 0` and `new Date(x)` and let
// the database complain: a price of "abc" or a date of "notadate" came back as
// a 500 carrying the Prisma query and a file path, while an order with a
// negative amount, no items, a status of "Banana" and ₹5,00,000 paid saved
// without a murmur.
//
// Every helper either returns a clean value or throws a ValidationError, which
// the error handler in server.js turns into a 400 with the message below.
// ─────────────────────────────────────────────────────────────────────────────

class ValidationError extends Error {
  constructor(message) {
    super(message);
    this.name = 'ValidationError';
    this.status = 400;
  }
}

const fail = (message) => {
  throw new ValidationError(message);
};

const isBlank = (v) => v === undefined || v === null || String(v).trim() === '';

/// Largest money value the NUMERIC(14,2) columns can hold.
const MAX_MONEY = 999999999999.99;
/// A quantity above this is a typo, not stock.
const MAX_QTY = 10000000;

/// A trimmed string. Objects and arrays are refused rather than stringified to
/// "[object Object]".
function text(v, field, { required = false, max = 500, fallback = '' } = {}) {
  if (isBlank(v)) {
    if (required) fail(`${field} is required`);
    return fallback;
  }
  if (typeof v !== 'string' && typeof v !== 'number') fail(`${field} must be text`);
  const s = String(v).trim();
  if (s.length > max) fail(`${field} must be at most ${max} characters`);
  return s;
}

/// A finite number inside [min, max]. Empty -> [fallback] unless required.
function number(v, field, { required = false, min = -Infinity, max = Infinity, fallback = 0 } = {}) {
  if (isBlank(v)) {
    if (required) fail(`${field} is required`);
    return fallback;
  }
  if (typeof v === 'boolean' || Array.isArray(v) || (typeof v === 'object' && v !== null)) {
    fail(`${field} must be a number`);
  }
  const n = Number(v);
  if (!Number.isFinite(n)) fail(`${field} must be a number`);
  if (n < min) fail(`${field} must be at least ${min}`);
  if (n > max) fail(`${field} is too large`);
  return n;
}

/// Money: 0 or more, at most 2 decimals' worth of precision kept.
function money(v, field, opts = {}) {
  const n = number(v, field, { min: 0, max: MAX_MONEY, ...opts });
  return Math.round(n * 100) / 100;
}

/// A whole number (stock levels, days, thresholds).
function whole(v, field, opts = {}) {
  const n = number(v, field, { min: 0, max: 2147483647, ...opts });
  if (!Number.isInteger(n)) fail(`${field} must be a whole number`);
  return n;
}

/// A positive integer id.
function id(v, field = 'id') {
  const n = Number(v);
  if (!Number.isInteger(n) || n <= 0) fail(`${field} must be a positive whole number`);
  return n;
}

/// An optional id: empty -> null.
function optionalId(v, field) {
  return isBlank(v) ? null : id(v, field);
}

/// A real date. `required` false lets an empty value through as null.
function date(v, field, { required = false } = {}) {
  if (isBlank(v)) {
    if (required) fail(`${field} is required`);
    return null;
  }
  const d = new Date(v);
  if (Number.isNaN(d.getTime())) fail(`${field} is not a valid date`);
  const year = d.getUTCFullYear();
  if (year < 2000 || year > 2100) fail(`${field} must be between the years 2000 and 2100`);
  return d;
}

function oneOf(v, field, allowed, { required = false, fallback = undefined } = {}) {
  if (isBlank(v)) {
    if (required) fail(`${field} is required`);
    return fallback;
  }
  const s = String(v).trim();
  const hit = allowed.find((a) => a.toLowerCase() === s.toLowerCase());
  if (hit === undefined) fail(`${field} must be one of: ${allowed.map((a) => a || '(none)').join(', ')}`);
  return hit;
}

/// Quantity on an order line, to 3 decimals. Whether a fraction is allowed
/// depends on the product's unit (kg yes, pieces no) and is checked against
/// the product itself — see stockService.assertUnitQuantities.
function lineQty(v, field) {
  const n = number(v, field, { required: true, min: 0, max: MAX_QTY });
  if (n <= 0) fail(`${field} must be greater than 0`);
  return Math.round(n * 1000) / 1000;
}

/// A stock level (opening stock, reorder point): 0 or more, to 3 decimals.
function stockQty(v, field, opts = {}) {
  const n = number(v, field, { min: 0, max: MAX_QTY, ...opts });
  return Math.round(n * 1000) / 1000;
}

/// Express param guard: `router.param('id', idParam)`.
function idParam(req, res, next, value) {
  const n = Number(value);
  if (!Number.isInteger(n) || n <= 0) {
    return res.status(400).json({ error: 'id must be a positive whole number' });
  }
  next();
}

module.exports = {
  ValidationError,
  fail,
  isBlank,
  text,
  number,
  money,
  whole,
  id,
  optionalId,
  date,
  oneOf,
  lineQty,
  stockQty,
  idParam,
  MAX_MONEY,
  MAX_QTY,
};

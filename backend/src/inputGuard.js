// ─────────────────────────────────────────────────────────────────────────────
// A last line of defence for every request, whatever route it reaches.
//
// - A NUL character ("\u0000") is not storable in PostgreSQL text, so a name or
//   a search box holding one used to surface as a 500. They are stripped here.
// - One text field of tens of thousands of characters (or a deeply nested
//   body) is never a real entry; it is refused with a clear 400 instead of
//   being stored and breaking every list that shows it.
//
// The routes still apply their own, tighter, per-field limits (validate.js);
// this only guarantees nothing absurd or unstorable gets past them.
// ─────────────────────────────────────────────────────────────────────────────

const MAX_TEXT = 10000;
const MAX_DEPTH = 8;
/// Fields that legitimately carry a base64 image (see routes/settings.js, which
/// applies its own 2 MB limit).
const LARGE_FIELDS = new Set(['logoBase64', 'signatureBase64']);

class InputError extends Error {
  constructor(message) {
    super(message);
    this.name = 'InputError';
    this.status = 400;
  }
}

/// Returns [value] cleaned: NULs removed from every string. Throws InputError
/// for an over-long string or an over-deep structure.
function clean(value, key = '', depth = 0) {
  if (typeof value === 'string') {
    if (value.length > MAX_TEXT && !LARGE_FIELDS.has(key)) {
      throw new InputError(`A text value is too long (at most ${MAX_TEXT} characters)`);
    }
    return value.includes('\u0000') ? value.replace(/\u0000/g, '') : value;
  }
  if (value === null || typeof value !== 'object') return value;
  if (depth >= MAX_DEPTH) throw new InputError('The request is nested too deeply');
  if (Array.isArray(value)) return value.map((v) => clean(v, key, depth + 1));
  const out = {};
  for (const [k, v] of Object.entries(value)) out[k] = clean(v, k, depth + 1);
  return out;
}

function inputGuard(req, res, next) {
  try {
    if (req.body && typeof req.body === 'object') req.body = clean(req.body);
    if (req.query && typeof req.query === 'object') req.query = clean(req.query);
    next();
  } catch (err) {
    next(err);
  }
}

module.exports = { inputGuard, clean, InputError, MAX_TEXT };

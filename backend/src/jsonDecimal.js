// ─────────────────────────────────────────────────────────────────────────────
// Keeps Decimal columns looking like numbers on the wire.
//
// Money is stored as Postgres NUMERIC so the arithmetic is exact - see the
// Decimal columns in schema.prisma. Prisma hands those back as Decimal
// objects, and Decimal.toJSON() renders a *string*: {"amount":"2800.55"}.
// Every client here reads those fields as numbers, so without this the switch
// away from Float would have broken each of them.
//
// A replacer passed to JSON.stringify cannot do the job: toJSON() runs first,
// so the replacer only ever sees the finished string and cannot tell it from a
// genuine one. The conversion therefore happens on the payload itself, before
// it is serialized.
// ─────────────────────────────────────────────────────────────────────────────

const { decimalsToNumbers } = require('./decimalToNumber');

/// Wraps res.json once per request, so anything that reached a route already
/// holding a Decimal - a raw query, a value built outside Prisma - still
/// serializes as a number rather than the string Decimal.toJSON() produces.
function decimalJson(req, res, next) {
  const original = res.json.bind(res);
  res.json = (body) => original(decimalsToNumbers(body));
  next();
}

module.exports = { decimalsToNumbers, decimalJson };

// ─────────────────────────────────────────────────────────────────────────────
// Phone numbers are stored as a plain 10-digit number: 9714888466.
//
// No country code, no separators. The seed data used to write
// "+91 98765 00001", and every form that later loaded such a row rejected it
// against its own 10-digit rule — an employee seeded months ago could not be
// edited until the phone box was retyped by hand.
//
// Normalising on the way in means the rule holds for rows written by the app,
// by a script, or by an import, rather than only for what the UI happens to
// allow today. Mirrored by lib/app/core/utils/phone_input.dart.
// ─────────────────────────────────────────────────────────────────────────────

const DIGITS = 10;

/// [raw] reduced to the bare 10-digit number: non-digits dropped, then a
/// any country code (91) or trunk prefix (0) while there are digits to spare -
/// so a real 10-digit number starting with 91 is left alone. Anything still
/// too long keeps its first ten. Too short is returned as-is: the field's own
/// validation reports that rather than this inventing digits. Empty in, empty
/// out. Mirrored by lib/app/core/utils/phone_input.dart.
function normalisePhone(raw) {
  if (raw === undefined || raw === null) return '';
  let digits = String(raw).replace(/\D/g, '');
  while (digits.length > DIGITS) {
    if (digits.startsWith('91')) digits = digits.slice(2);
    else if (digits.startsWith('0')) digits = digits.slice(1);
    else break;
  }
  return digits.length > DIGITS ? digits.slice(0, DIGITS) : digits;
}

module.exports = { normalisePhone, PHONE_DIGITS: DIGITS };

import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Phone numbers are a plain 10-digit number everywhere in this app: 9714888466.
//
// No country code, no separators. The seed data used to carry "+91 98765 00001"
// and rows written from it came back into the edit forms in that shape, where
// the 10-digit rule rejected them — an employee saved months ago could not be
// edited at all until the phone box was retyped by hand.
//
// [normalisePhone] is the one rule, and [kPhoneInputFormatters] applies it to
// every keystroke AND every paste. A plain digits-only + max-length pair was
// not enough: pasting "+91 97148 88466" kept the first ten of "919714888466"
// and silently left 9197148884 in the box.
//
// Mirrored by backend/src/phone.js — a row written by one is read by the other,
// so the two must agree. test/phone_input_test.dart and
// backend/src/phone.test.js check the same cases on both sides.
// ─────────────────────────────────────────────────────────────────────────────

const int kPhoneDigits = 10;

const String kPhoneHint = 'Enter 10-digit phone number';

/// [raw] reduced to the bare 10-digit number.
///
/// Non-digits go first, then any country code (91) or trunk prefix (0) while
/// there are digits to spare — so "+91 97148 88466", "09714888466" and
/// "9714888466" all come out the same, while a real 10-digit number that
/// happens to start with 91 is left alone. Anything still too long keeps its
/// first ten digits, which is what makes typing an eleventh a no-op rather
/// than a number that shifts under the cursor. Too short is returned as-is —
/// the field's own validation reports that rather than inventing digits.
String normalisePhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  while (digits.length > kPhoneDigits) {
    if (digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    } else {
      break;
    }
  }
  return digits.length > kPhoneDigits
      ? digits.substring(0, kPhoneDigits)
      : digits;
}

/// Holds a phone box to [normalisePhone] on every edit, typed or pasted.
class PhoneInputFormatter extends TextInputFormatter {
  const PhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = normalisePhone(newValue.text);
    if (cleaned == newValue.text) return newValue;
    // Measure the caret from the end of the text: a paste that dropped a "+91"
    // shortens everything before it, and counting from the start would park
    // the cursor several characters adrift.
    final fromEnd = newValue.text.length - newValue.selection.end;
    final offset = (cleaned.length - fromEnd).clamp(0, cleaned.length);
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

const List<TextInputFormatter> kPhoneInputFormatters = <TextInputFormatter>[
  PhoneInputFormatter(),
];

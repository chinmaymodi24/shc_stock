import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shc_stock/app/core/utils/phone_input.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Phone numbers are a plain 10-digit number everywhere: 9714888466.
//
// The Dart side mirrors backend/src/phone.js — these two must agree, because a
// row written by one is read by the other. The formatter stops anything else
// being typed; normalisePhone cleans what arrives from elsewhere.
// ─────────────────────────────────────────────────────────────────────────────

/// Types [input] one character at a time through the real formatters, the way
/// a TextField feeds them.
String typeIn(String input) {
  var value = TextEditingValue.empty;
  for (final ch in input.split('')) {
    var out = TextEditingValue(
      text: value.text + ch,
      selection: TextSelection.collapsed(offset: value.text.length + 1),
    );
    for (final f in kPhoneInputFormatters) {
      out = f.formatEditUpdate(value, out);
    }
    value = out;
  }
  return value.text;
}

/// Drops [input] into an empty box in one go, the way a paste does.
String pasteIn(String input) {
  var out = TextEditingValue(
    text: input,
    selection: TextSelection.collapsed(offset: input.length),
  );
  for (final f in kPhoneInputFormatters) {
    out = f.formatEditUpdate(TextEditingValue.empty, out);
  }
  return out.text;
}

void main() {
  group('typing', () {
    test('letters, spaces and a plus are never accepted', () {
      expect(typeIn('abc9714def888466'), '9714888466');
      expect(typeIn('9714 888 466'), '9714888466');
    });

    test('the eleventh digit is ignored, it does not shift the number', () {
      expect(typeIn('971488846699'), '9714888466');
      expect(typeIn('9714888466').length, kPhoneDigits);
    });
  });

  group('pasting', () {
    // A digits-only + max-length pair kept the first ten of "919714888466"
    // and silently left the wrong number in the box.
    test('a pasted +91 number lands as the right ten digits', () {
      expect(pasteIn('+91 97148 88466'), '9714888466');
      expect(pasteIn('+91-97148-88466'), '9714888466');
      expect(pasteIn('+919714888466'), '9714888466');
      expect(pasteIn('09714888466'), '9714888466');
    });

    test('a pasted plain number is untouched', () {
      expect(pasteIn('9714888466'), '9714888466');
    });
  });

  group('normalisePhone cleans what arrives from elsewhere', () {
    test('a plain number is left alone', () {
      expect(normalisePhone('9714888466'), '9714888466');
    });

    test('the old seed shape comes out clean', () {
      // What backend/prisma/seedUsers.js used to write.
      expect(normalisePhone('+91 98765 00001'), '9876500001');
    });

    test('separators and prefixes are stripped', () {
      expect(normalisePhone('+91-97148-88466'), '9714888466');
      expect(normalisePhone('09714888466'), '9714888466');
      expect(normalisePhone('00919714888466'), '9714888466');
      expect(normalisePhone('(+91) 97148 88466'), '9714888466');
    });

    test('empty stays empty', () {
      expect(normalisePhone(''), '');
      expect(normalisePhone('   '), '');
    });

    test('a short number is not padded or invented', () {
      expect(normalisePhone('98765'), '98765');
      expect(normalisePhone('abc'), '');
    });

    test('a 10-digit number starting with 91 survives', () {
      expect(normalisePhone('9198765432'), '9198765432');
    });
  });
}

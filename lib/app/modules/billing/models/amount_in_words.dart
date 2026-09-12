// ─────────────────────────────────────────────────────────────────────────────
// Amount in words, Indian numbering — Crore / Lakh / Thousand / Hundred.
//
// A tax invoice is a legal document and this line is the one a human reads to
// check the figures, so it is written as a pure function and tested rather
// than assembled inline in a widget.
// ─────────────────────────────────────────────────────────────────────────────

const _ones = [
  '',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
  'Eleven',
  'Twelve',
  'Thirteen',
  'Fourteen',
  'Fifteen',
  'Sixteen',
  'Seventeen',
  'Eighteen',
  'Nineteen',
];

const _tens = [
  '',
  '',
  'Twenty',
  'Thirty',
  'Forty',
  'Fifty',
  'Sixty',
  'Seventy',
  'Eighty',
  'Ninety',
];

/// 0–99 in words. Returns '' for 0 so callers can skip empty groups.
String _twoDigits(int n) {
  if (n < 20) return _ones[n];
  final tens = _tens[n ~/ 10];
  final ones = _ones[n % 10];
  return ones.isEmpty ? tens : '$tens $ones';
}

/// 0–999 in words, e.g. 342 -> "Three Hundred Forty Two".
String _threeDigits(int n) {
  final hundreds = n ~/ 100;
  final rest = n % 100;
  final parts = <String>[
    if (hundreds > 0) '${_ones[hundreds]} Hundred',
    if (rest > 0) _twoDigits(rest),
  ];
  return parts.join(' ');
}

/// A whole number in Indian words — no currency, no "Only".
/// 12345678 -> "One Crore Twenty Three Lakh Forty Five Thousand Six Hundred
/// Seventy Eight".
String numberToIndianWords(int value) {
  if (value == 0) return 'Zero';
  if (value < 0) return 'Minus ${numberToIndianWords(-value)}';

  // Crore is the largest group Indian numbering names, so anything above it
  // stays in the crore bucket ("One Hundred Twenty Crore").
  final crore = value ~/ 10000000;
  final lakh = (value ~/ 100000) % 100;
  final thousand = (value ~/ 1000) % 100;
  final hundred = value % 1000;

  final parts = <String>[
    if (crore > 0) '${numberToIndianWords(crore)} Crore',
    if (lakh > 0) '${_twoDigits(lakh)} Lakh',
    if (thousand > 0) '${_twoDigits(thousand)} Thousand',
    if (hundred > 0) _threeDigits(hundred),
  ];
  return parts.join(' ');
}

/// The invoice's "Amount Chargeable (in words)" line.
/// 48342 -> "INR Forty Eight Thousand Three Hundred Forty Two Only".
///
/// Paise are included only when there are any — a whole-rupee total reads
/// cleaner without "and Zero Paise" — and print as digits ("and 24 Paise"),
/// which is what the approved invoice design shows. Only the tax-amount line
/// ever carries them; the chargeable total is rounded to the rupee.
String amountInWords(double amount, {String currency = 'INR'}) {
  final negative = amount < 0;
  // Work in paise so 0.145 can't land between two representable rupees.
  final paiseTotal = (amount.abs() * 100).round();
  final rupees = paiseTotal ~/ 100;
  final paise = paiseTotal % 100;

  final buffer = StringBuffer(currency.isEmpty ? '' : '$currency ');
  if (negative) buffer.write('Minus ');
  buffer.write(numberToIndianWords(rupees));
  if (paise > 0) {
    buffer.write(' and ${paise.toString().padLeft(2, '0')} Paise');
  }
  buffer.write(' Only');
  return buffer.toString();
}

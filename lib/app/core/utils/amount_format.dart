/// Indian-grouped rupee amount, e.g. 2485600 -> "₹24,85,600".
///
/// Last three digits, then groups of two (lakh, crore …).
///
/// Shared by the Purchase, Sales and Inventory summary cards — all three used
/// to carry their own copy of a hand-rolled version that dropped the middle
/// separator whenever the thousands digits were zero (3000000 came out as
/// "₹30,00000").
String formatRupees(double v) {
  final negative = v < 0;
  final digits = v.abs().round().toString();

  final String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last3';
  }

  return '${negative ? '-' : ''}₹$grouped';
}

/// Short rupee amount for tight spots — "₹24.86L", "₹19.4K", "₹1.20Cr".
///
/// Uses Indian scale words (thousand / lakh / crore) so it matches the
/// grouping [formatRupees] applies everywhere else. Anything under ₹1,000
/// falls through to the full form, where the short one would say nothing.
String formatRupeesCompact(double v) {
  final abs = v.abs();
  final sign = v < 0 ? '-' : '';
  if (abs >= 10000000) return '$sign₹${(abs / 10000000).toStringAsFixed(2)}Cr';
  if (abs >= 100000) return '$sign₹${(abs / 100000).toStringAsFixed(2)}L';
  if (abs >= 1000) return '$sign₹${(abs / 1000).toStringAsFixed(1)}K';
  return formatRupees(v);
}

/// A plain, un-grouped amount for text fields the user edits — "1250",
/// "1250.5". Whole numbers lose the trailing ".0" so a prefilled box doesn't
/// read like a decimal figure the user has to clean up.
String trimAmount(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// Indian-grouped number with exactly two decimals and no symbol —
/// "1,42,00,000.00". What every cell of a tax invoice prints.
///
/// The invoice is a legal document: a figure there is never rounded for
/// display, so this keeps both paise even when they are zero.
String formatIndian2(double v) {
  final negative = v < 0;
  final fixed = v.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final grouped = groupIndian(parts[0]);
  return '${negative ? '-' : ''}$grouped.${parts[1]}';
}

/// Indian digit grouping on an already-formatted integer string: last three,
/// then pairs. "14200000" -> "1,42,00,000".
String groupIndian(String digits) {
  if (digits.length <= 3) return digits;
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}

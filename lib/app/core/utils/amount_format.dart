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

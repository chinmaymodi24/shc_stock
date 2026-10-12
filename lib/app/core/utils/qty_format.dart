/// A stock quantity as text: "14", "12.5", "13.875" — no trailing zeros.
/// Stock is kept to 3 decimals (see units.dart), so three are shown at most.
String fmtStockQty(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');
}

// ─────────────────────────────────────────────────────────────────────────────
// How much an order holds, as one short label for list rows.
//
// Adding every line's quantity together only means something when the lines
// share a unit: 100 pcs + 200 kg used to read "300". So:
//   * one unit across the order  -> "300 pcs"
//   * several units              -> "2 items" (the line count)
//   * no lines (older records)   -> the stored line count
// ─────────────────────────────────────────────────────────────────────────────

/// The short form of a unit: "Kilogram (kg)" -> "kg", "PCS" -> "PCS".
String shortUnit(String unit) {
  final u = unit.trim();
  final m = RegExp(r'\(([^)]+)\)\s*$').firstMatch(u);
  return m != null ? m.group(1)!.trim() : u;
}

String _qtyText(double q) =>
    q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toStringAsFixed(2);

/// Label for an order whose lines are [lines] (qty, unit), or [fallbackCount]
/// lines when the lines were not loaded.
String orderQtyLabel(
  List<(double, String)> lines, {
  required int fallbackCount,
}) {
  if (lines.isEmpty) {
    return fallbackCount == 1 ? '1 item' : '$fallbackCount items';
  }
  final units = lines.map((l) => shortUnit(l.$2).toLowerCase()).toSet();
  if (units.length == 1) {
    final total = lines.fold(0.0, (s, l) => s + l.$1);
    final unit = shortUnit(lines.first.$2);
    return unit.isEmpty ? _qtyText(total) : '${_qtyText(total)} $unit';
  }
  return '${lines.length} items';
}

/// "100 pcs + 200 kg" — the full breakdown, for a tooltip.
String orderQtyBreakdown(List<(double, String)> lines) =>
    lines.map((l) => '${_qtyText(l.$1)} ${shortUnit(l.$2)}'.trim()).join(' + ');

import 'dart:convert';
import 'dart:typed_data';

import 'package:shc_stock/app/core/export/export_table.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CSV writer — RFC 4180 quoting, CRLF line endings, UTF-8 BOM.
//
// The BOM is what makes Excel open a ₹ amount as "₹1,200" instead of
// "â‚¹1,200"; without it Excel guesses the system codepage.
// ─────────────────────────────────────────────────────────────────────────────
Uint8List buildCsv(ExportTable table) {
  final buffer = StringBuffer();
  buffer.write(_row(table.headers));
  for (final row in table.rows) {
    buffer.write(_row(row.map(_cellText).toList()));
  }
  return Uint8List.fromList([
    0xEF, 0xBB, 0xBF, // UTF-8 BOM
    ...utf8.encode(buffer.toString()),
  ]);
}

/// Numbers go out unformatted so a spreadsheet reads them as numbers — the
/// grouped "₹1,42,000" form would import as text and break every SUM.
String _cellText(ExportCell cell) {
  if (cell.isNumeric) return cell.number?.toString() ?? '';
  return cell.text;
}

String _row(List<String> values) => '${values.map(_escape).join(',')}\r\n';

String _escape(String value) {
  final needsQuotes =
      value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r');
  if (!needsQuotes) return value;
  return '"${value.replaceAll('"', '""')}"';
}

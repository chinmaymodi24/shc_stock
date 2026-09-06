import 'package:shc_stock/app/core/utils/amount_format.dart';

/// How a column's values are typed — decides alignment, and whether a
/// spreadsheet gets a real number it can sum or a string it cannot.
enum ExportCellType { text, number, money, date }

/// One resolved cell: the raw value plus the string a human reads.
class ExportCell {
  final ExportCellType type;

  /// `num` for [ExportCellType.number]/[ExportCellType.money], else null.
  /// Excel writes this as a numeric cell so totals still work in the sheet.
  final num? number;
  final String text;

  const ExportCell._(this.type, this.number, this.text);

  factory ExportCell.text(String value) =>
      ExportCell._(ExportCellType.text, null, value);

  factory ExportCell.number(num? value) => ExportCell._(
    ExportCellType.number,
    value,
    value == null ? '' : _trimNumber(value),
  );

  factory ExportCell.money(num? value) => ExportCell._(
    ExportCellType.money,
    value,
    value == null ? '' : formatRupees(value.toDouble()),
  );

  factory ExportCell.date(DateTime? value) => ExportCell._(
    ExportCellType.date,
    null,
    value == null ? '' : _formatDate(value),
  );

  bool get isNumeric =>
      type == ExportCellType.number || type == ExportCellType.money;

  static String _trimNumber(num value) {
    if (value is int || value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';
}

/// A fully resolved export payload — headers plus rows, in the exact order
/// the list showed them. Every writer consumes this and nothing else, so CSV,
/// Excel and PDF can never disagree about what was exported.
class ExportTable {
  final String title;
  final List<String> headers;
  final List<ExportCellType> types;
  final List<List<ExportCell>> rows;

  /// Column width hints, one per column, relative to each other. Used to lay
  /// out the PDF table and to size spreadsheet columns.
  final List<double> widths;

  /// Human-readable summary of what was exported — "248 of 611 products,
  /// filtered". Printed on the PDF and worth keeping with the file.
  final String scopeLine;

  const ExportTable({
    required this.title,
    required this.headers,
    required this.types,
    required this.rows,
    required this.widths,
    this.scopeLine = '',
  });

  int get rowCount => rows.length;
  int get columnCount => headers.length;
}

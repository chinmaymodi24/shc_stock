import 'dart:typed_data';

import 'package:shc_stock/app/core/export/export_table.dart';

/// Which rows an export covers. The list page decides what "filtered" means;
/// nothing here re-queries or re-filters.
enum ExportScope { filtered, all, selected }

extension ExportScopeX on ExportScope {
  /// The word that goes in the filename.
  String get slug => switch (this) {
    ExportScope.filtered => 'filtered',
    ExportScope.all => 'all',
    ExportScope.selected => 'selected',
  };
}

/// One exportable column of an entity.
class ExportColumn<T> {
  final String key;
  final String label;
  final ExportCellType type;

  /// Relative width hint, used to lay out the PDF table and size the
  /// spreadsheet columns. 1.0 is an ordinary short field.
  final double width;

  /// Pulls the value out of a row. Returns `num` for numeric/money columns,
  /// `DateTime` for dates, anything else is read as text.
  final Object? Function(T row) value;

  const ExportColumn({
    required this.key,
    required this.label,
    required this.value,
    this.type = ExportCellType.text,
    this.width = 1,
  });

  ExportCell cell(T row) {
    final raw = value(row);
    return switch (type) {
      ExportCellType.money => ExportCell.money(raw as num?),
      ExportCellType.number => ExportCell.number(raw as num?),
      ExportCellType.date => ExportCell.date(raw as DateTime?),
      ExportCellType.text => ExportCell.text(raw?.toString() ?? ''),
    };
  }
}

/// A named column set the user can pick from the COLUMN PRESET dropdown.
class ExportColumnPreset {
  final String name;
  final List<String> columnKeys;
  const ExportColumnPreset(this.name, this.columnKeys);
}

/// Column identity without the row type — what the dialog's chip picker needs.
class ExportColumnMeta {
  final String key;
  final String label;
  const ExportColumnMeta(this.key, this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
// The type-erased face of an entity's export config.
//
// Widgets and the job service talk to this; only the list page that owns the
// data supplies the generic [ExportEntityConfig] behind it. That is what lets
// one ExportMenu and one ExportDialog serve all seven list pages.
// ─────────────────────────────────────────────────────────────────────────────
abstract class ExportSource {
  /// Lowercase, hyphen-free key used in filenames — "products", "purchase".
  String get entityKey;

  /// Title case, as it appears in the dialog header — "Products".
  String get entityLabel;

  /// Plural noun for counts — "248 of 611 products".
  String get rowNoun;

  List<ExportColumnMeta> get columns;
  List<String> get defaultColumnKeys;
  List<ExportColumnPreset> get presets;

  /// Row counts per scope. These come from the same lists the table renders,
  /// so the button, the menu label, the radio cards and the footer can never
  /// disagree.
  int countOf(ExportScope scope);

  /// True when the list currently has a selection, which makes
  /// [ExportScope.selected] available and the default.
  bool get hasSelection;

  /// True when filters/search are narrowing the list — decides whether the
  /// menu says "DOWNLOAD 248 FILTERED" or just "DOWNLOAD 611".
  bool get isFiltered;

  /// Period fragment for the filename, e.g. "fy2025-26".
  String get periodSlug;

  /// Materialises the rows for [scope] into the given columns, in the order
  /// they are on screen.
  ExportTable buildTable(ExportScope scope, List<String> columnKeys);

  /// Same table, built in chunks so a 20,000-row export reports honest
  /// progress and never blocks a frame.
  Future<ExportTable> buildTableAsync(
    ExportScope scope,
    List<String> columnKeys, {
    void Function(int done, int total)? onProgress,
  });

  /// A source that has its own printed form — a financial statement, say —
  /// returns its PDF bytes here. Null means "use the generic table layout",
  /// which is what every list page wants.
  Uint8List? renderCustomPdf(String generatedLine) => null;
}

class ExportEntityConfig<T> implements ExportSource {
  @override
  final String entityKey;
  @override
  final String entityLabel;
  @override
  final String rowNoun;

  final List<ExportColumn<T>> allColumns;
  @override
  final List<String> defaultColumnKeys;
  @override
  final List<ExportColumnPreset> presets;

  /// The list exactly as the page shows it — filters, search and sort applied.
  final List<T> Function() filteredRows;

  /// Everything loaded for the entity, unfiltered.
  final List<T> Function() allRows;

  /// The checkbox selection, when the page has one.
  final List<T> Function()? selectedRows;

  final String Function()? periodSlugBuilder;

  const ExportEntityConfig({
    required this.entityKey,
    required this.entityLabel,
    required this.rowNoun,
    required this.allColumns,
    required this.defaultColumnKeys,
    required this.filteredRows,
    required this.allRows,
    this.presets = const [],
    this.selectedRows,
    this.periodSlugBuilder,
  });

  @override
  List<ExportColumnMeta> get columns =>
      allColumns.map((c) => ExportColumnMeta(c.key, c.label)).toList();

  List<T> rowsFor(ExportScope scope) => switch (scope) {
    ExportScope.filtered => filteredRows(),
    ExportScope.all => allRows(),
    ExportScope.selected => selectedRows?.call() ?? const [],
  };

  @override
  int countOf(ExportScope scope) => rowsFor(scope).length;

  @override
  bool get hasSelection => (selectedRows?.call().length ?? 0) > 0;

  @override
  bool get isFiltered => filteredRows().length != allRows().length;

  @override
  String get periodSlug => periodSlugBuilder?.call() ?? currentFinancialYear();

  /// A list page has no bespoke paper form — the generic table layout is
  /// exactly right for it.
  @override
  Uint8List? renderCustomPdf(String generatedLine) => null;

  @override
  ExportTable buildTable(ExportScope scope, List<String> columnKeys) {
    // Preserve the entity's own column order rather than the order the user
    // happened to tick the chips in — a spreadsheet should look like the table.
    final chosen = allColumns.where((c) => columnKeys.contains(c.key)).toList();
    final rows = rowsFor(scope);
    return ExportTable(
      title: entityLabel,
      headers: chosen.map((c) => c.label).toList(),
      types: chosen.map((c) => c.type).toList(),
      widths: chosen.map((c) => c.width).toList(),
      rows: [
        for (final row in rows) [for (final column in chosen) column.cell(row)],
      ],
      scopeLine: scopeLineFor(scope, rows.length),
    );
  }

  /// Rows per yield. Small enough that the UI keeps painting, large enough
  /// that the yields do not dominate the work.
  static const int chunkSize = 250;

  @override
  Future<ExportTable> buildTableAsync(
    ExportScope scope,
    List<String> columnKeys, {
    void Function(int done, int total)? onProgress,
  }) async {
    final chosen = allColumns.where((c) => columnKeys.contains(c.key)).toList();
    final rows = rowsFor(scope);
    final cells = <List<ExportCell>>[];

    for (var i = 0; i < rows.length; i++) {
      cells.add([for (final column in chosen) column.cell(rows[i])]);
      if ((i + 1) % chunkSize == 0) {
        onProgress?.call(i + 1, rows.length);
        // Hand the frame back so the progress bar actually moves.
        await Future<void>.delayed(Duration.zero);
      }
    }
    onProgress?.call(rows.length, rows.length);

    return ExportTable(
      title: entityLabel,
      headers: chosen.map((c) => c.label).toList(),
      types: chosen.map((c) => c.type).toList(),
      widths: chosen.map((c) => c.width).toList(),
      rows: cells,
      scopeLine: scopeLineFor(scope, rows.length),
    );
  }

  String scopeLineFor(ExportScope scope, int rowCount) {
    final total = allRows().length;
    return switch (scope) {
      ExportScope.all => '$total $rowNoun',
      ExportScope.filtered => '$rowCount of $total $rowNoun · current filters',
      ExportScope.selected => '$rowCount selected of $total $rowNoun',
    };
  }
}

/// Indian financial year the given date falls in — "fy2025-26" for anything
/// from 1 April 2025 to 31 March 2026.
String currentFinancialYear([DateTime? now]) {
  final date = now ?? DateTime.now();
  final startYear = date.month >= 4 ? date.year : date.year - 1;
  final endYear = (startYear + 1) % 100;
  return 'fy$startYear-${endYear.toString().padLeft(2, '0')}';
}

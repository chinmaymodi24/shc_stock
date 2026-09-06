import 'dart:typed_data';

import 'package:shc_stock/app/core/export/export_source.dart';
import 'package:shc_stock/app/core/export/export_table.dart';
import 'package:shc_stock/app/core/export/statement.dart';
import 'package:shc_stock/app/core/export/writers/pdf_statement_writer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// A statement, as an export source.
//
// Reports go through the same job pipeline and land in the same Downloads
// panel as every list export — the only difference is the paper: PDF renders
// the sheet layout via [renderCustomPdf], while Excel and CSV get the
// statement flattened to Particulars / Amount so the figures are still usable
// in a spreadsheet.
// ─────────────────────────────────────────────────────────────────────────────
class StatementExportSource implements ExportSource {
  final StatementDoc doc;

  /// Report key ("profit-loss") and period slug ("fy2025-26"), which together
  /// build the filename.
  @override
  final String entityKey;
  @override
  final String periodSlug;

  const StatementExportSource({
    required this.doc,
    required this.entityKey,
    required this.periodSlug,
  });

  @override
  String get entityLabel => doc.title;

  @override
  String get rowNoun => 'lines';

  @override
  List<ExportColumnMeta> get columns => const [
    ExportColumnMeta('particulars', 'Particulars'),
    ExportColumnMeta('amount', 'Amount'),
  ];

  @override
  List<String> get defaultColumnKeys => const ['particulars', 'amount'];

  @override
  List<ExportColumnPreset> get presets => const [];

  /// A statement is one document — there is no filtered/all distinction to
  /// make, so every scope is the whole thing.
  @override
  int countOf(ExportScope scope) => _exportableRows.length;

  @override
  bool get hasSelection => false;

  @override
  bool get isFiltered => false;

  /// Spacers carry nothing; notes are prose that belongs on the printed page
  /// but would be noise in a spreadsheet column.
  List<StatementRow> get _exportableRows => doc.rows
      .where(
        (r) =>
            r.kind != StatementRowKind.spacer &&
            r.kind != StatementRowKind.note,
      )
      .toList();

  @override
  ExportTable buildTable(ExportScope scope, List<String> columnKeys) {
    return ExportTable(
      title: doc.title,
      headers: const ['Particulars', 'Amount (₹)'],
      types: const [ExportCellType.text, ExportCellType.money],
      widths: const [4, 1.6],
      scopeLine: '${doc.companyName} · ${doc.periodLine}',
      rows: [
        for (final row in _exportableRows)
          [
            // Section labels keep their emphasis in a flat sheet by being the
            // only rows written in capitals.
            ExportCell.text(
              row.kind == StatementRowKind.section
                  ? row.label.toUpperCase()
                  : row.label,
            ),
            row.amount == null
                ? ExportCell.text('')
                : ExportCell.money(
                    row.negative ? -row.amount!.abs() : row.amount,
                  ),
          ],
      ],
    );
  }

  @override
  Future<ExportTable> buildTableAsync(
    ExportScope scope,
    List<String> columnKeys, {
    void Function(int done, int total)? onProgress,
  }) async {
    final table = buildTable(scope, columnKeys);
    onProgress?.call(table.rowCount, table.rowCount);
    return table;
  }

  @override
  Uint8List? renderCustomPdf(String generatedLine) =>
      buildStatementPdf(doc, generatedLine: generatedLine);
}

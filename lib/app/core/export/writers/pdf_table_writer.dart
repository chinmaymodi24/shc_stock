import 'dart:typed_data';

import 'package:shc_stock/app/core/export/export_table.dart';
import 'package:shc_stock/app/core/export/writers/pdf_document.dart';

/// Paper orientation for a PDF export. Wide tables default to landscape; a
/// statement is always portrait.
enum PdfPageLayout { landscape, portrait }

extension PdfPageLayoutX on PdfPageLayout {
  String get label =>
      this == PdfPageLayout.landscape ? 'Landscape' : 'Portrait';

  double get pageWidth =>
      this == PdfPageLayout.landscape ? kA4Height : kA4Width;
  double get pageHeight =>
      this == PdfPageLayout.landscape ? kA4Width : kA4Height;
}

// The paper palette. A printed page has no dark mode, so these are the light
// theme's tokens, fixed.
const _ink = PdfColor(0.102, 0.102, 0.180); // #1a1a2e
const _inkSoft = PdfColor(0.353, 0.341, 0.439); // #5a5770
const _inkFaint = PdfColor(0.541, 0.529, 0.592); // #8a8797
const _rule = PdfColor(0.925, 0.925, 0.925); // #ececec
const _headerFill = PdfColor(0.961, 0.957, 0.941); // #f5f4f0
const _zebra = PdfColor(0.980, 0.976, 0.968); // #faf9f7

/// Renders a list export as a paginated table.
Uint8List buildTablePdf(
  ExportTable table, {
  PdfPageLayout layout = PdfPageLayout.landscape,
  required String generatedLine,
}) {
  final doc = PdfDocument(title: table.title);
  final pageWidth = layout.pageWidth;
  final pageHeight = layout.pageHeight;

  const margin = 32.0;
  const rowHeight = 18.0;
  const headerHeight = 20.0;
  const fontSize = 8.5;
  final contentWidth = pageWidth - margin * 2;

  // Header block on page 1 is taller — it carries the title and scope line.
  const firstPageTop = 96.0;
  const laterPageTop = 56.0;
  const footerSpace = 34.0;

  int rowsFor(double top) =>
      ((pageHeight - footerSpace - top - headerHeight) ~/ rowHeight).clamp(
        1,
        1 << 20,
      );

  final firstPageRows = rowsFor(firstPageTop);
  final laterPageRows = rowsFor(laterPageTop);

  var pageCount = 1;
  if (table.rows.length > firstPageRows) {
    final remaining = table.rows.length - firstPageRows;
    pageCount += (remaining / laterPageRows).ceil();
  }

  // Column x positions from the relative width hints.
  final totalWeight = table.widths.fold<double>(0, (sum, w) => sum + w);
  final columnWidths = table.widths
      .map((w) => contentWidth * (w / totalWeight))
      .toList();
  final columnX = <double>[];
  var cursor = margin;
  for (final width in columnWidths) {
    columnX.add(cursor);
    cursor += width;
  }

  var rowIndex = 0;
  for (var pageNo = 1; pageNo <= pageCount; pageNo++) {
    final page = doc.addPage(width: pageWidth, height: pageHeight);
    var y = pageNo == 1 ? firstPageTop : laterPageTop;

    if (pageNo == 1) {
      page.text(
        table.title,
        margin,
        margin + 14,
        size: 15,
        bold: true,
        color: _ink,
      );
      if (table.scopeLine.isNotEmpty) {
        page.text(
          table.scopeLine,
          margin,
          margin + 32,
          size: 9,
          color: _inkFaint,
        );
      }
      page.line(
        margin,
        margin + 44,
        pageWidth - margin,
        margin + 44,
        color: _rule,
        strokeWidth: 1,
      );
    } else {
      page.text(
        '${table.title} (continued)',
        margin,
        margin + 10,
        size: 9,
        color: _inkFaint,
      );
    }

    // Header band.
    page.rect(margin, y, contentWidth, headerHeight, _headerFill);
    for (var c = 0; c < table.headers.length; c++) {
      final cellWidth = columnWidths[c] - 12;
      final label = PdfText.truncate(
        table.headers[c].toUpperCase(),
        cellWidth,
        fontSize,
        bold: true,
      );
      if (table.types[c] == ExportCellType.money ||
          table.types[c] == ExportCellType.number) {
        page.textRight(
          label,
          columnX[c] + columnWidths[c] - 6,
          y + 14,
          size: fontSize,
          bold: true,
          color: _inkSoft,
        );
      } else {
        page.text(
          label,
          columnX[c] + 6,
          y + 14,
          size: fontSize,
          bold: true,
          color: _inkSoft,
        );
      }
    }
    y += headerHeight;

    final capacity = pageNo == 1 ? firstPageRows : laterPageRows;
    for (var i = 0; i < capacity && rowIndex < table.rows.length; i++) {
      final row = table.rows[rowIndex];
      if (rowIndex.isOdd) {
        page.rect(margin, y, contentWidth, rowHeight, _zebra);
      }
      for (var c = 0; c < row.length && c < columnWidths.length; c++) {
        final cell = row[c];
        final cellWidth = columnWidths[c] - 12;
        final value = PdfText.truncate(cell.text, cellWidth, fontSize);
        if (cell.isNumeric) {
          page.textRight(
            value,
            columnX[c] + columnWidths[c] - 6,
            y + 12.5,
            size: fontSize,
            color: _ink,
          );
        } else {
          page.text(
            value,
            columnX[c] + 6,
            y + 12.5,
            size: fontSize,
            color: _ink,
          );
        }
      }
      page.line(
        margin,
        y + rowHeight,
        pageWidth - margin,
        y + rowHeight,
        color: _rule,
        strokeWidth: 0.4,
      );
      y += rowHeight;
      rowIndex++;
    }

    _footer(page, margin, pageNo, pageCount, generatedLine);
  }

  return doc.save();
}

void _footer(
  PdfPage page,
  double margin,
  int pageNo,
  int pageCount,
  String generatedLine,
) {
  final y = page.height - margin + 4;
  page.line(
    margin,
    y - 14,
    page.width - margin,
    y - 14,
    color: _rule,
    strokeWidth: 0.5,
  );
  page.text(generatedLine, margin, y, size: 8, color: _inkFaint);
  page.textRight(
    'Page $pageNo of $pageCount',
    page.width - margin,
    y,
    size: 8,
    color: _inkFaint,
  );
}

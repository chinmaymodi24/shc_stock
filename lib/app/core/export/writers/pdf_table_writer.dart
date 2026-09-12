import 'package:shc_stock/app/core/theme/brand_controller.dart';
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
// Same rule as the statement writer: the exported table wears the buyer's
// brand, not the shipped one.
PdfColor get _ink => PdfColor.of(brand.textPrimary);
PdfColor get _inkSoft => PdfColor.of(brand.textSecondary);
PdfColor get _inkFaint => PdfColor.of(brand.textTertiary);
PdfColor get _rule => PdfColor.of(brand.border);
PdfColor get _headerFill => PdfColor.of(brand.rowHover);
PdfColor get _zebra => PdfColor.of(brand.tableHeaderBg);

/// The accent rule under the report title — the brand's primary.
PdfColor get _accent => PdfColor.of(brand.primary);

/// The plate behind the short code when no logo is set.
PdfColor get _secondary => PdfColor.of(brand.secondary);
String get _shortCode =>
    brand.shortCode.isEmpty ? '-' : brand.shortCode.toUpperCase();

/// Renders a list export as a paginated table.
Uint8List buildTablePdf(
  ExportTable table, {
  PdfPageLayout layout = PdfPageLayout.landscape,
  required String generatedLine,

  /// The buyer's logo, already decoded (see `decodeLogoForPdf`). Null falls
  /// back to the short-code plate, exactly like the sidebar does on screen.
  PdfImage? logo,
}) {
  final doc = PdfDocument(title: table.title, images: [if (logo != null) logo]);
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
      // The brand mark leads the header. A logo is drawn to fit a 28pt box
      // (keeping its aspect ratio so a wide wordmark isn't squashed into a
      // square); with no logo we draw the same short-code plate the app shows.
      const markBox = 28.0;
      var textLeft = margin;
      if (logo != null) {
        final scale =
            markBox / (logo.width > logo.height ? logo.width : logo.height);
        final w = logo.width * scale;
        final h = logo.height * scale;
        page.image(0, margin, margin + 2, w, h);
        textLeft = margin + w + 10;
      } else {
        page.rect(margin, margin + 2, markBox, markBox, _secondary);
        page.textCenter(
          _shortCode,
          margin + markBox / 2,
          margin + 2 + markBox / 2 + 4,
          size: 13,
          bold: true,
          color: PdfColor.white,
        );
        textLeft = margin + markBox + 10;
      }

      page.text(
        table.title,
        textLeft,
        margin + 14,
        size: 15,
        bold: true,
        color: _ink,
      );
      if (table.scopeLine.isNotEmpty) {
        page.text(
          table.scopeLine,
          textLeft,
          margin + 32,
          size: 9,
          color: _inkFaint,
        );
      }
      // A short accent rule in the brand's primary, then the full hairline —
      // the spec asks for the primary accent to appear in report headers, and
      // this is where a reader's eye lands first.
      page.line(
        margin,
        margin + 44,
        margin + 54,
        margin + 44,
        color: _accent,
        strokeWidth: 2,
      );
      page.line(
        margin + 54,
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

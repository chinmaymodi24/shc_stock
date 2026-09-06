import 'dart:typed_data';

import 'package:shc_stock/app/core/export/statement.dart';
import 'package:shc_stock/app/core/export/writers/pdf_document.dart';

// The same paper palette the on-screen sheet uses, so the printout and the
// screen are recognisably the same document.
const _ink = PdfColor(0.102, 0.102, 0.180); // #1a1a2e
const _inkSoft = PdfColor(0.353, 0.341, 0.439); // #5a5770
const _inkFaint = PdfColor(0.541, 0.529, 0.592); // #8a8797
const _rule = PdfColor(0.847, 0.835, 0.804); // #d8d5cd
const _hairline = PdfColor(0.969, 0.965, 0.953); // #f7f6f3
const _band = PdfColor(0.980, 0.976, 0.968); // #faf9f7
const _resultBand = PdfColor(0.914, 0.969, 0.937); // #e9f7ef
const _resultInk = PdfColor(0.118, 0.518, 0.286); // #1e8449

/// Renders a [StatementDoc] as the printed twin of the on-screen sheet:
/// centred company header, ruled column heads, indented line items, tinted
/// derived and result bands.
Uint8List buildStatementPdf(StatementDoc doc, {required String generatedLine}) {
  final pdf = PdfDocument(title: doc.title);
  const margin = 56.0;
  final contentWidth = kA4Width - margin * 2;
  final right = kA4Width - margin;
  const footerSpace = 44.0;
  final maxY = kA4Height - footerSpace;

  var page = pdf.addPage();
  var y = margin;
  final pages = <PdfPage>[page];

  void header() {
    page.textCenter(
      doc.companyName,
      kA4Width / 2,
      y + 14,
      size: 15,
      bold: true,
      color: _ink,
    );
    y += 26;
    page.textCenter(
      doc.title,
      kA4Width / 2,
      y + 10,
      size: 11.5,
      bold: true,
      color: _ink,
    );
    y += 20;
    page.textCenter(
      doc.periodLine,
      kA4Width / 2,
      y + 9,
      size: 9,
      color: _inkFaint,
    );
    y += 18;
    page.line(margin, y, right, y, color: _ink, strokeWidth: 1.6);
    y += 18;
    page.text('PARTICULARS', margin, y, size: 8, bold: true, color: _inkFaint);
    page.textRight(
      'AMOUNT (₹)',
      right,
      y,
      size: 8,
      bold: true,
      color: _inkFaint,
    );
    y += 8;
    page.line(margin, y, right, y, color: _rule, strokeWidth: 0.6);
    y += 14;
  }

  void newPage() {
    page = pdf.addPage();
    pages.add(page);
    y = margin;
    page.text(
      '${doc.title} (continued)',
      margin,
      y + 9,
      size: 9,
      color: _inkFaint,
    );
    y += 22;
    page.line(margin, y, right, y, color: _rule, strokeWidth: 0.6);
    y += 14;
  }

  header();

  for (final row in doc.rows) {
    final needed = switch (row.kind) {
      StatementRowKind.spacer => 10.0,
      StatementRowKind.section => 24.0,
      StatementRowKind.result => 34.0,
      StatementRowKind.derived => 28.0,
      _ => 20.0,
    };
    if (y + needed > maxY) newPage();

    switch (row.kind) {
      case StatementRowKind.spacer:
        y += 10;

      case StatementRowKind.section:
        page.text(
          row.label.toUpperCase(),
          margin,
          y + 8,
          size: 8,
          bold: true,
          color: _inkFaint,
        );
        y += 22;

      case StatementRowKind.note:
        for (final line in PdfText.wrap(row.label, contentWidth - 14, 8.5)) {
          page.text(line, margin + 14, y + 8, size: 8.5, color: _inkFaint);
          y += 13;
        }
        y += 5;

      case StatementRowKind.item:
        page.text(
          PdfText.truncate(row.label, contentWidth - 130, 9.5),
          margin + 14,
          y + 9,
          size: 9.5,
          color: _inkSoft,
        );
        page.textRight(row.amountText, right, y + 9, size: 9.5, color: _ink);
        y += 18;
        page.line(
          margin + 14,
          y - 2,
          right,
          y - 2,
          color: _hairline,
          strokeWidth: 0.5,
        );

      case StatementRowKind.subtotal:
        page.line(margin, y, right, y, color: _rule, strokeWidth: 0.6);
        page.text(
          row.label,
          margin,
          y + 13,
          size: 9.5,
          bold: true,
          color: _ink,
        );
        page.textRight(
          row.amountText,
          right,
          y + 13,
          size: 9.5,
          bold: true,
          color: _ink,
        );
        y += 20;
        page.line(margin, y, right, y, color: _rule, strokeWidth: 0.6);
        y += 8;

      case StatementRowKind.derived:
        page.rect(margin, y, contentWidth, 24, _band);
        page.text(
          row.label,
          margin + 10,
          y + 16,
          size: 9.5,
          bold: true,
          color: _ink,
        );
        page.textRight(
          row.amountText,
          right - 10,
          y + 16,
          size: 9.5,
          bold: true,
          color: _ink,
        );
        y += 32;

      case StatementRowKind.result:
        page.rect(margin, y, contentWidth, 28, _resultBand);
        page.text(
          row.label,
          margin + 10,
          y + 18,
          size: 10.5,
          bold: true,
          color: _resultInk,
        );
        page.textRight(
          row.amountText,
          right - 10,
          y + 18,
          size: 10.5,
          bold: true,
          color: _resultInk,
        );
        y += 36;
    }
  }

  for (var i = 0; i < pages.length; i++) {
    final p = pages[i];
    final footerY = kA4Height - margin + 10;
    p.line(
      margin,
      footerY - 14,
      right,
      footerY - 14,
      color: _hairline,
      strokeWidth: 0.5,
    );
    p.text(generatedLine, margin, footerY, size: 8, color: _inkFaint);
    p.textRight(
      'Page ${i + 1} of ${pages.length}',
      right,
      footerY,
      size: 8,
      color: _inkFaint,
    );
  }

  return pdf.save();
}

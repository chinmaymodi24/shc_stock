import 'package:shc_stock/app/core/theme/brand_controller.dart';
import 'package:shc_stock/app/core/theme/brand_theme.dart';
import 'dart:typed_data';

import 'package:shc_stock/app/core/export/statement.dart';
import 'package:shc_stock/app/core/export/writers/pdf_document.dart';

// The same paper palette the on-screen sheet uses, so the printout and the
// screen are recognisably the same document.
// The statement's ink and rules come off the buyer's brand, so an exported
// PDF matches the screens it was produced from. These were the shipped hexes
// compiled in; a rebranded deployment used to export Secure Heat Care's
// palette no matter what the app looked like.
PdfColor get _ink => PdfColor.of(brand.textPrimary);
PdfColor get _inkSoft => PdfColor.of(brand.textSecondary);
PdfColor get _inkFaint => PdfColor.of(brand.textTertiary);
PdfColor get _rule => PdfColor.of(brand.border);
PdfColor get _hairline => PdfColor.of(tint(brand.border, 0.55));
PdfColor get _band => PdfColor.of(brand.tableHeaderBg);
PdfColor get _resultBand => PdfColor.of(brand.tintSuccess);
PdfColor get _resultInk => PdfColor.of(brand.success);

/// Renders a [StatementDoc] as the printed twin of the on-screen sheet:
/// centred company header, ruled column heads, indented line items, tinted
/// derived and result bands.
Uint8List buildStatementPdf(
  StatementDoc doc, {
  required String generatedLine,

  /// The buyer's logo, already decoded. Null just means the statement leads
  /// with the company name alone, as it always did.
  PdfImage? logo,
}) {
  final pdf = PdfDocument(title: doc.title, images: [if (logo != null) logo]);
  const margin = 56.0;
  final contentWidth = kA4Width - margin * 2;
  final right = kA4Width - margin;
  const footerSpace = 44.0;
  final maxY = kA4Height - footerSpace;

  var page = pdf.addPage();
  var y = margin;
  final pages = <PdfPage>[page];

  void header() {
    // A centred logo above the company name — a statement is the most
    // "letterhead" thing the app produces, so the mark leads it.
    if (logo != null) {
      const box = 34.0;
      final scale = box / (logo.width > logo.height ? logo.width : logo.height);
      final w = logo.width * scale;
      final h = logo.height * scale;
      page.image(0, (kA4Width - w) / 2, y, w, h);
      y += h + 8;
    }
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

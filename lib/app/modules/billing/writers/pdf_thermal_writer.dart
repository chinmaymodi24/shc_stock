import 'dart:typed_data';

import 'package:shc_stock/app/core/export/writers/pdf_document.dart';
import 'package:shc_stock/app/core/export/writers/pdf_logo.dart';
import 'package:shc_stock/app/modules/billing/models/bill_model.dart';
import 'package:shc_stock/app/modules/billing/models/billing_profile.dart';
import 'package:shc_stock/app/modules/billing/models/invoice_totals.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The 80 mm thermal receipt, as a PDF.
//
// A roll has no page break — it is one continuous strip that the printer cuts
// where the content ends. So the page is 80 mm wide and exactly as tall as
// what is on it: the layout is assembled as a list of blocks first, the
// heights are added up, and only then is the page created. (It has to be that
// way round: [PdfPage] flips top-left coordinates using its own height, so the
// height must be known before anything is drawn.)
//
// Content stays inside 72 mm — the printable width of an 80 mm head.
// ─────────────────────────────────────────────────────────────────────────────

const _ink = PdfColor(0.102, 0.102, 0.180); // #1a1a2e
const _muted = PdfColor(0.353, 0.341, 0.439); // #5a5770
const _faint = PdfColor(0.541, 0.529, 0.592); // #8a8797

const double _pageW = kThermalRollWidth;
const double _contentW = kThermalPrintWidth;
const double _left = (_pageW - _contentW) / 2;
const double _right = _left + _contentW;
const double _padTop = 14;
const double _padBottom = 22;

/// One horizontal band of the strip: how tall it is, and how to draw it once
/// the strip's total height — and therefore the page — is known.
typedef _Block = ({
  double height,
  void Function(PdfPage page, double top) draw,
});

Uint8List buildThermalPdf({
  required BillingProfile profile,
  required String sellerName,
  required SalesOrder order,
  required InvoiceTotals totals,
  required BillOptions options,
  required String invoiceNo,
  required DateTime invoiceDate,
  required String generatedLine,
  BillModel? bill,
  PdfImage? logo,
}) {
  final mark = logo ?? brandPdfLogo;
  final blocks = _blocks(
    profile: profile,
    sellerName: sellerName,
    order: order,
    totals: totals,
    options: options,
    invoiceNo: invoiceNo,
    invoiceDate: invoiceDate,
    generatedLine: generatedLine,
    bill: bill,
    logo: mark,
  );

  final doc = PdfDocument(
    title: 'Thermal Receipt',
    images: [if (mark != null) mark],
  );
  for (final chunk in _chunked(blocks)) {
    final strip = chunk.fold(0.0, (sum, b) => sum + b.height);
    final page = doc.addPage(
      width: _pageW,
      height: _padTop + strip + _padBottom,
    );
    var top = _padTop;
    for (final block in chunk) {
      block.draw(page, top);
      top += block.height;
    }
  }
  return doc.save();
}

/// Splits the strip so no page exceeds what a PDF can express.
///
/// A roll has no page break and an ordinary receipt is one page — but PDF caps
/// a page at 14400 units (200 inches), and an order long enough to pass that
/// would otherwise produce a file no reader will open. Splitting keeps every
/// line on paper; dropping them would not.
List<List<_Block>> _chunked(List<_Block> blocks) {
  const limit = kPdfMaxPageExtent - _padTop - _padBottom;
  final pages = <List<_Block>>[];
  var current = <_Block>[];
  var used = 0.0;
  for (final block in blocks) {
    if (current.isNotEmpty && used + block.height > limit) {
      pages.add(current);
      current = <_Block>[];
      used = 0;
    }
    current.add(block);
    used += block.height;
  }
  if (current.isNotEmpty) pages.add(current);
  return pages;
}

// ── The strip ────────────────────────────────────────────────────────────────
List<_Block> _blocks({
  required BillingProfile profile,
  required String sellerName,
  required SalesOrder order,
  required InvoiceTotals totals,
  required BillOptions options,
  required String invoiceNo,
  required DateTime invoiceDate,
  required String generatedLine,
  required BillModel? bill,
  required PdfImage? logo,
}) {
  final out = <_Block>[];

  void gap(double h) => out.add((height: h, draw: (_, _) {}));

  void dashes() =>
      out.add((height: 7, draw: (page, top) => _dashedRule(page, top + 3)));

  void centred(
    String value,
    double size, {
    bool bold = false,
    PdfColor color = _muted,
    double lead = 4,
  }) {
    if (value.trim().isEmpty) return;
    for (final line in PdfText.wrap(
      value,
      _contentW,
      size,
      bold: bold,
      mono: true,
    )) {
      out.add((
        height: size + lead,
        draw: (page, top) => page.textCenter(
          line,
          _pageW / 2,
          top + size,
          size: size,
          bold: bold,
          mono: true,
          color: color,
        ),
      ));
    }
  }

  /// Label left, value hard right — the whole receipt is built from this.
  void pair(
    String label,
    String value, {
    double size = 6.6,
    bool bold = false,
    double lead = 4,
  }) {
    out.add((
      height: size + lead,
      draw: (page, top) {
        page.text(
          label,
          _left,
          top + size,
          size: size,
          mono: true,
          color: _faint,
        );
        page.textRight(
          PdfText.truncate(
            value.isEmpty ? '-' : value,
            _contentW - PdfText.width(label, size, mono: true) - 8,
            size,
            bold: bold,
            mono: true,
          ),
          _right,
          top + size,
          size: size,
          bold: bold,
          mono: true,
          color: _ink,
        );
      },
    ));
  }

  // Masthead.
  if (logo != null) {
    const box = 22.0;
    final scale = box / (logo.width > logo.height ? logo.width : logo.height);
    final w = logo.width * scale;
    final h = logo.height * scale;
    out.add((
      height: h + 6,
      draw: (page, top) => page.image(0, (_pageW - w) / 2, top, w, h),
    ));
  }
  centred(sellerName, 9, bold: true, color: _ink, lead: 5);
  centred(profile.addressLine1, 6, lead: 3);
  centred(profile.phone, 6, lead: 3);
  if (profile.gstin.trim().isNotEmpty) {
    centred('GSTIN ${profile.gstin}', 6, lead: 3);
  }

  gap(6);
  dashes();
  gap(3);
  centred('TAX INVOICE', 7.5, bold: true, color: _ink, lead: 4);
  gap(3);
  dashes();
  gap(3);

  // Who, when, and who rang it up.
  final cashier = (bill?.generatedBy ?? '').trim().isNotEmpty
      ? bill!.generatedBy
      : order.modifiedBy;
  pair('Bill No', invoiceNo);
  pair('Date', shortDate(invoiceDate));
  pair('Party', order.client);
  pair('Cashier', cashier);

  gap(3);
  dashes();
  gap(2);

  // Column heads.
  out.add((
    height: 11,
    draw: (page, top) {
      page.text('ITEM', _left, top + 6, size: 6, mono: true, color: _faint);
      page.textRight(
        'QTY',
        _left + _contentW * 0.56,
        top + 6,
        size: 6,
        mono: true,
        color: _faint,
      );
      page.textRight(
        'RATE',
        _left + _contentW * 0.76,
        top + 6,
        size: 6,
        mono: true,
        color: _faint,
      );
      page.textRight(
        'AMT',
        _right,
        top + 6,
        size: 6,
        mono: true,
        color: _faint,
      );
    },
  ));
  dashes();

  // Two lines per item: the description gets the full width, the figures the
  // line beneath — nothing on 72 mm fits a name and four columns side by side.
  for (final line in totals.lines) {
    gap(3);
    for (final part in PdfText.wrap(line.line.name, _contentW, 7, mono: true)) {
      out.add((
        height: 10,
        draw: (page, top) =>
            page.text(part, _left, top + 7, size: 7, mono: true, color: _ink),
      ));
    }
    out.add((
      height: 10,
      draw: (page, top) {
        final baseline = top + 7;
        if (options.showHsnSummary && line.line.hsn.trim().isNotEmpty) {
          page.text(
            line.line.hsn,
            _left,
            baseline,
            size: 5.8,
            mono: true,
            color: _faint,
          );
        }
        page.textRight(
          line.qtyLabel,
          _left + _contentW * 0.56,
          baseline,
          size: 6.6,
          mono: true,
          color: _ink,
        );
        page.textRight(
          line.rateText,
          _left + _contentW * 0.76,
          baseline,
          size: 6.6,
          mono: true,
          color: _ink,
        );
        page.textRight(
          line.taxableText,
          _right,
          baseline,
          size: 6.6,
          bold: true,
          mono: true,
          color: _ink,
        );
      },
    ));
    gap(3);
  }

  dashes();
  gap(3);

  final half = totals.tax.halfLabel;
  pair('Taxable', totals.taxableTotalText);
  pair('CGST $half', totals.cgstTotalText);
  pair('SGST $half', totals.sgstTotalText);
  pair('Round Off', totals.roundOffText);

  gap(3);
  dashes();
  gap(3);

  out.add((
    height: 18,
    draw: (page, top) {
      page.text(
        'TOTAL',
        _left,
        top + 12,
        size: 8.5,
        bold: true,
        mono: true,
        color: _ink,
      );
      page.textRight(
        'Rs.${totals.grandTotalText}',
        _right,
        top + 12,
        size: 10.5,
        bold: true,
        mono: true,
        color: _ink,
      );
    },
  ));

  gap(3);
  dashes();
  gap(3);

  // The sale records how much is settled, not by which instrument — so this
  // prints the payment's standing rather than inventing "UPI".
  pair('Payment', order.paymentStatus.label);
  pair('Items / Qty', '${totals.itemCount} / ${_qty(totals.totalQty)}');

  gap(10);
  centred('Thank you, visit again', 6.6, lead: 4);
  if (options.showDeclaration) {
    centred('Goods once sold not returnable', 6.6, lead: 4);
  }
  gap(5);
  centred('- Godaam -', 6, lead: 3);
  gap(4);
  centred(generatedLine, 5.4, color: _faint, lead: 3);

  return out;
}

/// The torn rule a receipt uses instead of a ruled border — dashes are all an
/// ESC/POS head can draw without graphics mode.
void _dashedRule(PdfPage page, double top) {
  const dash = 3.0;
  const gap = 2.2;
  for (var x = _left; x < _right; x += dash + gap) {
    final end = (x + dash).clamp(_left, _right);
    page.line(x, top, end, top, color: _faint, strokeWidth: 0.5);
  }
}

/// dd/MM/yy — a roll has no room for a spelled-out month.
String shortDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/'
    '${(d.year % 100).toString().padLeft(2, '0')}';

String _qty(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

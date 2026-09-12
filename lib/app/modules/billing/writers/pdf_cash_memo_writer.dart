import 'dart:typed_data';

import 'package:shc_stock/app/core/export/writers/pdf_document.dart';
import 'package:shc_stock/app/core/export/writers/pdf_logo.dart';
import 'package:shc_stock/app/modules/billing/models/amount_in_words.dart';
import 'package:shc_stock/app/modules/billing/models/billing_profile.dart';
import 'package:shc_stock/app/modules/billing/models/invoice_totals.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The cash memo, on paper — A5, the size a counter memo book is printed at.
//
// It renders the same [InvoiceTotals] the A4 invoice and the on-screen memo
// render, so the three agree to the paise. See `cash_memo.dart` for why the
// memo carries the invoice's own number and its full, tax-inclusive total.
//
// A memo can outgrow its sheet — 13 lines fill one A5 — so the items table
// paginates and repeats its column heads, the way the tax invoice does. A PDF
// will happily accept a baseline below the page and simply draw the row where
// nobody can see it, which on a bill is silent data loss, not a layout nit.
//
// Like every PDF here it prints "Rs." rather than ₹ — the base-14 fonts carry
// no rupee glyph (PdfText.sanitize).
// ─────────────────────────────────────────────────────────────────────────────

const _ink = PdfColor(0.102, 0.102, 0.180); // #1a1a2e
const _muted = PdfColor(0.353, 0.341, 0.439); // #5a5770
const _faint = PdfColor(0.541, 0.529, 0.592); // #8a8797
const _rule = PdfColor(0, 0, 0);
const _shade = PdfColor(0.961, 0.957, 0.941); // #f5f4f0

const double _margin = 28;
const double _pageW = kA5Width;
const double _pageH = kA5Height;
const double _left = _margin;
const double _right = _pageW - _margin;
const double _contentW = _pageW - _margin * 2;

/// The lowest baseline a row may use. Below this the footer line lives.
const double _bottomLimit = _pageH - _margin - 12;

/// Particulars columns, left to right: Sl, name, Qty, Rate, Amount.
/// They sum to [_contentW].
const _cols = <double>[18, 157.53, 55, 60, 73];

/// How much of the letterhead's right edge the No./Date block may claim.
const double _headBlockW = 150;

Uint8List buildCashMemoPdf({
  required BillingProfile profile,
  required String sellerName,
  required SalesOrder order,
  required InvoiceTotals totals,
  required BillOptions options,
  required String invoiceNo,
  required DateTime invoiceDate,
  required String generatedLine,

  /// The memo's title colour — the brand accent, matching the screen. Passed
  /// in so the writer stays free of GetX and can be exercised from a test.
  required PdfColor accent,
  ClientModel? client,
  PdfImage? logo,
}) {
  final mark = logo ?? brandPdfLogo;
  final doc = PdfDocument(title: 'Cash Memo', images: [if (mark != null) mark]);
  _MemoWriter(
    doc: doc,
    profile: profile,
    sellerName: sellerName,
    order: order,
    client: client,
    totals: totals,
    options: options,
    invoiceNo: invoiceNo,
    invoiceDate: invoiceDate,
    accent: accent,
    logo: mark,
  ).render(generatedLine);
  return doc.save();
}

class _MemoWriter {
  final PdfDocument doc;
  final BillingProfile profile;
  final String sellerName;
  final SalesOrder order;
  final ClientModel? client;
  final InvoiceTotals totals;
  final BillOptions options;
  final String invoiceNo;
  final DateTime invoiceDate;
  final PdfColor accent;
  final PdfImage? logo;

  late PdfPage page;
  double y = _margin;

  _MemoWriter({
    required this.doc,
    required this.profile,
    required this.sellerName,
    required this.order,
    required this.client,
    required this.totals,
    required this.options,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.accent,
    required this.logo,
  });

  void render(String generatedLine) {
    page = doc.addPage(width: _pageW, height: _pageH);
    _letterhead();
    page.line(_left, y, _right, y, color: _rule, strokeWidth: 0.8);
    y += 16;
    _party();
    _items();
    _totals();
    _words();
    _footer();
    _footers(generatedLine);
  }

  /// Starts a fresh sheet. The caller re-draws whatever heading its section
  /// needs — the items table repeats its columns, the totals do not.
  void _newPage() {
    page = doc.addPage(width: _pageW, height: _pageH);
    y = _margin;
    page.textCenter(
      'CASH MEMO (continued)',
      _pageW / 2,
      y + 8,
      size: 6.5,
      color: _faint,
    );
    y += 16;
  }

  /// Ensures [needed] points are free, starting a sheet if not.
  bool _ensure(double needed) {
    if (y + needed <= _bottomLimit) return false;
    _newPage();
    return true;
  }

  // ── Letterhead ────────────────────────────────────────────────────────────
  void _letterhead() {
    const markBox = 26.0;
    var textX = _left;
    final mark = logo;
    if (mark != null) {
      final scale =
          markBox / (mark.width > mark.height ? mark.width : mark.height);
      page.image(0, _left, y, mark.width * scale, mark.height * scale);
      textX = _left + markBox + 9;
    }

    // The seller's name stops where the No./Date block starts, rather than
    // running under it.
    final nameW = _right - _headBlockW - textX - 10;
    page.text(
      PdfText.truncate(sellerName, nameW, 12, bold: true),
      textX,
      y + 11,
      size: 12,
      bold: true,
      color: _ink,
    );
    final contact = [
      profile.addressLine1,
      profile.phone,
    ].where((v) => v.trim().isNotEmpty).join(', ');
    if (contact.isNotEmpty) {
      page.text(
        PdfText.truncate(contact, _right - _headBlockW - textX - 10, 7),
        textX,
        y + 22,
        size: 7,
        color: _muted,
      );
    }

    // The memo's title carries the accent, the way the printed memo book it
    // replaces does. Everything else is black on white.
    page.textRight(
      'CASH MEMO',
      _right,
      y + 9,
      size: 8,
      bold: true,
      color: accent,
    );
    _headLine('No.', invoiceNo, y + 22);
    _headLine('Date', _date(invoiceDate), y + 32);

    y += 46;
  }

  /// A right-aligned `label value` pair in the letterhead's top corner. The
  /// value is trimmed to what is left of [_headBlockW] after the label, so a
  /// long series number cannot push the label off the left of the sheet.
  void _headLine(String label, String value, double baseline) {
    final labelW = PdfText.width(label, 6.5);
    final trimmed = PdfText.truncate(
      value,
      _headBlockW - labelW - 5,
      7.5,
      bold: true,
      mono: true,
    );
    final valueW = PdfText.width(trimmed, 7.5, bold: true, mono: true);
    page.text(
      trimmed,
      _right - valueW,
      baseline,
      size: 7.5,
      bold: true,
      mono: true,
      color: _ink,
    );
    page.textRight(
      label,
      _right - valueW - 5,
      baseline,
      size: 6.5,
      color: _faint,
    );
  }

  // ── Buyer ─────────────────────────────────────────────────────────────────
  void _party() {
    final address = order.clientAddress.trim().isNotEmpty
        ? order.clientAddress.trim()
        : (client?.address ?? '').trim();
    final primary = (client?.phone ?? '').trim();
    final mobile = primary.isNotEmpty
        ? primary
        : (client?.contactPhone ?? '').trim();

    final splitX = _left + _contentW * 0.6;
    page.text('NAME', _left, y + 6, size: 5.8, color: _faint);
    page.text(
      PdfText.truncate(order.client, splitX - _left - 10, 9.5, bold: true),
      _left,
      y + 18,
      size: 9.5,
      bold: true,
      color: _ink,
    );
    if (address.isNotEmpty) {
      page.text(
        PdfText.truncate(address, splitX - _left - 10, 7),
        _left,
        y + 28,
        size: 7,
        color: _muted,
      );
    }

    page.text('MOBILE', splitX, y + 6, size: 5.8, color: _faint);
    page.text(
      PdfText.truncate(
        mobile.isEmpty ? '-' : mobile,
        _right - splitX,
        8.5,
        bold: true,
        mono: true,
      ),
      splitX,
      y + 18,
      size: 8.5,
      bold: true,
      mono: true,
      color: _ink,
    );

    y += 44;
  }

  // ── Particulars ───────────────────────────────────────────────────────────
  double _colX(int index) {
    var x = _left;
    for (var i = 0; i < index; i++) {
      x += _cols[i];
    }
    return x;
  }

  /// The column heads and the rule beneath them. Drawn again at the top of
  /// every continuation sheet so no page carries orphan rows.
  void _itemsHead() {
    page.text('Sl', _colX(0), y + 7, size: 6.2, bold: true, color: _faint);
    page.text(
      'Particulars',
      _colX(1),
      y + 7,
      size: 6.2,
      bold: true,
      color: _faint,
    );
    page.textRight(
      'Qty',
      _colX(2) + _cols[2],
      y + 7,
      size: 6.2,
      bold: true,
      color: _faint,
    );
    page.textRight(
      'Rate',
      _colX(3) + _cols[3],
      y + 7,
      size: 6.2,
      bold: true,
      color: _faint,
    );
    page.textRight(
      'Amount',
      _colX(4) + _cols[4],
      y + 7,
      size: 6.2,
      bold: true,
      color: _faint,
    );
    y += 12;
    page.line(_left, y, _right, y, color: _rule, strokeWidth: 0.7);
  }

  void _items() {
    _itemsHead();

    for (var i = 0; i < totals.lines.length; i++) {
      // A row is 21pt; the closing rule under the table needs a couple more.
      if (_ensure(23)) _itemsHead();
      final line = totals.lines[i];
      final baseline = y + 14;
      page.text(
        '${i + 1}',
        _colX(0),
        baseline,
        size: 8,
        mono: true,
        color: _ink,
      );
      page.text(
        PdfText.truncate(line.line.name, _cols[1] - 8, 8.5, bold: true),
        _colX(1),
        baseline,
        size: 8.5,
        bold: true,
        color: _ink,
      );
      _amount(line.qtyLabel, 2, baseline);
      _amount(line.rateText, 3, baseline);
      _amount(line.taxableText, 4, baseline);
      y += 21;
    }
    page.line(_left, y, _right, y, color: _rule, strokeWidth: 0.7);
    y += 14;
  }

  void _amount(String value, int col, double baseline) => page.textRight(
    value,
    _colX(col) + _cols[col],
    baseline,
    size: 8,
    mono: true,
    color: _ink,
  );

  // ── Money ─────────────────────────────────────────────────────────────────
  void _totals() {
    const blockW = 176.0;
    final blockL = _right - blockW;
    // Three rows, the rule, and the grand total line — kept together, because
    // a total split across sheets is unreadable.
    _ensure(75);

    void row(String label, String value) {
      page.text(label, blockL, y + 8, size: 7.5, color: _muted);
      page.textRight(value, _right, y + 8, size: 8, mono: true, color: _ink);
      y += 13;
    }

    row('Sub Total', totals.taxableTotalText);
    row('GST ${_ratePercent(totals.tax.gstPercent)}', totals.totalTaxText);
    row('Round Off', totals.roundOffText);

    y += 4;
    page.line(blockL, y, _right, y, color: _rule, strokeWidth: 0.7);
    y += 6;
    page.text(
      'Grand Total',
      blockL,
      y + 11,
      size: 9.5,
      bold: true,
      color: _ink,
    );
    page.textRight(
      'Rs.${totals.grandTotalText}',
      _right,
      y + 12,
      size: 12,
      bold: true,
      mono: true,
      color: _ink,
    );
    y += 26;
  }

  static String _ratePercent(double percent) {
    final text = percent == percent.roundToDouble()
        ? percent.toStringAsFixed(0)
        : percent.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
    return '$text%';
  }

  // ── Words ─────────────────────────────────────────────────────────────────
  void _words() {
    const height = 32.0;
    _ensure(height + 6);
    page.rect(_left, y, _contentW, height, _shade);
    page.text('IN WORDS', _left + 9, y + 11, size: 5.8, color: _faint);
    page.text(
      PdfText.truncate(
        amountInWords(totals.grandTotal, currency: 'Rupees'),
        _contentW - 18,
        8.5,
        bold: true,
      ),
      _left + 9,
      y + 24,
      size: 8.5,
      bold: true,
      color: _ink,
    );
    y += height + 26;
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  static const memoTerms =
      'Goods once sold will not be taken back. Please retain this memo for '
      'any warranty claim.';

  void _footer() {
    _ensure(50);
    if (options.showDeclaration) {
      var cursor = y + 8;
      for (final line in PdfText.wrap(memoTerms, _contentW * 0.55, 7)) {
        page.text(line, _left, cursor, size: 7, color: _muted);
        cursor += 9;
      }
    }
    final signBase = y + 30;
    page.line(
      _right - 100,
      signBase,
      _right,
      signBase,
      color: _faint,
      strokeWidth: 0.5,
    );
    page.textRight('Signature', _right, signBase + 9, size: 6.4, color: _faint);
    y = signBase + 16;
  }

  /// The provenance line on every sheet, and a sheet count once there is more
  /// than one — otherwise a dropped page goes unnoticed.
  void _footers(String generatedLine) {
    for (var i = 0; i < doc.pages.length; i++) {
      final p = doc.pages[i];
      p.text(generatedLine, _left, _pageH - 14, size: 5.8, color: _faint);
      if (doc.pages.length > 1) {
        p.textRight(
          'Page ${i + 1} of ${doc.pages.length}',
          _right,
          _pageH - 14,
          size: 5.8,
          color: _faint,
        );
      }
    }
  }

  static String _date(DateTime d) {
    const months = [
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
    return '${d.day.toString().padLeft(2, '0')}-${months[d.month - 1]}-${d.year}';
  }
}

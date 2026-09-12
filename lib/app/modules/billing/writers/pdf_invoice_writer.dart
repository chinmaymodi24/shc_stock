import 'dart:typed_data';

import 'package:shc_stock/app/core/export/writers/pdf_document.dart';
import 'package:shc_stock/app/core/export/writers/pdf_logo.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/modules/billing/models/amount_in_words.dart';
import 'package:shc_stock/app/modules/billing/models/bill_model.dart';
import 'package:shc_stock/app/modules/billing/models/billing_profile.dart';
import 'package:shc_stock/app/modules/billing/models/invoice_totals.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/shared/models/order_payment.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The GST tax invoice, on paper.
//
// A ruled document in the Indian tax-invoice convention: every block is a
// bordered cell, captions are small and grey, values are black, and all
// numerals are Courier so the columns line up digit for digit.
//
// It prints black on white whatever the app's theme is — a printed invoice has
// no dark mode. The only figures it shows come from [InvoiceTotals], the same
// object the on-screen document renders, so the two cannot disagree.
//
// One thing the base-14 PDF fonts cost us, a deliberate trade-off against
// shipping a font-embedding library: the rupee sign prints as "Rs." (see
// PdfText.sanitize). Everywhere else — screen, CSV, Excel — keeps the symbol.
// ─────────────────────────────────────────────────────────────────────────────

const _ink = PdfColor(0.102, 0.102, 0.180); // #1a1a2e
const _muted = PdfColor(0.353, 0.341, 0.439); // #5a5770
const _faint = PdfColor(0.541, 0.529, 0.592); // #8a8797
const _rule = PdfColor(0, 0, 0);
const _shade = PdfColor(0.961, 0.957, 0.941); // #f5f4f0

const double _margin = 24;
const double _pageW = kA4Width;
const double _pageH = kA4Height;
const double _contentW = _pageW - _margin * 2;
const double _right = _pageW - _margin;

/// Items-table column widths, left to right. They sum to [_contentW].
const _itemCols = <double>[22, 150, 54, 54, 46, 60, 48, 48, 65.28];

/// HSN-summary column widths: HSN, taxable, CGST rate, CGST amount,
/// SGST rate, SGST amount, total tax.
const _hsnCols = <double>[90, 100, 60, 85, 60, 85, 67.28];

Uint8List buildInvoicePdf({
  required BillingProfile profile,
  required SalesOrder order,
  required InvoiceTotals totals,
  required BillOptions options,
  required String generatedLine,

  /// Already resolved by the caller — the billing profile's legal name, or
  /// the brand's company name when none is set. The writer stays free of
  /// GetX so it can be exercised straight from a test.
  required String sellerName,
  ClientModel? client,
  BillModel? bill,

  /// The buyer's decoded logo. Defaults to whatever the applied brand has
  /// warmed into the PDF cache, so a bill carries the same mark the app does.
  PdfImage? logo,

  /// The authorised signature, drawn above the signatory rule. Defaults to
  /// the one the billing profile warmed into the cache.
  PdfImage? signature,
}) {
  final mark = logo ?? brandPdfLogo;
  final sign = signature ?? billingPdfSignature;
  // Index order matters: the writer draws /Im0 for the mark and /Im1 for the
  // signature, so both slots are registered even when one is missing.
  final images = <PdfImage>[if (mark != null) mark, if (sign != null) sign];
  final doc = PdfDocument(title: 'Tax Invoice', images: images);
  final w = _Writer(
    doc,
    profile,
    order,
    client,
    bill,
    totals,
    options,
    sellerName,
    mark,
    sign,
    mark == null ? -1 : 0,
    sign == null ? -1 : (mark == null ? 0 : 1),
  );
  w.render(generatedLine);
  return doc.save();
}

class _Writer {
  final PdfDocument doc;
  final BillingProfile profile;
  final SalesOrder order;
  final ClientModel? client;
  final BillModel? bill;
  final InvoiceTotals totals;
  final BillOptions options;
  final String sellerName;
  final PdfImage? logo;
  final PdfImage? signature;

  /// Positions in the document's image list, or -1 when that image is absent.
  final int logoSlot;
  final int signatureSlot;

  late PdfPage page;
  double y = _margin;

  _Writer(
    this.doc,
    this.profile,
    this.order,
    this.client,
    this.bill,
    this.totals,
    this.options,
    this.sellerName,
    this.logo,
    this.signature,
    this.logoSlot,
    this.signatureSlot,
  );

  double get _bottomLimit => _pageH - _margin - 14;

  void render(String generatedLine) {
    page = doc.addPage(width: _pageW, height: _pageH);
    _caption();
    _headerRow();
    _partyRow();
    _itemsTable();
    _wordsBand(
      'Amount Chargeable (in words)',
      amountInWords(totals.grandTotal),
      rightNote: 'E. & O.E',
    );
    if (options.showHsnSummary) {
      _hsnTable();
      _wordsBand('Tax Amount (in words)', amountInWords(totals.totalTax));
    }
    _footerRow();
    _footNote();
    _pageNumbers(generatedLine);
  }

  // ── Chrome ────────────────────────────────────────────────────────────────
  void _newPage({String title = 'TAX INVOICE (continued)'}) {
    page = doc.addPage(width: _pageW, height: _pageH);
    y = _margin;
    _box(y, 16);
    page.textCenter(title, _pageW / 2, y + 11, size: 7.5, color: _faint);
    y += 16;
  }

  /// Ensures [needed] points are free, starting a page if not.
  void _ensure(double needed) {
    if (y + needed > _bottomLimit) _newPage();
  }

  /// A bordered band spanning the full content width.
  void _box(double top, double height) {
    page.line(_margin, top, _right, top, color: _rule, strokeWidth: 0.7);
    page.line(
      _margin,
      top + height,
      _right,
      top + height,
      color: _rule,
      strokeWidth: 0.7,
    );
    page.line(
      _margin,
      top,
      _margin,
      top + height,
      color: _rule,
      strokeWidth: 0.7,
    );
    page.line(
      _right,
      top,
      _right,
      top + height,
      color: _rule,
      strokeWidth: 0.7,
    );
  }

  void _vline(double x, double top, double height) =>
      page.line(x, top, x, top + height, color: _rule, strokeWidth: 0.7);

  /// A small grey caption with a bold value beneath it — the pattern the
  /// header grid and the party cells are built from.
  void _captionValue(
    String caption,
    String value,
    double x,
    double top,
    double width, {
    bool mono = false,
  }) {
    page.text(caption, x + 5, top + 8, size: 5.6, color: _faint);
    page.text(
      PdfText.truncate(value, width - 10, 7.5, bold: true, mono: mono),
      x + 5,
      top + 17,
      size: 7.5,
      bold: true,
      mono: mono,
      color: _ink,
    );
  }

  void _caption() {
    _box(y, 15);
    page.textCenter(
      'T A X   I N V O I C E',
      _pageW / 2,
      y + 10,
      size: 7,
      color: _muted,
    );
    y += 15;
  }

  // ── Header: seller | document grid ────────────────────────────────────────
  void _headerRow() {
    const height = 92.0;
    const splitX = _margin + 300.0;
    _box(y, height);
    _vline(splitX, y, height);

    // The brand mark leads the seller cell — the one place the accent is
    // allowed on the paper. Scaled to fit a 34pt box, whatever its aspect.
    const markBox = 34.0;
    var textX = _margin + 8;
    final mark = logo;
    if (mark != null) {
      final scale =
          markBox / (mark.width > mark.height ? mark.width : mark.height);
      page.image(
        logoSlot,
        _margin + 8,
        y + 8,
        mark.width * scale,
        mark.height * scale,
      );
      textX = _margin + 8 + markBox + 10;
    }
    final textWidth = splitX - textX - 8;

    var cursor = y + 13;
    page.text(sellerName, textX, cursor, size: 10.5, bold: true, color: _ink);
    cursor += 13;
    for (final line in [profile.addressLine1, profile.addressLine2]) {
      if (line.trim().isEmpty) continue;
      page.text(
        PdfText.truncate(line, textWidth, 7.5),
        textX,
        cursor,
        size: 7.5,
        color: _muted,
      );
      cursor += 10;
    }
    cursor += 3;
    if (profile.gstin.isNotEmpty) {
      _labelled('GSTIN/UIN: ', profile.gstin, textX, cursor);
      cursor += 10;
    }
    if (profile.stateName.isNotEmpty) {
      page.text(
        'State Name: ${profile.stateName}'
        '${profile.stateCode.isEmpty ? '' : ', Code: ${profile.stateCode}'}',
        textX,
        cursor,
        size: 7,
        color: _muted,
      );
      cursor += 10;
    }
    final contact = [
      profile.phone,
      profile.email,
    ].where((v) => v.trim().isNotEmpty).join('  ·  ');
    if (contact.isNotEmpty) {
      page.text(
        PdfText.truncate(contact, textWidth, 7),
        textX,
        cursor,
        size: 7,
        color: _muted,
      );
    }

    // Document grid — 2 columns × 4 rows.
    final gridW = _right - splitX;
    final colW = gridW / 2;
    const rowH = height / 4;
    for (var r = 1; r < 4; r++) {
      page.line(
        splitX,
        y + rowH * r,
        _right,
        y + rowH * r,
        color: _rule,
        strokeWidth: 0.5,
      );
    }
    for (var r = 0; r < 4; r++) {
      _vline(splitX + colW, y + rowH * r, rowH);
    }

    final invoiceNo = bill?.invoiceNo ?? order.invoiceNo;
    final dated = bill?.issuedOn ?? order.invoiceDate ?? order.date;
    final cells = <List<String>>[
      [
        'Invoice No.',
        invoiceNo.isEmpty ? '—' : invoiceNo,
        'Dated',
        _date(dated),
      ],
      [
        "Buyer's Order No.",
        order.soNumber,
        'Mode/Terms of Payment',
        order.paymentType.label.isEmpty ? '—' : order.paymentType.label,
      ],
      [
        'Dispatched through',
        order.despatchedThrough.isEmpty ? '—' : order.despatchedThrough,
        'Vehicle No.',
        '—',
      ],
      [
        'Destination',
        order.destination.isEmpty ? '—' : order.destination,
        'Reverse Charge',
        'No',
      ],
    ];
    for (var r = 0; r < cells.length; r++) {
      final top = y + rowH * r;
      _captionValue(cells[r][0], cells[r][1], splitX, top, colW, mono: r == 0);
      _captionValue(
        cells[r][2],
        cells[r][3],
        splitX + colW,
        top,
        colW,
        mono: r == 0,
      );
    }
    y += height;
  }

  void _labelled(String label, String value, double x, double baseline) {
    page.text(label, x, baseline, size: 7, color: _muted);
    page.text(
      value,
      x + PdfText.width(label, 7),
      baseline,
      size: 7,
      bold: true,
      mono: true,
      color: _ink,
    );
  }

  // ── Party row: buyer | consignee ──────────────────────────────────────────
  void _partyRow() {
    const height = 78.0;
    final splitX = _margin + _contentW / 2;
    _box(y, height);
    _vline(splitX, y, height);

    _party(
      x: _margin,
      title: 'BUYER (BILL TO)',
      name: order.client,
      address: order.clientAddress.isNotEmpty
          ? order.clientAddress
          : (client?.address ?? ''),
      rows: [
        (
          'GSTIN/UIN',
          order.buyerGstin.isNotEmpty
              ? order.buyerGstin
              : (client?.gstin ?? ''),
        ),
        ('PAN', order.pan.isNotEmpty ? order.pan : (client?.pan ?? '')),
        ('Place of Supply', client?.state ?? ''),
      ],
    );

    // Ship-to falls back to the bill-to address, which is what "same as
    // registered" means on the client record.
    final shipCity = client?.shipCity ?? '';
    _party(
      x: splitX,
      title: 'CONSIGNEE (SHIP TO)',
      name: order.client,
      address: shipCity.trim().isEmpty
          ? (order.clientAddress.isNotEmpty
                ? order.clientAddress
                : (client?.address ?? ''))
          : [
              client?.shipAddr1 ?? '',
              client?.shipAddr2 ?? '',
              '$shipCity ${client?.shipPin ?? ''}',
              client?.shipState ?? '',
            ].where((l) => l.trim().isNotEmpty).join(', '),
      rows: [
        ('Delivery Note', order.soNumber),
        ('Destination', order.destination),
        ('State Name', client?.shipState ?? client?.state ?? ''),
      ],
    );
    y += height;
  }

  void _party({
    required double x,
    required String title,
    required String name,
    required String address,
    required List<(String, String)> rows,
  }) {
    final width = _contentW / 2;
    var cursor = y + 11;
    page.text(title, x + 8, cursor, size: 5.8, color: _faint);
    cursor += 11;
    page.text(
      PdfText.truncate(name, width - 16, 9, bold: true),
      x + 8,
      cursor,
      size: 9,
      bold: true,
      color: _ink,
    );
    cursor += 11;
    for (final line in PdfText.wrap(address, width - 16, 7).take(2)) {
      page.text(line, x + 8, cursor, size: 7, color: _muted);
      cursor += 9;
    }
    cursor += 2;
    for (final row in rows) {
      if (row.$2.trim().isEmpty) continue;
      _labelled('${row.$1}: ', row.$2, x + 8, cursor);
      cursor += 9;
    }
  }

  // ── Items ─────────────────────────────────────────────────────────────────
  double _colX(int index) {
    var x = _margin;
    for (var i = 0; i < index; i++) {
      x += _itemCols[i];
    }
    return x;
  }

  void _itemsHeader() {
    const height = 20.0;
    page.rect(_margin, y, _contentW, height, _shade);
    _box(y, height);
    const labels = [
      'Sl',
      'Description of Goods',
      'HSN/SAC',
      'Quantity',
      'Rate',
      'Taxable Value',
      'CGST',
      'SGST',
      'Amount',
    ];
    for (var i = 0; i < labels.length; i++) {
      final x = _colX(i);
      if (i > 0) _vline(x, y, height);
      final label = i == 6 || i == 7
          ? '${labels[i]} ${totals.tax.halfLabel}'
          : labels[i];
      final width = _itemCols[i] - 8;
      final text = PdfText.truncate(label, width, 6.4, bold: true);
      if (i >= 3) {
        page.textRight(
          text,
          x + _itemCols[i] - 4,
          y + 13,
          size: 6.4,
          bold: true,
          color: _muted,
        );
      } else {
        page.text(text, x + 4, y + 13, size: 6.4, bold: true, color: _muted);
      }
    }
    y += height;
  }

  void _itemsTable() {
    _ensure(60);
    _itemsHeader();

    const rowH = 26.0;
    for (var i = 0; i < totals.lines.length; i++) {
      if (y + rowH > _bottomLimit) {
        _newPage();
        _itemsHeader();
      }
      _itemRow(i, totals.lines[i], rowH);
    }

    // A filler row so the table reads as a ruled ledger rather than stopping
    // mid-air, but only when there is room for it.
    if (y + 24 <= _bottomLimit) {
      _emptyRow(20);
    }

    _ensure(40);
    _totalsRows();
  }

  void _itemRow(int index, InvoiceLineTotals line, double height) {
    _box(y, height);
    for (var i = 1; i < _itemCols.length; i++) {
      _vline(_colX(i), y, height);
    }

    page.text(
      '${index + 1}',
      _colX(0) + 6,
      y + 12,
      size: 7,
      mono: true,
      color: _ink,
    );

    final descW = _itemCols[1] - 10;
    page.text(
      PdfText.truncate(line.line.name, descW, 7.6, bold: true),
      _colX(1) + 5,
      y + 12,
      size: 7.6,
      bold: true,
      color: _ink,
    );
    if (line.line.spec.trim().isNotEmpty) {
      page.text(
        PdfText.truncate(line.line.spec, descW, 6.2),
        _colX(1) + 5,
        y + 21,
        size: 6.2,
        color: _faint,
      );
    }

    page.text(
      line.line.hsn.isEmpty ? '—' : line.line.hsn,
      _colX(2) + 5,
      y + 12,
      size: 7,
      mono: true,
      color: _ink,
    );

    void number(int col, String value, {bool bold = false}) => page.textRight(
      value,
      _colX(col) + _itemCols[col] - 5,
      y + 12,
      size: 7,
      bold: bold,
      mono: true,
      color: _ink,
    );

    number(3, line.qtyLabel);
    number(4, line.rateText);
    number(5, line.taxableText);
    number(6, line.cgstText);
    number(7, line.sgstText);
    number(8, line.amountText, bold: true);
    y += height;
  }

  void _emptyRow(double height) {
    _box(y, height);
    for (var i = 1; i < _itemCols.length; i++) {
      _vline(_colX(i), y, height);
    }
    y += height;
  }

  void _totalsRows() {
    // Round Off — label right-aligned in the Taxable column, value in Amount.
    const roundH = 16.0;
    _box(y, roundH);
    _vline(_colX(5), y, roundH);
    _vline(_colX(8), y, roundH);
    page.textRight('Round Off', _colX(5) - 6, y + 11, size: 6.8, color: _muted);
    page.textRight(
      totals.roundOffText,
      _right - 5,
      y + 11,
      size: 7,
      mono: true,
      color: _ink,
    );
    y += roundH;

    const totalH = 20.0;
    page.rect(_margin, y, _contentW, totalH, _shade);
    _box(y, totalH);
    for (var i = 5; i < _itemCols.length; i++) {
      _vline(_colX(i), y, totalH);
    }
    page.textRight(
      'Total',
      _colX(5) - 6,
      y + 13,
      size: 8,
      bold: true,
      color: _ink,
    );
    void total(int col, String value) => page.textRight(
      value,
      _colX(col) + _itemCols[col] - 5,
      y + 13,
      size: 7.4,
      bold: true,
      mono: true,
      color: _ink,
    );
    total(5, totals.taxableTotalText);
    total(6, totals.cgstTotalText);
    total(7, totals.sgstTotalText);
    total(8, 'Rs. ${totals.grandTotalText}');
    y += totalH;
  }

  // ── Words bands ───────────────────────────────────────────────────────────
  void _wordsBand(String caption, String words, {String rightNote = ''}) {
    const height = 30.0;
    _ensure(height);
    _box(y, height);
    page.text(caption, _margin + 8, y + 11, size: 6, color: _faint);
    if (rightNote.isNotEmpty) {
      page.textRight(rightNote, _right - 8, y + 11, size: 6, color: _faint);
    }
    page.text(
      PdfText.truncate(words, _contentW - 16, 8, bold: true),
      _margin + 8,
      y + 23,
      size: 8,
      bold: true,
      color: _ink,
    );
    y += height;
  }

  // ── HSN summary ───────────────────────────────────────────────────────────
  double _hsnX(int index) {
    var x = _margin;
    for (var i = 0; i < index; i++) {
      x += _hsnCols[i];
    }
    return x;
  }

  void _hsnHeader() {
    const topH = 12.0;
    const bottomH = 12.0;
    const height = topH + bottomH;
    page.rect(_margin, y, _contentW, height, _shade);
    _box(y, height);

    // Level one: the two tax groups span their pair of columns.
    page.text(
      'HSN/SAC',
      _hsnX(0) + 5,
      y + 15,
      size: 6.2,
      bold: true,
      color: _muted,
    );
    page.textRight(
      'Taxable Value',
      _hsnX(1) + _hsnCols[1] - 5,
      y + 15,
      size: 6.2,
      bold: true,
      color: _muted,
    );
    page.textCenter(
      'Central Tax',
      _hsnX(2) + (_hsnCols[2] + _hsnCols[3]) / 2,
      y + 8,
      size: 6.2,
      bold: true,
      color: _muted,
    );
    page.textCenter(
      'State Tax',
      _hsnX(4) + (_hsnCols[4] + _hsnCols[5]) / 2,
      y + 8,
      size: 6.2,
      bold: true,
      color: _muted,
    );
    page.textRight(
      'Total Tax Amount',
      _right - 5,
      y + 15,
      size: 6.2,
      bold: true,
      color: _muted,
    );

    // Level two: Rate | Amount under each group.
    page.line(
      _hsnX(2),
      y + topH,
      _hsnX(6),
      y + topH,
      color: _rule,
      strokeWidth: 0.5,
    );
    page.textRight(
      'Rate',
      _hsnX(2) + _hsnCols[2] - 5,
      y + 21,
      size: 6,
      color: _muted,
    );
    page.textRight(
      'Amount',
      _hsnX(3) + _hsnCols[3] - 5,
      y + 21,
      size: 6,
      color: _muted,
    );
    page.textRight(
      'Rate',
      _hsnX(4) + _hsnCols[4] - 5,
      y + 21,
      size: 6,
      color: _muted,
    );
    page.textRight(
      'Amount',
      _hsnX(5) + _hsnCols[5] - 5,
      y + 21,
      size: 6,
      color: _muted,
    );

    for (var i = 1; i < _hsnCols.length; i++) {
      _vline(_hsnX(i), y, height);
    }
    y += height;
  }

  void _hsnTable() {
    _ensure(70);
    _hsnHeader();

    const rowH = 15.0;
    final rate = totals.tax.halfLabel;
    for (final row in totals.hsnSummary) {
      if (y + rowH > _bottomLimit) {
        _newPage();
        _hsnHeader();
      }
      _box(y, rowH);
      for (var i = 1; i < _hsnCols.length; i++) {
        _vline(_hsnX(i), y, rowH);
      }
      page.text(
        row.hsn,
        _hsnX(0) + 5,
        y + 10,
        size: 7,
        mono: true,
        color: _ink,
      );
      void cell(int col, String value, {bool mono = true}) => page.textRight(
        value,
        _hsnX(col) + _hsnCols[col] - 5,
        y + 10,
        size: 7,
        mono: mono,
        color: _ink,
      );
      cell(1, _money(row.taxableValue));
      cell(2, rate, mono: false);
      cell(3, _money(row.cgst));
      cell(4, rate, mono: false);
      cell(5, _money(row.sgst));
      cell(6, _money(row.totalTax));
      y += rowH;
    }

    const totalH = 16.0;
    _ensure(totalH);
    page.rect(_margin, y, _contentW, totalH, _shade);
    _box(y, totalH);
    for (var i = 1; i < _hsnCols.length; i++) {
      _vline(_hsnX(i), y, totalH);
    }
    page.text('Total', _hsnX(0) + 5, y + 11, size: 7, bold: true, color: _ink);
    void total(int col, String value) => page.textRight(
      value,
      _hsnX(col) + _hsnCols[col] - 5,
      y + 11,
      size: 7,
      bold: true,
      mono: true,
      color: _ink,
    );
    total(1, totals.taxableTotalText);
    total(3, totals.cgstTotalText);
    total(5, totals.sgstTotalText);
    total(6, totals.totalTaxText);
    y += totalH;
  }

  static String _money(double v) => formatIndian2(v);

  // ── Footer: bank + declaration | e-invoice + signatory ────────────────────
  void _footerRow() {
    final height = options.showDeclaration ? 126.0 : 100.0;
    _ensure(height);
    final splitX = _margin + _contentW * 0.56;
    _box(y, height);
    _vline(splitX, y, height);

    var cursor = y + 12;
    if (options.showBankDetails && profile.bankName.trim().isNotEmpty) {
      page.text(
        "COMPANY'S BANK DETAILS",
        _margin + 8,
        cursor,
        size: 5.8,
        color: _faint,
      );
      cursor += 11;
      for (final row in [
        ('Bank Name: ', profile.bankName),
        ('A/c No.: ', profile.accountNo),
        ('Branch & IFSC: ', profile.branchAndIfsc),
        ('UPI: ', profile.upiId),
      ]) {
        if (row.$2.trim().isEmpty) continue;
        _labelled(row.$1, row.$2, _margin + 8, cursor);
        cursor += 9.5;
      }
      cursor += 4;
    }

    if (options.showDeclaration && profile.declaration.trim().isNotEmpty) {
      page.text('DECLARATION', _margin + 8, cursor, size: 5.8, color: _faint);
      cursor += 10;
      final width = splitX - _margin - 16;
      for (final line in PdfText.wrap(
        profile.declaration,
        width,
        6.3,
      ).take(6)) {
        page.text(line, _margin + 8, cursor, size: 6.3, color: _muted);
        cursor += 8;
      }
    }

    // Right cell — e-Invoice registration, then the signatory block pinned to
    // the bottom right.
    var rightCursor = y + 12;
    if (options.showEInvoice) {
      page.text('E-INVOICE', splitX + 8, rightCursor, size: 5.8, color: _faint);
      rightCursor += 11;
      final info = bill?.eInvoice;
      if (info != null && info.isRegistered) {
        page.text('IRN', splitX + 8, rightCursor, size: 6, color: _faint);
        rightCursor += 8;
        final width = _right - splitX - 16;
        for (final line in _chunk(info.irn!, width, 6)) {
          page.text(
            line,
            splitX + 8,
            rightCursor,
            size: 6,
            mono: true,
            color: _ink,
          );
          rightCursor += 7.5;
        }
        if ((info.ackNo ?? '').isNotEmpty) {
          _labelled('Ack No.: ', info.ackNo!, splitX + 8, rightCursor);
          rightCursor += 9;
        }
        if (info.ackDate != null) {
          _labelled(
            'Ack Date: ',
            _date(info.ackDate!),
            splitX + 8,
            rightCursor,
          );
        }
      } else {
        // No IRP integration exists, so the document says so rather than
        // showing a registration number it does not have.
        page.text(
          'Not registered with the IRP',
          splitX + 8,
          rightCursor,
          size: 6.5,
          color: _faint,
        );
        rightCursor += 9;
        if (options.showUpiQr && profile.upiId.trim().isNotEmpty) {
          page.text(
            'UPI QR: pay to ${profile.upiId}',
            splitX + 8,
            rightCursor,
            size: 6.5,
            color: _faint,
          );
        }
      }
    }

    final signBase = y + height - 10;
    page.textRight(
      'for $sellerName',
      _right - 8,
      signBase - 46,
      size: 7.5,
      bold: true,
      color: _ink,
    );

    // The uploaded signature goes in the whitespace a hand-signed invoice
    // leaves between the company line and the rule — scaled to fit that gap
    // rather than to its own size, so a big scan cannot push the rule off.
    final sign = signature;
    if (sign != null && signatureSlot >= 0) {
      const boxW = 130.0;
      const boxH = 30.0;
      final scale = (boxW / sign.width) < (boxH / sign.height)
          ? boxW / sign.width
          : boxH / sign.height;
      final w = sign.width * scale;
      final h = sign.height * scale;
      page.image(
        signatureSlot,
        _right - 8 - w,
        signBase - 40 + (boxH - h),
        w,
        h,
      );
    }

    page.line(
      _right - 150,
      signBase - 8,
      _right - 8,
      signBase - 8,
      color: _faint,
      strokeWidth: 0.5,
    );
    page.textRight(
      'Authorised Signatory',
      _right - 8,
      signBase,
      size: 6.4,
      color: _faint,
    );
    y += height;
  }

  /// Splits a long unbroken token (an IRN hash) into lines that fit [width].
  List<String> _chunk(String value, double width, double size) {
    final perLine = (width / (0.6 * size)).floor().clamp(8, 200);
    final lines = <String>[];
    for (var i = 0; i < value.length; i += perLine) {
      lines.add(value.substring(i, (i + perLine).clamp(0, value.length)));
    }
    return lines.take(3).toList();
  }

  void _footNote() {
    _ensure(16);
    page.textCenter(
      '${profile.footerNote} · Generated by Godaam',
      _pageW / 2,
      y + 11,
      size: 6.2,
      color: _faint,
    );
    y += 16;
  }

  void _pageNumbers(String generatedLine) {
    for (var i = 0; i < doc.pages.length; i++) {
      final p = doc.pages[i];
      final base = _pageH - 10;
      p.text(generatedLine, _margin, base, size: 5.8, color: _faint);
      p.textRight(
        'Page ${i + 1} of ${doc.pages.length}',
        _right,
        base,
        size: 5.8,
        color: _faint,
      );
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

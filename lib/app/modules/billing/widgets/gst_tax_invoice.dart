import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/modules/billing/models/amount_in_words.dart';
import 'package:shc_stock/app/modules/billing/models/bill_model.dart';
import 'package:shc_stock/app/modules/billing/models/billing_profile.dart';
import 'package:shc_stock/app/modules/billing/models/invoice_totals.dart';
import 'package:shc_stock/app/modules/billing/widgets/invoice_paper.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/shared/models/order_payment.dart';
import 'package:shc_stock/app/shared/widgets/brand_mark.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The GST tax invoice, on screen.
//
// A ruled A4 sheet in the Indian tax-invoice convention. Every figure comes
// from [InvoiceTotals] — the same object `pdf_invoice_writer.dart` renders —
// so the screen and the printout cannot disagree.
//
// The five [BillOptions] add and remove whole blocks live, and carry straight
// through to the PDF.
// ─────────────────────────────────────────────────────────────────────────────
class GstTaxInvoice extends StatelessWidget {
  final BillingProfile profile;
  final String sellerName;
  final SalesOrder order;
  final ClientModel? client;
  final BillModel? bill;
  final InvoiceTotals totals;
  final BillOptions options;
  final String invoiceNo;
  final DateTime invoiceDate;

  const GstTaxInvoice({
    super.key,
    required this.profile,
    required this.sellerName,
    required this.order,
    required this.totals,
    required this.options,
    required this.invoiceNo,
    required this.invoiceDate,
    this.client,
    this.bill,
  });

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

  static String formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${_months[d.month - 1]}-${d.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: InvoicePaper.width,
      color: InvoicePaper.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _caption(),
          _headerRow(),
          _partyRow(),
          _itemsTable(),
          _wordsBand(
            'Amount Chargeable (in words)',
            amountInWords(totals.grandTotal),
            rightNote: 'E. & O.E',
          ),
          if (options.showHsnSummary) ...[
            _hsnTable(),
            _wordsBand('Tax Amount (in words)', amountInWords(totals.totalTax)),
          ],
          _footerRow(),
          _footNote(),
        ],
      ),
    );
  }

  // ── TAX INVOICE caption ───────────────────────────────────────────────────
  Widget _caption() => InvoiceBox(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Center(
        child: Text(
          'T A X   I N V O I C E',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w500,
            color: InvoicePaper.muted,
            fontFamily: InvoicePaper.body,
          ),
        ),
      ),
    ),
  );

  // ── Seller | document grid ────────────────────────────────────────────────
  Widget _headerRow() {
    final contact = [
      profile.phone,
      profile.email,
    ].where((v) => v.trim().isNotEmpty).join('  ·  ');

    return InvoiceBox(
      bottom: false,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 52,
              child: InvoiceCell(
                right: true,
                bottom: true,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The one place the brand accent is allowed on the paper.
                    const Padding(
                      padding: EdgeInsets.only(right: 12, top: 2),
                      child: BrandMark(height: 40),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sellerName, style: InvoicePaper.value(15)),
                          const SizedBox(height: 3),
                          for (final line in [
                            profile.addressLine1,
                            profile.addressLine2,
                          ])
                            if (line.trim().isNotEmpty)
                              Text(line, style: InvoicePaper.text(10)),
                          const SizedBox(height: 5),
                          LabelledValue(
                            label: 'GSTIN/UIN',
                            value: profile.gstin,
                          ),
                          if (profile.stateName.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'State Name: ${profile.stateName}'
                                '${profile.stateCode.isEmpty ? '' : ', Code: ${profile.stateCode}'}',
                                style: InvoicePaper.text(10),
                              ),
                            ),
                          if (contact.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                contact,
                                style: InvoicePaper.text(10),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(flex: 48, child: _documentGrid()),
          ],
        ),
      ),
    );
  }

  Widget _documentGrid() {
    final rows = <List<(String, String, bool)>>[
      [
        ('Invoice No.', invoiceNo, true),
        ('Dated', formatDate(invoiceDate), true),
      ],
      [
        ("Buyer's Order No.", order.soNumber, true),
        (
          'Mode/Terms of Payment',
          order.paymentType.label.isEmpty ? '—' : order.paymentType.label,
          false,
        ),
      ],
      [
        (
          'Dispatched through',
          order.despatchedThrough.isEmpty ? '—' : order.despatchedThrough,
          false,
        ),
        ('Vehicle No.', '—', false),
      ],
      [
        (
          'Destination',
          order.destination.isEmpty ? '—' : order.destination,
          false,
        ),
        ('Reverse Charge', 'No', false),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < row.length; i++)
                  Expanded(
                    child: InvoiceCell(
                      right: i == 0,
                      bottom: true,
                      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
                      child: CaptionValue(
                        caption: row[i].$1,
                        value: row[i].$2,
                        mono: row[i].$3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Buyer | consignee ─────────────────────────────────────────────────────
  Widget _partyRow() {
    final billAddress = order.clientAddress.trim().isNotEmpty
        ? order.clientAddress
        : (client?.address ?? '');

    final shipParts = [
      client?.shipAddr1 ?? '',
      client?.shipAddr2 ?? '',
      [
        client?.shipCity ?? '',
        client?.shipPin ?? '',
      ].where((p) => p.trim().isNotEmpty).join(' '),
      client?.shipState ?? '',
    ].where((p) => p.trim().isNotEmpty).join(', ');

    return InvoiceBox(
      bottom: false,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: InvoiceCell(
                right: true,
                bottom: true,
                child: _party(
                  title: 'BUYER (BILL TO)',
                  name: order.client,
                  address: billAddress,
                  rows: [
                    (
                      'GSTIN/UIN',
                      order.buyerGstin.isNotEmpty
                          ? order.buyerGstin
                          : (client?.gstin ?? ''),
                    ),
                    (
                      'PAN',
                      order.pan.isNotEmpty ? order.pan : (client?.pan ?? ''),
                    ),
                    ('Place of Supply', client?.state ?? ''),
                  ],
                ),
              ),
            ),
            Expanded(
              child: InvoiceCell(
                bottom: true,
                child: _party(
                  title: 'CONSIGNEE (SHIP TO)',
                  name: order.client,
                  // "Same as registered" is the common case on a client
                  // record, and then the bill-to address is the ship-to one.
                  address: shipParts.isNotEmpty ? shipParts : billAddress,
                  rows: [
                    ('Delivery Note', order.soNumber),
                    ('Destination', order.destination),
                    ('State Name', client?.shipState ?? client?.state ?? ''),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _party({
    required String title,
    required String name,
    required String address,
    required List<(String, String)> rows,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: InvoicePaper.sectionCaption()),
        const SizedBox(height: 5),
        Text(name, style: InvoicePaper.value(12.5)),
        if (address.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(address, style: InvoicePaper.text(10)),
          ),
        const SizedBox(height: 4),
        for (final row in rows) LabelledValue(label: row.$1, value: row.$2),
      ],
    );
  }

  // ── Items ─────────────────────────────────────────────────────────────────
  /// Column widths of the items table, as flex units.
  static const _itemFlex = [4, 27, 10, 10, 8, 11, 9, 9, 12];

  Widget _itemsTable() {
    return InvoiceBox(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _itemsHeader(),
          for (var i = 0; i < totals.lines.length; i++)
            _itemRow(i, totals.lines[i]),
          // A filler row so the table reads as a ruled ledger rather than
          // stopping mid-air.
          _itemsFiller(),
          _roundOffRow(),
          _totalRow(),
        ],
      ),
    );
  }

  Widget _headerCell(
    String label,
    int flex, {
    bool right = true,
    bool end = false,
  }) => Expanded(
    flex: flex,
    child: InvoiceCell(
      right: right,
      bottom: true,
      background: InvoicePaper.shade,
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      align: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      child: Text(
        label,
        textAlign: end ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: 8.5,
          height: 1.25,
          letterSpacing: 0.2,
          fontWeight: FontWeight.w700,
          color: InvoicePaper.muted,
          fontFamily: InvoicePaper.body,
        ),
      ),
    ),
  );

  Widget _itemsHeader() {
    final rate = totals.tax.halfLabel;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _headerCell('Sl', _itemFlex[0]),
          _headerCell('Description of Goods', _itemFlex[1]),
          _headerCell('HSN/SAC', _itemFlex[2]),
          _headerCell('Quantity', _itemFlex[3], end: true),
          _headerCell('Rate', _itemFlex[4], end: true),
          _headerCell('Taxable Value', _itemFlex[5], end: true),
          _headerCell('CGST $rate', _itemFlex[6], end: true),
          _headerCell('SGST $rate', _itemFlex[7], end: true),
          _headerCell('Amount', _itemFlex[8], right: false, end: true),
        ],
      ),
    );
  }

  Widget _numberCell(
    String value,
    int flex, {
    bool right = true,
    bool bold = false,
  }) => Expanded(
    flex: flex,
    child: InvoiceCell(
      right: right,
      bottom: true,
      padding: const EdgeInsets.fromLTRB(6, 9, 6, 9),
      align: CrossAxisAlignment.end,
      child: Text(
        value,
        textAlign: TextAlign.right,
        style: InvoicePaper.number(
          10.5,
          bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
  );

  Widget _itemRow(int index, InvoiceLineTotals line) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: _itemFlex[0],
            child: InvoiceCell(
              right: true,
              bottom: true,
              padding: const EdgeInsets.fromLTRB(6, 9, 6, 9),
              child: Text('${index + 1}', style: InvoicePaper.number(10.5)),
            ),
          ),
          Expanded(
            flex: _itemFlex[1],
            child: InvoiceCell(
              right: true,
              bottom: true,
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(line.line.name, style: InvoicePaper.value(11)),
                  if (line.line.spec.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        line.line.spec,
                        style: InvoicePaper.caption(9),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: _itemFlex[2],
            child: InvoiceCell(
              right: true,
              bottom: true,
              padding: const EdgeInsets.fromLTRB(8, 9, 6, 9),
              child: Text(
                line.line.hsn.isEmpty ? '—' : line.line.hsn,
                style: InvoicePaper.number(10.5),
              ),
            ),
          ),
          _numberCell(line.qtyLabel, _itemFlex[3]),
          _numberCell(line.rateText, _itemFlex[4]),
          _numberCell(line.taxableText, _itemFlex[5]),
          _numberCell(line.cgstText, _itemFlex[6]),
          _numberCell(line.sgstText, _itemFlex[7]),
          _numberCell(line.amountText, _itemFlex[8], right: false, bold: true),
        ],
      ),
    );
  }

  Widget _itemsFiller() => SizedBox(
    height: 34,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _itemFlex.length; i++)
          Expanded(
            flex: _itemFlex[i],
            child: InvoiceCell(
              right: i != _itemFlex.length - 1,
              bottom: true,
              padding: EdgeInsets.zero,
              child: const SizedBox.shrink(),
            ),
          ),
      ],
    ),
  );

  /// Round-off and Total both leave the left of the table blank and start at
  /// the Taxable Value column, the way a ledger's totals do.
  Widget _blankSpan(int flex, {Color? background}) => Expanded(
    flex: flex,
    child: InvoiceCell(
      bottom: true,
      right: true,
      background: background,
      padding: EdgeInsets.zero,
      child: const SizedBox.shrink(),
    ),
  );

  Widget _roundOffRow() {
    const leadFlex = 4 + 27 + 10 + 10 + 8;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: leadFlex,
            child: InvoiceCell(
              right: true,
              bottom: true,
              padding: const EdgeInsets.fromLTRB(6, 7, 10, 7),
              align: CrossAxisAlignment.end,
              child: Text(
                'Round Off',
                style: InvoicePaper.text(
                  10,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          _blankSpan(_itemFlex[5]),
          _blankSpan(_itemFlex[6]),
          _blankSpan(_itemFlex[7]),
          _numberCell(totals.roundOffText, _itemFlex[8], right: false),
        ],
      ),
    );
  }

  Widget _totalRow() {
    const leadFlex = 4 + 27 + 10 + 10 + 8;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: leadFlex,
            child: InvoiceCell(
              right: true,
              bottom: true,
              background: InvoicePaper.shade,
              padding: const EdgeInsets.fromLTRB(6, 9, 10, 9),
              align: CrossAxisAlignment.end,
              child: Text('Total', style: InvoicePaper.value(11.5)),
            ),
          ),
          _totalCell(totals.taxableTotalText, _itemFlex[5]),
          _totalCell(totals.cgstTotalText, _itemFlex[6]),
          _totalCell(totals.sgstTotalText, _itemFlex[7]),
          Expanded(
            flex: _itemFlex[8],
            child: InvoiceCell(
              bottom: true,
              background: InvoicePaper.shade,
              padding: const EdgeInsets.fromLTRB(6, 9, 6, 9),
              align: CrossAxisAlignment.end,
              child: Text(
                '₹ ${totals.grandTotalText}',
                textAlign: TextAlign.right,
                style: InvoicePaper.number(11.5, FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalCell(String value, int flex) => Expanded(
    flex: flex,
    child: InvoiceCell(
      right: true,
      bottom: true,
      background: InvoicePaper.shade,
      padding: const EdgeInsets.fromLTRB(6, 9, 6, 9),
      align: CrossAxisAlignment.end,
      child: Text(
        value,
        textAlign: TextAlign.right,
        style: InvoicePaper.number(10.5, FontWeight.w700),
      ),
    ),
  );

  // ── Words bands ───────────────────────────────────────────────────────────
  Widget _wordsBand(String caption, String words, {String rightNote = ''}) {
    return InvoiceBox(
      bottom: false,
      child: InvoiceCell(
        bottom: true,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Text(caption, style: InvoicePaper.caption(9))),
                if (rightNote.isNotEmpty)
                  Text(rightNote, style: InvoicePaper.caption(9)),
              ],
            ),
            const SizedBox(height: 3),
            Text(words, style: InvoicePaper.value(11.5)),
          ],
        ),
      ),
    );
  }

  // ── HSN-wise tax summary ──────────────────────────────────────────────────
  static const _hsnFlex = [17, 18, 11, 15, 11, 15, 13];

  Widget _hsnTable() {
    final rate = totals.tax.halfLabel;
    return InvoiceBox(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hsnHeader(),
          for (final row in totals.hsnSummary)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: _hsnFlex[0],
                    child: InvoiceCell(
                      right: true,
                      bottom: true,
                      padding: const EdgeInsets.fromLTRB(10, 7, 6, 7),
                      child: Text(row.hsn, style: InvoicePaper.number(10.5)),
                    ),
                  ),
                  _numberCell(_money(row.taxableValue), _hsnFlex[1]),
                  _rateCell(rate, _hsnFlex[2]),
                  _numberCell(_money(row.cgst), _hsnFlex[3]),
                  _rateCell(rate, _hsnFlex[4]),
                  _numberCell(_money(row.sgst), _hsnFlex[5]),
                  _numberCell(_money(row.totalTax), _hsnFlex[6], right: false),
                ],
              ),
            ),
          _hsnTotalRow(),
        ],
      ),
    );
  }

  Widget _rateCell(String rate, int flex) => Expanded(
    flex: flex,
    child: InvoiceCell(
      right: true,
      bottom: true,
      padding: const EdgeInsets.fromLTRB(6, 7, 6, 7),
      align: CrossAxisAlignment.end,
      child: Text(
        rate,
        textAlign: TextAlign.right,
        style: InvoicePaper.text(10.5).copyWith(color: InvoicePaper.ink),
      ),
    ),
  );

  /// Two-level header: the tax groups span their Rate/Amount pair.
  Widget _hsnHeader() {
    Widget group(
      String label,
      int rateFlex,
      int amountFlex, {
      bool last = false,
    }) {
      return Expanded(
        flex: rateFlex + amountFlex,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InvoiceCell(
              right: !last,
              bottom: true,
              background: InvoicePaper.shade,
              padding: const EdgeInsets.symmetric(vertical: 5),
              align: CrossAxisAlignment.center,
              child: Text(label, style: _hsnHeadStyle),
            ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: rateFlex,
                    child: InvoiceCell(
                      right: true,
                      bottom: true,
                      background: InvoicePaper.shade,
                      padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
                      align: CrossAxisAlignment.end,
                      child: Text('Rate', style: _hsnHeadStyle),
                    ),
                  ),
                  Expanded(
                    flex: amountFlex,
                    child: InvoiceCell(
                      right: !last,
                      bottom: true,
                      background: InvoicePaper.shade,
                      padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
                      align: CrossAxisAlignment.end,
                      child: Text('Amount', style: _hsnHeadStyle),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget tall(
      String label,
      int flex, {
      bool end = false,
      bool last = false,
    }) => Expanded(
      flex: flex,
      child: InvoiceCell(
        right: !last,
        bottom: true,
        background: InvoicePaper.shade,
        padding: const EdgeInsets.fromLTRB(8, 16, 6, 16),
        align: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        child: Text(
          label,
          textAlign: end ? TextAlign.right : TextAlign.left,
          style: _hsnHeadStyle,
        ),
      ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tall('HSN/SAC', _hsnFlex[0]),
          tall('Taxable Value', _hsnFlex[1], end: true),
          group('Central Tax', _hsnFlex[2], _hsnFlex[3]),
          group('State Tax', _hsnFlex[4], _hsnFlex[5]),
          tall('Total Tax Amount', _hsnFlex[6], end: true, last: true),
        ],
      ),
    );
  }

  static final _hsnHeadStyle = TextStyle(
    fontSize: 8.5,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: InvoicePaper.muted,
    fontFamily: InvoicePaper.body,
  );

  Widget _hsnTotalRow() => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: _hsnFlex[0],
          child: InvoiceCell(
            right: true,
            bottom: true,
            background: InvoicePaper.shade,
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Text('Total', style: InvoicePaper.value(11)),
          ),
        ),
        _totalCell(totals.taxableTotalText, _hsnFlex[1]),
        _blankSpan(_hsnFlex[2], background: InvoicePaper.shade),
        _totalCell(totals.cgstTotalText, _hsnFlex[3]),
        _blankSpan(_hsnFlex[4], background: InvoicePaper.shade),
        _totalCell(totals.sgstTotalText, _hsnFlex[5]),
        Expanded(
          flex: _hsnFlex[6],
          child: InvoiceCell(
            bottom: true,
            background: InvoicePaper.shade,
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
            align: CrossAxisAlignment.end,
            child: Text(
              totals.totalTaxText,
              textAlign: TextAlign.right,
              style: InvoicePaper.number(10.5, FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );

  static String _money(double v) => formatIndian2(v);

  // ── Bank + declaration | e-invoice + signatory ────────────────────────────
  Widget _footerRow() {
    final showBank =
        options.showBankDetails && profile.bankName.trim().isNotEmpty;
    final showDeclaration =
        options.showDeclaration && profile.declaration.trim().isNotEmpty;

    return InvoiceBox(
      bottom: false,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 56,
              child: InvoiceCell(
                right: true,
                bottom: true,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showBank) ...[
                      Text(
                        "COMPANY'S BANK DETAILS",
                        style: InvoicePaper.sectionCaption(),
                      ),
                      const SizedBox(height: 4),
                      LabelledValue(
                        label: 'Bank Name',
                        value: profile.bankName,
                        mono: false,
                      ),
                      LabelledValue(label: 'A/c No.', value: profile.accountNo),
                      LabelledValue(
                        label: 'Branch & IFSC',
                        value: profile.branchAndIfsc,
                      ),
                      LabelledValue(label: 'UPI', value: profile.upiId),
                      const SizedBox(height: 10),
                    ],
                    if (showDeclaration) ...[
                      Text('DECLARATION', style: InvoicePaper.sectionCaption()),
                      const SizedBox(height: 4),
                      Text(profile.declaration, style: InvoicePaper.text(9.5)),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 44,
              child: InvoiceCell(
                bottom: true,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (options.showEInvoice || options.showUpiQr)
                      _eInvoiceBlock(),
                    const SizedBox(height: 22),
                    _signatory(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eInvoiceBlock() {
    final info = bill?.eInvoice;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (options.showUpiQr) ...[_qrPlaceholder(), const SizedBox(width: 12)],
        if (options.showEInvoice)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('E-INVOICE', style: InvoicePaper.sectionCaption()),
                const SizedBox(height: 4),
                if (info != null && info.isRegistered) ...[
                  Text('IRN', style: InvoicePaper.caption(9)),
                  Text(info.irn!, style: InvoicePaper.number(8.5)),
                  LabelledValue(label: 'Ack No.', value: info.ackNo ?? ''),
                  if (info.ackDate != null)
                    LabelledValue(
                      label: 'Ack Date',
                      value: formatDate(info.ackDate!),
                    ),
                ] else
                  // No IRP integration exists in this system, so the document
                  // says so rather than showing a registration it never got.
                  Text(
                    'Not registered with the IRP',
                    style: InvoicePaper.text(9.5),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _qrPlaceholder() => Container(
    width: 62,
    height: 62,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border.all(color: InvoicePaper.faint, width: 0.8),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.qr_code_2_rounded,
          size: 26,
          color: InvoicePaper.faint,
        ),
        const SizedBox(height: 2),
        Text('UPI QR', style: InvoicePaper.caption(7)),
      ],
    ),
  );

  Widget _signatory() => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: Text('for $sellerName', style: InvoicePaper.value(11)),
      ),
      const SizedBox(height: 6),
      // The uploaded signature, or the whitespace a pen would use. Both
      // reserve the same height so the rule sits in the same place either way.
      SizedBox(height: 34, child: _signatureImage()),
      const SizedBox(height: 4),
      Container(width: 170, height: 0.7, color: InvoicePaper.faint),
      const SizedBox(height: 4),
      Text('Authorised Signatory', style: InvoicePaper.caption(9)),
    ],
  );

  Widget _signatureImage() {
    final encoded = profile.signatureBase64;
    if (encoded == null || encoded.isEmpty) return const SizedBox.shrink();
    try {
      return Align(
        alignment: Alignment.bottomRight,
        child: Image.memory(
          base64Decode(encoded),
          // Keyed so a test can assert the signature specifically, rather than
          // matching whichever Image happens to be on the page.
          key: const ValueKey('invoice-signature'),
          height: 34,
          fit: BoxFit.contain,
          // A signature that will not decode must leave the blank space a
          // pen can still use, not a broken-image box on an invoice.
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _footNote() => InvoiceBox(
    child: InvoiceCell(
      padding: const EdgeInsets.symmetric(vertical: 7),
      align: CrossAxisAlignment.center,
      child: Text(
        '${profile.footerNote} · Generated by Godaam',
        style: InvoicePaper.caption(9),
      ),
    ),
  );
}

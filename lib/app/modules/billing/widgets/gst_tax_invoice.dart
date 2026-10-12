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

part 'gst_tax_invoice_part1.dart';

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
  static const _itemFlex = [4, 25, 10, 12, 8, 11, 9, 9, 12];

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
          // Inter-state: one IGST column across the CGST + SGST space.
          if (totals.interState)
            _headerCell(
              totals.igstHeader,
              _itemFlex[6] + _itemFlex[7],
              end: true,
            )
          else ...[
            _headerCell(totals.cgstHeader, _itemFlex[6], end: true),
            _headerCell(totals.sgstHeader, _itemFlex[7], end: true),
          ],
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
      // One line, shrunk to fit: a "12 (pcs)" quantity used to wrap in its
      // narrow column, and IntrinsicHeight had sized the row for one line, so
      // the second line overflowed the bottom of the row.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          value,
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.right,
          style: InvoicePaper.number(
            10.5,
            bold ? FontWeight.w700 : FontWeight.w500,
          ),
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
          if (totals.interState)
            _numberCell(line.igstText, _itemFlex[6] + _itemFlex[7])
          else ...[
            _numberCell(line.cgstText, _itemFlex[6]),
            _numberCell(line.sgstText, _itemFlex[7]),
          ],
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
          if (totals.interState)
            _totalCell(totals.igstTotalText, _itemFlex[6] + _itemFlex[7])
          else ...[
            _totalCell(totals.cgstTotalText, _itemFlex[6]),
            _totalCell(totals.sgstTotalText, _itemFlex[7]),
          ],
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
}

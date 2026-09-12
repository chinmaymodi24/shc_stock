import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/billing/models/amount_in_words.dart';
import 'package:shc_stock/app/modules/billing/models/billing_profile.dart';
import 'package:shc_stock/app/modules/billing/models/invoice_totals.dart';
import 'package:shc_stock/app/modules/billing/widgets/gst_tax_invoice.dart';
import 'package:shc_stock/app/modules/billing/widgets/invoice_paper.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/shared/widgets/brand_mark.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The cash memo — the same bill, laid out for the counter.
//
// An A5 letterhead rather than a ruled A4 form: no HSN column, no consignee,
// no e-invoice block, no bank details. What it keeps is the money, and it
// keeps it to the rupee — [InvoiceTotals.grandTotal] here is the same figure
// the tax invoice prints, so a buyer handed the memo and a buyer handed the
// invoice owe the same amount.
//
// That is the one place this departs from the approved mockup, which showed a
// pre-tax grand total under a Discount row. There is no discount on a sale in
// this system, and a memo that quietly dropped the GST would disagree with the
// invoice raised against the same sale.
// ─────────────────────────────────────────────────────────────────────────────
class CashMemo extends StatelessWidget {
  final BillingProfile profile;
  final String sellerName;
  final SalesOrder order;
  final ClientModel? client;
  final InvoiceTotals totals;
  final BillOptions options;
  final String invoiceNo;
  final DateTime invoiceDate;

  const CashMemo({
    super.key,
    required this.profile,
    required this.sellerName,
    required this.order,
    required this.totals,
    required this.options,
    required this.invoiceNo,
    required this.invoiceDate,
    this.client,
  });

  /// Column widths of the particulars table, as flex units.
  static const _cols = [5, 42, 15, 16, 22];

  static const _pad = EdgeInsets.symmetric(horizontal: 22);

  /// The terms line along the bottom, behind the Declaration toggle.
  static const memoTerms =
      'Goods once sold will not be taken back. Please retain this memo for '
      'any warranty claim.';

  String get _mobile {
    final phone = (client?.phone ?? '').trim();
    if (phone.isNotEmpty) return phone;
    return (client?.contactPhone ?? '').trim();
  }

  String get _address {
    final onOrder = order.clientAddress.trim();
    if (onOrder.isNotEmpty) return onOrder;
    return (client?.address ?? '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: InvoicePaper.memoWidth,
      color: InvoicePaper.paper,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(padding: _pad, child: _letterhead()),
          const SizedBox(height: 16),
          Padding(
            padding: _pad,
            child: Container(height: 0.8, color: InvoicePaper.rule),
          ),
          const SizedBox(height: 14),
          Padding(padding: _pad, child: _partyRow()),
          const SizedBox(height: 18),
          Padding(padding: _pad, child: _items()),
          const SizedBox(height: 14),
          Padding(padding: _pad, child: _totalsBlock()),
          const SizedBox(height: 18),
          Padding(padding: _pad, child: _words()),
          const SizedBox(height: 26),
          Padding(padding: _pad, child: _footer()),
        ],
      ),
    );
  }

  // ── Letterhead ────────────────────────────────────────────────────────────
  Widget _letterhead() {
    final contact = [
      profile.addressLine1,
      profile.phone,
    ].where((v) => v.trim().isNotEmpty).join(', ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 11, top: 1),
          child: BrandMark(height: 34),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(sellerName, style: InvoicePaper.value(14)),
              if (contact.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(contact, style: InvoicePaper.text(9.5)),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Bounded, so a long series number trims itself rather than pushing
        // the seller's name off the sheet.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _headBlockWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // The memo's title carries the accent, the way the printed memo
              // book it replaces does. Everything else stays black on white.
              Text(
                'CASH MEMO',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange,
                  fontFamily: InvoicePaper.body,
                ),
              ),
              const SizedBox(height: 7),
              _headLine('No.', invoiceNo),
              const SizedBox(height: 2),
              _headLine('Date', GstTaxInvoice.formatDate(invoiceDate)),
            ],
          ),
        ),
      ],
    );
  }

  /// How much of the letterhead's right edge the No./Date block may claim.
  static const double _headBlockWidth = 170;

  Widget _headLine(String label, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: InvoicePaper.caption(9)),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: InvoicePaper.number(10, FontWeight.w700),
        ),
      ),
    ],
  );

  // ── Buyer ─────────────────────────────────────────────────────────────────
  Widget _partyRow() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('NAME', style: InvoicePaper.sectionCaption()),
            const SizedBox(height: 5),
            Text(order.client, style: InvoicePaper.value(12)),
            if (_address.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(_address, style: InvoicePaper.text(9.5)),
              ),
          ],
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        flex: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('MOBILE', style: InvoicePaper.sectionCaption()),
            const SizedBox(height: 5),
            Text(
              _mobile.isEmpty ? '—' : _mobile,
              style: InvoicePaper.number(11, FontWeight.w600),
            ),
          ],
        ),
      ),
    ],
  );

  // ── Particulars ───────────────────────────────────────────────────────────
  Widget _items() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      _itemsHead(),
      Container(height: 0.7, color: InvoicePaper.rule),
      for (var i = 0; i < totals.lines.length; i++)
        _itemRow(i, totals.lines[i]),
      Container(height: 0.7, color: InvoicePaper.rule),
    ],
  );

  Widget _itemsHead() => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        _head('Sl', _cols[0]),
        _head('Particulars', _cols[1]),
        _head('Qty', _cols[2], end: true),
        _head('Rate', _cols[3], end: true),
        _head('Amount', _cols[4], end: true),
      ],
    ),
  );

  Widget _head(String label, int flex, {bool end = false}) => Expanded(
    flex: flex,
    child: Text(
      label,
      textAlign: end ? TextAlign.right : TextAlign.left,
      style: TextStyle(
        fontSize: 8.5,
        letterSpacing: 0.3,
        fontWeight: FontWeight.w700,
        color: InvoicePaper.faint,
        fontFamily: InvoicePaper.body,
      ),
    ),
  );

  Widget _itemRow(int index, InvoiceLineTotals line) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: _cols[0],
          child: Text('${index + 1}', style: InvoicePaper.number(10)),
        ),
        Expanded(
          flex: _cols[1],
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(line.line.name, style: InvoicePaper.value(10.5)),
          ),
        ),
        _cell(line.qtyLabel, _cols[2]),
        _cell(line.rateText, _cols[3]),
        _cell(line.taxableText, _cols[4]),
      ],
    ),
  );

  Widget _cell(String value, int flex) => Expanded(
    flex: flex,
    child: Text(
      value,
      textAlign: TextAlign.right,
      style: InvoicePaper.number(10.5),
    ),
  );

  // ── Money ─────────────────────────────────────────────────────────────────
  /// The right-hand stack. The memo prints no per-line tax, so the GST arrives
  /// as one line here — and the grand total lands on the invoice's own figure.
  Widget _totalsBlock() => Row(
    children: [
      const Spacer(),
      SizedBox(
        width: 236,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _moneyRow('Sub Total', totals.taxableTotalText),
            _moneyRow(
              'GST ${ratePercent(totals.tax.gstPercent)}',
              totals.totalTaxText,
            ),
            _moneyRow('Round Off', totals.roundOffText),
            const SizedBox(height: 8),
            Container(height: 0.7, color: InvoicePaper.rule),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: Text('Grand Total', style: InvoicePaper.value(12)),
                ),
                Text(
                  '₹${totals.grandTotalText}',
                  style: InvoicePaper.number(15, FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  Widget _moneyRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        Expanded(child: Text(label, style: InvoicePaper.text(10))),
        Text(value, style: InvoicePaper.number(10.5)),
      ],
    ),
  );

  /// "18%" / "12.5%" — the whole GST rate, since the memo does not split it.
  static String ratePercent(double percent) {
    final text = percent == percent.roundToDouble()
        ? percent.toStringAsFixed(0)
        : percent.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
    return '$text%';
  }

  // ── Words ─────────────────────────────────────────────────────────────────
  Widget _words() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
    color: InvoicePaper.shade,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('IN WORDS', style: InvoicePaper.sectionCaption()),
        const SizedBox(height: 4),
        Text(
          amountInWords(totals.grandTotal, currency: 'Rupees'),
          style: InvoicePaper.value(11),
        ),
      ],
    ),
  );

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _footer() => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: options.showDeclaration
            ? Text(memoTerms, style: InvoicePaper.text(9))
            : const SizedBox.shrink(),
      ),
      const SizedBox(width: 20),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 26),
          Container(width: 108, height: 0.7, color: InvoicePaper.faint),
          const SizedBox(height: 4),
          Text('Signature', style: InvoicePaper.caption(9)),
        ],
      ),
    ],
  );
}

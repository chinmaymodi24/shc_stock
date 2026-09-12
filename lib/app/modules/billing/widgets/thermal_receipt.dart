import 'package:flutter/material.dart';
import 'package:shc_stock/app/modules/billing/models/bill_model.dart';
import 'package:shc_stock/app/modules/billing/models/billing_profile.dart';
import 'package:shc_stock/app/modules/billing/models/invoice_totals.dart';
import 'package:shc_stock/app/modules/billing/widgets/invoice_paper.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/shared/widgets/brand_mark.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The 80 mm thermal receipt.
//
// The same bill again, and the same figures — what changes is that there are
// 72 mm of printable paper and no ruled boxes, because an ESC/POS head draws
// dashes and text and little else. So: one column, monospaced throughout,
// sections separated by dashed rules, and every amount right-aligned to the
// same edge.
//
// Nothing here is a summary of the invoice. [InvoiceTotals] is the same object
// the A4 sheet renders, so the roll and the sheet cannot disagree.
// ─────────────────────────────────────────────────────────────────────────────
class ThermalReceipt extends StatelessWidget {
  final BillingProfile profile;
  final String sellerName;
  final SalesOrder order;
  final BillModel? bill;
  final InvoiceTotals totals;
  final BillOptions options;
  final String invoiceNo;
  final DateTime invoiceDate;

  const ThermalReceipt({
    super.key,
    required this.profile,
    required this.sellerName,
    required this.order,
    required this.totals,
    required this.options,
    required this.invoiceNo,
    required this.invoiceDate,
    this.bill,
  });

  /// The line the receipt ends on, behind the Declaration toggle.
  static const returnsNote = 'Goods once sold not returnable';

  /// dd/MM/yy — a roll has no room for a spelled-out month.
  static String shortDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${(d.year % 100).toString().padLeft(2, '0')}';

  String get _cashier {
    final generated = (bill?.generatedBy ?? '').trim();
    if (generated.isNotEmpty) return generated;
    return order.modifiedBy;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: InvoicePaper.thermalWidth,
      color: InvoicePaper.paper,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _head(),
          const SizedBox(height: 12),
          const PaperDashedRule(),
          const SizedBox(height: 9),
          Center(
            child: Text(
              'TAX INVOICE',
              style: _mono(9.5, FontWeight.w700).copyWith(letterSpacing: 1.1),
            ),
          ),
          const SizedBox(height: 9),
          const PaperDashedRule(),
          const SizedBox(height: 9),
          _meta(),
          const SizedBox(height: 9),
          const PaperDashedRule(),
          const SizedBox(height: 8),
          _itemsHead(),
          const SizedBox(height: 6),
          const PaperDashedRule(),
          for (final line in totals.lines) _itemBlock(line),
          const PaperDashedRule(),
          const SizedBox(height: 8),
          _taxBlock(),
          const SizedBox(height: 8),
          const PaperDashedRule(),
          const SizedBox(height: 9),
          _totalRow(),
          const SizedBox(height: 9),
          const PaperDashedRule(),
          const SizedBox(height: 9),
          _payBlock(),
          const SizedBox(height: 12),
          _footer(),
        ],
      ),
    );
  }

  static TextStyle _mono(double size, [FontWeight weight = FontWeight.w500]) =>
      TextStyle(
        fontSize: size,
        height: 1.45,
        fontWeight: weight,
        color: InvoicePaper.ink,
        fontFamily: InvoicePaper.mono,
      );

  static TextStyle _faint(double size) => TextStyle(
    fontSize: size,
    height: 1.45,
    color: InvoicePaper.muted,
    fontFamily: InvoicePaper.mono,
  );

  // ── Masthead ──────────────────────────────────────────────────────────────
  Widget _head() {
    final lines = [
      profile.addressLine1,
      profile.phone,
      if (profile.gstin.trim().isNotEmpty) 'GSTIN ${profile.gstin}',
    ].where((v) => v.trim().isNotEmpty);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandMark(height: 26),
        const SizedBox(height: 8),
        Text(
          sellerName,
          textAlign: TextAlign.center,
          style: _mono(11, FontWeight.w700),
        ),
        const SizedBox(height: 3),
        for (final line in lines)
          Text(line, textAlign: TextAlign.center, style: _faint(7.5)),
      ],
    );
  }

  // ── Bill No / Date / Party / Cashier ──────────────────────────────────────
  Widget _meta() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _pair('Bill No', invoiceNo),
      _pair('Date', shortDate(invoiceDate)),
      _pair('Party', order.client),
      _pair('Cashier', _cashier),
    ],
  );

  /// Label left, value hard right — the whole receipt is built from this.
  Widget _pair(String label, String value, {TextStyle? valueStyle}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: _faint(8)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value.isEmpty ? '—' : value,
          textAlign: TextAlign.right,
          style: valueStyle ?? _mono(8),
        ),
      ),
    ],
  );

  // ── Items ─────────────────────────────────────────────────────────────────
  Widget _itemsHead() => Row(
    children: [
      Expanded(flex: 40, child: Text('ITEM', style: _faint(7.5))),
      Expanded(
        flex: 16,
        child: Text('QTY', textAlign: TextAlign.right, style: _faint(7.5)),
      ),
      Expanded(
        flex: 20,
        child: Text('RATE', textAlign: TextAlign.right, style: _faint(7.5)),
      ),
      Expanded(
        flex: 24,
        child: Text('AMT', textAlign: TextAlign.right, style: _faint(7.5)),
      ),
    ],
  );

  /// Two lines per item: the description gets the full width, the figures get
  /// the line beneath it. Nothing on an 80 mm roll fits a name and four
  /// columns side by side.
  Widget _itemBlock(InvoiceLineTotals line) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(line.line.name, style: _mono(8.5)),
        const SizedBox(height: 1),
        Row(
          children: [
            Expanded(
              flex: 40,
              child: Text(
                options.showHsnSummary ? line.line.hsn : '',
                style: _faint(7),
              ),
            ),
            Expanded(
              flex: 16,
              child: Text(
                line.qtyLabel,
                textAlign: TextAlign.right,
                style: _mono(8),
              ),
            ),
            Expanded(
              flex: 20,
              child: Text(
                line.rateText,
                textAlign: TextAlign.right,
                style: _mono(8),
              ),
            ),
            Expanded(
              flex: 24,
              child: Text(
                line.taxableText,
                textAlign: TextAlign.right,
                style: _mono(8, FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  // ── Money ─────────────────────────────────────────────────────────────────
  Widget _taxBlock() {
    final half = totals.tax.halfLabel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _pair('Taxable', totals.taxableTotalText),
        _pair('CGST $half', totals.cgstTotalText),
        _pair('SGST $half', totals.sgstTotalText),
        _pair('Round Off', totals.roundOffText),
      ],
    );
  }

  Widget _totalRow() => Row(
    children: [
      Text('TOTAL', style: _mono(10.5, FontWeight.w700)),
      Expanded(
        child: Text(
          '₹${totals.grandTotalText}',
          textAlign: TextAlign.right,
          style: _mono(12.5, FontWeight.w700),
        ),
      ),
    ],
  );

  Widget _payBlock() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // The sale records how much is settled, not by which instrument — so
      // this prints the payment's standing rather than inventing "UPI".
      _pair('Payment', order.paymentStatus.label),
      _pair('Items / Qty', '${totals.itemCount} / ${_qty(totals.totalQty)}'),
    ],
  );

  static String _qty(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  Widget _footer() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('Thank you, visit again', style: _faint(8)),
      if (options.showDeclaration)
        Text(returnsNote, textAlign: TextAlign.center, style: _faint(8)),
      const SizedBox(height: 6),
      Text('— Godaam —', style: _faint(7.5)),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/shared/models/order_payment.dart';

/// Read-only "Sale Details" side panel — opened from the list page's View
/// icon. Falls back to "—" for any field a given order doesn't carry
/// (older/seed orders predate the full-detail fields).
class SaleDetailsDialog extends StatelessWidget {
  final SalesOrder order;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SaleDetailsDialog({
    super.key,
    required this.order,
    this.onEdit,
    this.onDelete,
  });

  String _fmtDate(DateTime? d) =>
      d == null ? '—' : DateFormat('yyyy-MM-dd').format(d);
  String _fmtAmt(double v) => '₹${NumberFormat('#,##,##0', 'en_IN').format(v)}';

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fmt = NumberFormat('#,##,##0', 'en_IN');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      alignment: Alignment.centerRight,
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          // Full-width on phones — a fixed 407px side panel would overflow
          // (and mostly clip off-screen) on anything narrower than that.
          width: MediaQuery.of(context).size.width < 480
              ? MediaQuery.of(context).size.width
              : 407,
          height: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 24,
                offset: const Offset(-6, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sale Details',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: Get.back,
                      borderRadius: BorderRadius.circular(8),
                      child: Icon(
                        Icons.close_rounded,
                        color: colors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.divider),

              // ── Body ──────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('CLIENT NAME', colors),
                      const SizedBox(height: 4),
                      Text(
                        order.client,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (order.clientAddress.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          order.clientAddress,
                          style: TextStyle(
                            fontSize: 12.5,
                            // Was AppColors.primaryPurple — a fixed dark
                            // indigo that's nearly invisible against the
                            // dark theme's surface. Muted secondary text
                            // reads correctly in both themes.
                            color: colors.textSecondary,
                            fontFamily: 'Poppins',
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _PairRow(
                        'BUYER GSTIN/UIN',
                        order.buyerGstin,
                        'PAN NO.',
                        order.pan,
                        colors,
                      ),
                      const SizedBox(height: 16),
                      _PairRow(
                        'INVOICE NO.',
                        order.invoiceNo.isEmpty
                            ? order.soNumber
                            : order.invoiceNo,
                        'INVOICE DATE',
                        _fmtDate(order.invoiceDate ?? order.date),
                        colors,
                      ),
                      const SizedBox(height: 16),
                      _PairRow(
                        'DISPATCHED THROUGH',
                        order.despatchedThrough,
                        'DESTINATION',
                        order.destination,
                        colors,
                      ),
                      const SizedBox(height: 16),
                      _PairRow(
                        'EXPECTED DELIVERY',
                        _fmtDate(order.expectedDelivery),
                        'ORDER PAID',
                        order.paymentType.displayLabel,
                        colors,
                      ),
                      if (order.paidAmount > 0) ...[
                        const SizedBox(height: 16),
                        _Label('AMOUNT PAID', colors),
                        const SizedBox(height: 4),
                        _Value(_fmtAmt(order.paidAmount), colors),
                      ],
                      const SizedBox(height: 20),

                      // ── Items ──────────────────────────────────────
                      _Label('ITEMS', colors),
                      const SizedBox(height: 8),
                      if (order.items.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.inputFill,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.border),
                          ),
                          child: Text(
                            'No item detail recorded for this order.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colors.textHint,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        )
                      else
                        ...order.items.map(
                          (item) => Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'HSN ${item.hsn.isEmpty ? '—' : item.hsn} · ${item.qty.toStringAsFixed(0)} ${item.unit} · '
                                  '₹${fmt.format(item.rate)}/unit',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: colors.textHint,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // ── Totals ─────────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.inputFill,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            _TotalLine(
                              'Taxable Value',
                              _fmtAmt(order.taxableValue),
                              colors,
                            ),
                            const SizedBox(height: 8),
                            _TotalLine(
                              'CGST (9%)',
                              _fmtAmt(order.cgst),
                              colors,
                            ),
                            const SizedBox(height: 8),
                            _TotalLine(
                              'SGST (9%)',
                              _fmtAmt(order.sgst),
                              colors,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Divider(height: 1, color: colors.divider),
                            ),
                            _TotalLine(
                              'Grand Total',
                              _fmtAmt(order.amount),
                              colors,
                              bold: true,
                              valueColor: AppColors.primaryOrange,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Modified By ────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.inputFill,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('MODIFIED BY', colors),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 15,
                                  backgroundColor: AppColors.primaryPurple,
                                  child: const Text(
                                    'CM',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.modifiedBy,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textPrimary,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    Text(
                                      order.modifiedAt == null
                                          ? '—'
                                          : DateFormat(
                                              'MMM d, yyyy, h:mm a',
                                            ).format(order.modifiedAt!),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: colors.textHint,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Footer: Edit / Delete ──────────────────────────────
              Divider(height: 1, color: colors.divider),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onEdit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.inputFill,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared small pieces
// ─────────────────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  final AppThemeColors colors;
  const _Label(this.text, this.colors);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: colors.textHint,
        fontFamily: 'Poppins',
        letterSpacing: 0.5,
      ),
    );
  }
}

class _Value extends StatelessWidget {
  final String text;
  final AppThemeColors colors;
  const _Value(this.text, this.colors);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
        fontFamily: 'Poppins',
      ),
    );
  }
}

class _PairRow extends StatelessWidget {
  final String label1;
  final String value1;
  final String label2;
  final String value2;
  final AppThemeColors colors;
  const _PairRow(
    this.label1,
    this.value1,
    this.label2,
    this.value2,
    this.colors,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Label(label1, colors),
              const SizedBox(height: 4),
              _Value(value1.isEmpty ? '—' : value1, colors),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Label(label2, colors),
              const SizedBox(height: 4),
              _Value(value2.isEmpty ? '—' : value2, colors),
            ],
          ),
        ),
      ],
    );
  }
}

class _TotalLine extends StatelessWidget {
  final String label;
  final String value;
  final AppThemeColors colors;
  final bool bold;
  final Color? valueColor;
  const _TotalLine(
    this.label,
    this.value,
    this.colors, {
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 14 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: bold ? colors.textPrimary : colors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 15 : 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? colors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

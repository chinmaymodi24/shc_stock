import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/modules/sales/controllers/add_sale_controller.dart';
import 'package:shc_stock/app/modules/sales/models/sale_payment.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/shared/widgets/form_fields.dart';
import 'package:shc_stock/app/shared/widgets/section_card.dart';

/// Rupees with up to two decimals — what a payment amount box accepts.
final List<TextInputFormatter> kPaymentAmountFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
];

// ─────────────────────────────────────────────────────────────────────────────
// "Payments" section of the Add / Edit Sale form — web and mobile.
//
// A sale can be paid in several goes, so payments are rows like the item rows:
// "Add Payment" adds one for whatever is still due. Each saved row shows up in
// the Transactions list under the sale's SO number. State lives in
// AddSaleController; this file only draws it (no setState).
// ─────────────────────────────────────────────────────────────────────────────
class SalePaymentsSection extends StatelessWidget {
  final AddSaleController controller;
  final AppThemeColors colors;
  final int number;
  final bool mobile;

  const SalePaymentsSection({
    super.key,
    required this.controller,
    required this.colors,
    required this.number,
    this.mobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppNumberedSectionCard(
      mobile: mobile,
      colors: colors,
      number: number,
      title: 'Payments',
      trailing: AppAddRowPill(
        mobile: mobile,
        colors: colors,
        label: mobile ? 'Add' : 'Add Payment',
        onTap: controller.addPayment,
      ),
      child: Obx(() {
        // Read the totals inside the Obx so a changed item or amount redraws
        // the summary.
        controller.items.length;
        final rows = controller.payments.toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (rows.isEmpty)
              _EmptyNote(colors: colors)
            else if (mobile)
              for (var i = 0; i < rows.length; i++)
                _MobilePaymentCard(
                  key: ValueKey(rows[i].id),
                  index: i,
                  row: rows[i],
                  controller: controller,
                  colors: colors,
                )
            else ...[
              _WebHeader(colors: colors),
              for (var i = 0; i < rows.length; i++)
                _WebPaymentRow(
                  key: ValueKey(rows[i].id),
                  index: i,
                  row: rows[i],
                  controller: controller,
                  colors: colors,
                ),
            ],
            const SizedBox(height: 12),
            _Summary(controller: controller, colors: colors, mobile: mobile),
          ],
        );
      }),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final AppThemeColors colors;
  const _EmptyNote({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colors.rowEven,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'No payment recorded yet — the sale will be saved as Pending. '
        'Use "Add Payment" for each amount the client pays.',
        style: TextStyle(
          fontSize: 12.5,
          color: colors.textSecondary,
          fontFamily: brandFontFamily,
        ),
      ),
    );
  }
}

// ── Web: one table row per payment ──────────────────────────────────────────
const double _wIndexWidth = 36;
const double _wDateWidth = 150;
const double _wAmountWidth = 150;
const double _wModeWidth = 170;
const double _wDelWidth = 36;

class _WebHeader extends StatelessWidget {
  final AppThemeColors colors;
  const _WebHeader({required this.colors});

  @override
  Widget build(BuildContext context) {
    TextStyle s() => TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: colors.textSecondary,
      fontFamily: brandFontFamily,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: colors.tableHeaderBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _wIndexWidth,
            child: Text('#', style: s()),
          ),
          SizedBox(
            width: _wDateWidth,
            child: Text('Date', style: s()),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: _wAmountWidth,
            child: Text('Amount (₹)', style: s()),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: _wModeWidth,
            child: Text('Mode', style: s()),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('Notes', style: s())),
          const SizedBox(width: _wDelWidth),
        ],
      ),
    );
  }
}

class _WebPaymentRow extends StatelessWidget {
  final int index;
  final SalePaymentRow row;
  final AddSaleController controller;
  final AppThemeColors colors;

  const _WebPaymentRow({
    super.key,
    required this.index,
    required this.row,
    required this.controller,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 0, 0),
      child: Row(
        children: [
          SizedBox(
            width: _wIndexWidth,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                fontFamily: brandFontFamily,
              ),
            ),
          ),
          SizedBox(
            width: _wDateWidth,
            child: Obx(
              () => AppDateBox(
                date: row.date.value,
                colors: colors,
                onTap: () => controller.pickPaymentDate(context, row),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: _wAmountWidth,
            child: AppTextBox(
              controller: row.amountCtrl,
              hint: 'e.g. 5000',
              colors: colors,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: kPaymentAmountFormatters,
              onChanged: (_) => controller.paymentTyped(row),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: _wModeWidth,
            child: Obx(
              () => AppDropBox(
                hint: 'Mode',
                value: row.mode.value.isEmpty ? null : row.mode.value,
                items: kPaymentModes,
                colors: colors,
                onChanged: (v) => controller.setPaymentMode(row, v),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppTextBox(
              controller: row.notesCtrl,
              hint: 'Optional — cheque no., UTR, who paid…',
              colors: colors,
            ),
          ),
          SizedBox(
            width: _wDelWidth,
            child: IconButton(
              tooltip: 'Remove payment',
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppColors.danger,
              ),
              onPressed: () => controller.removePayment(index),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile: one card per payment ────────────────────────────────────────────
class _MobilePaymentCard extends StatelessWidget {
  final int index;
  final SalePaymentRow row;
  final AddSaleController controller;
  final AppThemeColors colors;

  const _MobilePaymentCard({
    super.key,
    required this.index,
    required this.row,
    required this.controller,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(appColors.radius),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Payment ${index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: brandFontFamily,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove payment',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppColors.danger,
                ),
                onPressed: () => controller.removePayment(index),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppField(
                        mobile: true,
                        label: 'Date',
                        colors: colors,
                        child: Obx(
                          () => AppDateBox(
                            mobile: true,
                            date: row.date.value,
                            colors: colors,
                            onTap: () =>
                                controller.pickPaymentDate(context, row),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppField(
                        mobile: true,
                        label: 'Amount (₹)',
                        colors: colors,
                        child: AppTextBox(
                          controller: row.amountCtrl,
                          hint: 'e.g. 5000',
                          colors: colors,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: kPaymentAmountFormatters,
                          onChanged: (_) => controller.paymentTyped(row),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppField(
                  mobile: true,
                  label: 'Mode',
                  colors: colors,
                  child: Obx(
                    () => AppDropBox(
                      mobile: true,
                      hint: 'Select mode',
                      value: row.mode.value.isEmpty ? null : row.mode.value,
                      items: kPaymentModes,
                      colors: colors,
                      onChanged: (v) => controller.setPaymentMode(row, v),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AppField(
                  mobile: true,
                  label: 'Notes',
                  colors: colors,
                  child: AppTextBox(
                    controller: row.notesCtrl,
                    hint: 'Optional — cheque no., UTR…',
                    colors: colors,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Paid / Due summary under the rows ───────────────────────────────────────
class _Summary extends StatelessWidget {
  final AddSaleController controller;
  final AppThemeColors colors;
  final bool mobile;

  const _Summary({
    required this.controller,
    required this.colors,
    required this.mobile,
  });

  @override
  Widget build(BuildContext context) {
    final status = controller.paymentStatusPreview;
    final over = controller.paidAmount > controller.grandTotal + 1;
    Widget figure(String label, String value, {Color? color}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: colors.textSecondary,
            fontFamily: brandFontFamily,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color ?? colors.textPrimary,
            fontFamily: brandFontFamily,
          ),
        ),
      ],
    );

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: status.color,
          fontFamily: brandFontFamily,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.rowEven,
        borderRadius: BorderRadius.circular(appColors.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: figure(
                  'Grand Total',
                  formatRupees(controller.grandTotal),
                ),
              ),
              Expanded(
                child: figure(
                  'Paid',
                  formatRupees(controller.paidAmount),
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: figure(
                  'Due',
                  formatRupees(controller.balanceDue),
                  color: controller.balanceDue > 0 ? AppColors.warning : null,
                ),
              ),
              if (!mobile) chip,
            ],
          ),
          if (mobile) ...[
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: chip),
          ],
          if (over) ...[
            const SizedBox(height: 8),
            Text(
              'The payments add up to more than the grand total.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.danger,
                fontFamily: brandFontFamily,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

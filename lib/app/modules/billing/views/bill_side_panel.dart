import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/billing/controllers/bill_controller.dart';
import 'package:shc_stock/app/modules/billing/models/bill_format.dart';
import 'package:shc_stock/app/modules/billing/models/bill_model.dart';
import 'package:shc_stock/app/modules/billing/views/bill_view.dart';
import 'package:shc_stock/app/modules/billing/widgets/gst_tax_invoice.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The bill screen's side panel: status, what appears on the document, the ways
// to send it, and what has happened to it so far.
// ─────────────────────────────────────────────────────────────────────────────
class BillSidePanel extends GetView<BillController> {
  /// The wide layout scrolls the panel independently; the narrow one stacks it
  /// under the paper inside the page's own scroll view.
  final bool scrollable;

  const BillSidePanel({super.key, this.scrollable = true});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() => BillProfileNotice(profile: controller.profile)),
        Obx(() => _generateCta(context)),
        const _StatusCard(),
        const SizedBox(height: 12),
        const _OptionsCard(),
        const SizedBox(height: 12),
        const _SendCard(),
        const SizedBox(height: 12),
        const _TrailCard(),
      ],
    );

    if (!scrollable) return content;
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(left: BorderSide(color: colors.divider)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }

  /// Until the bill is generated there is no invoice number and no trail, so
  /// the panel leads with the one action that matters.
  Widget _generateCta(BuildContext context) {
    if (controller.isGenerated) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Obx(
        () => ElevatedButton.icon(
          onPressed: controller.isBusy.value ? null : controller.generate,
          icon: const Icon(
            Icons.receipt_long_rounded,
            size: 17,
            color: Colors.white,
          ),
          label: Text(
            controller.isBusy.value ? 'Generating…' : 'Generate Bill',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: brandFontFamily,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            disabledBackgroundColor: AppColors.primaryOrange.withValues(
              alpha: 0.6,
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(appColors.radiusSm),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared card chrome ───────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _Card({required this.title, required this.child, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(appColors.radius),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              fontFamily: brandFontFamily,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.4,
                color: colors.textHint,
                fontFamily: brandFontFamily,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final Widget value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          // The value is laid out first at its natural size and the label
          // takes what is left — in a 296px panel "e-Invoice · Not registered"
          // does not fit at a large text scale, and the status is the half
          // worth keeping whole.
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                fontFamily: brandFontFamily,
              ),
            ),
          ),
          const SizedBox(width: 8),
          value,
        ],
      ),
    );
  }
}

// ── 1. Bill status ───────────────────────────────────────────────────────────
class _StatusCard extends GetView<BillController> {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _Card(
      title: 'Bill status',
      child: Obx(() {
        final order = controller.order.value;
        final bill = controller.bill.value;
        final paid = order?.paymentStatus.label ?? '—';
        return Column(
          children: [
            _Row(
              label: 'Invoice',
              value: BillStatusPill(
                label: bill == null ? 'Not generated' : 'Generated',
                color: bill == null ? colors.textHint : colors.success,
              ),
            ),
            _Row(
              label: 'Payment',
              value: BillStatusPill(
                label: paid,
                color: order?.paymentStatus.color ?? colors.textHint,
              ),
            ),
            _Row(
              label: 'e-Invoice',
              value: BillStatusPill(
                label: bill?.eInvoice.isRegistered == true
                    ? 'IRN received'
                    : 'Not registered',
                color: bill?.eInvoice.isRegistered == true
                    ? colors.accent
                    : colors.textHint,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _Row(
                label: 'Amount',
                value: Text(
                  billAmountLabel(controller.totals.grandTotal),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: brandFontFamily,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── 2. What appears on the bill ──────────────────────────────────────────────
//
// The switches belong to the bill, not to a layout, so all five stay on the
// card whichever format is showing. The ones the current format cannot render
// — a cash memo has no HSN summary, no bank block and no IRN; a 72 mm roll
// has room for neither bank details nor a QR — are greyed rather than left
// live, so no toggle here ever looks like it did nothing.
class _OptionsCard extends GetView<BillController> {
  const _OptionsCard();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final format = controller.format.value;
      final o = controller.options.value;
      final dimmed = BillOption.values.where((x) => !format.applies(x)).length;
      return _Card(
        title: 'What appears on the bill',
        subtitle: dimmed == 0
            ? 'Applies to this invoice only. Set the defaults in Settings.'
            : 'Applies to this invoice only. Greyed rows do not reach the '
                  '${format.label.toLowerCase()}.',
        child: Column(
          children: [
            for (var i = 0; i < BillOption.values.length; i++)
              _Toggle(
                label: BillOption.values[i].label,
                value: BillOption.values[i].read(o),
                enabled: format.applies(BillOption.values[i]),
                onChanged: (v) =>
                    controller.setOption(BillOption.values[i].write(o, v)),
                last: i == BillOption.values.length - 1,
              ),
          ],
        ),
      );
    });
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;

  /// False when the switch has no effect on the format currently showing.
  /// It keeps its stored value — it is just not this document's control.
  final bool enabled;

  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
    this.last = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final track = enabled ? AppColors.primaryOrange : colors.border;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: enabled ? colors.textPrimary : colors.textHint,
                fontFamily: brandFontFamily,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.78,
            child: Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              thumbColor: const WidgetStatePropertyAll(Colors.white),
              activeTrackColor: track,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: colors.border,
              trackOutlineColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? track
                    : colors.border,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3. Send to client ────────────────────────────────────────────────────────
class _SendCard extends GetView<BillController> {
  const _SendCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _Card(
      title: 'Send to client',
      child: Obx(
        () => Column(
          children: [
            _SendRow(
              icon: Icons.chat_outlined,
              tint: colors.success,
              label: 'WhatsApp',
              detail: controller.buyerPhone.isEmpty
                  ? 'No number on record'
                  : controller.buyerPhone,
              onTap: controller.sendOnWhatsApp,
            ),
            _SendRow(
              icon: Icons.mail_outline_rounded,
              tint: colors.accent,
              label: 'Email PDF',
              detail: controller.buyerEmail.isEmpty
                  ? 'No address on record'
                  : controller.buyerEmail,
              onTap: controller.emailPdf,
            ),
            _SendRow(
              icon: Icons.link_rounded,
              tint: colors.textSecondary,
              label: 'Copy payment link',
              detail: controller.paymentLink.isEmpty
                  ? 'Add a UPI id in Settings'
                  : 'UPI · pays the invoice total',
              onTap: controller.copyPaymentLink,
              last: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SendRow extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label;
  final String detail;
  final VoidCallback onTap;
  final bool last;

  const _SendRow({
    required this.icon,
    required this.tint,
    required this.label,
    required this.detail,
    required this.onTap,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(appColors.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(appColors.radiusSm),
            border: Border.all(color: colors.divider),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: tint),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        fontFamily: brandFontFamily,
                      ),
                    ),
                    Text(
                      detail,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: colors.textHint,
                        fontFamily: brandFontFamily,
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

// ── 4. Trail ─────────────────────────────────────────────────────────────────
class _TrailCard extends GetView<BillController> {
  const _TrailCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _Card(
      title: 'Trail',
      child: Obx(() {
        final events = controller.bill.value?.events ?? const <BillEvent>[];
        if (events.isEmpty) {
          return Text(
            controller.isGenerated
                ? 'Nothing recorded yet.'
                : 'The trail starts when the bill is generated.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: colors.textHint,
              fontFamily: brandFontFamily,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < events.length; i++)
              _TrailRow(event: events[i], last: i == events.length - 1),
          ],
        );
      }),
    );
  }
}

class _TrailRow extends StatelessWidget {
  final BillEvent event;
  final bool last;

  const _TrailRow({required this.event, required this.last});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: billEventColor(context, event),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    fontFamily: brandFontFamily,
                  ),
                ),
                Text(
                  '${event.actor} · '
                  '${GstTaxInvoice.formatDate(event.at)}, ${_time(event.at)}'
                  '${event.note.isEmpty ? '' : ' · ${event.note}'}',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: colors.textHint,
                    fontFamily: brandFontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _time(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$hour:${d.minute.toString().padLeft(2, '0')} '
        '${d.hour < 12 ? 'AM' : 'PM'}';
  }
}

/// Route helper so the Sale module does not have to know the panel's imports.
void openBillSettings() => Get.toNamed(AppRoutes.settings);

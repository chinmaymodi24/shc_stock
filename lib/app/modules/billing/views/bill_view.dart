import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/modules/billing/controllers/bill_controller.dart';
import 'package:shc_stock/app/modules/billing/models/bill_format.dart';
import 'package:shc_stock/app/modules/billing/models/bill_model.dart';
import 'package:shc_stock/app/modules/billing/models/billing_profile.dart';
import 'package:shc_stock/app/modules/billing/views/bill_side_panel.dart';
import 'package:shc_stock/app/modules/billing/widgets/cash_memo.dart';
import 'package:shc_stock/app/modules/billing/widgets/gst_tax_invoice.dart';
import 'package:shc_stock/app/modules/billing/widgets/invoice_paper.dart';
import 'package:shc_stock/app/modules/billing/widgets/thermal_receipt.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The bill screen.
//
// Three regions: a toolbar, the document itself on the page background, and a
// side panel of controls. The document is the only part that prints — the
// toolbar and the panel exist to act on it, and the PDF writer never draws
// them.
// ─────────────────────────────────────────────────────────────────────────────
class BillView extends GetView<BillController> {
  const BillView({super.key});

  static const double _panelWidth = 296;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const AppLoadingIndicator(
              label: 'Opening the bill...',
              padding: 96,
            );
          }
          if (controller.error.value.isNotEmpty ||
              controller.order.value == null) {
            return _errorState(context, colors);
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              // Below this the document and a 296px panel cannot both fit, so
              // the panel moves under the paper instead of squeezing it.
              final wide = constraints.maxWidth >= 1180;
              return Column(
                children: [
                  const BillTopBar(),
                  Expanded(
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _documentPane(colors)),
                              const SizedBox(
                                width: _panelWidth,
                                child: BillSidePanel(),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                _paper(colors),
                                const Padding(
                                  padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                                  child: BillSidePanel(scrollable: false),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              );
            },
          );
        }),
      ),
    );
  }

  Widget _documentPane(AppThemeColors colors) =>
      SingleChildScrollView(child: _paper(colors));

  /// The sheet, centred on the page background with a soft drop shadow so it
  /// reads as paper lying on a desk.
  ///
  /// The document is a fixed A4 width — it is a legal form, so it is never
  /// reflowed or shrunk to fit. On anything narrower than the sheet the pane
  /// scrolls sideways instead, which is how every invoice viewer on a phone
  /// behaves.
  Widget _paper(AppThemeColors colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Obx(() {
          final sheet = _sheetWidth(controller.format.value);
          final fits = constraints.maxWidth >= sheet + 32;
          final body = _sheet(colors, centred: fits);
          if (fits) return body;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: body,
          );
        });
      },
    );
  }

  static double _sheetWidth(BillFormat format) => switch (format) {
    BillFormat.taxInvoice => InvoicePaper.width,
    BillFormat.cashMemo => InvoicePaper.memoWidth,
    BillFormat.thermal => InvoicePaper.thermalWidth,
  };

  Widget _sheet(AppThemeColors colors, {required bool centred}) {
    return Container(
      width: centred ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      color: colors.background,
      child: Center(
        child: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 26,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _document(),
              ),
              if (controller.format.value == BillFormat.thermal)
                _rollNote(colors),
            ],
          ),
        ),
      ),
    );
  }

  /// The document itself, in whichever layout the toolbar has selected. All
  /// three read the same totals, so switching never changes a figure.
  Widget _document() {
    final order = controller.order.value!;
    switch (controller.format.value) {
      case BillFormat.taxInvoice:
        return GstTaxInvoice(
          profile: controller.profile,
          sellerName: controller.sellerName,
          order: order,
          client: controller.client.value,
          bill: controller.bill.value,
          totals: controller.totals,
          options: controller.options.value,
          invoiceNo: controller.invoiceNo,
          invoiceDate: controller.invoiceDate,
        );
      case BillFormat.cashMemo:
        return CashMemo(
          profile: controller.profile,
          sellerName: controller.sellerName,
          order: order,
          client: controller.client.value,
          totals: controller.totals,
          options: controller.options.value,
          invoiceNo: controller.invoiceNo,
          invoiceDate: controller.invoiceDate,
        );
      case BillFormat.thermal:
        return ThermalReceipt(
          profile: controller.profile,
          sellerName: controller.sellerName,
          order: order,
          bill: controller.bill.value,
          totals: controller.totals,
          options: controller.options.value,
          invoiceNo: controller.invoiceNo,
          invoiceDate: controller.invoiceDate,
        );
    }
  }

  /// The receipt is 302 px on screen because it is 80 mm on paper — small
  /// enough that it reads as a mistake unless the page says why.
  Widget _rollNote(AppThemeColors colors) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: SizedBox(
      width: 260,
      child: Text(
        '80 mm roll width. Prints on any ESC/POS thermal printer over USB, '
        'LAN or Bluetooth.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          height: 1.45,
          color: colors.textHint,
          fontFamily: brandFontFamily,
        ),
      ),
    ),
  );

  Widget _errorState(BuildContext context, AppThemeColors colors) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 34, color: colors.textHint),
          const SizedBox(height: 14),
          Text(
            controller.error.value.isEmpty
                ? 'That sale could not be found.'
                : controller.error.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              fontFamily: brandFontFamily,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: Get.back,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(appColors.radiusSm),
              ),
            ),
            child: Text(
              'Back to Sale',
              style: TextStyle(
                fontSize: 12.5,
                color: colors.textPrimary,
                fontFamily: brandFontFamily,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Toolbar — back, what this document is, and the three things you do with it.
// ─────────────────────────────────────────────────────────────────────────────
class BillTopBar extends GetView<BillController> {
  const BillTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Below this the labelled buttons and the format chip cannot share a
        // line with the invoice number, so the actions go icon-only and the
        // chip — which only names what the document already says — is dropped.
        final wide = constraints.maxWidth >= 720;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(bottom: BorderSide(color: colors.divider)),
          ),
          child: Obx(
            () => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _bar(context, colors, wide: wide),
                // Three labelled formats cannot share a line with the invoice
                // number on a handset, so they drop to their own row rather
                // than disappearing — and that row scrolls, because three
                // labels at a large text scale still outrun a narrow phone.
                if (!wide) ...[
                  const SizedBox(height: 10),
                  const SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: BillFormatSwitcher(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bar(
    BuildContext context,
    AppThemeColors colors, {
    required bool wide,
  }) {
    final order = controller.order.value;
    return Row(
      children: [
        InkWell(
          onTap: Get.back,
          borderRadius: BorderRadius.circular(appColors.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_rounded,
                  size: 17,
                  color: colors.textSecondary,
                ),
                if (wide) ...[
                  const SizedBox(width: 6),
                  Text(
                    'Sale',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                      fontFamily: brandFontFamily,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(width: wide ? 12 : 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.invoiceNo,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: brandFontFamily,
                ),
              ),
              Text(
                '${order?.client ?? ''} · '
                '${GstTaxInvoice.formatDate(controller.invoiceDate)}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textHint,
                  fontFamily: brandFontFamily,
                ),
              ),
            ],
          ),
        ),
        if (wide) ...[
          const SizedBox(width: 16),
          // The switcher takes the whole gap between the invoice number and
          // the actions — it is the only part of the bar that grows with the
          // text scale, so it gets the slack rather than competing with a
          // Spacer for it. It scrolls only once even that is not enough,
          // because a toolbar that overflows is worse than one that scrolls.
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: BillFormatSwitcher(),
              ),
            ),
          ),
        ] else
          const Spacer(),
        _BillAction(
          icon: Icons.share_outlined,
          label: 'WhatsApp',
          showLabel: wide,
          onTap: controller.sendOnWhatsApp,
        ),
        SizedBox(width: wide ? 8 : 6),
        _BillAction(
          icon: Icons.picture_as_pdf_outlined,
          label: 'PDF',
          showLabel: wide,
          onTap: controller.downloadPdf,
        ),
        SizedBox(width: wide ? 8 : 6),
        _BillAction(
          icon: Icons.print_outlined,
          label: 'Print',
          showLabel: wide,
          filled: true,
          onTap: controller.printBill,
        ),
      ],
    );
  }
}

class _BillAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  /// Off on a handset, where three labelled buttons cannot share a line with
  /// the invoice number. The label survives as the tooltip.
  final bool showLabel;

  const _BillAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(appColors.radiusSm),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: showLabel ? 13 : 10,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: filled ? AppColors.primaryOrange : colors.surface,
            borderRadius: BorderRadius.circular(appColors.radiusSm),
            border: Border.all(
              color: filled ? AppColors.primaryOrange : colors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: filled ? Colors.white : colors.textSecondary,
              ),
              if (showLabel) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: filled ? Colors.white : colors.textPrimary,
                    fontFamily: brandFontFamily,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// The format switcher.
//
// One bill, three layouts. This picks which is on screen and — because the
// toolbar's PDF and Print act on whatever is showing — which one is exported.
// ─────────────────────────────────────────────────────────────────────────────
class BillFormatSwitcher extends GetView<BillController> {
  const BillFormatSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Obx(() {
      final active = controller.format.value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final format in BillFormat.values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _chip(colors, format, selected: format == active),
            ),
        ],
      );
    });
  }

  Widget _chip(
    AppThemeColors colors,
    BillFormat format, {
    required bool selected,
  }) {
    return InkWell(
      onTap: () => controller.showFormat(format),
      borderRadius: BorderRadius.circular(appColors.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(appColors.radiusSm),
        ),
        child: Text(
          format.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : colors.textSecondary,
            fontFamily: brandFontFamily,
          ),
        ),
      ),
    );
  }
}

/// Shown at the top of the side panel while the seller's own details are
/// missing — a tax invoice without a GSTIN is not a tax invoice.
class BillProfileNotice extends StatelessWidget {
  final BillingProfile profile;
  const BillProfileNotice({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile.isConfigured) return const SizedBox.shrink();
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(appColors.radiusSm),
        border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 15, color: colors.warning),
              const SizedBox(width: 7),
              Text(
                'Seller details missing',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: brandFontFamily,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Add your GSTIN, address and bank details before issuing this '
            'invoice.',
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: colors.textSecondary,
              fontFamily: brandFontFamily,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => Get.toNamed(AppRoutes.settings),
            child: Text(
              'Open Billing settings',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryOrange,
                fontFamily: brandFontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats an amount for the panel's status card.
String billAmountLabel(double value) => formatRupees(value);

/// The pill badges the status card uses.
class BillStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const BillStatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
          fontFamily: brandFontFamily,
        ),
      ),
    );
  }
}

/// Colour for a bill event's dot, resolved from the theme's status palette.
Color billEventColor(BuildContext context, BillEvent event) {
  final colors = context.appColors;
  return event.color(
    Theme.of(context).colorScheme,
    success: colors.success,
    info: colors.accent,
    warning: colors.warning,
    neutral: colors.textHint,
  );
}

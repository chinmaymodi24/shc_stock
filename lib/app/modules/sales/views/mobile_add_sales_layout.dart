import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/utils/gst.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/shared/widgets/async_button.dart';
import 'package:shc_stock/app/modules/sales/controllers/add_sale_controller.dart';
import 'package:shc_stock/app/modules/sales/widgets/sale_payments_section.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/products/widgets/product_autocomplete_field.dart';
import 'package:shc_stock/app/modules/products/widgets/stock_badge.dart';
import 'package:shc_stock/app/modules/sales/utils/sale_stock_guard.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/clients/widgets/client_autocomplete_field.dart';
import 'package:shc_stock/app/shared/widgets/form_fields.dart';
import 'package:shc_stock/app/shared/widgets/section_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Add Sale — mobile, stacked tax-invoice style entry form
// State and saving live in AddSaleController — the SAME controller the web
// form uses, so mobile can edit and duplicate a sale and saves every field the
// web does. No setState anywhere in this file.
// ─────────────────────────────────────────────────────────────────────────────
class MobileAddSalesLayout extends GetView<AddSaleController> {
  const MobileAddSalesLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: back button + title ──────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppBackButton(
                    colors: colors,
                    mobile: true,
                    onTap: () => Get.offNamed(AppRoutes.sales),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.isEditing ? 'Edit Sale' : 'Add Sale',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontFamily: brandFontFamily,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          controller.isEditing
                              ? 'Editing ${controller.editing!.soNumber}'
                              : 'As per sales tax invoice',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontFamily: brandFontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── Section 1: Buyer & Invoice ────────
              AppNumberedSectionCard(
                mobile: true,
                colors: colors,
                number: 1,
                title: 'Buyer & Invoice',
                child: Obx(
                  () => Column(
                    children: [
                      AppField(
                        mobile: true,
                        label: 'Client',
                        colors: colors,
                        child: ClientAutocompleteField(
                          initialValue: controller.client.value,
                          colors: colors,
                          hint: 'Type to search client...',
                          onTyped: (text) => controller.client.value = text,
                          onSelected: (ClientModel c) =>
                              controller.applyClient(c),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppField(
                        mobile: true,
                        label: "Buyer Address",
                        colors: colors,
                        child: AppTextBox(
                          controller: controller.addressCtrl,
                          hint: "Plot No, Industrial Area, City",
                          colors: colors,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppField(
                              mobile: true,
                              label: "Buyer GSTIN/UIN",
                              colors: colors,
                              child: AppTextBox(
                                controller: controller.buyerGstCtrl,
                                hint: "24ADVPT9528N1ZD",
                                colors: colors,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppField(
                              mobile: true,
                              label: "PAN No.",
                              colors: colors,
                              child: AppTextBox(
                                controller: controller.panCtrl,
                                hint: "e.g. ADVPT9528N",
                                colors: colors,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppField(
                              mobile: true,
                              label: "Invoice No.",
                              colors: colors,
                              child: AppTextBox(
                                controller: controller.invoiceNoCtrl,
                                hint: "e.g. SO/0001/26-27",
                                colors: colors,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppField(
                              mobile: true,
                              label: "Invoice Date",
                              colors: colors,
                              child: AppDateBox(
                                mobile: true,
                                date: controller.invoiceDate.value,
                                colors: colors,
                                onTap: () => controller.pickDate(
                                  context,
                                  controller.invoiceDate,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppField(
                              mobile: true,
                              label: "Buyer's Order No.",
                              colors: colors,
                              child: AppTextBox(
                                controller: controller.poNoCtrl,
                                hint: "",
                                colors: colors,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppField(
                              mobile: true,
                              label: "Buyer's Order Date",
                              colors: colors,
                              child: AppDateBox(
                                mobile: true,
                                date: controller.poDate.value,
                                colors: colors,
                                onTap: () => controller.pickDate(
                                  context,
                                  controller.poDate,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppField(
                        mobile: true,
                        label: 'Dispatched Through',
                        colors: colors,
                        child: AppDropBox(
                          mobile: true,
                          hint: 'Select mode',
                          value: controller.despatchThrough.value,
                          items: const [
                            'DIRECT VEHICLE',
                            'BY ROAD',
                            'BY RAIL',
                            'COURIER',
                          ],
                          colors: colors,
                          onChanged: (v) =>
                              controller.despatchThrough.value = v ?? '',
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppField(
                        mobile: true,
                        label: "Place of Supply / Destination",
                        colors: colors,
                        child: AppTextBox(
                          controller: controller.placeOfSupplyCtrl,
                          hint: "e.g. Gondal (Gujarat)",
                          colors: colors,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppField(
                        mobile: true,
                        label: 'Expected Delivery',
                        colors: colors,
                        child: AppDateBox(
                          mobile: true,
                          date: controller.expectedDelivery.value,
                          colors: colors,
                          onTap: () => controller.pickDate(
                            context,
                            controller.expectedDelivery,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Section 2: Item Details ──────────
              AppNumberedSectionCard(
                mobile: true,
                colors: colors,
                number: 2,
                title: 'Item Details',
                trailing: AppAddRowPill(
                  mobile: true,
                  colors: colors,
                  label: 'Add',
                  onTap: controller.addItemRow,
                ),
                child: Obx(
                  () => Column(
                    children: controller.items
                        .asMap()
                        .entries
                        .map(
                          (e) => _MobileItemCard(
                            index: e.key,
                            row: e.value,
                            guard: controller.stock,
                            colors: colors,
                            canDelete: controller.items.length > 1,
                            onChanged: controller.notifyItemsChanged,
                            onDelete: () => controller.removeItemRow(e.key),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Section 3: GST & Totals ───────────
              AppNumberedSectionCard(
                mobile: true,
                colors: colors,
                number: 3,
                title: 'GST & Totals',
                child: Obx(
                  () => Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.rowEven,
                      borderRadius: BorderRadius.circular(appColors.radius),
                    ),
                    child: Column(
                      children: [
                        AppTotalRow(
                          label: 'Taxable Value',
                          value:
                              '₹${controller.taxableValue.toStringAsFixed(0)}',
                          colors: colors,
                        ),
                        const SizedBox(height: 10),
                        // IGST for a party in another state, CGST + SGST otherwise —
                        if (controller.gst.interState)
                          AppTotalRow(
                            label: controller.gst.igstLabel,
                            value: '₹${controller.igst.toStringAsFixed(0)}',
                            colors: colors,
                          )
                        else ...[
                          AppTotalRow(
                            label: controller.gst.cgstLabel,
                            value: '₹${controller.cgst.toStringAsFixed(0)}',
                            colors: colors,
                          ),
                          const SizedBox(height: 10),
                          AppTotalRow(
                            label: controller.gst.sgstLabel,
                            value: '₹${controller.sgst.toStringAsFixed(0)}',
                            colors: colors,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Divider(height: 1, color: colors.divider),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Grand Total',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                                fontFamily: brandFontFamily,
                              ),
                            ),
                            Text(
                              '₹${controller.grandTotal.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryOrange,
                                fontFamily: brandFontFamily,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Section 4: Payments ───────────────
              SalePaymentsSection(
                controller: controller,
                colors: colors,
                number: 4,
                mobile: true,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.offNamed(AppRoutes.sales),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: brandFontFamily,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppAsyncButton(
                  label: controller.isEditing ? 'Update Sale' : 'Save Sale',
                  onPressed: controller.save,
                  expand: true,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item card — "ITEM n" label + autocomplete + stacked field grid
// ─────────────────────────────────────────────────────────────────────────────
class _MobileItemCard extends StatelessWidget {
  final int index;
  final SaleItemRow row;
  final AppThemeColors colors;
  final bool canDelete;
  final SaleStockGuard guard;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _MobileItemCard({
    required this.index,
    required this.row,
    required this.guard,
    required this.colors,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  /// A name typed over (or instead of) a picked product: the line is now a
  /// hand-typed one, so it is no longer tied to a product.
  void _typeName(String text) {
    row.product = text;
    row.productId = null;
    // A typed line is not a product: the usual 18% applies.
    row.taxPercent = kDefaultGstRate;
    onChanged();
  }

  void _applyProduct(ProductModel p) {
    // Nothing left to sell: the dropdown already refuses it, this is the
    // backstop for any other way a pick could arrive.
    if (guard.unavailableReason(p) != null) return;
    row.productId = int.tryParse(p.id);
    row.product = p.name;
    row.taxPercent = p.taxPercent;
    row.hsn = p.hsnCode ?? '';
    row.unit = p.unit;
    row.rate = p.sellingPrice;
    // A fresh row starts at qty 0, which pinned the line — and the invoice
    // total — to ₹0 until a quantity was typed; the picked product should
    // price itself straight away.
    if (row.qty == 0) row.qty = 1;
    // Re-seeds the HSN / UoM / Rate boxes below, which otherwise keep the
    // text they were first built with.
    row.version++;
    onChanged();
    // Say so the moment it's picked, not only when Save is pressed.
    final blocked = guard.errorFor(row.productId);
    final problem = blocked ?? guard.lowNoteFor(row.productId);
    if (problem != null) {
      showAppToast(
        blocked != null ? 'Not in stock' : 'Low stock',
        problem,
        backgroundColor: blocked != null ? AppColors.danger : AppColors.warning,
        colorText: Colors.white,
      );
    }
  }

  /// A quantity can't pass what inventory holds: a ± tap or typed number over
  /// the limit is pulled back to it, with a message saying why.
  void _setQty(double v) {
    final max = guard.maxQtyFor(row.productId, thisLineQty: row.qty);
    if (max != null && v > max) {
      row.qty = max;
      showAppToast(
        'Not enough stock',
        guard.limitMessage(row.productId),
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
      );
    } else {
      row.qty = v;
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(appColors.radius),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ITEM ${index + 1}',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: colors.textHint,
                  fontFamily: brandFontFamily,
                ),
              ),
              if (canDelete)
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(6),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.danger,
                    size: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ProductAutocompleteField(
            initialValue: row.product,
            colors: colors,
            onSelected: _applyProduct,
            onTyped: _typeName,
            priceOf: (p) => p.sellingPrice,
            showStock: true,
            blockReason: guard.unavailableReason,
          ),
          StockMessage(
            error: guard.errorFor(row.productId),
            note: guard.lowNoteFor(row.productId),
            colors: colors,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppSmallInput(
                  key: ValueKey('${row.id}_hsn_${row.version}'),
                  mobile: true,
                  hint: 'HSN/SAC',
                  value: row.hsn,
                  colors: colors,
                  center: true,
                  onChanged: (v) {
                    row.hsn = v;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppSmallStepper(
                  mobile: true,
                  hint: 'Quantity',
                  value: row.qty,
                  colors: colors,
                  onChanged: _setQty,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppSmallInput(
                  key: ValueKey('${row.id}_uom_${row.version}'),
                  mobile: true,
                  hint: 'UoM',
                  value: row.unit,
                  colors: colors,
                  center: true,
                  onChanged: (v) {
                    row.unit = v;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppSmallNumber(
                  key: ValueKey('${row.id}_rate_${row.version}'),
                  mobile: true,
                  hint: 'Rate',
                  value: row.rate,
                  colors: colors,
                  decimal: true,
                  onChanged: (v) {
                    row.rate = v;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 36,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: colors.rowEven,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    '₹${row.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontFamily: brandFontFamily,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

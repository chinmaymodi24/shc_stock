import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/utils/gst.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/shared/widgets/async_button.dart';
import 'package:shc_stock/app/modules/sales/controllers/add_sale_controller.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/products/widgets/stock_badge.dart';
import 'package:shc_stock/app/modules/sales/utils/sale_stock_guard.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/clients/widgets/client_autocomplete_field.dart';
import 'package:shc_stock/app/modules/sales/widgets/sale_payments_section.dart';
import 'package:shc_stock/app/shared/widgets/form_fields.dart';
import 'package:shc_stock/app/shared/widgets/section_card.dart';

part 'web_new_sales_layout_part1.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Add Sale — tax-invoice style entry form
// All form state lives in AddSaleController (registered by SalesBinding) —
// no setState anywhere in this file.
// ─────────────────────────────────────────────────────────────────────────────
class WebNewSalesLayout extends GetView<AddSaleController> {
  const WebNewSalesLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          const WebSidebar(),
          Expanded(
            child: Column(
              children: [
                const WebTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header: back button + title ──────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AppBackButton(
                              colors: colors,
                              onTap: () => Get.offNamed(AppRoutes.sales),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.isEditing
                                      ? 'Edit Sale'
                                      : 'Add Sale',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                    fontFamily: brandFontFamily,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  controller.isEditing
                                      ? 'Editing ${controller.editing!.soNumber} — change any detail and save'
                                      : 'Enter details as they appear on the sales tax invoice',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: colors.textSecondary,
                                    fontFamily: brandFontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Section 1: Client & Invoice Details ──
                        AppNumberedSectionCard(
                          colors: colors,
                          number: 1,
                          title: 'Client & Invoice Details',
                          child: Obx(
                            () => Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: AppField(
                                        label: 'Client Name',
                                        colors: colors,
                                        child: ClientAutocompleteField(
                                          initialValue: controller.client.value,
                                          colors: colors,
                                          hint: 'Type to search client...',
                                          onTyped: (text) =>
                                              controller.client.value = text,
                                          onSelected: (ClientModel c) =>
                                              controller.applyClient(c),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppField(
                                        label: 'Address',
                                        colors: colors,
                                        child: AppTextBox(
                                          controller: controller.addressCtrl,
                                          hint: '202, Venus Benecia',
                                          colors: colors,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: AppField(
                                              label: 'City',
                                              colors: colors,
                                              child: AppTextBox(
                                                controller: controller.cityCtrl,
                                                hint: 'Ahmedabad',
                                                colors: colors,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            flex: 2,
                                            child: AppField(
                                              label: 'Pin Code',
                                              colors: colors,
                                              child: AppTextBox(
                                                controller: controller.pinCtrl,
                                                hint: '380001',
                                                colors: colors,
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                  LengthLimitingTextInputFormatter(
                                                    6,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppField(
                                        label: 'State',
                                        colors: colors,
                                        child: AppTextBox(
                                          controller: controller.stateCtrl,
                                          hint: 'Gujarat',
                                          colors: colors,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppField(
                                        label: 'Buyer GST No.',
                                        colors: colors,
                                        child: AppTextBox(
                                          controller: controller.buyerGstCtrl,
                                          hint: '24ABMFS5824P1ZH',
                                          colors: colors,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppField(
                                        label: 'PAN No.',
                                        colors: colors,
                                        child: AppTextBox(
                                          controller: controller.panCtrl,
                                          hint: 'ADVPT9528N',
                                          colors: colors,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppField(
                                        label: 'Invoice No.',
                                        colors: colors,
                                        child: AppTextBox(
                                          controller: controller.invoiceNoCtrl,
                                          hint: 'e.g. T 464',
                                          colors: colors,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppField(
                                        label: 'Invoice Date',
                                        colors: colors,
                                        child: AppDateBox(
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
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppField(
                                        label: 'P.O. No.',
                                        colors: colors,
                                        child: AppTextBox(
                                          controller: controller.poNoCtrl,
                                          hint: 'E-MAIL',
                                          colors: colors,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppField(
                                        label: 'P.O. Dt.',
                                        colors: colors,
                                        child: AppDateBox(
                                          date: controller.poDate.value,
                                          colors: colors,
                                          onTap: () => controller.pickDate(
                                            context,
                                            controller.poDate,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppField(
                                        label: 'Despatch Through',
                                        colors: colors,
                                        child: AppDropBox(
                                          hint: 'Select mode',
                                          value:
                                              controller.despatchThrough.value,
                                          items: const [
                                            'DIRECT VEHICLE',
                                            'BY ROAD',
                                            'BY RAIL',
                                            'COURIER',
                                          ],
                                          colors: colors,
                                          onChanged: (v) =>
                                              controller.despatchThrough.value =
                                                  v ?? '',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppField(
                                        label: 'L.R. No.',
                                        colors: colors,
                                        child: AppTextBox(
                                          controller: controller.lrNoCtrl,
                                          hint: '',
                                          colors: colors,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppField(
                                        label: 'L.R. Date',
                                        colors: colors,
                                        child: AppDateBox(
                                          date: controller.lrDate.value,
                                          colors: colors,
                                          onTap: () => controller.pickDate(
                                            context,
                                            controller.lrDate,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppField(
                                        label: 'Vehicle No.',
                                        colors: colors,
                                        child: AppTextBox(
                                          controller: controller.vehicleNoCtrl,
                                          hint: 'e.g. GJ-03-CT-6544',
                                          colors: colors,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppField(
                                        label: 'Freight',
                                        colors: colors,
                                        child: AppTextBox(
                                          controller: controller.freightCtrl,
                                          hint: '',
                                          colors: colors,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppField(
                                        label: 'Place of Supply',
                                        colors: colors,
                                        child: AppTextBox(
                                          controller:
                                              controller.placeOfSupplyCtrl,
                                          hint: 'e.g. Ahmedabad (Gujarat)',
                                          colors: colors,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppField(
                                        label: 'Due Date',
                                        colors: colors,
                                        child: AppDateBox(
                                          date: controller.dueDate.value,
                                          colors: colors,
                                          onTap: () => controller.pickDate(
                                            context,
                                            controller.dueDate,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Optional. Set it and the backend marks
                                    // the order Delivered on that date, which
                                    // is what takes the stock out; leave it
                                    // empty and the status stays put.
                                    Expanded(
                                      child: AppField(
                                        label: 'Expected Delivery',
                                        colors: colors,
                                        child: AppDateBox(
                                          date:
                                              controller.expectedDelivery.value,
                                          colors: colors,
                                          onTap: () => controller.pickDate(
                                            context,
                                            controller.expectedDelivery,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Payments have their own section (4) — a
                                    // sale can be paid in several goes.
                                    const Expanded(child: SizedBox()),
                                    const SizedBox(width: 16),
                                    const Expanded(child: SizedBox()),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Section 2: Item Details ──────────
                        AppNumberedSectionCard(
                          colors: colors,
                          number: 2,
                          title: 'Item Details',
                          trailing: AppAddRowPill(
                            colors: colors,
                            label: 'Add Row',
                            onTap: controller.addItemRow,
                          ),
                          child: Obx(
                            () => _ItemDetailsTable(
                              items: controller.items.toList(),
                              guard: controller.stock,
                              colors: colors,
                              onChanged: controller.notifyItemsChanged,
                              onDelete: controller.removeItemRow,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Section 3: GST & Totals ───────────
                        AppNumberedSectionCard(
                          colors: colors,
                          number: 3,
                          title: 'GST & Totals',
                          child: Obx(
                            () => Row(
                              children: [
                                const Expanded(child: SizedBox()),
                                Container(
                                  width: 340,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colors.rowEven,
                                    borderRadius: BorderRadius.circular(
                                      appColors.radius,
                                    ),
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
                                          value:
                                              '₹${controller.igst.toStringAsFixed(0)}',
                                          colors: colors,
                                        )
                                      else ...[
                                        AppTotalRow(
                                          label: controller.gst.cgstLabel,
                                          value:
                                              '₹${controller.cgst.toStringAsFixed(0)}',
                                          colors: colors,
                                        ),
                                        const SizedBox(height: 10),
                                        AppTotalRow(
                                          label: controller.gst.sgstLabel,
                                          value:
                                              '₹${controller.sgst.toStringAsFixed(0)}',
                                          colors: colors,
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      Divider(height: 1, color: colors.divider),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Section 4: Payments ───────────────
                        SalePaymentsSection(
                          controller: controller,
                          colors: colors,
                          number: 4,
                        ),
                        const SizedBox(height: 20),

                        // ── Footer buttons ────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Get.offNamed(AppRoutes.sales),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colors.border),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 13,
                                ),
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
                            const SizedBox(width: 12),
                            AppAsyncButton(
                              label: controller.isEditing
                                  ? 'Update Sale'
                                  : 'Save Sale',
                              onPressed: controller.save,
                            ),
                          ],
                        ),
                      ],
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Item Details Table — with product autocomplete that fetches HSN/rate
// ─────────────────────────────────────────────────────────────────────────────
const int _iItemFlex = 30;
const double _iHsnWidth = 90.0;
// Wider than a plain number cell — it holds the - / qty / + stepper.
const double _iQtyWidth = 104.0;
const double _iUomWidth = 90.0;
const double _iRateWidth = 100.0;
const double _iAmtWidth = 100.0;
const double _iDelWidth = 32.0;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/utils/gst.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/shared/widgets/async_button.dart';
import 'package:shc_stock/app/modules/purchase/controllers/add_purchase_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/clients/widgets/client_autocomplete_field.dart';
import 'package:shc_stock/app/shared/models/order_payment.dart';
import 'package:shc_stock/app/shared/widgets/form_fields.dart';
import 'package:shc_stock/app/shared/widgets/section_card.dart';

part 'web_new_purchase_layout_part1.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Add Purchase — tax-invoice style entry form
// All form state lives in AddPurchaseController (registered by PurchaseBinding)
// — no setState anywhere in this file.
// ─────────────────────────────────────────────────────────────────────────────
class WebNewPurchaseLayout extends GetView<AddPurchaseController> {
  const WebNewPurchaseLayout({super.key});

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
                              onTap: () => Get.offNamed(AppRoutes.purchase),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.isEditing
                                      ? 'Edit Purchase'
                                      : 'Add Purchase',
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
                                      ? 'Editing ${controller.editing!.poNumber} — change any detail and save'
                                      : "Enter details as they appear on the supplier's tax invoice",
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
                                        required: true,
                                        colors: colors,
                                        child: ClientAutocompleteField(
                                          initialValue: controller.client.value,
                                          colors: colors,
                                          hint: 'Select client...',
                                          suffixIcon: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 18,
                                            color: colors.textSecondary,
                                          ),
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
                                          hint: 'e.g. 202, Venus Benecia',
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
                                                hint: 'e.g. Ahmedabad',
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
                                          hint: 'e.g. Gujarat',
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
                                          hint: 'e.g. 24ABMFS5824P1ZH',
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
                                          hint: 'e.g. ADVPT9528N',
                                          colors: colors,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppField(
                                        label: 'Invoice No.',
                                        required: true,
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
                                        required: true,
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
                                          hint: 'Enter PO number',
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
                                    // the order Received on that date, which
                                    // is what adds the stock; leave it empty
                                    // and the status stays put.
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
                                    Expanded(
                                      child: AppField(
                                        label: 'Order Paid',
                                        colors: colors,
                                        child: AppDropBox(
                                          hint: 'Select...',
                                          value:
                                              controller
                                                  .paymentType
                                                  .value
                                                  .label
                                                  .isEmpty
                                              ? null
                                              : controller
                                                    .paymentType
                                                    .value
                                                    .label,
                                          items: kOrderPaymentOptions
                                              .map((t) => t.label)
                                              .toList(),
                                          colors: colors,
                                          onChanged: (v) =>
                                              controller.setPaymentType(
                                                orderPaymentTypeFrom(v),
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Only meaningful once a payment type is
                                    // chosen — prefilled from the grand total
                                    // for Full/Half, and editable either way.
                                    Expanded(
                                      child:
                                          controller.paymentType.value ==
                                              OrderPaymentType.none
                                          ? const SizedBox()
                                          : AppField(
                                              label: 'Amount Paid',
                                              colors: colors,
                                              child: AppTextBox(
                                                controller:
                                                    controller.paidAmountCtrl,
                                                hint: 'e.g. 25000',
                                                colors: colors,
                                                onChanged: (_) => controller
                                                    .paidAmountTyped(),
                                              ),
                                            ),
                                    ),
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
                                SizedBox(
                                  width: 340,
                                  child: Column(
                                    children: [
                                      AppTotalRow(
                                        label: 'Sub Total',
                                        value:
                                            '₹${controller.subTotal.toStringAsFixed(0)}',
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
                        const SizedBox(height: 20),

                        // ── Footer buttons ────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Get.offNamed(AppRoutes.purchase),
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
                                  ? 'Update Purchase'
                                  : 'Save Purchase',
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
// Item Details Table
// ─────────────────────────────────────────────────────────────────────────────
const int _cItem = 31;
const int _cHsn = 10;
const int _cGrade = 8;
const int _cDensity = 9;
const int _cNoPkg = 10;
const int _cTotalQty = 16;
const int _cUom = 9;
const int _cNetPrice = 11;
const int _cAmount = 14;

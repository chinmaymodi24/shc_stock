import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sales_controller.dart';
import '../controllers/mobile_add_sale_controller.dart';
import '../models/sales_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../products/controllers/products_controller.dart';
import '../../products/models/product_model.dart';
import '../../clients/models/client_model.dart';
import '../../clients/widgets/client_autocomplete_field.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../core/utils/app_toast.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Add Sell — mobile, stacked tax-invoice style entry form
// State lives in MobileAddSaleController (registered by SalesBinding) — no
// setState anywhere in this file.
// ─────────────────────────────────────────────────────────────────────────────
class MobileAddSalesLayout extends GetView<MobileAddSaleController> {
  const MobileAddSalesLayout({super.key});

  void _saveSale() {
    final c = Get.find<SalesController>();
    final newId = 'so_${DateTime.now().millisecondsSinceEpoch}';
    final newSoNum =
        'SO-2024-${(10000 + c.orders.length + 1).toString().padLeft(5, '0')}';
    final clientName = controller.client.value.isEmpty
        ? 'New Client'
        : controller.client.value;
    c.addOrder(
      SalesOrder(
        id: newId,
        soNumber: newSoNum,
        client: clientName,
        clientBadge: clientName
            .substring(0, clientName.length < 2 ? clientName.length : 2)
            .toUpperCase(),
        clientColor: AppColors.primaryOrange,
        date: controller.invoiceDate.value ?? DateTime.now(),
        itemCount: controller.items.length,
        amount: controller.grandTotal,
        status: SalesStatus.confirmed,
        paymentStatus: PaymentStatus.pending,
      ),
    );
    Get.back();
    showAppToast(
      '✅ Sale Saved',
      '$newSoNum has been successfully created.',
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
    );
  }

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
                    onTap: () => Get.back(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Sell',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'As per sales tax invoice',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontFamily: 'Poppins',
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
                          onSelected: (ClientModel c) =>
                              controller.applyClient(c),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppField(
            mobile: true,
                        label: 'Buyer Address',
                        colors: colors,
                        child: AppTextBox(
                          controller: controller.buyerAddressCtrl,
                          hint: 'Plot No, Industrial Area, City',
                          colors: colors,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppField(
            mobile: true,
                        label: 'Buyer GSTIN/UIN',
                        colors: colors,
                        child: AppTextBox(
                          controller: controller.buyerGstinCtrl,
                          hint: '24ADVPT9528N1ZD',
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
                              label: 'Invoice No.',
                              colors: colors,
                              child: AppTextBox(
                                controller: controller.invoiceNoCtrl,
                                hint: 'e.g. ST/0255/26-27',
                                colors: colors,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppField(
            mobile: true,
                              label: 'Invoice Date',
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
                              label: 'Delivery Note',
                              colors: colors,
                              child: AppTextBox(
                                controller: controller.deliveryNoteCtrl,
                                hint: 'e.g. 255',
                                colors: colors,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppField(
            mobile: true,
                              label: 'Mode/Terms of Payment',
                              colors: colors,
                              child: AppTextBox(
                                controller: controller.paymentTermsCtrl,
                                hint: 'e.g. Credit 30 Days',
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
                              label: "Buyer's Order No.",
                              colors: colors,
                              child: AppTextBox(
                                controller: controller.buyerOrderNoCtrl,
                                hint: '',
                                colors: colors,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppField(
            mobile: true,
                              label: 'Dispatch Doc No.',
                              colors: colors,
                              child: AppTextBox(
                                controller: controller.dispatchDocNoCtrl,
                                hint: 'e.g. 255',
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
                              label: 'Delivery Note Date',
                              colors: colors,
                              child: AppDateBox(
            mobile: true,
                                date: controller.deliveryNoteDate.value,
                                colors: colors,
                                onTap: () => controller.pickDate(
                                  context,
                                  controller.deliveryNoteDate,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppField(
            mobile: true,
                              label: 'Dispatched Through',
                              colors: colors,
                              child: AppTextBox(
                                controller: controller.dispatchedThroughCtrl,
                                hint: 'e.g. By Road',
                                colors: colors,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppField(
            mobile: true,
                        label: 'Destination',
                        colors: colors,
                        child: AppTextBox(
                          controller: controller.destinationCtrl,
                          hint: 'e.g. Gondal',
                          colors: colors,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppField(
            mobile: true,
                        label: 'Terms of Delivery',
                        colors: colors,
                        child: AppTextBox(
                          controller: controller.termsOfDeliveryCtrl,
                          hint: '',
                          colors: colors,
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
                      borderRadius: BorderRadius.circular(10),
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
                        AppTotalRow(
                          label: 'CGST (9%)',
                          value: '₹${controller.cgst.toStringAsFixed(0)}',
                          colors: colors,
                        ),
                        const SizedBox(height: 10),
                        AppTotalRow(
                          label: 'SGST (9%)',
                          value: '₹${controller.sgst.toStringAsFixed(0)}',
                          colors: colors,
                        ),
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
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              '₹${controller.grandTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryOrange,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
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
                  onPressed: () => Get.back(),
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
                      fontFamily: 'Poppins',
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'Save Sale',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
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
  final MobileSaleItemRow row;
  final AppThemeColors colors;
  final bool canDelete;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _MobileItemCard({
    required this.index,
    required this.row,
    required this.colors,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  void _applyProduct(ProductModel p) {
    row.product = p.name;
    row.hsn = p.hsnCode ?? '';
    row.unit = p.unit;
    row.rate = p.sellingPrice;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
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
                  fontFamily: 'Poppins',
                ),
              ),
              if (canDelete)
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(6),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFEF4444),
                    size: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _ProductAutocomplete(
            initialValue: row.product,
            colors: colors,
            onSelected: _applyProduct,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppSmallInput(
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
                child: AppSmallNumber(
            mobile: true,
                  hint: 'Quantity',
                  value: row.qty,
                  colors: colors,
                  onChanged: (v) {
                    row.qty = v;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppSmallInput(
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
                      fontFamily: 'Poppins',
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

// ─────────────────────────────────────────────────────────────────────────────
// Product autocomplete — typing filters ProductsController by name; selecting
// an option fetches its HSN/SAC, unit and rate into the row.
// ─────────────────────────────────────────────────────────────────────────────
class _ProductAutocomplete extends StatelessWidget {
  final String initialValue;
  final AppThemeColors colors;
  final ValueChanged<ProductModel> onSelected;

  const _ProductAutocomplete({
    required this.initialValue,
    required this.colors,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final products = Get.find<ProductsController>().products;
    return Autocomplete<ProductModel>(
      displayStringForOption: (p) => p.name,
      optionsBuilder: (textEditingValue) {
        final q = textEditingValue.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<ProductModel>.empty();
        return products.where((p) => p.name.toLowerCase().contains(q)).take(30);
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        if (controller.text.isEmpty && initialValue.isNotEmpty) {
          controller.text = initialValue;
        }
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: TextStyle(
            fontSize: 13,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
          decoration: InputDecoration(
            hintText: 'Type e.g. Ceramic Fiber Blanket 1260...',
            hintStyle: TextStyle(
              fontSize: 12.5,
              color: colors.textHint,
              fontFamily: 'Poppins',
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            filled: true,
            fillColor: colors.surface,
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 16,
              color: colors.textHint,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 34,
              minHeight: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primaryOrange,
                width: 1.2,
              ),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelect, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            color: colors.surface,
            child: Container(
              width: MediaQuery.of(context).size.width - 56,
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final p = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelect(p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'HSN ${p.hsnCode ?? '—'} · ${p.unit}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textHint,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${p.sellingPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

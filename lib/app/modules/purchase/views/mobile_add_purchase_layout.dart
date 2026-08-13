import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/purchase/controllers/purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/controllers/mobile_add_purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/models/purchase_model.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/clients/widgets/client_autocomplete_field.dart';
import 'package:shc_stock/app/shared/widgets/form_fields.dart';
import 'package:shc_stock/app/shared/widgets/section_card.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Add Purchase — mobile, stacked tax-invoice style entry form
// State lives in MobileAddPurchaseController (registered by PurchaseBinding)
// — no setState anywhere in this file.
// ─────────────────────────────────────────────────────────────────────────────
class MobileAddPurchaseLayout extends GetView<MobileAddPurchaseController> {
  const MobileAddPurchaseLayout({super.key});

  Future<void> _savePurchase() async {
    final c = Get.find<PurchaseController>();
    final newId = 'po_${DateTime.now().millisecondsSinceEpoch}';
    final newPoNum =
        'PO-2024-${(10000 + c.orders.length + 1).toString().padLeft(5, '0')}';
    final supplierName = controller.client.value.isEmpty
        ? 'Unknown Supplier'
        : controller.client.value;
    final ok = await c.addOrder(
      PurchaseOrder(
        id: newId,
        poNumber: newPoNum,
        supplier: supplierName,
        supplierIcon: supplierName
            .substring(0, supplierName.length < 2 ? supplierName.length : 2)
            .toUpperCase(),
        date: controller.invoiceDate.value ?? DateTime.now(),
        itemCount: controller.items.length,
        amount: controller.grandTotal,
        status: PurchaseStatus.pending,
        // Items carry the productId, which is what makes the backend add the
        // received quantity into inventory.
        items: controller.items
            .map(
              (r) => PurchaseDetailItem(
                productId: r.productId,
                product: r.product,
                hsn: r.hsn,
                grade: r.grade,
                density: r.density,
                qty: r.totalQty,
                unit: r.uom,
                rate: r.netPrice,
              ),
            )
            .toList(),
      ),
    );
    if (!ok) return; // controller already showed the error toast
    Get.back();
    showAppToast(
      '✅ Purchase Saved',
      '$newPoNum has been successfully created.',
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
                          'Add Purchase',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "As per supplier's tax invoice",
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

              // ── Section 1: Consignee, Buyer & Invoice ──
              AppNumberedSectionCard(
                mobile: true,
                colors: colors,
                number: 1,
                title: 'Consignee, Buyer & Invoice',
                child: Obx(
                  () => Column(
                    children: [
                      AppField(
                        mobile: true,
                        label: 'Name & Address of Consignee',
                        colors: colors,
                        child: AppTextBox(
                          controller: controller.consigneeCtrl,
                          hint: 'SECURE HEAT CARE...',
                          colors: colors,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppField(
                        mobile: true,
                        label: 'Buyer GST No.',
                        colors: colors,
                        child: AppTextBox(
                          controller: controller.buyerGstCtrl,
                          hint: '24ABMFS5824P1ZH',
                          colors: colors,
                        ),
                      ),
                      const SizedBox(height: 14),
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
                                hint: 'e.g. T 464',
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
                              label: 'P.O. No.',
                              colors: colors,
                              child: AppTextBox(
                                controller: controller.poNoCtrl,
                                hint: '',
                                colors: colors,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppField(
                              mobile: true,
                              label: 'P.O. Dt.',
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
                        label: 'Despatch Through',
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppField(
                              mobile: true,
                              label: 'L.R. No & Dt.',
                              colors: colors,
                              child: AppTextBox(
                                controller: controller.lrNoCtrl,
                                hint: '',
                                colors: colors,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppField(
                              mobile: true,
                              label: 'Vehicle No.',
                              colors: colors,
                              child: AppTextBox(
                                controller: controller.vehicleNoCtrl,
                                hint: 'e.g. GJ-03-CT-6544',
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
                              label: 'Freight',
                              colors: colors,
                              child: AppTextBox(
                                controller: controller.freightCtrl,
                                hint: '',
                                colors: colors,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppField(
                              mobile: true,
                              label: 'Due Date',
                              colors: colors,
                              child: AppDateBox(
                                mobile: true,
                                date: controller.dueDate.value,
                                colors: colors,
                                onTap: () => controller.pickDate(
                                  context,
                                  controller.dueDate,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppField(
                        mobile: true,
                        label: 'Place of Supply',
                        colors: colors,
                        child: AppTextBox(
                          controller: controller.placeOfSupplyCtrl,
                          hint: 'e.g. Ahmedabad (Gujarat)',
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
                            key: ValueKey(e.value.id),
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
                          label: 'Sub Total',
                          value: '₹${controller.subTotal.toStringAsFixed(0)}',
                          colors: colors,
                        ),
                        const SizedBox(height: 10),
                        AppTotalRow(
                          label: 'SGST (9%)',
                          value: '₹${controller.sgst.toStringAsFixed(0)}',
                          colors: colors,
                        ),
                        const SizedBox(height: 10),
                        AppTotalRow(
                          label: 'CGST (9%)',
                          value: '₹${controller.cgst.toStringAsFixed(0)}',
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
                  onPressed: _savePurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'Save Purchase',
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
  static final _densityNum = RegExp(r'(\d+(?:\.\d+)?)\s*kg/m');
  static final _gradeNum = RegExp(r'(\d+)\s*°?C');

  final int index;
  final MobilePurchaseItemRow row;
  final AppThemeColors colors;
  final bool canDelete;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _MobileItemCard({
    super.key,
    required this.index,
    required this.row,
    required this.colors,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  void _applyProduct(ProductModel p) {
    row.productId = int.tryParse(p.id);
    row.product = p.name;
    row.hsn = p.hsnCode ?? '';
    row.uom = p.unit;
    row.netPrice = p.costPrice;
    if (p.densityVariants.isNotEmpty) {
      row.density = p.densityVariants.first;
    } else {
      final m = _densityNum.firstMatch(p.name);
      if (m != null) row.density = '${m.group(1)} kg/m³';
    }
    final g = _gradeNum.firstMatch(p.name);
    if (g != null) row.grade = g.group(1)!;
    row.version++;
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
                  key: ValueKey('${row.id}_hsn_${row.version}'),
                  mobile: true,
                  hint: 'HSN',
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
                child: AppSmallInput(
                  key: ValueKey('${row.id}_grade_${row.version}'),
                  mobile: true,
                  hint: 'Grade',
                  value: row.grade,
                  colors: colors,
                  center: true,
                  onChanged: (v) {
                    row.grade = v;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppSmallInput(
                  key: ValueKey('${row.id}_density_${row.version}'),
                  mobile: true,
                  hint: 'Density',
                  value: row.density,
                  colors: colors,
                  center: true,
                  onChanged: (v) {
                    row.density = v;
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
                  hint: 'No. Pkg',
                  value: row.noPkg,
                  colors: colors,
                  onChanged: (v) {
                    row.noPkg = v;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppSmallNumber(
                  mobile: true,
                  hint: 'Cont/Pkg',
                  value: row.avgContPerPkg,
                  colors: colors,
                  onChanged: (v) {
                    row.avgContPerPkg = v;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.rowEven,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    row.totalQty == 0
                        ? 'Total Qty'
                        : row.totalQty.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: row.totalQty == 0
                          ? colors.textHint
                          : colors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppSmallInput(
                  key: ValueKey('${row.id}_uom_${row.version}'),
                  mobile: true,
                  hint: 'UoM',
                  value: row.uom,
                  colors: colors,
                  center: true,
                  onChanged: (v) {
                    row.uom = v;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppSmallNumber(
                  key: ValueKey('${row.id}_netPrice_${row.version}'),
                  mobile: true,
                  hint: 'Net Price',
                  value: row.netPrice,
                  colors: colors,
                  decimal: true,
                  onChanged: (v) {
                    row.netPrice = v;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '₹${row.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product autocomplete — typing filters ProductsController by name; selecting
// an option fetches its HSN, density/grade, UoM and cost price into the row.
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
                            '₹${p.costPrice.toStringAsFixed(0)}',
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

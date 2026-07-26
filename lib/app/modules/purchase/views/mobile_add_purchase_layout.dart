import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/purchase_controller.dart';
import '../controllers/mobile_add_purchase_controller.dart';
import '../models/purchase_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../products/controllers/products_controller.dart';
import '../../products/models/product_model.dart';
import '../../clients/models/client_model.dart';
import '../../clients/widgets/client_autocomplete_field.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Add Purchase — mobile, stacked tax-invoice style entry form
// State lives in MobileAddPurchaseController (registered by PurchaseBinding)
// — no setState anywhere in this file.
// ─────────────────────────────────────────────────────────────────────────────
class MobileAddPurchaseLayout extends GetView<MobileAddPurchaseController> {
  const MobileAddPurchaseLayout({super.key});

  void _savePurchase() {
    final c = Get.find<PurchaseController>();
    final newId = 'po_${DateTime.now().millisecondsSinceEpoch}';
    final newPoNum =
        'PO-2024-${(10000 + c.orders.length + 1).toString().padLeft(5, '0')}';
    final supplierName = controller.client.value.isEmpty
        ? 'Unknown Supplier'
        : controller.client.value;
    c.addOrder(
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
      ),
    );
    Get.back();
    Get.snackbar(
      '✅ Purchase Saved',
      '$newPoNum has been successfully created.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
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
                  _BackButton(colors: colors, onTap: () => Get.back()),
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
              _NumberedSectionCard(
                colors: colors,
                number: 1,
                title: 'Consignee, Buyer & Invoice',
                child: Obx(
                  () => Column(
                    children: [
                      _Field(
                        label: 'Name & Address of Consignee',
                        colors: colors,
                        child: _TextBox(
                          controller: controller.consigneeCtrl,
                          hint: 'SECURE HEAT CARE...',
                          colors: colors,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Field(
                        label: 'Buyer GST No.',
                        colors: colors,
                        child: _TextBox(
                          controller: controller.buyerGstCtrl,
                          hint: '24ABMFS5824P1ZH',
                          colors: colors,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _Field(
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
                            child: _Field(
                              label: 'Invoice No.',
                              colors: colors,
                              child: _TextBox(
                                controller: controller.invoiceNoCtrl,
                                hint: 'e.g. T 464',
                                colors: colors,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Field(
                              label: 'Invoice Date',
                              colors: colors,
                              child: _DateBox(
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
                            child: _Field(
                              label: 'P.O. No.',
                              colors: colors,
                              child: _TextBox(
                                controller: controller.poNoCtrl,
                                hint: '',
                                colors: colors,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Field(
                              label: 'P.O. Dt.',
                              colors: colors,
                              child: _DateBox(
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
                      _Field(
                        label: 'Despatch Through',
                        colors: colors,
                        child: _DropBox(
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
                            child: _Field(
                              label: 'L.R. No & Dt.',
                              colors: colors,
                              child: _TextBox(
                                controller: controller.lrNoCtrl,
                                hint: '',
                                colors: colors,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Field(
                              label: 'Vehicle No.',
                              colors: colors,
                              child: _TextBox(
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
                            child: _Field(
                              label: 'Freight',
                              colors: colors,
                              child: _TextBox(
                                controller: controller.freightCtrl,
                                hint: '',
                                colors: colors,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Field(
                              label: 'Due Date',
                              colors: colors,
                              child: _DateBox(
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
                      _Field(
                        label: 'Place of Supply',
                        colors: colors,
                        child: _TextBox(
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
              _NumberedSectionCard(
                colors: colors,
                number: 2,
                title: 'Item Details',
                trailing: _AddPillButton(
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
              _NumberedSectionCard(
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
                        _TotalRow(
                          label: 'Sub Total',
                          value: '₹${controller.subTotal.toStringAsFixed(0)}',
                          colors: colors,
                        ),
                        const SizedBox(height: 10),
                        _TotalRow(
                          label: 'SGST (9%)',
                          value: '₹${controller.sgst.toStringAsFixed(0)}',
                          colors: colors,
                        ),
                        const SizedBox(height: 10),
                        _TotalRow(
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
                child: _SmallInput(
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
                child: _SmallInput(
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
                child: _SmallInput(
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
                child: _SmallNumber(
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
                child: _SmallNumber(
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
                child: _SmallInput(
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
                child: _SmallNumber(
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

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  final AppThemeColors colors;
  final VoidCallback onTap;
  const _BackButton({required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.inputFill,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          color: colors.textPrimary,
          size: 18,
        ),
      ),
    );
  }
}

class _AddPillButton extends StatelessWidget {
  final AppThemeColors colors;
  final String label;
  final VoidCallback onTap;
  const _AddPillButton({
    required this.colors,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_rounded,
                size: 15,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(width: 3),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.primaryOrange,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberedSectionCard extends StatelessWidget {
  final AppThemeColors colors;
  final int number;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _NumberedSectionCard({
    required this.colors,
    required this.number,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final AppThemeColors colors;
  final Widget child;
  const _Field({
    required this.label,
    required this.colors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _TextBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final AppThemeColors colors;
  const _TextBox({
    required this.controller,
    required this.hint,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(
        fontSize: 13,
        color: colors.textPrimary,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: colors.textHint,
          fontFamily: 'Poppins',
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        filled: true,
        fillColor: colors.surface,
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
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _DropBox extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final AppThemeColors colors;
  final ValueChanged<String?> onChanged;

  const _DropBox({
    required this.hint,
    required this.value,
    required this.items,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeVal = (value != null && items.contains(value)) ? value : null;
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeVal,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 13,
              color: colors.textHint,
              fontFamily: 'Poppins',
            ),
          ),
          isDense: true,
          isExpanded: true,
          dropdownColor: colors.surface,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: colors.textSecondary,
          ),
          style: TextStyle(
            fontSize: 13,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
          items: items
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DateBox extends StatefulWidget {
  final DateTime? date;
  final AppThemeColors colors;
  final VoidCallback onTap;
  const _DateBox({
    required this.date,
    required this.colors,
    required this.onTap,
  });

  @override
  State<_DateBox> createState() => _DateBoxState();
}

class _DateBoxState extends State<_DateBox> {
  // Local, widget-scoped focus flag — kept as an Rx on the persistent State
  // object (not setState) so only the border repaints on focus change, and
  // so this date field is reachable via Tab like every other field.
  final _focused = false.obs;

  @override
  void dispose() {
    _focused.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.date;
    final colors = widget.colors;
    final label = d == null
        ? 'dd-mm-yyyy'
        : '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
    return Focus(
      onFocusChange: (f) => _focused.value = f,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: InkWell(
        onTap: widget.onTap,
        child: Obx(
          () => Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused.value ? AppColors.primaryOrange : colors.border,
                width: _focused.value ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: d == null ? colors.textHint : colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_month_outlined,
                  size: 15,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label, value;
  final AppThemeColors colors;
  const _TotalRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

class _SmallInput extends StatelessWidget {
  final String hint;
  final String value;
  final AppThemeColors colors;
  final bool center;
  final ValueChanged<String> onChanged;

  const _SmallInput({
    required this.hint,
    required this.value,
    required this.colors,
    this.center = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontSize: 12,
        color: colors.textPrimary,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 11.5,
          color: colors.textHint,
          fontFamily: 'Poppins',
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: AppColors.primaryOrange,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _SmallNumber extends StatelessWidget {
  final String hint;
  final double value;
  final AppThemeColors colors;
  final bool decimal;
  final ValueChanged<double> onChanged;

  const _SmallNumber({
    required this.hint,
    required this.value,
    required this.colors,
    this.decimal = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value == 0
          ? ''
          : (decimal ? value.toStringAsFixed(2) : value.toStringAsFixed(0)),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
      style: TextStyle(
        fontSize: 12,
        color: colors.textPrimary,
        fontFamily: 'Poppins',
      ),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 11.5,
          color: colors.textHint,
          fontFamily: 'Poppins',
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: AppColors.primaryOrange,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/shared/widgets/async_button.dart';
import 'package:shc_stock/app/modules/purchase/controllers/purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/controllers/add_purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/models/purchase_model.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/clients/widgets/client_autocomplete_field.dart';
import 'package:shc_stock/app/shared/widgets/form_fields.dart';
import 'package:shc_stock/app/shared/widgets/section_card.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Add Purchase — tax-invoice style entry form
// All form state lives in AddPurchaseController (registered by PurchaseBinding)
// — no setState anywhere in this file.
// ─────────────────────────────────────────────────────────────────────────────
class WebNewPurchaseLayout extends GetView<AddPurchaseController> {
  const WebNewPurchaseLayout({super.key});

  Future<void> _savePurchase() async {
    final c = Get.find<PurchaseController>();
    // Editing keeps the record's own id, PO number and status — only the
    // details being edited change.
    final editing = controller.editing;
    final newId = editing?.id ?? 'po_${DateTime.now().millisecondsSinceEpoch}';
    final newPoNum =
        editing?.poNumber ??
        'PO-2024-${(10000 + c.orders.length + 1).toString().padLeft(5, '0')}';
    final supplierName = controller.client.value.isEmpty
        ? 'Unknown Supplier'
        : controller.client.value;
    final order = PurchaseOrder(
      id: newId,
      poNumber: newPoNum,
      supplier: supplierName,
      supplierIcon: supplierName.substring(0, 2).toUpperCase(),
      date: controller.invoiceDate.value ?? DateTime.now(),
      itemCount: controller.items.length,
      amount: controller.grandTotal,
      status: editing?.status ?? PurchaseStatus.pending,
      modifiedBy: currentActorName,
      modifiedAt: DateTime.now(),
      supplierAddress: controller.addressCtrl.text.trim(),
      buyerGst: controller.buyerGstCtrl.text.trim(),
      pan: controller.panCtrl.text.trim(),
      invoiceNo: controller.invoiceNoCtrl.text.trim().isEmpty
          ? newPoNum
          : controller.invoiceNoCtrl.text.trim(),
      invoiceDate: controller.invoiceDate.value,
      despatchThrough: controller.despatchThrough.value,
      lrNo: controller.lrNoCtrl.text.trim(),
      lrDate: controller.lrDate.value,
      vehicleNo: controller.vehicleNoCtrl.text.trim(),
      freight: double.tryParse(controller.freightCtrl.text.trim()) ?? 0,
      placeOfSupply: controller.placeOfSupplyCtrl.text.trim(),
      dueDate: controller.dueDate.value,
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
    );

    final ok = editing == null
        ? await c.addOrder(order)
        : await c.updateOrder(order);
    if (!ok) return; // controller already showed the error toast
    Get.offNamed(AppRoutes.purchase);
    showAppToast(
      editing == null ? '✅ Purchase Saved' : '✅ Purchase Updated',
      editing == null
          ? '$newPoNum has been successfully created.'
          : '$newPoNum has been successfully updated.',
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
    );
  }

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
                                    fontFamily: 'Poppins',
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
                                    fontFamily: 'Poppins',
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
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppField(
                                        label: 'State & PIN',
                                        colors: colors,
                                        child: AppTextBox(
                                          controller: controller.statePinCtrl,
                                          hint: 'e.g. Gujarat - 380001',
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
                                    const Expanded(child: SizedBox()),
                                    const SizedBox(width: 16),
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
                                      AppTotalRow(
                                        label: 'SGST (9%)',
                                        value:
                                            '₹${controller.sgst.toStringAsFixed(0)}',
                                        colors: colors,
                                      ),
                                      const SizedBox(height: 10),
                                      AppTotalRow(
                                        label: 'CGST (9%)',
                                        value:
                                            '₹${controller.cgst.toStringAsFixed(0)}',
                                        colors: colors,
                                      ),
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
                                  fontFamily: 'Poppins',
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            AppAsyncButton(
                              label: controller.isEditing
                                  ? 'Update Purchase'
                                  : 'Save Purchase',
                              onPressed: _savePurchase,
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
const int _cNoPkg = 8;
const int _cAvgCont = 10;
const int _cTotalQty = 13;
const int _cUom = 9;
const int _cNetPrice = 11;
const int _cAmount = 14;

class _ItemDetailsTable extends StatelessWidget {
  final List<PurchaseItemRow> items;
  final AppThemeColors colors;
  final VoidCallback onChanged;
  final void Function(int) onDelete;

  const _ItemDetailsTable({
    required this.items,
    required this.colors,
    required this.onChanged,
    required this.onDelete,
  });

  TextStyle get _h => TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: colors.textSecondary,
    fontFamily: 'Poppins',
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: colors.rowEven,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                flex: _cItem,
                child: Text('Item (type to search)', style: _h),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: _cHsn,
                child: Text('HSN', style: _h, textAlign: TextAlign.center),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: _cGrade,
                child: Text('Grade', style: _h, textAlign: TextAlign.center),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: _cDensity,
                child: Text('Density', style: _h, textAlign: TextAlign.center),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: _cNoPkg,
                child: Text('No. Pkg', style: _h, textAlign: TextAlign.center),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: _cAvgCont,
                child: Text(
                  'Avg Cont/Pkg',
                  style: _h,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: _cTotalQty,
                child: Text(
                  'Total Qty',
                  style: _h,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: _cUom,
                child: Text('UoM', style: _h, textAlign: TextAlign.center),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: _cNetPrice,
                child: Text('Net Price', style: _h, textAlign: TextAlign.right),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: _cAmount,
                child: Text('Amount', style: _h, textAlign: TextAlign.right),
              ),
              const SizedBox(width: 28),
            ],
          ),
        ),
        Divider(height: 1, color: colors.divider),
        ...items.asMap().entries.map(
          (e) => _ItemDetailsRow(
            key: ValueKey(e.value.id),
            row: e.value,
            colors: colors,
            onChanged: onChanged,
            onDelete: () => onDelete(e.key),
          ),
        ),
      ],
    );
  }
}

class _ItemDetailsRow extends StatelessWidget {
  static final _densityNum = RegExp(r'(\d+(?:\.\d+)?)\s*kg/m');
  static final _gradeNum = RegExp(r'(\d+)\s*°?C');

  final PurchaseItemRow row;
  final AppThemeColors colors;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _ItemDetailsRow({
    super.key,
    required this.row,
    required this.colors,
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
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider, width: 0.8)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: _cItem,
            child: _ProductAutocomplete(
              initialValue: row.product,
              colors: colors,
              onSelected: _applyProduct,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: _cHsn,
            child: AppSmallInput(
              key: ValueKey('${row.id}_hsn_${row.version}'),
              hint: '—',
              value: row.hsn,
              colors: colors,
              center: true,
              onChanged: (v) {
                row.hsn = v;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: _cGrade,
            child: AppSmallInput(
              key: ValueKey('${row.id}_grade_${row.version}'),
              hint: '—',
              value: row.grade,
              colors: colors,
              center: true,
              onChanged: (v) {
                row.grade = v;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: _cDensity,
            child: AppSmallInput(
              key: ValueKey('${row.id}_density_${row.version}'),
              hint: '—',
              value: row.density,
              colors: colors,
              center: true,
              onChanged: (v) {
                row.density = v;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: _cNoPkg,
            child: AppSmallNumber(
              value: row.noPkg,
              colors: colors,
              onChanged: (v) {
                row.noPkg = v;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: _cAvgCont,
            child: AppSmallNumber(
              value: row.avgContPerPkg,
              colors: colors,
              onChanged: (v) {
                row.avgContPerPkg = v;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: _cTotalQty,
            // Editable, with ± steppers — the total used to be a read-only
            // readout of packs x per-pack, so a plain quantity could only be
            // entered through those two boxes.
            child: AppSmallStepper(
              value: row.totalQty,
              colors: colors,
              onChanged: (v) {
                row.totalQty = v;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: _cUom,
            child: AppSmallDrop(
              hint: 'UoM',
              items: const ['BOX', 'KG', 'PCS', 'MTR', 'LTR', 'SET'],
              value: row.uom.isEmpty ? null : row.uom,
              colors: colors,
              onChanged: (v) {
                row.uom = v ?? 'BOX';
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: _cNetPrice,
            child: AppSmallNumber(
              key: ValueKey('${row.id}_netPrice_${row.version}'),
              value: row.netPrice,
              colors: colors,
              decimal: true,
              onChanged: (v) {
                row.netPrice = v;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: _cAmount,
            child: Text(
              '₹${row.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 28,
            child: IconButton(
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              icon: const Icon(
                Icons.close_rounded,
                color: Color(0xFFEF4444),
                size: 16,
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
// an option fetches its HSN, density/grade (parsed from the name), UoM and
// cost price into the row.
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
          onSubmitted: (_) => onSubmit(),
          style: TextStyle(
            fontSize: 12,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
          decoration: InputDecoration(
            hintText: 'Type e.g. Ceramic Fiber Blanket 1260...',
            hintStyle: TextStyle(
              fontSize: 12,
              color: colors.textHint,
              fontFamily: 'Poppins',
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
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
      },
      optionsViewBuilder: (context, onSelect, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            color: colors.surface,
            child: Container(
              width: 380,
              constraints: const BoxConstraints(maxHeight: 260),
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
                  final highlighted =
                      AutocompleteHighlightedOption.of(context) == index;
                  if (highlighted) {
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      Scrollable.ensureVisible(context, alignment: 0.5);
                    });
                  }
                  return Container(
                    color: highlighted
                        ? AppColors.primaryOrange.withValues(alpha: 0.1)
                        : null,
                    child: InkWell(
                      onTap: () => onSelect(p),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
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
                                      fontSize: 13,
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
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
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

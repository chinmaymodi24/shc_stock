import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import '../controllers/sales_controller.dart';
import '../controllers/add_sale_controller.dart';
import '../models/sales_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/widgets/web_sidebar.dart';
import '../../dashboard/widgets/web_top_bar.dart';
import '../../products/controllers/products_controller.dart';
import '../../products/models/product_model.dart';
import '../../clients/models/client_model.dart';
import '../../clients/widgets/client_autocomplete_field.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../core/utils/app_toast.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Add Sell — tax-invoice style entry form
// All form state lives in AddSaleController (registered by SalesBinding) —
// no setState anywhere in this file.
// ─────────────────────────────────────────────────────────────────────────────
class WebNewSalesLayout extends GetView<AddSaleController> {
  const WebNewSalesLayout({super.key});

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
                              onTap: () => Get.back(),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add Sell',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Enter details as they appear on the sales tax invoice',
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
                                        colors: colors,
                                        child: ClientAutocompleteField(
                                          initialValue: controller.client.value,
                                          colors: colors,
                                          hint: 'Type to search client...',
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
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: AppField(
                                        label: 'State & PIN',
                                        colors: colors,
                                        child: AppTextBox(
                                          controller: controller.statePinCtrl,
                                          hint: 'Gujarat - 380001',
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
                                Container(
                                  width: 340,
                                  padding: const EdgeInsets.all(16),
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
                                        value:
                                            '₹${controller.cgst.toStringAsFixed(0)}',
                                        colors: colors,
                                      ),
                                      const SizedBox(height: 10),
                                      AppTotalRow(
                                        label: 'SGST (9%)',
                                        value:
                                            '₹${controller.sgst.toStringAsFixed(0)}',
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
                              onPressed: () => Get.back(),
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
                            ElevatedButton(
                              onPressed: _saveSale,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryOrange,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 13,
                                ),
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
const double _iQtyWidth = 80.0;
const double _iUomWidth = 90.0;
const double _iRateWidth = 100.0;
const double _iAmtWidth = 100.0;
const double _iDelWidth = 32.0;

class _ItemDetailsTable extends StatelessWidget {
  final List<SaleItemRow> items;
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
                flex: _iItemFlex,
                child: Text('Item (type to search)', style: _h),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: _iHsnWidth,
                child: Text('HSN/SAC', style: _h, textAlign: TextAlign.center),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: _iQtyWidth,
                child: Text('Quantity', style: _h, textAlign: TextAlign.center),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: _iUomWidth,
                child: Text('UoM', style: _h, textAlign: TextAlign.center),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: _iRateWidth,
                child: Text('Rate', style: _h, textAlign: TextAlign.right),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: _iAmtWidth,
                child: Text('Amount', style: _h, textAlign: TextAlign.right),
              ),
              SizedBox(width: _iDelWidth),
            ],
          ),
        ),
        Divider(height: 1, color: colors.divider),
        ...items.asMap().entries.map(
          (e) => _ItemDetailsRow(
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
  final SaleItemRow row;
  final AppThemeColors colors;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _ItemDetailsRow({
    required this.row,
    required this.colors,
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
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider, width: 0.8)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: _iItemFlex,
            child: _ProductAutocomplete(
              initialValue: row.product,
              colors: colors,
              onSelected: _applyProduct,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: _iHsnWidth,
            child: AppSmallInput(
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
          SizedBox(
            width: _iQtyWidth,
            child: AppSmallNumber(
              value: row.qty,
              colors: colors,
              onChanged: (v) {
                row.qty = v;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: _iUomWidth,
            child: AppSmallInput(
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
          const SizedBox(width: 8),
          SizedBox(
            width: _iRateWidth,
            child: AppSmallNumber(
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
          SizedBox(
            width: _iAmtWidth,
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
            width: _iDelWidth,
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
          onSubmitted: (_) => onSubmit(),
          style: TextStyle(
            fontSize: 12.5,
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
              horizontal: 10,
              vertical: 8,
            ),
            filled: true,
            fillColor: colors.surface,
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 15,
              color: colors.textHint,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 20,
            ),
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
                              '₹${p.sellingPrice.toStringAsFixed(0)}',
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

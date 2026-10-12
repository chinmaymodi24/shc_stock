import 'package:shc_stock/app/core/session/app_modules.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/utils/units.dart';
import 'package:shc_stock/app/core/utils/qty_format.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/core/utils/stock_sync.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/views/add_product_dialog.dart';
import 'package:shc_stock/app/modules/stock/controllers/stock_controller.dart';
import 'package:shc_stock/app/modules/stock/models/stock_item_model.dart';
import 'package:shc_stock/app/modules/stock/views/stock_item_details_panel.dart';
import 'package:shc_stock/app/shared/widgets/async_button.dart';
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';
import 'package:shc_stock/app/shared/widgets/form_fields.dart';

part 'stock_adjustment_dialog_part1.dart';

ProductsController _productsController() {
  if (Get.isRegistered<ProductsController>()) {
    return Get.find<ProductsController>();
  }
  return Get.put(ProductsController(), permanent: true);
}

enum _AdjType { add, remove, reorderOnly }

extension on _AdjType {
  String get label => switch (this) {
    _AdjType.add => 'Add Stock (found extra / correction)',
    _AdjType.remove => 'Remove Stock (damage / loss / correction)',
    _AdjType.reorderOnly => 'Set Reorder Point Only',
  };

  String get qtyLabel => switch (this) {
    _AdjType.add => 'Quantity to Add',
    _AdjType.remove => 'Quantity to Remove',
    _AdjType.reorderOnly => 'New Reorder Point',
  };
}

const _kAdjTypeLabels = [
  'Add Stock (found extra / correction)',
  'Remove Stock (damage / loss / correction)',
  'Set Reorder Point Only',
];

const _kReasonPlaceholder = 'Select reason...';
const _kReasonOther = 'Other';
const _kOtherReasonMax = 200;
const _kReasons = [
  _kReasonPlaceholder,
  'Physical count correction',
  'Damaged / defective goods',
  'Theft / loss',
  'Opening balance entry',
  'Other',
];

/// "Stock Adjustment" — the manual counterpart to the automatic stock moves
/// purchases and sales make. Opened from Inventory's "Adjust Stock" button
/// (web_stock_layout.dart); books a stock_movements entry via
/// StockController.adjustStock, or (Set Reorder Point Only) just updates the
/// product's minimumStock — it never touches currentStock directly.
class StockAdjustmentDialog extends StatefulWidget {
  const StockAdjustmentDialog({super.key});

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _qtyCtrl = TextEditingController(text: '1');

  /// Optional — left blank most of the time. Only feeds the Item Details
  /// ledger's amount column when the person doing the adjustment actually
  /// knows/wants to record a per-unit price (e.g. an opening-balance entry).
  final _priceCtrl = TextEditingController();
  // Reactive (no setState): the dialog body is one Obx, so changing any of
  // these redraws it.
  final Rx<StockItemModel?> _selectedRx = Rx<StockItemModel?>(null);
  final Rx<_AdjType> _typeRx = _AdjType.add.obs;
  final RxString _reasonRx = _kReasonPlaceholder.obs;

  /// Bumped when the quantity text changes, so the "new stock" preview — which
  /// reads the text box, not an Rx — redraws.
  final RxInt _qtyTick = 0.obs;

  StockItemModel? get _selected => _selectedRx.value;
  set _selected(StockItemModel? v) => _selectedRx.value = v;
  _AdjType get _type => _typeRx.value;
  set _type(_AdjType v) => _typeRx.value = v;
  String get _reason => _reasonRx.value;
  set _reason(String v) => _reasonRx.value = v;

  /// The person's own words when the reason is "Other"; this is what gets
  /// saved as the movement's note.
  final _otherCtrl = TextEditingController();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _otherCtrl.dispose();
    _selectedRx.close();
    _typeRx.close();
    _reasonRx.close();
    _qtyTick.close();
    super.dispose();
  }

  /// Decimals allowed — whether they make sense depends on the unit (below).
  double get _qty => double.tryParse(_qtyCtrl.text.trim()) ?? 0;

  /// Null when there's nothing to preview (no item picked yet, or the type
  /// doesn't touch currentStock at all).
  double? get _previewStock {
    final sel = _selected;
    if (sel == null) return null;
    switch (_type) {
      case _AdjType.add:
        return sel.stockInHand + _qty;
      case _AdjType.remove:
        final left = sel.stockInHand - _qty;
        return left < 0 ? 0 : left;
      case _AdjType.reorderOnly:
        return null;
    }
  }

  void _onTypeChanged(String? label) {
    final type = _AdjType.values.firstWhere((t) => t.label == label);
    _type = type;
    // Reorder Point starts from the item's current reorder point, not "1".
    if (type == _AdjType.reorderOnly && _selected != null) {
      _qtyCtrl.text = fmtStockQty(_selected!.minimumStock);
    } else if (_qtyCtrl.text == '0') {
      _qtyCtrl.text = '1';
    }
    _qtyTick.value++;
  }

  /// Opens the same read-only "Item Details" panel as Inventory's row-level
  /// View action, so the full purchase/sale ledger behind the number is one
  /// tap away without leaving the adjustment flow. Edit/Delete inside it are
  /// wired the same way too; a delete there also closes this dialog, since
  /// the item it was adjusting no longer exists.
  void _openFullHistory() {
    final sel = _selected;
    if (sel == null) return;
    Get.dialog(
      StockItemDetailsPanel(
        item: sel,
        onEdit: () {
          if (!requireWrite('Products')) return;
          final product = _productsController().products.firstWhereOrNull(
            (p) => p.id == sel.productId.toString(),
          );
          Get.back(); // close the details panel
          if (product != null) {
            Get.dialog(AddProductDialog(product: product));
          }
        },
        onDelete: () {
          if (!requireWrite('Products')) return;
          Get.back(); // close the details panel
          // This dialog's own route, captured now: after the await a refusal
          // toast may be on top, and Get.back() would close that instead.
          final route = ModalRoute.of(context);
          final navigator = Navigator.of(context);
          confirmDelete(
            context,
            itemName: sel.name,
            itemLabel: 'Product',
            onConfirm: () async {
              final id = sel.productId.toString();
              await _productsController().deleteProduct(id);
              await refreshStockViews();
              // Close this adjustment dialog too — but only when the product is
              // really gone (a product with history is refused and stays).
              final gone = !_productsController().products.any(
                (p) => p.id == id,
              );
              if (gone &&
                  route != null &&
                  route.isActive &&
                  navigator.canPop()) {
                navigator.removeRoute(route);
              }
            },
          );
        },
      ),
    );
  }

  void _onItemSelected(StockItemModel item) {
    _selected = item;
    if (_type == _AdjType.reorderOnly) {
      _qtyCtrl.text = fmtStockQty(item.minimumStock);
    }
    _qtyTick.value++;
  }

  Future<void> _save() async {
    final sel = _selected;
    if (sel == null) {
      showAppToast(
        'Error',
        'Please select an item.',
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
      );
      return;
    }
    if (_type == _AdjType.reorderOnly ? _qty < 0 : _qty <= 0) {
      showAppToast(
        'Error',
        _type == _AdjType.reorderOnly
            ? 'Reorder point cannot be negative.'
            : 'Quantity must be greater than 0.',
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
      );
      return;
    }
    // A counted unit (pieces, rolls, bags) is moved in whole units only.
    if (_type != _AdjType.reorderOnly &&
        _qty != _qty.roundToDouble() &&
        !unitAllowsFraction(sel.unit)) {
      showAppToast(
        'Error',
        '"${sel.name}" is counted in ${sel.unit} — use a whole number.',
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
      );
      return;
    }
    if (_reason == _kReasonPlaceholder) {
      showAppToast(
        'Error',
        'Please select a reason.',
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
      );
      return;
    }
    final other = _otherCtrl.text.trim();
    if (_reason == _kReasonOther && other.isEmpty) {
      showAppToast(
        'Error',
        'Please write the reason.',
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
      );
      return;
    }
    final priceText = _priceCtrl.text.trim();
    double? price;
    if (priceText.isNotEmpty) {
      price = double.tryParse(priceText);
      if (price == null || price < 0) {
        showAppToast(
          'Error',
          'Price must be 0 or more.',
          backgroundColor: AppColors.danger,
          colorText: Colors.white,
        );
        return;
      }
    }

    final c = Get.find<StockController>();
    final ok = _type == _AdjType.reorderOnly
        ? await c.updateItem(sel.productId, minimumStock: _qty)
        : await c.adjustStock(
            productId: sel.productId,
            type: _type == _AdjType.add ? 'IN' : 'OUT',
            qty: _qty,
            note: _reason == _kReasonOther ? other : _reason,
            rate: price,
          );
    if (!ok) return; // controller already showed the error toast
    Get.back();
    showAppToast(
      '✅ Stock Updated',
      _type == _AdjType.reorderOnly
          ? '${sel.name}\'s reorder point is now ${fmtStockQty(_qty)}.'
          : '${sel.name} adjusted successfully.',
      backgroundColor: AppColors.success,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    _qtyTick.value; // the preview reads the text box: redraw when it changes
    return _buildBody(context);
  });

  Widget _buildBody(BuildContext context) {
    final colors = context.appColors;
    final sel = _selected;
    final preview = _previewStock;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      alignment: Alignment.centerRight,
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          // Full-width on phones — a fixed 440px side panel would overflow
          // (and mostly clip off-screen) on anything narrower than that.
          width: MediaQuery.of(context).size.width < 480
              ? MediaQuery.of(context).size.width
              : 440,
          height: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 24,
                offset: const Offset(-6, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Stock Adjustment',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              fontFamily: brandFontFamily,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: Get.back,
                          borderRadius: BorderRadius.circular(8),
                          child: Icon(
                            Icons.close_rounded,
                            color: colors.textSecondary,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Purchases and sales update stock automatically. Use '
                      'this only to correct a count, record damage/loss, or '
                      "set an item's reorder point.",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                        fontFamily: brandFontFamily,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.divider),

              // ── Body ──────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Item ──────────────────────────────────────
                      AppField(
                        label: 'Item',
                        colors: colors,
                        child: _ItemAutocomplete(
                          colors: colors,
                          onSelected: _onItemSelected,
                          onTextChanged: (text) {
                            if (sel != null && text != sel.name) {
                              _selected = null;
                            }
                          },
                        ),
                      ),

                      if (sel != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(
                              appColors.radius,
                            ),
                            border: Border.all(
                              color: AppColors.primaryOrange.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sel.name,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryOrange,
                                        fontFamily: brandFontFamily,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'SKU: ${sel.sku} · Category: ${sel.category}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: colors.textSecondary,
                                        fontFamily: brandFontFamily,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Current Stock',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.textSecondary,
                                      fontFamily: brandFontFamily,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    fmtStockQty(sel.stockInHand),
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                      fontFamily: brandFontFamily,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: _openFullHistory,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 16,
                                  color: colors.accent,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Show Full History',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colors.accent,
                                    fontFamily: brandFontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // ── Adjustment Type ──────────────────────────────────
                      AppField(
                        label: 'Adjustment Type',
                        colors: colors,
                        child: AppDropBox(
                          hint: 'Select type...',
                          value: _type.label,
                          items: _kAdjTypeLabels,
                          colors: colors,
                          onChanged: _onTypeChanged,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Quantity / Reorder Point ─────────────────────────
                      AppField(
                        label: _type.qtyLabel,
                        colors: colors,
                        child: TextField(
                          controller: _qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            // Up to 3 decimals (12.5 kg, 0.125 kg).
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,3}'),
                            ),
                          ],
                          onChanged: (_) => _qtyTick.value++,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textPrimary,
                            fontFamily: brandFontFamily,
                          ),
                          decoration: InputDecoration(
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
                              borderSide: BorderSide(
                                color: AppColors.primaryOrange,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_type != _AdjType.reorderOnly) ...[
                        const SizedBox(height: 14),
                        // ── Price per unit (optional) ──────────────────────
                        AppField(
                          label: 'Price per Unit (optional)',
                          colors: colors,
                          child: TextField(
                            controller: _priceCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textPrimary,
                              fontFamily: brandFontFamily,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'e.g. 350 — shown on Item Details if set',
                              hintStyle: TextStyle(
                                fontSize: 12.5,
                                color: colors.textHint,
                                fontFamily: brandFontFamily,
                              ),
                              isDense: true,
                              prefixText: '₹ ',
                              prefixStyle: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                                fontFamily: brandFontFamily,
                              ),
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
                                borderSide: BorderSide(
                                  color: AppColors.primaryOrange,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // ── Reason ────────────────────────────────────────────
                      AppField(
                        label: 'Reason',
                        colors: colors,
                        child: AppDropBox(
                          hint: _kReasonPlaceholder,
                          value: _reason,
                          items: _kReasons,
                          colors: colors,
                          onChanged: (v) => _reason = v ?? _reason,
                        ),
                      ),
                      if (_reason == _kReasonOther) ...[
                        const SizedBox(height: 10),
                        AppTextBox(
                          controller: _otherCtrl,
                          hint: 'Write the reason',
                          colors: colors,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(_kOtherReasonMax),
                          ],
                        ),
                      ],

                      if (preview != null) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              'New Stock After Adjustment',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colors.textSecondary,
                                fontFamily: brandFontFamily,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              fmtStockQty(preview),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryOrange,
                                fontFamily: brandFontFamily,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Footer ────────────────────────────────────────────
              Divider(height: 1, color: colors.divider),
              Padding(
                padding: const EdgeInsets.all(16),
                // IntrinsicHeight + stretch rather than trusting matching
                // padding to land on the same pixel height — see
                // web_categories_layout.dart's identical fix.
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: Get.back,
                          borderRadius: BorderRadius.circular(appColors.radius),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: colors.background.computeLuminance() > 0.5
                                  ? const Color(0xFFF3F1EC)
                                  : colors.inputFill,
                              borderRadius: BorderRadius.circular(
                                appColors.radius,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                                fontFamily: brandFontFamily,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppAsyncButton(
                          label: 'Save',
                          onPressed: _save,
                          expand: true,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          radius: 10,
                        ),
                      ),
                    ],
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

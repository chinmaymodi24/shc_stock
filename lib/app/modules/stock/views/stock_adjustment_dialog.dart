import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
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
  StockItemModel? _selected;
  _AdjType _type = _AdjType.add;
  String _reason = _kReasonPlaceholder;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  int get _qty => int.tryParse(_qtyCtrl.text.trim()) ?? 0;

  /// Null when there's nothing to preview (no item picked yet, or the type
  /// doesn't touch currentStock at all).
  int? get _previewStock {
    final sel = _selected;
    if (sel == null) return null;
    switch (_type) {
      case _AdjType.add:
        return sel.stockInHand + _qty;
      case _AdjType.remove:
        return sel.stockInHand - _qty < 0 ? 0 : sel.stockInHand - _qty;
      case _AdjType.reorderOnly:
        return null;
    }
  }

  void _onTypeChanged(String? label) {
    final type = _AdjType.values.firstWhere((t) => t.label == label);
    setState(() {
      _type = type;
      // Reorder Point starts from the item's current reorder point, not "1".
      if (type == _AdjType.reorderOnly && _selected != null) {
        _qtyCtrl.text = _selected!.minimumStock.toString();
      } else if (_qtyCtrl.text == '0') {
        _qtyCtrl.text = '1';
      }
    });
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
          final product = _productsController().products.firstWhereOrNull(
            (p) => p.id == sel.productId.toString(),
          );
          Get.back(); // close the details panel
          if (product != null) {
            Get.dialog(AddProductDialog(product: product));
          }
        },
        onDelete: () {
          Get.back(); // close the details panel
          confirmDelete(
            context,
            itemName: sel.name,
            itemLabel: 'Product',
            onConfirm: () async {
              await _productsController().deleteProduct(
                sel.productId.toString(),
              );
              await refreshStockViews();
              Get.back(); // close this adjustment dialog too
            },
          );
        },
      ),
    );
  }

  void _onItemSelected(StockItemModel item) {
    setState(() {
      _selected = item;
      if (_type == _AdjType.reorderOnly) {
        _qtyCtrl.text = item.minimumStock.toString();
      }
    });
  }

  Future<void> _save() async {
    final sel = _selected;
    if (sel == null) {
      showAppToast(
        'Error',
        'Please select an item.',
        backgroundColor: const Color(0xFFEF4444),
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
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }
    if (_reason == _kReasonPlaceholder) {
      showAppToast(
        'Error',
        'Please select a reason.',
        backgroundColor: const Color(0xFFEF4444),
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
          backgroundColor: const Color(0xFFEF4444),
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
            qty: _qty.toDouble(),
            note: _reason,
            rate: price,
          );
    if (!ok) return; // controller already showed the error toast
    Get.back();
    showAppToast(
      '✅ Stock Updated',
      _type == _AdjType.reorderOnly
          ? '${sel.name}\'s reorder point is now $_qty.'
          : '${sel.name} adjusted successfully.',
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                              fontFamily: 'Poppins',
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
                        fontFamily: 'Poppins',
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
                              setState(() => _selected = null);
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
                            borderRadius: BorderRadius.circular(10),
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
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryOrange,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'SKU: ${sel.sku} · Category: ${sel.category}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: colors.textSecondary,
                                        fontFamily: 'Poppins',
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
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${sel.stockInHand}',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                      fontFamily: 'Poppins',
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
                                    fontFamily: 'Poppins',
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
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
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
                              borderSide: const BorderSide(
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
                              fontFamily: 'Poppins',
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. 350 — shown on Item Details if set',
                              hintStyle: TextStyle(
                                fontSize: 12.5,
                                color: colors.textHint,
                                fontFamily: 'Poppins',
                              ),
                              isDense: true,
                              prefixText: '₹ ',
                              prefixStyle: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                                fontFamily: 'Poppins',
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
                                borderSide: const BorderSide(
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
                          onChanged: (v) =>
                              setState(() => _reason = v ?? _reason),
                        ),
                      ),

                      if (preview != null) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              'New Stock After Adjustment',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colors.textSecondary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$preview',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryOrange,
                                fontFamily: 'Poppins',
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
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: Get.back,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: colors.background.computeLuminance() > 0.5
                                ? const Color(0xFFF3F1EC)
                                : colors.inputFill,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Cancel',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              fontFamily: 'Poppins',
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Item search — typing filters the loaded inventory list by name or SKU;
/// selecting an option hands the full [StockItemModel] back. Mirrors
/// ClientAutocompleteField's pattern (Flutter's built-in Autocomplete, so
/// arrow keys + Enter just work).
class _ItemAutocomplete extends StatelessWidget {
  final AppThemeColors colors;
  final ValueChanged<StockItemModel> onSelected;
  final ValueChanged<String> onTextChanged;

  const _ItemAutocomplete({
    required this.colors,
    required this.onSelected,
    required this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = Get.find<StockController>().items;
    return Autocomplete<StockItemModel>(
      displayStringForOption: (i) => i.name,
      optionsBuilder: (textEditingValue) {
        final q = textEditingValue.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<StockItemModel>.empty();
        return items
            .where(
              (i) =>
                  i.name.toLowerCase().contains(q) ||
                  i.sku.toLowerCase().contains(q),
            )
            .take(30);
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, textCtrl, focusNode, onSubmit) {
        return TextField(
          controller: textCtrl,
          focusNode: focusNode,
          onSubmitted: (_) => onSubmit(),
          onChanged: onTextChanged,
          style: TextStyle(
            fontSize: 13,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
          decoration: InputDecoration(
            hintText: 'Type item name or SKU...',
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
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 18,
              color: colors.textHint,
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
                width: 1.5,
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
              width: 432,
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
                  final item = options.elementAt(index);
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
                      onTap: () => onSelect(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                  fontFamily: 'Poppins',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'Current stock: ${item.stockInHand}',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textHint,
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

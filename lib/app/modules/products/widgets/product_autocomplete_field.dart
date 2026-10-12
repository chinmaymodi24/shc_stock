import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/products/widgets/stock_badge.dart';
import 'package:shc_stock/app/shared/widgets/overlay_autocomplete_field.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Product name typeahead for the Add Purchase / Add Sale item rows.
//
// Built on [OverlayAutocompleteField] rather than the framework's
// `Autocomplete`, which always drops its list below the field and so hid it
// behind the soft keyboard on mobile — see that widget for the full story.
// ─────────────────────────────────────────────────────────────────────────────
class ProductAutocompleteField extends StatelessWidget {
  final String initialValue;
  final AppThemeColors colors;
  final ValueChanged<ProductModel> onSelected;

  /// The text as typed, for a line that is not one of the listed products.
  final ValueChanged<String>? onTyped;

  /// Price shown on the right of each suggestion row — cost price on
  /// Purchase, selling price on Sale.
  final double Function(ProductModel product) priceOf;

  /// Sale only: show how many are in stock under each suggestion.
  final bool showStock;

  /// Sale only: why a product cannot be picked (nothing left to sell), or null
  /// when it can. Such a product stays in the list, greyed out with the reason
  /// under its name, and tapping it does nothing.
  final String? Function(ProductModel product)? blockReason;

  const ProductAutocompleteField({
    super.key,
    required this.initialValue,
    required this.colors,
    required this.onSelected,
    this.onTyped,
    required this.priceOf,
    this.showStock = false,
    this.blockReason,
  });

  @override
  Widget build(BuildContext context) {
    final products = Get.find<ProductsController>().products;
    return OverlayAutocompleteField<ProductModel>(
      initialValue: initialValue,
      colors: colors,
      maxDropdownHeight: 240,
      optionsFor: (query) {
        final q = query.toLowerCase();
        return products
            .where((p) => p.isActive && p.name.toLowerCase().contains(q))
            .take(30)
            .toList();
      },
      displayStringFor: (p) => p.name,
      onSelected: onSelected,
      isSelectable: blockReason == null ? null : (p) => blockReason!(p) == null,
      onTextChanged: onTyped,
      textStyle: TextStyle(
        fontSize: 13,
        color: colors.textPrimary,
        fontFamily: brandFontFamily,
      ),
      decoration: InputDecoration(
        hintText: 'Type e.g. Ceramic Fiber Blanket 1260...',
        hintStyle: TextStyle(
          fontSize: 12.5,
          color: colors.textHint,
          fontFamily: brandFontFamily,
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
          borderSide: BorderSide(color: AppColors.primaryOrange, width: 1.2),
        ),
      ),
      optionBuilder: (context, p, highlighted) {
        final blocked = blockReason?.call(p);
        return Opacity(
          opacity: blocked == null ? 1 : 0.7,
          child: Container(
            color: highlighted && blocked == null
                ? AppColors.primaryOrange.withValues(alpha: 0.1)
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          fontFamily: brandFontFamily,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'HSN ${p.hsnCode ?? '—'} · ${p.unit}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textHint,
                                fontFamily: brandFontFamily,
                              ),
                            ),
                          ),
                          if (showStock && blocked == null) ...[
                            const SizedBox(width: 8),
                            StockBadge(product: p, colors: colors),
                          ],
                        ],
                      ),
                      if (blocked != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 12,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                blocked,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '₹${priceOf(p).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                    fontFamily: brandFontFamily,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

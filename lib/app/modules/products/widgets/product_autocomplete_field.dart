import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
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

  /// Price shown on the right of each suggestion row — cost price on
  /// Purchase, selling price on Sale.
  final double Function(ProductModel product) priceOf;

  const ProductAutocompleteField({
    super.key,
    required this.initialValue,
    required this.colors,
    required this.onSelected,
    required this.priceOf,
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
            .where((p) => p.name.toLowerCase().contains(q))
            .take(30)
            .toList();
      },
      displayStringFor: (p) => p.name,
      onSelected: onSelected,
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
      optionBuilder: (context, p, highlighted) => Container(
        color: highlighted
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
                  Text(
                    'HSN ${p.hsnCode ?? '—'} · ${p.unit}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textHint,
                      fontFamily: brandFontFamily,
                    ),
                  ),
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
  }
}

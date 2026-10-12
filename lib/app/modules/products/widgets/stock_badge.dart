import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/sales/utils/sale_stock_guard.dart';

/// "Out of stock" / "Low · 3 left" / "12 in stock" — shown beside a product in
/// the Add Sale suggestion list so a missing or short product is obvious
/// before it's picked.
class StockBadge extends StatelessWidget {
  final ProductModel product;
  final AppThemeColors colors;
  const StockBadge({super.key, required this.product, required this.colors});

  @override
  Widget build(BuildContext context) {
    final out = product.currentStock <= 0;
    final free = product.availableStock;
    final reserved = !out && free <= 0;
    final low = !out && !reserved && product.stockStatus == 'Low Stock';
    final color = out || reserved
        ? colors.error
        : low
        ? colors.warning
        : colors.textHint;
    final left = fmtStockQty(free.toDouble());
    final text = out
        ? 'Out of stock'
        : reserved
        ? 'All reserved'
        : low
        ? 'Low · $left left'
        : product.committedStock > 0
        ? '$left free'
        : '$left in stock';
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: out || reserved || low ? FontWeight.w700 : FontWeight.w500,
        color: color,
        fontFamily: brandFontFamily,
      ),
    );
  }
}

/// The line under an item row: a red blocking error, or an amber low-stock
/// heads-up. Draws nothing when there is neither.
class StockMessage extends StatelessWidget {
  final String? error;
  final String? note;
  final AppThemeColors colors;
  const StockMessage({
    super.key,
    required this.error,
    required this.note,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final text = error ?? note;
    if (text == null) return const SizedBox.shrink();
    final color = error != null ? colors.error : colors.warning;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error != null
                ? Icons.error_outline_rounded
                : Icons.warning_amber_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: brandFontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

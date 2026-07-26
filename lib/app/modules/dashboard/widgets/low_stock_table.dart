import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import '../models/dashboard_models.dart';

/// "Low stock alerts" panel — warning icon + product name + a red progress
/// bar showing current/max stock.
class LowStockTable extends StatelessWidget {
  final List<LowStockAlertItem> items;

  const LowStockTable({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) => _LowStockRow(item: item)).toList(),
    );
  }
}

class _LowStockRow extends StatelessWidget {
  final LowStockAlertItem item;

  const _LowStockRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ratio = item.max == 0
        ? 0.0
        : (item.current / item.max).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: colors.error,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.product,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    Text(
                      '${item.current}/${item.max}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: colors.error,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 5,
                    backgroundColor: colors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.error),
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

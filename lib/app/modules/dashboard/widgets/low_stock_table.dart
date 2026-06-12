import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import '../models/dashboard_models.dart';

class LowStockTable extends StatelessWidget {
  final List<LowStockItem> items;

  const LowStockTable({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(child: Text('Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textSecondary, fontFamily: 'Poppins'))),
              const SizedBox(width: 16),
              Text('Current Stock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textSecondary, fontFamily: 'Poppins')),
              const SizedBox(width: 24),
              Text('Minimum Stock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textSecondary, fontFamily: 'Poppins')),
            ],
          ),
        ),
        Divider(height: 1, color: colors.divider),
        ...items.map((item) => _LowStockRow(item: item)),
      ],
    );
  }
}

class _LowStockRow extends StatelessWidget {
  final LowStockItem item;

  const _LowStockRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(item.product,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: colors.textPrimary, fontFamily: 'Poppins')),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: Text(
              item.currentStock.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFEF4444), fontFamily: 'Poppins'),
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 80,
            child: Text(
              item.minimumStock.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }
}

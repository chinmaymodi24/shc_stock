import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';

class LowStockTable extends StatelessWidget {
  final List<LowStockItem> items;

  const LowStockTable({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: const [
              Expanded(child: Text('Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B6B8A), fontFamily: 'Poppins'))),
              SizedBox(width: 16),
              Text('Current Stock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B6B8A), fontFamily: 'Poppins')),
              SizedBox(width: 24),
              Text('Minimum Stock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B6B8A), fontFamily: 'Poppins')),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF0EFF8)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(item.product,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF1A1240), fontFamily: 'Poppins')),
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
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1240), fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }
}

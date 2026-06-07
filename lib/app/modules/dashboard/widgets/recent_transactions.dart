import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';
import '../../../core/theme/app_colors.dart';

class RecentTransactions extends StatelessWidget {
  final List<TransactionData> transactions;

  const RecentTransactions({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: transactions.asMap().entries.map((e) {
        final isLast = e.key == transactions.length - 1;
        return Column(
          children: [
            _TransactionRow(data: e.value),
            if (!isLast) const Divider(height: 1, color: Color(0xFFF0EFF8)),
          ],
        );
      }).toList(),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionData data;

  const _TransactionRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final isSales = data.type == 'Sales';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: isSales ? const Color(0xFF4A3AFF).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSales ? Icons.shopping_cart_outlined : Icons.receipt_long_outlined,
              size: 16,
              color: isSales ? const Color(0xFF4A3AFF) : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(data.type,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1A1240), fontFamily: 'Poppins')),
          ),
          Expanded(
            child: Text(data.invoiceNo,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B8A), fontFamily: 'Poppins')),
          ),
          Text(data.amount,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1240), fontFamily: 'Poppins')),
          const SizedBox(width: 16),
          Text(data.date,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B6B8A), fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}

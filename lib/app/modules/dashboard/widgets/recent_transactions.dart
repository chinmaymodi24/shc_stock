import 'package:flutter/material.dart';
import 'package:shc_stock/app/modules/dashboard/models/dashboard_models.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

class RecentTransactions extends StatelessWidget {
  final List<TransactionRow> transactions;

  const RecentTransactions({super.key, required this.transactions});

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
              Expanded(
                flex: 3,
                child: Text('Item', style: _headerStyle(colors)),
              ),
              Expanded(
                flex: 2,
                child: Text('Type', style: _headerStyle(colors)),
              ),
              Expanded(
                flex: 2,
                child: Text('Warehouse', style: _headerStyle(colors)),
              ),
              Expanded(
                flex: 2,
                child: Text('Date', style: _headerStyle(colors)),
              ),
              Expanded(
                flex: 2,
                child: Text('Status', style: _headerStyle(colors)),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.divider),
        ...transactions.asMap().entries.map((e) {
          final isLast = e.key == transactions.length - 1;
          return Column(
            children: [
              _TransactionRowTile(data: e.value),
              if (!isLast) Divider(height: 1, color: colors.divider),
            ],
          );
        }),
      ],
    );
  }

  TextStyle _headerStyle(AppThemeColors colors) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: colors.textSecondary,
    fontFamily: 'Poppins',
  );
}

class _TransactionRowTile extends StatelessWidget {
  final TransactionRow data;

  const _TransactionRowTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              data.item,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              data.type,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              data.warehouse,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              data.date,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(flex: 2, child: _StatusChip(status: data.status)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    late Color bg;
    late Color fg;
    switch (status) {
      case 'Received':
      case 'Delivered':
        bg = colors.success.withValues(alpha: 0.12);
        fg = colors.success;
      case 'Shipped':
        bg = AppColors.accentPurple.withValues(alpha: 0.12);
        fg = AppColors.accentPurple;
      case 'Pending':
        bg = colors.warning.withValues(alpha: 0.14);
        fg = colors.warning;
      default:
        bg = colors.divider;
        fg = colors.textSecondary;
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: fg,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';
import '../../../core/theme/app_colors.dart';

class StatCard extends StatelessWidget {
  final StatCardData data;
  final bool compact;

  const StatCard({super.key, required this.data, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(data.title, style: TextStyle(fontSize: compact ? 12 : 13, fontWeight: FontWeight.w500, color: colors.textSecondary, fontFamily: 'Poppins')),
              ),
              _buildIcon(),
            ],
          ),
          SizedBox(height: compact ? 6 : 10),
          Text(data.value, style: TextStyle(fontSize: compact ? 20 : 24, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins')),
          if (data.change != null) ...[
            const SizedBox(height: 4),
            Text(data.change!, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500,
              color: (data.isPositive ?? true) ? const Color(0xFF22C55E) : const Color(0xFFEF4444), fontFamily: 'Poppins')),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    switch (data.icon) {
      case StatCardIcon.box: icon = Icons.inventory_2_outlined;
      case StatCardIcon.warning: icon = Icons.warning_amber_rounded;
      case StatCardIcon.cart: icon = Icons.shopping_cart_outlined;
      case StatCardIcon.chart: icon = Icons.bar_chart_rounded;
    }
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: AppColors.primaryOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: AppColors.primaryOrange, size: 22),
    );
  }
}

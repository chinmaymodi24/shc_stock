import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const QuickActionButton({super.key, required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.divider),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primaryOrange, size: 32),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary, fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }
}

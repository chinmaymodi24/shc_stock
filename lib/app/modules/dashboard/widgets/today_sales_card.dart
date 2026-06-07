import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TodaySalesCard extends StatelessWidget {
  const TodaySalesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's Sales",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70, fontFamily: 'Poppins')),
                const SizedBox(height: 8),
                const Text('₹ 1,25,000',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.arrow_upward_rounded, color: Color(0xFF90EE90), size: 14),
                    const SizedBox(width: 2),
                    Text('+18% from yesterday',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF90EE90), fontFamily: 'Poppins')),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

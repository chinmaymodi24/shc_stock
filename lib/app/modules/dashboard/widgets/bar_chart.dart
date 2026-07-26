import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/dashboard_models.dart';

/// Simple flat-bar chart used for the "Purchases" / "Sales" (6 months) panels.
class SimpleBarChart extends StatelessWidget {
  final List<ChartPoint> data;
  final Color barColor;
  final double height;

  const SimpleBarChart({
    super.key,
    required this.data,
    required this.barColor,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (data.isEmpty) return SizedBox(height: height);

    final maxVal = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((point) {
          final ratio = maxVal == 0 ? 0.0 : point.value / maxVal;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: ratio.clamp(0.04, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    point.label,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

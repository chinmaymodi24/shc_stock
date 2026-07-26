import 'dart:math';
import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';
import '../../../core/theme/app_colors.dart';

/// Multi-slice donut with a dot-legend — used for "Sales by category".
class CategoryDonutChart extends StatelessWidget {
  final List<CategorySlice> slices;
  final double size;

  const CategoryDonutChart({super.key, required this.slices, this.size = 140});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(slices: slices),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: slices
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _LegendItem(
                      color: s.color,
                      label: s.label,
                      percent: s.percent,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double percent;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label — ${percent.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
              fontFamily: 'Poppins',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<CategorySlice> slices;

  _DonutPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 24.0;
    const gapAngle = 0.04;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final total = slices.fold<double>(0, (sum, s) => sum + s.percent);
    double startAngle = -pi / 2;

    for (final slice in slices) {
      final sweep = total == 0
          ? 0.0
          : (slice.percent / total) * 2 * pi - gapAngle;
      paint.color = slice.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

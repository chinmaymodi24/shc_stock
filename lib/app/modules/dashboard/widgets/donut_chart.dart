import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DonutChart extends StatelessWidget {
  final double inStock;
  final double lowStock;
  final double outOfStock;
  final int totalItems;

  const DonutChart({
    super.key,
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(180, 180),
                painter: _DonutPainter(
                  inStock: inStock,
                  lowStock: lowStock,
                  outOfStock: outOfStock,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    totalItems.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (m) => '${m[1]},'),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins'),
                  ),
                  Text('Total Items', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: colors.textSecondary, fontFamily: 'Poppins')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 28),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: AppColors.primaryOrange, label: 'In Stock', value: '1,001 (${inStock}%)'),
            const SizedBox(height: 16),
            _LegendItem(color: const Color(0xFFFBBF24), label: 'Low Stock', value: '179 (${lowStock}%)'),
            const SizedBox(height: 16),
            _LegendItem(color: const Color(0xFFEF4444), label: 'Out of Stock', value: '65 (${outOfStock}%)'),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary, fontFamily: 'Poppins')),
            Text(value, style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Poppins')),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double inStock;
  final double lowStock;
  final double outOfStock;

  _DonutPainter({required this.inStock, required this.lowStock, required this.outOfStock});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 28.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    const gapAngle = 0.035; // small gap between segments
    final total = inStock + lowStock + outOfStock;

    final inStockAngle = (inStock / total) * 2 * pi - gapAngle;
    final lowStockAngle = (lowStock / total) * 2 * pi - gapAngle;
    final outStockAngle = (outOfStock / total) * 2 * pi - gapAngle;

    double startAngle = -pi / 2;

    // In Stock - orange
    paint.color = AppColors.primaryOrange;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, inStockAngle, false, paint);
    startAngle += inStockAngle + gapAngle;

    // Low Stock - yellow
    paint.color = const Color(0xFFFBBF24);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, lowStockAngle, false, paint);
    startAngle += lowStockAngle + gapAngle;

    // Out of Stock - red
    paint.color = const Color(0xFFEF4444);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, outStockAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

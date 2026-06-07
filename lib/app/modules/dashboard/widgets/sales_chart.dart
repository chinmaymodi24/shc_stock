import 'dart:math';
import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';
import '../../../core/theme/app_colors.dart';

class SalesLineChart extends StatelessWidget {
  final List<SalesChartPoint> data;

  const SalesLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SalesChartPainter(data: data),
    );
  }
}

class _SalesChartPainter extends CustomPainter {
  final List<SalesChartPoint> data;

  _SalesChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double maxVal = 200000;
    final yLabels = [200000.0, 150000.0, 100000.0, 50000.0, 0.0];
    final double leftPad = 52;
    final double bottomPad = 32;
    final double topPad = 12;
    final double chartW = size.width - leftPad;
    final double chartH = size.height - bottomPad - topPad;

    final gridPaint = Paint()
      ..color = const Color(0xFFF0EFF8)
      ..strokeWidth = 1;

    final textStyle = const TextStyle(fontSize: 11, color: Color(0xFF9090AA), fontFamily: 'Poppins');

    // Draw Y grid lines and labels
    for (int i = 0; i < yLabels.length; i++) {
      final y = topPad + chartH * (1 - yLabels[i] / maxVal);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);

      String label;
      if (yLabels[i] == 0) label = '0';
      else label = '${(yLabels[i] / 1000).toInt()}K';

      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Compute point positions
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = leftPad + (i / (data.length - 1)) * chartW;
      final y = topPad + chartH * (1 - data[i].value / maxVal);
      points.add(Offset(x, y));
    }

    // Draw filled area under the line
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, topPad + chartH);
    for (final pt in points) fillPath.lineTo(pt.dx, pt.dy);
    fillPath.lineTo(points.last.dx, topPad + chartH);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primaryOrange.withValues(alpha: 0.15), AppColors.primaryOrange.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, topPad, size.width, chartH));
    canvas.drawPath(fillPath, fillPaint);

    // Draw smooth line
    final linePaint = Paint()
      ..color = AppColors.primaryOrange
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
      final cp2 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i + 1].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i + 1].dx, points[i + 1].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw dots
    final dotPaint = Paint()..color = AppColors.primaryOrange..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    for (final pt in points) {
      canvas.drawCircle(pt, 6, dotBorderPaint);
      canvas.drawCircle(pt, 4, dotPaint);
    }

    // Draw X labels
    for (int i = 0; i < data.length; i++) {
      final x = leftPad + (i / (data.length - 1)) * chartW;
      final tp = TextPainter(
        text: TextSpan(text: data[i].label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - bottomPad + 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

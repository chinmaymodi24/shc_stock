import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';
import '../../../core/theme/app_colors.dart';

class SalesLineChart extends StatelessWidget {
  final List<ChartPoint> data;
  final Color lineColor;

  const SalesLineChart({
    super.key,
    required this.data,
    this.lineColor = AppColors.primaryOrange,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Without an explicit width, a bare CustomPaint collapses to zero width
    // when its parent (a Column) only offers a loose 0..maxWidth constraint.
    return SizedBox(
      width: double.infinity,
      child: CustomPaint(
        painter: _SalesChartPainter(
          data: data,
          lineColor: lineColor,
          gridColor: colors.divider,
          labelColor: colors.textSecondary,
          dotBorderColor: colors.surface,
        ),
      ),
    );
  }
}

class _SalesChartPainter extends CustomPainter {
  final List<ChartPoint> data;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;
  final Color dotBorderColor;

  _SalesChartPainter({
    required this.data,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
    required this.dotBorderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double maxVal =
        data.map((d) => d.value).reduce((a, b) => a > b ? a : b) * 1.15;
    final double leftPad = 8;
    final double bottomPad = 24;
    final double topPad = 12;
    final double chartW = size.width - leftPad;
    final double chartH = size.height - bottomPad - topPad;

    final textStyle = TextStyle(
      fontSize: 11,
      color: labelColor,
      fontFamily: 'Poppins',
    );

    // Compute point positions
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x =
          leftPad + (data.length == 1 ? 0 : (i / (data.length - 1)) * chartW);
      final y =
          topPad + chartH * (1 - (maxVal == 0 ? 0 : data[i].value / maxVal));
      points.add(Offset(x, y));
    }

    // Draw filled area under the line
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, topPad + chartH);
    for (final pt in points) {
      fillPath.lineTo(pt.dx, pt.dy);
    }
    fillPath.lineTo(points.last.dx, topPad + chartH);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.18),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, topPad, size.width, chartH));
    canvas.drawPath(fillPath, fillPaint);

    // Draw smooth line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset((points[i].dx + points[i + 1].dx) / 2, points[i].dy);
      final cp2 = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        points[i + 1].dy,
      );
      linePath.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        points[i + 1].dx,
        points[i + 1].dy,
      );
    }
    canvas.drawPath(linePath, linePaint);

    // Draw dots
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = dotBorderColor
      ..style = PaintingStyle.fill;
    for (final pt in points) {
      canvas.drawCircle(pt, 5, dotBorderPaint);
      canvas.drawCircle(pt, 3.5, dotPaint);
    }

    // Draw X labels
    for (int i = 0; i < data.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: data[i].label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(points[i].dx - tp.width / 2, size.height - bottomPad + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SalesChartPainter oldDelegate) =>
      oldDelegate.gridColor != gridColor ||
      oldDelegate.labelColor != labelColor ||
      oldDelegate.lineColor != lineColor;
}

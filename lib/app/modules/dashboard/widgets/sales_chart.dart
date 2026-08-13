import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/dashboard/models/dashboard_models.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/chart_tooltip.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

/// Line + area chart ("New clients"). Stateful so the hovered point survives
/// parent rebuilds; the index itself is an Rx read through [Obx].
class SalesLineChart extends StatefulWidget {
  final List<ChartPoint> data;
  final Color lineColor;

  /// Formats the hover tooltip value. Defaults to a plain count.
  final String Function(double value)? valueFormatter;

  const SalesLineChart({
    super.key,
    required this.data,
    this.lineColor = AppColors.primaryOrange,
    this.valueFormatter,
  });

  @override
  State<SalesLineChart> createState() => _SalesLineChartState();
}

class _SalesLineChartState extends State<SalesLineChart> {
  final RxInt _hovered = (-1).obs;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (widget.data.isEmpty) return const SizedBox.expand();

    // Without an explicit width, a bare CustomPaint collapses to zero width
    // when its parent (a Column) only offers a loose 0..maxWidth constraint.
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final points = ChartGeometry.linePoints(size, widget.data);

          return MouseRegion(
            onHover: (event) =>
                _hovered.value = _nearest(event.localPosition, points),
            onExit: (_) => _hovered.value = -1,
            child: Obx(() {
              final hovered = _hovered.value;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SalesChartPainter(
                        data: widget.data,
                        lineColor: widget.lineColor,
                        gridColor: colors.divider,
                        labelColor: colors.textSecondary,
                        dotBorderColor: colors.surface,
                        hoveredIndex: hovered,
                      ),
                    ),
                  ),
                  if (hovered >= 0 && hovered < points.length)
                    _buildTooltip(hovered, points[hovered], size),
                ],
              );
            }),
          );
        },
      ),
    );
  }

  /// Nearest point by horizontal distance — hovering anywhere in a month's
  /// column reads that month, which is far easier than hitting a 7px dot.
  int _nearest(Offset local, List<Offset> points) {
    var best = 0;
    var bestDx = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final dx = (points[i].dx - local.dx).abs();
      if (dx < bestDx) {
        bestDx = dx;
        best = i;
      }
    }
    return best;
  }

  Widget _buildTooltip(int i, Offset point, Size size) {
    final left = (point.dx - ChartTooltip.width / 2)
        .clamp(0.0, math.max(size.width - ChartTooltip.width, 0.0))
        .toDouble();
    final top = (point.dy - ChartTooltip.height - 12)
        .clamp(0.0, math.max(size.height - ChartTooltip.height, 0.0))
        .toDouble();
    final value = widget.data[i].value;

    return Positioned(
      left: left,
      top: top,
      child: ChartTooltip(
        label: widget.data[i].label,
        value:
            widget.valueFormatter?.call(value) ??
            (value == value.roundToDouble()
                ? value.round().toString()
                : value.toStringAsFixed(1)),
        accent: widget.lineColor,
      ),
    );
  }
}

/// Point placement shared by the painter and the hover hit-test, so the
/// tooltip can never drift away from the dot it describes.
class ChartGeometry {
  ChartGeometry._();

  static const double leftPad = 8;
  static const double bottomPad = 24;
  static const double topPad = 12;

  static List<Offset> linePoints(Size size, List<ChartPoint> data) {
    if (data.isEmpty) return const [];
    final maxVal = data.map((d) => d.value).reduce((a, b) => a > b ? a : b) * 1.15;
    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad - topPad;

    return [
      for (var i = 0; i < data.length; i++)
        Offset(
          leftPad + (data.length == 1 ? 0 : (i / (data.length - 1)) * chartW),
          topPad + chartH * (1 - (maxVal == 0 ? 0 : data[i].value / maxVal)),
        ),
    ];
  }
}

class _SalesChartPainter extends CustomPainter {
  final List<ChartPoint> data;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;
  final Color dotBorderColor;
  final int hoveredIndex;

  _SalesChartPainter({
    required this.data,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
    required this.dotBorderColor,
    this.hoveredIndex = -1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const bottomPad = ChartGeometry.bottomPad;
    const topPad = ChartGeometry.topPad;
    final chartH = size.height - bottomPad - topPad;

    final textStyle = TextStyle(
      fontSize: 11,
      color: labelColor,
      fontFamily: 'Poppins',
    );

    final points = ChartGeometry.linePoints(size, data);

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

    // Hover guide: a dashed vertical rule down to the axis at the read point.
    if (hoveredIndex >= 0 && hoveredIndex < points.length) {
      final pt = points[hoveredIndex];
      final guidePaint = Paint()
        ..color = lineColor.withValues(alpha: 0.35)
        ..strokeWidth = 1.2;
      const dash = 4.0;
      for (var y = pt.dy; y < topPad + chartH; y += dash * 2) {
        canvas.drawLine(
          Offset(pt.dx, y),
          Offset(pt.dx, math.min(y + dash, topPad + chartH)),
          guidePaint,
        );
      }
    }

    // Draw dots — the hovered one grows and gains a soft halo.
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = dotBorderColor
      ..style = PaintingStyle.fill;
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      if (i == hoveredIndex) {
        canvas.drawCircle(
          pt,
          10,
          Paint()..color = lineColor.withValues(alpha: 0.18),
        );
        canvas.drawCircle(pt, 7, dotBorderPaint);
        canvas.drawCircle(pt, 5, dotPaint);
      } else {
        canvas.drawCircle(pt, 5, dotBorderPaint);
        canvas.drawCircle(pt, 3.5, dotPaint);
      }
    }

    // Draw X labels
    for (int i = 0; i < data.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: data[i].label,
          style: i == hoveredIndex
              ? textStyle.copyWith(
                  color: lineColor,
                  fontWeight: FontWeight.w600,
                )
              : textStyle,
        ),
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
      oldDelegate.lineColor != lineColor ||
      oldDelegate.hoveredIndex != hoveredIndex ||
      oldDelegate.data != data;
}

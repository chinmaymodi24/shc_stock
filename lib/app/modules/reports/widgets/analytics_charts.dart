import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/chart_tooltip.dart';
import 'package:shc_stock/app/modules/reports/models/analytics_models.dart';

part 'analytics_charts_part1.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The charts the Analytics tab is built from. Each one highlights what the
// pointer is over and reads its value out through the shared [ChartTooltip],
// and each works by tap/drag on touch devices where onHover never fires.
// ─────────────────────────────────────────────────────────────────────────────

/// Series colors, in the order a ranked list or a treemap hands them out.
/// Callers that need the theme's indigo pass `context.appColors.accent` —
/// the indigo is never hardcoded at a call site.
List<Color> analyticsPalette(BuildContext context) => [
  context.appColors.accent,
  AppColors.primaryOrange,
  const Color(0xFF7C6BE8),
  const Color(0xFF16A34A),
  const Color(0xFF1D6FD8),
  AppColors.danger,
];

// ── Sales vs Purchases ───────────────────────────────────────────────────────

/// Two smooth lines sharing one vertical scale. Hovering anywhere in a month's
/// column reads out the nearer of the two series at that month.
class DualLineChart extends StatefulWidget {
  final List<TrendPoint> data;
  final Color salesColor;
  final Color purchaseColor;
  final String Function(double value) valueFormatter;

  const DualLineChart({
    super.key,
    required this.data,
    required this.salesColor,
    required this.purchaseColor,
    required this.valueFormatter,
  });

  @override
  State<DualLineChart> createState() => _DualLineChartState();
}

class _DualLineChartState extends State<DualLineChart> {
  /// Hovered month, or -1.
  final RxInt _index = (-1).obs;

  /// Which series the pointer sits closer to: 0 = sales, 1 = purchases.
  final RxInt _series = 0.obs;

  static const double _bottomPad = 24;
  static const double _topPad = 12;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (widget.data.isEmpty) return const SizedBox.expand();

    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final maxVal = _maxValue();
          final sales = _points(size, maxVal, (p) => p.sales);
          final purchases = _points(size, maxVal, (p) => p.purchases);

          void read(Offset local) {
            final i = _nearestIndex(local, sales);
            _index.value = i;
            final dSales = (sales[i].dy - local.dy).abs();
            final dPurchase = (purchases[i].dy - local.dy).abs();
            _series.value = dSales <= dPurchase ? 0 : 1;
          }

          return MouseRegion(
            onHover: (e) => read(e.localPosition),
            onExit: (_) => _index.value = -1,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => read(d.localPosition),
              onPanUpdate: (d) => read(d.localPosition),
              child: Obx(() {
                final i = _index.value;
                final series = _series.value;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DualLinePainter(
                          data: widget.data,
                          salesPoints: sales,
                          purchasePoints: purchases,
                          salesColor: widget.salesColor,
                          purchaseColor: widget.purchaseColor,
                          labelColor: colors.textSecondary,
                          dotBorderColor: colors.surface,
                          hoveredIndex: i,
                          hoveredSeries: series,
                          axisY: size.height - _bottomPad,
                        ),
                      ),
                    ),
                    if (i >= 0)
                      _tooltip(
                        size,
                        series == 0 ? sales[i] : purchases[i],
                        series == 0 ? 'Sales' : 'Purchases',
                        series == 0
                            ? widget.data[i].sales
                            : widget.data[i].purchases,
                        series == 0 ? widget.salesColor : widget.purchaseColor,
                        widget.data[i].label,
                      ),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }

  double _maxValue() {
    var max = 0.0;
    for (final p in widget.data) {
      max = math.max(max, math.max(p.sales, p.purchases));
    }
    return max * 1.15;
  }

  List<Offset> _points(
    Size size,
    double maxVal,
    double Function(TrendPoint) of,
  ) {
    final chartH = size.height - _bottomPad - _topPad;
    final n = widget.data.length;
    return [
      for (var i = 0; i < n; i++)
        Offset(
          n == 1 ? size.width / 2 : (i / (n - 1)) * size.width,
          _topPad +
              chartH * (1 - (maxVal == 0 ? 0 : of(widget.data[i]) / maxVal)),
        ),
    ];
  }

  int _nearestIndex(Offset local, List<Offset> points) {
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

  Widget _tooltip(
    Size size,
    Offset point,
    String seriesLabel,
    double value,
    Color color,
    String monthLabel,
  ) {
    final left = (point.dx - ChartTooltip.width / 2)
        .clamp(0.0, math.max(size.width - ChartTooltip.width, 0.0))
        .toDouble();
    final top = (point.dy - ChartTooltip.height - 12)
        .clamp(0.0, math.max(size.height - ChartTooltip.height, 0.0))
        .toDouble();
    return Positioned(
      left: left,
      top: top,
      child: ChartTooltip(
        label: '$monthLabel · $seriesLabel',
        value: widget.valueFormatter(value),
        accent: color,
      ),
    );
  }
}

class _DualLinePainter extends CustomPainter {
  final List<TrendPoint> data;
  final List<Offset> salesPoints;
  final List<Offset> purchasePoints;
  final Color salesColor;
  final Color purchaseColor;
  final Color labelColor;
  final Color dotBorderColor;
  final int hoveredIndex;
  final int hoveredSeries;
  final double axisY;

  _DualLinePainter({
    required this.data,
    required this.salesPoints,
    required this.purchasePoints,
    required this.salesColor,
    required this.purchaseColor,
    required this.labelColor,
    required this.dotBorderColor,
    required this.hoveredIndex,
    required this.hoveredSeries,
    required this.axisY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    _drawSeries(canvas, purchasePoints, purchaseColor);
    _drawSeries(canvas, salesPoints, salesColor);

    if (hoveredIndex >= 0 && hoveredIndex < salesPoints.length) {
      final active = hoveredSeries == 0 ? salesPoints : purchasePoints;
      final color = hoveredSeries == 0 ? salesColor : purchaseColor;
      final pt = active[hoveredIndex];

      final guide = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..strokeWidth = 1.2;
      const dash = 4.0;
      for (var y = pt.dy; y < axisY; y += dash * 2) {
        canvas.drawLine(
          Offset(pt.dx, y),
          Offset(pt.dx, math.min(y + dash, axisY)),
          guide,
        );
      }

      canvas.drawCircle(pt, 10, Paint()..color = color.withValues(alpha: 0.18));
      canvas.drawCircle(pt, 7, Paint()..color = dotBorderColor);
      canvas.drawCircle(pt, 5, Paint()..color = color);
    }

    // X labels — the hovered month is emphasised in its series' color.
    final baseStyle = TextStyle(
      fontSize: 11,
      color: labelColor,
      fontFamily: brandFontFamily,
    );
    for (var i = 0; i < data.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: data[i].label,
          style: i == hoveredIndex
              ? baseStyle.copyWith(
                  color: hoveredSeries == 0 ? salesColor : purchaseColor,
                  fontWeight: FontWeight.w600,
                )
              : baseStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = salesPoints[i].dx
          .clamp(tp.width / 2, size.width - tp.width / 2)
          .toDouble();
      tp.paint(canvas, Offset(dx - tp.width / 2, axisY + 8));
    }
  }

  void _drawSeries(Canvas canvas, List<Offset> points, Color color) {
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final midX = (points[i].dx + points[i + 1].dx) / 2;
      path.cubicTo(
        midX,
        points[i].dy,
        midX,
        points[i + 1].dy,
        points[i + 1].dx,
        points[i + 1].dy,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DualLinePainter old) =>
      old.hoveredIndex != hoveredIndex ||
      old.hoveredSeries != hoveredSeries ||
      old.data != data ||
      old.labelColor != labelColor;
}

// ── Stock movement ───────────────────────────────────────────────────────────

/// Two bars per month — inflow beside outflow. Hovering either bar lifts it
/// and reads its own value out, so the pair never has to be eyeballed.
class GroupedBarChart extends StatefulWidget {
  final List<FlowPoint> data;
  final Color inflowColor;
  final Color outflowColor;
  final double height;

  const GroupedBarChart({
    super.key,
    required this.data,
    required this.inflowColor,
    required this.outflowColor,
    this.height = 170,
  });

  @override
  State<GroupedBarChart> createState() => _GroupedBarChartState();
}

class _GroupedBarChartState extends State<GroupedBarChart> {
  /// index * 2 + series — a single Rx keeps column and series in step.
  final RxInt _hovered = (-1).obs;

  static const double _labelBlock = 24;
  static const double _maxBarWidth = 26;
  static const double _barGap = 6;

  /// Bars narrow to fit rather than overflowing their column — six months in a
  /// phone-width panel leaves about 54px per month for a 58px pair.
  double _barWidth(double columnWidth) =>
      math.max(math.min(_maxBarWidth, (columnWidth - _barGap - 6) / 2), 4);

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return SizedBox(height: widget.height);

    var maxVal = 0.0;
    for (final p in widget.data) {
      maxVal = math.max(maxVal, math.max(p.inflow, p.outflow));
    }
    final plotH = math.max(widget.height - _labelBlock, 0.0);

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final colW = constraints.maxWidth / widget.data.length;
          final barW = _barWidth(colW);
          return Obx(() {
            final hovered = _hovered.value;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < widget.data.length; i++)
                      Expanded(
                        child: _column(
                          context,
                          i,
                          maxVal,
                          plotH,
                          hovered,
                          barW,
                        ),
                      ),
                  ],
                ),
                if (hovered >= 0)
                  _tooltip(
                    hovered,
                    maxVal,
                    plotH,
                    colW,
                    barW,
                    constraints.maxWidth,
                  ),
              ],
            );
          });
        },
      ),
    );
  }

  Widget _column(
    BuildContext context,
    int i,
    double maxVal,
    double plotH,
    int hovered,
    double barW,
  ) {
    final colors = context.appColors;
    final point = widget.data[i];
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(
              i,
              0,
              point.inflow,
              maxVal,
              plotH,
              widget.inflowColor,
              hovered,
              barW,
            ),
            const SizedBox(width: _barGap),
            _bar(
              i,
              1,
              point.outflow,
              maxVal,
              plotH,
              widget.outflowColor,
              hovered,
              barW,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          point.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: hovered ~/ 2 == i ? FontWeight.w600 : FontWeight.w400,
            color: hovered ~/ 2 == i
                ? colors.textPrimary
                : colors.textSecondary,
            fontFamily: brandFontFamily,
          ),
        ),
      ],
    );
  }

  Widget _bar(
    int index,
    int series,
    double value,
    double maxVal,
    double plotH,
    Color color,
    int hovered,
    double barW,
  ) {
    final key = index * 2 + series;
    final active = hovered == key;
    final dimmed = hovered >= 0 && !active;
    // A bar for a zero month still shows a 2px stub, so the column reads as
    // "nothing moved" rather than as missing data.
    final h = maxVal == 0 ? 2.0 : math.max((value / maxVal) * plotH, 2.0);

    return MouseRegion(
      onEnter: (_) => _hovered.value = key,
      onExit: (_) {
        if (_hovered.value == key) _hovered.value = -1;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _hovered.value = _hovered.value == key ? -1 : key,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: barW,
          height: h,
          decoration: BoxDecoration(
            color: color.withValues(alpha: dimmed ? 0.45 : 1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
      ),
    );
  }

  Widget _tooltip(
    int key,
    double maxVal,
    double plotH,
    double colW,
    double barW,
    double width,
  ) {
    final i = key ~/ 2;
    final series = key % 2;
    final point = widget.data[i];
    final value = series == 0 ? point.inflow : point.outflow;
    final color = series == 0 ? widget.inflowColor : widget.outflowColor;
    final barH = maxVal == 0 ? 2.0 : math.max((value / maxVal) * plotH, 2.0);

    // Centre of the hovered bar: the pair straddles the column's midpoint.
    final pairOffset = series == 0
        ? -(barW + _barGap) / 2
        : (barW + _barGap) / 2;
    final centre = colW * i + colW / 2 + pairOffset;

    return Positioned(
      left: (centre - ChartTooltip.width / 2)
          .clamp(0.0, math.max(width - ChartTooltip.width, 0.0))
          .toDouble(),
      top: math.max(plotH - barH - ChartTooltip.height - 8, 0.0),
      child: ChartTooltip(
        label: '${point.label} · ${series == 0 ? 'Inflow' : 'Outflow'}',
        value: '${value.toStringAsFixed(0)} units',
        accent: color,
      ),
    );
  }
}

// ── Ranked lists ─────────────────────────────────────────────────────────────

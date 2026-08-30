import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/dashboard/models/dashboard_models.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/chart_tooltip.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

/// Multi-slice donut with a dot-legend — used for "Sales by category".
///
/// Stateful so the hovered slice survives parent rebuilds; the index is an Rx
/// read through [Obx]. Hovering an arc highlights its legend row and vice
/// versa, so the two halves always read as one chart.
class CategoryDonutChart extends StatefulWidget {
  final List<CategorySlice> slices;
  final double size;

  const CategoryDonutChart({super.key, required this.slices, this.size = 140});

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  final RxInt _hovered = (-1).obs;
  final Rx<Offset> _cursor = Offset.zero.obs;

  /// Height of one legend row — fixed so the gap between rows can be solved
  /// for exactly against the available height.
  static const double _legendRowHeight = 18;
  static const double _maxLegendGap = 12;

  static const double _ringInset = 10;
  static const double _strokeWidth = 24;

  @override
  Widget build(BuildContext context) {
    // mainAxisAlignment.center (rather than mainAxisSize.min) centers the
    // [chart, legend] pair as a block within the full-width Row — avoids a
    // mainAxisSize.min Row directly under Center, which is a known trigger
    // for a spurious "Cannot hit test a render box with no size" hover
    // crash on Flutter web.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Obx(() {
          final hovered = _hovered.value;
          return MouseRegion(
            onHover: (event) {
              _cursor.value = event.localPosition;
              _hovered.value = _sliceAt(event.localPosition);
            },
            onExit: (_) => _hovered.value = -1,
            // Touch devices never fire onHover — tap toggles the slice under
            // the finger so the chart works identically on mobile.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                _cursor.value = d.localPosition;
                final slice = _sliceAt(d.localPosition);
                _hovered.value = _hovered.value == slice ? -1 : slice;
              },
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _DonutPainter(
                          slices: widget.slices,
                          hoveredIndex: hovered,
                          ringInset: _ringInset,
                          strokeWidth: _strokeWidth,
                        ),
                      ),
                    ),
                    if (hovered >= 0 && hovered < widget.slices.length)
                      _buildTooltip(hovered),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 28),
        // Flexible: the legend used to hold four short hardcoded labels, but
        // the categories now come from the API ("Fire & Welding Protection",
        // an "Other (n)" bucket, …) and overflowed the card at laptop widths.
        Flexible(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // The card gives the chart a fixed height; the slice count is
              // API-driven (up to five categories plus an "Other" bucket), so
              // the row gap is shrunk to fit rather than left at a constant
              // that overflows the card once six slices come back.
              var gap = _maxLegendGap;
              if (constraints.maxHeight.isFinite && widget.slices.length > 1) {
                final free =
                    constraints.maxHeight -
                    widget.slices.length * _legendRowHeight;
                gap = (free / (widget.slices.length - 1)).clamp(
                  0.0,
                  _maxLegendGap,
                );
              }
              return Obx(() {
                final hovered = _hovered.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.slices.length; i++) ...[
                      if (i > 0) SizedBox(height: gap),
                      MouseRegion(
                        onEnter: (_) => _hovered.value = i,
                        onExit: (_) {
                          if (_hovered.value == i) _hovered.value = -1;
                        },
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () =>
                              _hovered.value = _hovered.value == i ? -1 : i,
                          child: SizedBox(
                            height: _legendRowHeight,
                            child: _LegendItem(
                              slice: widget.slices[i],
                              highlighted: hovered == i,
                              dimmed: hovered >= 0 && hovered != i,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              });
            },
          ),
        ),
      ],
    );
  }

  /// Which arc sits under [local] — ‑1 for the hole, the gap outside the ring,
  /// or the corners of the square box.
  int _sliceAt(Offset local) {
    if (widget.slices.isEmpty) return -1;
    final center = Offset(widget.size / 2, widget.size / 2);
    final mid = widget.size / 2 - _ringInset;
    final delta = local - center;
    final distance = delta.distance;
    if (distance < mid - _strokeWidth / 2 ||
        distance > mid + _strokeWidth / 2) {
      return -1;
    }

    // Arcs start at 12 o'clock and run clockwise.
    var angle = atan2(delta.dy, delta.dx) + pi / 2;
    if (angle < 0) angle += 2 * pi;

    final total = widget.slices.fold<double>(0, (sum, s) => sum + s.percent);
    if (total <= 0) return -1;

    var start = 0.0;
    for (var i = 0; i < widget.slices.length; i++) {
      final sweep = (widget.slices[i].percent / total) * 2 * pi;
      if (angle >= start && angle < start + sweep) return i;
      start += sweep;
    }
    return widget.slices.length - 1;
  }

  Widget _buildTooltip(int i) {
    final slice = widget.slices[i];
    final pos = _cursor.value;
    // Follows the cursor, flipping to the left of it near the right edge so
    // the card never runs off toward the next dashboard panel.
    final flip = pos.dx + 16 + ChartTooltip.width > widget.size + 40;
    return Positioned(
      left: flip ? pos.dx - ChartTooltip.width - 16 : pos.dx + 16,
      top: (pos.dy - ChartTooltip.height / 2).clamp(
        -8.0,
        widget.size - ChartTooltip.height + 8,
      ),
      child: ChartTooltip(
        label: slice.label,
        value: slice.tooltipValue,
        accent: slice.color,
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final CategorySlice slice;
  final bool highlighted;
  final bool dimmed;

  const _LegendItem({
    required this.slice,
    this.highlighted = false,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      // Shrink-wrap so the legend column takes only the width it needs —
      // that lets the parent Row's mainAxisAlignment.center actually centre
      // the [chart, legend] block instead of the legend eating the slack.
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: highlighted ? 11 : 9,
          height: highlighted ? 11 : 9,
          decoration: BoxDecoration(
            color: slice.color.withValues(alpha: dimmed ? 0.45 : 1),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: highlighted ? 6 : 8),
        // Capped width + ellipsis: category names come from the API and can
        // be long, so the label shrinks rather than blowing out the legend.
        // A fixed cap (not Flexible) keeps the row shrink-wrapped.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            slice.legendText ??
                '${slice.label} — ${slice.percent.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12.5,
              // Pinned line height so a legend row always fits its 18px slot,
              // whatever line spacing the font itself reports.
              height: 1.3,
              fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
              color: dimmed ? colors.textSecondary : colors.textPrimary,
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
  final int hoveredIndex;
  final double ringInset;
  final double strokeWidth;

  _DonutPainter({
    required this.slices,
    required this.hoveredIndex,
    required this.ringInset,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - ringInset;
    const gapAngle = 0.0;

    final total = slices.fold<double>(0, (sum, s) => sum + s.percent);
    double startAngle = -pi / 2;

    for (var i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final sweep = total == 0
          ? 0.0
          : (slice.percent / total) * 2 * pi - gapAngle;
      final isHovered = i == hoveredIndex;
      final dimmed = hoveredIndex >= 0 && !isHovered;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        // The hovered arc thickens outward and the rest fade back, so the
        // read slice is obvious without moving anything.
        ..strokeWidth = isHovered ? strokeWidth + 7 : strokeWidth
        ..color = slice.color.withValues(alpha: dimmed ? 0.4 : 1);

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
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.hoveredIndex != hoveredIndex || oldDelegate.slices != slices;
}

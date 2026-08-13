import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/dashboard/models/dashboard_models.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/chart_tooltip.dart';

/// Simple flat-bar chart used for the "Purchases" / "Sales" (6 months) panels.
///
/// Stateful only to keep the hovered-column index alive across parent
/// rebuilds — the index itself is an Rx, read through [Obx].
class SimpleBarChart extends StatefulWidget {
  final List<ChartPoint> data;
  final Color barColor;
  final double height;

  /// Formats the hover tooltip value — rupees for Purchases/Sales, plain
  /// counts elsewhere.
  final String Function(double value)? valueFormatter;

  const SimpleBarChart({
    super.key,
    required this.data,
    required this.barColor,
    this.height = 160,
    this.valueFormatter,
  });

  @override
  State<SimpleBarChart> createState() => _SimpleBarChartState();
}

class _SimpleBarChartState extends State<SimpleBarChart> {
  final RxInt _hovered = (-1).obs;

  /// Label strip below the bars: text line + its gap. Kept as a constant so
  /// the tooltip can be positioned against the true bar top.
  static const double _labelBlock = 24;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return SizedBox(height: widget.height);

    final maxVal = widget.data
        .map((d) => d.value)
        .reduce((a, b) => a > b ? a : b);
    final plotH = math.max(widget.height - _labelBlock, 0.0);

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final colW = constraints.maxWidth / widget.data.length;
          return Obx(() {
            final hovered = _hovered.value;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < widget.data.length; i++)
                      Expanded(child: _buildColumn(context, i, maxVal, hovered)),
                  ],
                ),
                if (hovered >= 0)
                  _buildTooltip(hovered, maxVal, plotH, colW, constraints),
              ],
            );
          });
        },
      ),
    );
  }

  Widget _buildColumn(BuildContext context, int i, double maxVal, int hovered) {
    final colors = context.appColors;
    final point = widget.data[i];
    final ratio = maxVal == 0 ? 0.0 : point.value / maxVal;
    final isHovered = hovered == i;
    final dimmed = hovered >= 0 && !isHovered;

    return MouseRegion(
      onEnter: (_) => _hovered.value = i,
      onExit: (_) {
        if (_hovered.value == i) _hovered.value = -1;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Only the bar itself reacts — no full-height column wash behind
            // it; the wash read as a stray light block above the bar.
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: ratio.clamp(0.04, 1.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    decoration: BoxDecoration(
                      color: widget.barColor.withValues(
                        alpha: dimmed ? 0.45 : 1,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      boxShadow: isHovered
                          ? [
                              BoxShadow(
                                color: widget.barColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 16,
              child: Text(
                point.label,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.3,
                  fontWeight: isHovered ? FontWeight.w600 : FontWeight.w400,
                  color: isHovered ? colors.textPrimary : colors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip(
    int i,
    double maxVal,
    double plotH,
    double colW,
    BoxConstraints constraints,
  ) {
    final point = widget.data[i];
    final ratio = maxVal == 0 ? 0.0 : point.value / maxVal;
    final barH = ratio.clamp(0.04, 1.0).toDouble() * plotH;

    final left = (colW * (i + 0.5) - ChartTooltip.width / 2)
        .clamp(0.0, math.max(constraints.maxWidth - ChartTooltip.width, 0.0))
        .toDouble();
    // Sit just above the bar, but never past the top of the chart box.
    final bottom = math.min(
      _labelBlock + barH + 10,
      math.max(widget.height - ChartTooltip.height, 0.0),
    );

    return Positioned(
      left: left,
      bottom: bottom,
      child: ChartTooltip(
        label: point.label,
        value: widget.valueFormatter?.call(point.value) ?? _plainCount(point.value),
        accent: widget.barColor,
      ),
    );
  }

  String _plainCount(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
}

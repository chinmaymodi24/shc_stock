import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerHoverEvent;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/dashboard/models/dashboard_models.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/chart_tooltip.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

class CategoryBreakdown extends StatelessWidget {
  final List<CategorySlice> categories;

  const CategoryBreakdown({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: categories
          .map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _CategoryRow(slice: c),
            ),
          )
          .toList(),
    );
  }
}

/// Stateful so the hover flag survives parent rebuilds; the flag itself is an
/// Rx read through [Obx].
class _CategoryRow extends StatefulWidget {
  final CategorySlice slice;
  const _CategoryRow({required this.slice});

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  final RxBool _hovered = false.obs;

  /// Tooltip x, already clamped inside the row. Solved in the hover callback
  /// off `context.size` rather than a LayoutBuilder — the breakdown card sits
  /// inside an IntrinsicHeight, which cannot measure a LayoutBuilder.
  final RxDouble _tooltipLeft = 0.0.obs;

  void _trackCursor(PointerHoverEvent event) {
    final width = context.size?.width ?? 0;
    _tooltipLeft.value = (event.localPosition.dx - ChartTooltip.width / 2)
        .clamp(0.0, math.max(width - ChartTooltip.width, 0.0));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final slice = widget.slice;

    return MouseRegion(
      onEnter: (_) => _hovered.value = true,
      onHover: _trackCursor,
      onExit: (_) => _hovered.value = false,
      // Touch devices never fire onEnter/onHover — a tap toggles the same
      // tooltip so the chart works identically on mobile.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) {
          final width = context.size?.width ?? 0;
          _tooltipLeft.value = (d.localPosition.dx - ChartTooltip.width / 2)
              .clamp(0.0, math.max(width - ChartTooltip.width, 0.0));
          _hovered.value = !_hovered.value;
        },
        child: Obx(() {
          final hovered = _hovered.value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Category names come from the API and can be long, so
                      // the label flexes and ellipsises instead of pushing
                      // the percentage out.
                      Expanded(
                        child: Text(
                          slice.label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: hovered
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: hovered ? slice.color : colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${slice.percent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: hovered ? slice.color : colors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      height: hovered ? 9 : 6,
                      child: LinearProgressIndicator(
                        value: slice.percent / 100,
                        minHeight: hovered ? 9 : 6,
                        backgroundColor: colors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(slice.color),
                      ),
                    ),
                  ),
                ],
              ),
              if (hovered)
                Positioned(
                  left: _tooltipLeft.value,
                  // Floats just above the row it describes.
                  top: -ChartTooltip.height - 4,
                  child: ChartTooltip(
                    label: slice.label,
                    value: slice.tooltipValue,
                    accent: slice.color,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

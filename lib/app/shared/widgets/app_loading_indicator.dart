import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

/// Branded loading indicator shown while an API call is in flight — three
/// dots bouncing in a staggered wave, light-to-dark orange left to right.
///
/// Every screen backed by `ApiClient` should show this during `isLoading`
/// — API calls carry a deliberate artificial delay
/// ([[feedback_api_loading_delay]] in project memory) specifically so this
/// is visible, so don't skip rendering it.
class AppLoadingIndicator extends StatefulWidget {
  final String? label;
  final double padding;
  const AppLoadingIndicator({super.key, this.label, this.padding = 56});

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  static const _dotColors = [
    Color(0xFFFFCC99), // light peach
    AppColors.primaryOrange,
    Color(0xFFE5650A), // deep orange
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: widget.padding),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 26,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_dotColors.length, (i) {
                      // Each dot's bounce is offset by 0.16 of the cycle so
                      // the hop travels left → right in a wave.
                      final t = (_controller.value - i * 0.16) % 1.0;
                      final lift = max(0.0, sin(t * pi));
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Transform.translate(
                          offset: Offset(0, -lift * 10),
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _dotColors[i],
                              boxShadow: [
                                BoxShadow(
                                  color: _dotColors[i].withValues(
                                    alpha: 0.35 * (1 - lift),
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            if (widget.label != null) ...[
              const SizedBox(height: 14),
              Text(
                widget.label!,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// The floating readout every dashboard chart shows on hover — one widget so
/// the bar, line, donut and breakdown charts all speak with the same voice.
///
/// Always dark-on-light and dark-on-dark (a tooltip that matched the card
/// surface disappeared into it), and always wrapped in [IgnorePointer] so it
/// can never steal the hover it was triggered by.
class ChartTooltip extends StatelessWidget {
  /// Series/point name — "Aug", "Ceramic Fiber Products", …
  final String label;

  /// Already-formatted value — "₹24,85,600", "1,037 clients", …
  final String value;

  /// Dot color; matches the bar/slice/line being hovered.
  final Color accent;

  const ChartTooltip({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
  });

  /// Fixed width so callers can clamp the tooltip inside the chart box
  /// without having to measure it first.
  static const double width = 136;
  static const double height = 54;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF221F3D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFB6B3D6),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

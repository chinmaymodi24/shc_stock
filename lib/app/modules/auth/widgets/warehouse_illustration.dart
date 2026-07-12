import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Warehouse background image — fills its container completely.
/// Uses the theme-appropriate asset and fades in smoothly when loaded.
class WarehouseIllustration extends StatelessWidget {
  final double width;
  final double height;

  const WarehouseIllustration({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = context.isDarkMode
        ? 'assets/background_dark.png'
        : 'assets/background_light.png';

    return Image.asset(
      assetPath,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      frameBuilder: (ctx, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return AnimatedOpacity(
            opacity: frame != null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            child: child,
          );
        }
        // Shimmer placeholder while the image loads
        return _ImageShimmer(width: width, height: height);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated shimmer shown while an image is loading
// ─────────────────────────────────────────────────────────────────────────────
class _ImageShimmer extends StatefulWidget {
  final double width;
  final double height;
  const _ImageShimmer({required this.width, required this.height});

  @override
  State<_ImageShimmer> createState() => _ImageShimmerState();
}

class _ImageShimmerState extends State<_ImageShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final base  = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE8E6FF);
    final shine = isDark ? const Color(0xFF252545) : const Color(0xFFF0EEFF);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [base, shine, base],
            stops: [
              0.0,
              _anim.value,
              1.0,
            ],
          ),
        ),
      ),
    );
  }
}
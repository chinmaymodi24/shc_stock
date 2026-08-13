import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme_ripple_controller.dart';

/// Wraps the app's navigator content with the RepaintBoundary
/// [ThemeRippleController] needs to capture screenshots, plus the animated
/// circular-reveal overlay itself. Install once, in GetMaterialApp's
/// `builder`.
class ThemeRippleHost extends StatefulWidget {
  final Widget child;
  const ThemeRippleHost({super.key, required this.child});

  @override
  State<ThemeRippleHost> createState() => _ThemeRippleHostState();
}

class _ThemeRippleHostState extends State<ThemeRippleHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _anim,
    curve: Curves.easeInOutCubic,
  );
  late final Worker _worker;

  ThemeRippleController get _c => Get.find<ThemeRippleController>();

  @override
  void initState() {
    super.initState();
    _worker = ever<bool>(_c.isRippling, (rippling) {
      if (rippling) _anim.forward(from: 0);
    });
    _anim.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _c.finish();
      _anim.value = 0;
    }
  }

  @override
  void dispose() {
    _worker.dispose();
    _anim
      ..removeStatusListener(_onStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(key: _c.boundaryKey, child: widget.child),
        Obx(() {
          final snapshot = _c.snapshot;
          final origin = _c.origin.value;
          if (!_c.isRippling.value || snapshot == null || origin == null) {
            return const SizedBox.shrink();
          }
          return AnimatedBuilder(
            animation: _curve,
            builder: (context, _) {
              final radius = _curve.value * _c.maxRadius.value;
              return Positioned.fill(
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _HoleClipper(center: origin, radius: radius),
                    child: RawImage(
                      image: snapshot,
                      fit: BoxFit.fill,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

/// Clips everything EXCEPT a growing circle — what's left visible is the
/// old-theme screenshot with a hole in it, through which the new theme
/// (already switched underneath) shows.
class _HoleClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;
  const _HoleClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) {
    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    return Path.combine(PathOperation.difference, full, hole);
  }

  @override
  bool shouldReclip(covariant _HoleClipper oldClipper) =>
      oldClipper.center != center || oldClipper.radius != radius;
}

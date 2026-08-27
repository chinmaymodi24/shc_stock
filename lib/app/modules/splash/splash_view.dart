import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Splash View
//   • Web  : white scaffold while microtask fires (HTML splash handles display)
//   • Mobile: white branded animation (≥ 2.5 s) → login
// ─────────────────────────────────────────────────────────────────────────────
class SplashView extends StatefulWidget {
  const SplashView({super.key});
  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _textFadeAnim;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      // Post-frame, not microtask: a microtask swaps the route tree inside the
      // very first frame, so when the browser hands focus to the Flutter view
      // the focus traversal walks a RenderStack that has never been laid out
      // ("RenderBox was not laid out" assert). Waiting for the first frame to
      // finish gives every render object a size before the route changes.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Get.offAllNamed(AppRoutes.login);
      });
      return;
    }

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _fadeAnim = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.80, curve: Curves.elasticOut),
      ),
    );
    _textFadeAnim = CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.38, 1.0, curve: Curves.easeOut),
    );

    _mainCtrl.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) Get.offAllNamed(AppRoutes.login);
    });
  }

  @override
  void dispose() {
    if (!kIsWeb) _mainCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox.expand(),
      );
    }

    final size = MediaQuery.of(context).size;
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Dot grid – top-left ────────────────────────────────
          Positioned(
            top: top + 24,
            left: 24,
            child: FadeTransition(opacity: _fadeAnim, child: const _DotGrid()),
          ),

          // ── Dot grid – bottom-right (subtle) ──────────────────
          Positioned(
            bottom: bottom + 120,
            right: 24,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Opacity(opacity: 0.40, child: const _DotGrid()),
            ),
          ),

          // ── Ring + tagline, centred together as one block ──────
          // The web splash centres `.orbit-wrap` and hangs the tagline
          // 24 px under it; keeping them in one centred column is what
          // reproduces those proportions on a phone.
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: const _OrbitalRing(),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _textFadeAnim,
                  child: const _TaglineBlock(),
                ),
              ],
            ),
          ),

          // ── City skyline, pinned to the bottom edge ────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              width: size.width,
              height: size.height * 0.11,
              child: CustomPaint(painter: _CityPainter()),
            ),
          ),

          // ── The app's three-dot indicator, same as every page uses ──
          Positioned(
            left: 0,
            right: 0,
            bottom: bottom + 36,
            child: FadeTransition(
              opacity: _textFadeAnim,
              child: const AppLoadingIndicator(padding: 0),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature item model
// ─────────────────────────────────────────────────────────────────────────────
class _FeatureItem {
  final IconData icon;
  final double angle; // radians (0 = 3-o'clock)
  const _FeatureItem(this.icon, this.angle);
}

final _kFeatures = [
  _FeatureItem(Icons.inventory_2_outlined, -math.pi / 2), // Top
  _FeatureItem(Icons.shopping_cart_outlined, math.pi), // Left
  _FeatureItem(Icons.bar_chart_rounded, 0.0), // Right
  _FeatureItem(Icons.shield_outlined, math.pi + math.pi / 4), // Bottom-L
  _FeatureItem(Icons.people_outline, -math.pi / 4), // Bottom-R
];

// ─────────────────────────────────────────────────────────────────────────────
// Animated orbital ring
//   • Ring rotates slowly (14 s / revolution)
//   • Icons counter-rotate so they stay upright
//   • Icons pop in sequentially (elastic stagger)
//   • Inner glow pulses gently
// ─────────────────────────────────────────────────────────────────────────────
class _OrbitalRing extends StatefulWidget {
  const _OrbitalRing();
  @override
  State<_OrbitalRing> createState() => _OrbitalRingState();
}

class _OrbitalRingState extends State<_OrbitalRing>
    with TickerProviderStateMixin {
  static const double _size = 320.0;
  static const double _orbitR = 128.0;
  static const double _btnSz = 40.0;
  static const double _iconSz = 18.0;

  late AnimationController _orbitCtrl; // continuous orbit rotation
  late AnimationController _pulseCtrl; // inner glow pulse
  late AnimationController _staggerCtrl; // icon pop-in stagger

  @override
  void initState() {
    super.initState();

    // Orbit: one full revolution every 14 seconds
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    // Pulse: breathes in & out every 2.4 seconds
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Stagger: all 5 icons appear within 1.6 seconds
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _pulseCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  /// Elastic scale for icon [index], staggered by index * 0.16
  double _iconScale(int index) {
    const interval = 0.16;
    final delay = index * interval;
    final v = _staggerCtrl.value;
    if (v <= delay) return 0.0;
    final t = ((v - delay) / 0.38).clamp(0.0, 1.0);
    return Curves.elasticOut.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_orbitCtrl, _pulseCtrl, _staggerCtrl]),
      builder: (context, _) {
        final orbitAngle = _orbitCtrl.value * 2 * math.pi;
        // Smooth sine-based pulse (1.0 → 1.08)
        final pulseScale = 1.0 + 0.08 * math.sin(_pulseCtrl.value * math.pi);

        return SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Rotating dashed ring (counter-clockwise looks elegant) ──
              Transform.rotate(
                angle: orbitAngle,
                child: CustomPaint(
                  size: const Size(_size, _size),
                  painter: _RingPainter(
                    orbitRadius: _orbitR,
                    iconAngles: _kFeatures.map((f) => f.angle).toList(),
                  ),
                ),
              ),

              // ── Pulsing glow behind the logo ────────────────────────────
              Transform.scale(
                scale: pulseScale,
                child: Container(
                  width: 215,
                  height: 108,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(64),
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryOrange.withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Full Secure Heat Care logo (static – does not rotate) ────
              Image.asset('assets/logo.png', width: 210, fit: BoxFit.contain),

              // ── Feature icons ────────────────────────────────────────────
              // They sit still at their anchor points — only the dashed ring
              // sweeps past behind them, exactly like the web splash.
              for (int i = 0; i < _kFeatures.length; i++) ...[
                Transform.translate(
                  offset: Offset(
                    _orbitR * math.cos(_kFeatures[i].angle),
                    _orbitR * math.sin(_kFeatures[i].angle),
                  ),
                  child: Transform.scale(
                    // Staggered elastic pop-in
                    scale: _iconScale(i),
                    child: Container(
                      width: _btnSz,
                      height: _btnSz,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.primaryOrange,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrange.withValues(
                              alpha: 0.15,
                            ),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        _kFeatures[i].icon,
                        size: _iconSz,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed orbit ring painter + anchor dots
// ─────────────────────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double orbitRadius;
  final List<double> iconAngles;
  const _RingPainter({required this.orbitRadius, required this.iconAngles});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final paint = Paint()
      ..color = AppColors.primaryOrange.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dashLen = 6.0;
    const gapLen = 4.0;
    final circ = 2 * math.pi * orbitRadius;
    final steps = circ / (dashLen + gapLen);
    final stepAng = 2 * math.pi / steps;
    final dashAng = stepAng * (dashLen / (dashLen + gapLen));

    for (var i = 0; i < steps.floor(); i++) {
      final start = i * stepAng;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: orbitRadius),
        start,
        dashAng,
        false,
        paint,
      );
    }

    // Anchor dots at each icon position
    final dotPaint = Paint()
      ..color = AppColors.primaryOrange.withValues(alpha: 0.40)
      ..style = PaintingStyle.fill;

    for (final angle in iconAngles) {
      canvas.drawCircle(
        Offset(
          center.dx + orbitRadius * math.cos(angle),
          center.dy + orbitRadius * math.sin(angle),
        ),
        3.8,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.orbitRadius != orbitRadius;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tagline block
// ─────────────────────────────────────────────────────────────────────────────
class _TaglineBlock extends StatelessWidget {
  const _TaglineBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.primaryOrange,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Smart Solutions for Inventory,\nSales, Purchase & Reports',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFAAAAAA),
            fontSize: 13.5,
            fontFamily: 'Poppins',
            height: 1.75,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dot grid decoration
// ─────────────────────────────────────────────────────────────────────────────
class _DotGrid extends StatelessWidget {
  const _DotGrid();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(90, 76), painter: _DotGridPainter());
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();
  @override
  void paint(Canvas canvas, Size size) {
    const cols = 5, rows = 5;
    final sx = size.width / (cols - 1);
    final sy = size.height / (rows - 1);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final dist = math.sqrt(math.pow(cols - 1 - c, 2) + math.pow(r, 2));
        final maxD = math.sqrt(math.pow(cols - 1, 2) + math.pow(rows - 1, 2));
        final opacity = 0.20 + 0.55 * (1 - dist / maxD);
        canvas.drawCircle(
          Offset(c * sx, r * sy),
          2.2,
          Paint()
            ..color = AppColors.primaryOrange.withValues(alpha: opacity)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// City skyline silhouette
// ─────────────────────────────────────────────────────────────────────────────
class _CityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = const Color(0xFFEEECFF).withValues(alpha: 0.70)
      ..style = PaintingStyle.fill;
    final path = Path()..moveTo(0, h);
    _rect(path, w * 0.00, h * 0.42, w * 0.04, h);
    _rect(path, w * 0.04, h * 0.55, w * 0.07, h);
    _rect(path, w * 0.07, h * 0.30, w * 0.10, h);
    _rect(path, w * 0.10, h * 0.46, w * 0.13, h);
    _rect(path, w * 0.13, h * 0.22, w * 0.16, h);
    _rect(path, w * 0.16, h * 0.14, w * 0.18, h);
    _rect(path, w * 0.18, h * 0.32, w * 0.22, h);
    _rect(path, w * 0.22, h * 0.50, w * 0.28, h);
    path.lineTo(w * 0.72, h);
    _rect(path, w * 0.72, h * 0.50, w * 0.78, h);
    _rect(path, w * 0.78, h * 0.32, w * 0.82, h);
    _rect(path, w * 0.82, h * 0.14, w * 0.84, h);
    _rect(path, w * 0.84, h * 0.22, w * 0.87, h);
    _rect(path, w * 0.87, h * 0.46, w * 0.90, h);
    _rect(path, w * 0.90, h * 0.30, w * 0.93, h);
    _rect(path, w * 0.93, h * 0.55, w * 0.96, h);
    _rect(path, w * 0.96, h * 0.42, w * 1.00, h);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _rect(Path p, double x1, double y1, double x2, double y2) {
    p.moveTo(x1, y2);
    p.lineTo(x1, y1);
    p.lineTo(x2, y1);
    p.lineTo(x2, y2);
    p.lineTo(x1, y2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

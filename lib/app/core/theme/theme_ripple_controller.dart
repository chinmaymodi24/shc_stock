import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

/// Drives the full-screen circular-reveal "ripple" shown whenever the theme
/// is switched. A screenshot of the current (old-theme) frame is captured,
/// the real theme is swapped underneath it, then a hole grows from wherever
/// the user tapped — through that screenshot — revealing the new theme as
/// it expands, until it covers the whole screen.
///
/// Registered once (permanent) in main.dart; install `ThemeRippleHost` in
/// GetMaterialApp's `builder` so it can capture the app's own content.
class ThemeRippleController extends GetxController {
  /// Wraps the app's navigator content — see ThemeRippleHost. Needed to
  /// capture a screenshot of the current frame.
  final GlobalKey boundaryKey = GlobalKey();

  final Rx<ui.Image?> _snapshot = Rx<ui.Image?>(null);
  ui.Image? get snapshot => _snapshot.value;

  final Rx<Offset?> origin = Rx<Offset?>(null);
  final RxDouble maxRadius = 0.0.obs;
  final RxBool isRippling = false.obs;

  bool _busy = false;

  /// Captures the current frame, applies [applyTheme] (which should flip
  /// the actual theme), then arms the ripple to animate a hole growing from
  /// [globalPosition]. `ThemeRippleHost` is what actually drives the
  /// animation frame-by-frame and calls [finish] when it completes.
  Future<void> trigger({
    required Offset globalPosition,
    required VoidCallback applyTheme,
  }) async {
    if (_busy) return;
    final boundaryContext = boundaryKey.currentContext;
    final renderObject = boundaryContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      // Can't capture a screenshot to reveal through — just switch instantly.
      applyTheme();
      return;
    }

    _busy = true;
    final dpr = MediaQuery.of(boundaryContext!).devicePixelRatio;
    final image = await renderObject.toImage(pixelRatio: dpr);

    final localOrigin = renderObject.globalToLocal(globalPosition);
    final size = renderObject.size;
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    final farthest = corners
        .map((c) => (c - localOrigin).distance)
        .reduce((a, b) => a > b ? a : b);

    _snapshot.value?.dispose();
    _snapshot.value = image;
    origin.value = localOrigin;
    maxRadius.value = farthest;
    isRippling.value = true;

    // Swap the real theme now — it's hidden behind the snapshot until the
    // hole grows over it.
    applyTheme();
  }

  /// Called by ThemeRippleHost once the reveal animation finishes.
  void finish() {
    isRippling.value = false;
    _snapshot.value?.dispose();
    _snapshot.value = null;
    origin.value = null;
    _busy = false;
  }
}

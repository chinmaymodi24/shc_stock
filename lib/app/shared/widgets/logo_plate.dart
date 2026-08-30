import 'package:flutter/material.dart';

/// SHC logo for the drawer / sidebar / mobile AppBar header.
///
/// The default artwork uses a deep-navy wordmark that disappears on dark
/// surfaces, so in dark mode we swap to `logo_dark.png` (light wordmark, same
/// orange flame). No plate or border — just the image, in both themes.
class LogoPlate extends StatelessWidget {
  final bool isDark;

  /// Logo height (web sidebar / mobile AppBar) — mutually exclusive with
  /// [width].
  final double? height;

  /// Logo width (mobile drawer) — mutually exclusive with [height].
  final double? width;

  const LogoPlate({super.key, required this.isDark, this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      isDark ? 'assets/logo_dark.png' : 'assets/logo.png',
      height: height,
      width: width,
      fit: width != null ? BoxFit.fitWidth : BoxFit.contain,
      alignment: Alignment.center,
    );
  }
}

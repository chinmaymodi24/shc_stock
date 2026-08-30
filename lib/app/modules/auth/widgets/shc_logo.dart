import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// SHC brand logo.
/// Adapts its size dynamically based on the available screen width.
/// On mobile it uses 38% of screen width; on web the parent passes an explicit size.
///
/// In dark mode it swaps to `logo_dark.png` — the default artwork's deep-navy
/// wordmark is unreadable on the dark login card. Same rule as [LogoPlate].
class SHCLogo extends StatelessWidget {
  /// Override the width. If null, falls back to 38% of screen width (mobile default).
  final double? width;

  const SHCLogo({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    final double logoWidth = width ?? MediaQuery.of(context).size.width * 0.38;

    return Image.asset(
      context.isDarkMode ? 'assets/logo_dark.png' : 'assets/logo.png',
      width: logoWidth,
      fit: BoxFit.fitWidth,
    );
  }
}

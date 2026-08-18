import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

/// SHC logo for the drawer / sidebar header.
///
/// The default artwork uses a deep-navy wordmark that disappears on dark
/// surfaces, so in dark mode we swap to `logo_dark.png` (light wordmark, same
/// orange flame) and sit it on a soft elevated plate taken from the dark
/// palette. Light mode renders the original artwork with no plate.
class LogoPlate extends StatelessWidget {
  final bool isDark;

  /// Logo height (web sidebar) — mutually exclusive with [width].
  final double? height;

  /// Logo width (mobile drawer) — mutually exclusive with [height].
  final double? width;

  final EdgeInsetsGeometry padding;

  const LogoPlate({
    super.key,
    required this.isDark,
    this.height,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      isDark ? 'assets/logo_dark.png' : 'assets/logo.png',
      height: height,
      width: width,
      fit: width != null ? BoxFit.fitWidth : BoxFit.contain,
      alignment: Alignment.center,
    );

    if (!isDark) return logo;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppThemeColors.dark.tagBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemeColors.dark.border),
      ),
      child: logo,
    );
  }
}

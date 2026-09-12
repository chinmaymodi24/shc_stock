import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/shared/widgets/brand_mark.dart';

/// The brand mark on the login screens.
///
/// Adapts its size to the available width: on mobile 38% of the screen, on web
/// the parent passes an explicit one. Renders the buyer's uploaded logo, or
/// their short code on a secondary plate — the login screen is the first thing
/// anyone sees, so it must already be their brand, not ours.
class SHCLogo extends StatelessWidget {
  /// Override the width. If null, falls back to 38% of screen width.
  final double? width;

  const SHCLogo({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    final double logoWidth = width ?? MediaQuery.of(context).size.width * 0.38;
    return BrandMark(width: logoWidth, isDark: context.isDarkMode);
  }
}

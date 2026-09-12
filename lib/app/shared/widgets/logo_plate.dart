import 'package:flutter/material.dart';
import 'package:shc_stock/app/shared/widgets/brand_mark.dart';

/// The brand mark for the drawer / sidebar / mobile AppBar header.
///
/// Now a thin wrapper over [BrandMark]: it used to hardcode `assets/logo.png`,
/// which is exactly what stopped a buyer's own logo from reaching the places
/// their staff look at most. The dark-mode swap is still here — the shipped
/// artwork has a navy wordmark that vanishes on a dark surface.
class LogoPlate extends StatelessWidget {
  final bool isDark;

  /// Logo height (web sidebar / mobile AppBar) — mutually exclusive with
  /// [width].
  final double? height;

  /// Logo width (mobile drawer) — mutually exclusive with [height].
  final double? width;

  const LogoPlate({super.key, required this.isDark, this.height, this.width});

  @override
  Widget build(BuildContext context) =>
      BrandMark(isDark: isDark, height: height, width: width);
}

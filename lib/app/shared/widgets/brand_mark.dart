import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/brand_controller.dart';
import 'package:shc_stock/app/core/theme/brand_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The buyer's mark, wherever the app shows one: sidebar, mobile AppBar,
// drawer, login screen and exported report headers.
//
// Three states, in order of preference:
//   1. an uploaded logo,
//   2. the shipped Secure Heat Care artwork — but only while the brand is
//      still the shipped one, since that asset IS that brand,
//   3. the short code on a secondary-coloured plate.
//
// (3) is what makes the white-label story work without asking every buyer to
// upload artwork before the app looks like theirs.
// ─────────────────────────────────────────────────────────────────────────────
class BrandMark extends StatelessWidget {
  final double? height;
  final double? width;

  /// Draw the shipped artwork's light-on-dark variant.
  final bool isDark;

  /// Show the company name beside the mark (login screens do; the sidebar
  /// doesn't, because the artwork already carries it).
  final bool showName;

  const BrandMark({
    super.key,
    this.height,
    this.width,
    this.isDark = false,
    this.showName = false,
  });

  bool get _isShippedBrand =>
      brand.companyName == BrandTheme.defaults.companyName &&
      brand.logoBase64 == null;

  @override
  Widget build(BuildContext context) {
    // Obx only where there is an observable to watch. With no controller
    // registered — every widget test that pumps a page — the builder would
    // read nothing and GetX throws "improper use of GetX" rather than simply
    // rendering the defaults.
    if (!Get.isRegistered<BrandController>()) {
      return _content(context, BrandTheme.defaults);
    }
    final bc = Get.find<BrandController>();
    return Obx(() => _content(context, bc.applied.value));
  }

  Widget _content(BuildContext context, BrandTheme b) {
    final mark = _mark(context, b);
    if (!showName) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            b.companyName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: b.font,
              fontSize: (height ?? 32) * 0.46,
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _mark(BuildContext context, BrandTheme b) {
    final size = height ?? width ?? 40;

    if (b.logoBase64 != null) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(b.radiusSm),
          child: Image.memory(
            base64Decode(b.logoBase64!),
            height: height,
            width: width,
            fit: width != null ? BoxFit.fitWidth : BoxFit.contain,
            // An SVG (which Flutter can't decode without a plugin) or a
            // corrupt upload falls back to the code plate rather than a
            // broken-image box on the buyer's login screen.
            errorBuilder: (_, _, _) => _codePlate(b, size),
          ),
        );
      } catch (_) {
        return _codePlate(b, size);
      }
    }

    if (_isShippedBrand) {
      return Image.asset(
        isDark ? 'assets/logo_dark.png' : 'assets/logo.png',
        height: height,
        width: width,
        fit: width != null ? BoxFit.fitWidth : BoxFit.contain,
        alignment: Alignment.center,
      );
    }

    return _codePlate(b, size);
  }

  Widget _codePlate(BrandTheme b, double size) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: b.secondary,
      borderRadius: BorderRadius.circular(b.radiusSm),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: size * 0.14),
        child: Text(
          b.shortCode.isEmpty ? '·' : b.shortCode.toUpperCase(),
          style: TextStyle(
            fontFamily: b.font,
            fontSize: size * 0.44,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}

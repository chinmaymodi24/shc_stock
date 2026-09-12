import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/brand_controller.dart';
import 'package:shc_stock/app/core/theme/brand_theme.dart';
import 'app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Builds Flutter's ThemeData from the buyer's [BrandTheme].
//
// Everything that used to be baked in here — the orange focus ring, the 10px
// input corners, the 'Poppins' family on every text style — now comes from the
// brand, so applying a theme restyles the framework's own widgets too, not
// just the ones we paint by hand.
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(String font, Color primary, Color secondary) {
    TextStyle s(Color c) => TextStyle(fontFamily: font, color: c);
    return TextTheme(
      displayLarge: s(primary),
      displayMedium: s(primary),
      displaySmall: s(primary),
      headlineLarge: s(primary),
      headlineMedium: s(primary),
      headlineSmall: s(primary),
      titleLarge: s(primary),
      titleMedium: s(primary),
      titleSmall: s(primary),
      bodyLarge: s(primary),
      bodyMedium: s(secondary),
      bodySmall: s(secondary),
      labelLarge: s(primary),
      labelMedium: s(secondary),
      labelSmall: s(secondary),
    );
  }

  static InputDecorationTheme _inputTheme(AppThemeColors c, BrandTheme b) =>
      InputDecorationTheme(
        filled: true,
        fillColor: c.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(b.radius),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(b.radius),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(b.radius),
          borderSide: BorderSide(color: b.primary, width: 1.5),
        ),
      );

  static ThemeData _build(BrandTheme b, {required bool dark}) {
    // Resolve once per build: the same family string every hand-written
    // TextStyle gets from brandFontFamily.
    final font = fontFamilyFor(b.font);
    final c = dark
        ? AppThemeColors.darkFromBrand(b)
        : AppThemeColors.fromBrand(b);
    final brightness = dark ? Brightness.dark : Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: b.secondary,
        primary: dark ? c.purple : b.secondary,
        secondary: b.primary,
        brightness: brightness,
        surface: c.surface,
      ),
      scaffoldBackgroundColor: c.background,
      fontFamily: font,
      textTheme: _textTheme(font, c.textPrimary, c.textSecondary),
      inputDecorationTheme: _inputTheme(c, b),
      dividerColor: c.divider,
      cardColor: c.surface,
      extensions: [c],
    );
  }

  /// Rebuilt on every read so an applied theme takes effect immediately —
  /// `main()` hands these to GetMaterialApp inside an Obx.
  static ThemeData get lightTheme => _build(brand, dark: false);
  static ThemeData get darkTheme => _build(brand, dark: true);
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/brand_controller.dart';
import 'package:shc_stock/app/core/theme/brand_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Brand accessors.
//
// These used to be `static const` hexes, which is exactly why the app couldn't
// be rebranded: 350-odd call sites had the orange compiled into them. They are
// now getters that read the live [BrandTheme], so every one of those call sites
// follows the buyer's palette without being touched.
//
// Nothing here holds a colour of its own — this is a view onto [brand].
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static Color get primaryOrange => brand.primary;
  static Color get primaryPurple => brand.secondary;
  static Color get accentPurple => brand.accent;

  static Color get backgroundLavender => brand.tintSecondary;
  static Color get backgroundPurpleTint => tint(brand.secondary, 0.82);
  static Color get white => brand.cardBg;

  static Color get textDark => brand.textPrimary;
  static Color get textMedium => brand.textSecondary;
  static Color get textLight => brand.textTertiary;

  static Color get inputBorder => brand.border;
  static Color get inputIcon => brand.accent;
  static Color get dividerPurple => brand.accent;

  static Color get cardShadow => brand.accent.withValues(alpha: 0.10);
}

/// The buyer's font family, resolved to a family Flutter can actually render.
///
/// Two things were wrong before. Every hand-written `TextStyle` said
/// `fontFamily: 'Poppins'`, overriding whatever ThemeData set — and no font
/// was bundled in pubspec at all, so that name resolved to nothing and the
/// app silently drew the platform default. Going through google_fonts
/// registers the real family (fetching and caching it once), so picking a
/// font in Appearance changes the text instead of doing nothing.
///
/// Falls back to the plain name if the font can't be resolved — offline, or a
/// family google_fonts doesn't carry — rather than throwing mid-build.
String get brandFontFamily => fontFamilyFor(brand.font);

/// Turned off by `test/flutter_test_config.dart`.
///
/// Resolving a family makes google_fonts load it, and that load reaches for
/// path_provider and the network — neither of which exists under
/// `flutter test`. It also fails ASYNCHRONOUSLY, so a try/catch here can't
/// contain it; the error surfaced on whichever unrelated test happened to be
/// running. Tests keep the plain family name, which is all they assert on.
bool kResolveBrandFonts = true;

String fontFamilyFor(String name) {
  if (!kResolveBrandFonts) return name;
  try {
    return GoogleFonts.getFont(name).fontFamily ?? name;
  } catch (_) {
    return name;
  }
}

/// Lifts a brand colour off a dark background. A deep navy secondary is
/// invisible on #13131F, so dark mode lightens anything too dark to read
/// rather than asking the buyer to configure a second palette.
Color _forDark(Color c) =>
    c.computeLuminance() < 0.35 ? tint(c, 0.55) : tint(c, 0.10);

// ─────────────────────────────────────────────────────────────────────────────
// Semantic color tokens — derived from the brand, swapped by Light / Dark
// ─────────────────────────────────────────────────────────────────────────────
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color background;
  final Color surface; // card / white areas
  final Color topBarBg;
  final Color sidebarBg;
  final Color tableHeaderBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color border;
  final Color divider;
  final Color inputFill;
  final Color rowEven; // table alternating rows / hover
  final Color tagBg; // filter chip / tag bg
  final Color iconBgPurple; // icon container with secondary tint
  final Color sidebarFooter; // admin footer in sidebar
  final Color drawerBg; // mobile drawer body
  final Color comingSoonBadge;

  // Semantic Action Colors
  final Color purple; // the brand's secondary
  final Color accent;
  final Color info;
  final Color success;
  final Color warning;
  final Color error; // the brand's danger

  // Tinted surfaces — mixed from the base colours above, never configured.
  final Color tintPrimary;
  final Color tintInfo;
  final Color tintAccent;
  final Color tintSuccess;
  final Color tintWarning;
  final Color tintDanger;

  /// Corner radius and its small variant, so a widget can round itself from
  /// the theme instead of hardcoding 10.
  final double radius;
  final double radiusSm;

  /// The buyer's font, for the handful of places that set fontFamily by hand.
  final String fontFamily;

  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.topBarBg,
    required this.sidebarBg,
    required this.tableHeaderBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.divider,
    required this.inputFill,
    required this.rowEven,
    required this.tagBg,
    required this.iconBgPurple,
    required this.sidebarFooter,
    required this.drawerBg,
    required this.comingSoonBadge,
    required this.purple,
    required this.accent,
    required this.info,
    required this.success,
    required this.warning,
    required this.error,
    required this.tintPrimary,
    required this.tintInfo,
    required this.tintAccent,
    required this.tintSuccess,
    required this.tintWarning,
    required this.tintDanger,
    required this.radius,
    required this.radiusSm,
    required this.fontFamily,
  });

  /// The light palette, straight off the buyer's configured surfaces and text.
  factory AppThemeColors.fromBrand(BrandTheme b) => AppThemeColors(
    background: b.bg,
    surface: b.cardBg,
    topBarBg: b.cardBg,
    sidebarBg: b.sidebarBg,
    tableHeaderBg: b.tableHeaderBg,
    textPrimary: b.textPrimary,
    textSecondary: b.textSecondary,
    textHint: b.textTertiary,
    border: b.border,
    divider: tint(b.border, 0.45),
    inputFill: b.cardBg,
    rowEven: b.rowHover,
    tagBg: b.rowHover,
    iconBgPurple: b.tintSecondary,
    sidebarFooter: const Color(0x14000000),
    drawerBg: b.sidebarBg,
    comingSoonBadge: b.rowHover,
    purple: b.secondary,
    accent: b.accent,
    info: b.info,
    success: b.success,
    warning: b.warning,
    error: b.danger,
    tintPrimary: b.tintPrimary,
    tintInfo: b.tintInfo,
    tintAccent: b.tintAccent,
    tintSuccess: b.tintSuccess,
    tintWarning: b.tintWarning,
    tintDanger: b.tintDanger,
    radius: b.radius,
    radiusSm: b.radiusSm,
    fontFamily: b.font,
  );

  /// Dark mode keeps the buyer's brand hues and swaps only the surfaces and
  /// text, which is why there is no second palette to configure.
  factory AppThemeColors.darkFromBrand(BrandTheme b) {
    final primary = _forDark(b.primary);
    final secondary = _forDark(b.secondary);
    final info = _forDark(b.info);
    final accent = _forDark(b.accent);
    final success = _forDark(b.success);
    final warning = _forDark(b.warning);
    final danger = _forDark(b.danger);
    return AppThemeColors(
      background: const Color(0xFF13131F),
      surface: const Color(0xFF1E1E2E),
      topBarBg: const Color(0xFF1E1E2E),
      sidebarBg: const Color(0xFF1E1E2E),
      tableHeaderBg: const Color(0xFF1A1A2E),
      textPrimary: const Color(0xFFEAE8FF),
      textSecondary: const Color(0xFF9B9BB4),
      textHint: const Color(0xFF6B6B8A),
      border: const Color(0xFF2E2E4A),
      divider: const Color(0xFF252538),
      inputFill: const Color(0xFF252538),
      rowEven: const Color(0xFF1A1A2E),
      tagBg: const Color(0xFF252538),
      iconBgPurple: const Color(0xFF2A2A48),
      sidebarFooter: const Color(0x33000000),
      drawerBg: const Color(0xFF1E1E2E),
      comingSoonBadge: const Color(0xFF252538),
      purple: secondary,
      accent: accent,
      info: info,
      success: success,
      warning: warning,
      error: danger,
      // Tints go the other way in the dark: mixing toward white would glare,
      // so a tinted surface is the hue laid faintly over the dark card.
      tintPrimary: Color.alphaBlend(
        primary.withValues(alpha: 0.18),
        const Color(0xFF1E1E2E),
      ),
      tintInfo: Color.alphaBlend(
        info.withValues(alpha: 0.18),
        const Color(0xFF1E1E2E),
      ),
      tintAccent: Color.alphaBlend(
        accent.withValues(alpha: 0.18),
        const Color(0xFF1E1E2E),
      ),
      tintSuccess: Color.alphaBlend(
        success.withValues(alpha: 0.18),
        const Color(0xFF1E1E2E),
      ),
      tintWarning: Color.alphaBlend(
        warning.withValues(alpha: 0.18),
        const Color(0xFF1E1E2E),
      ),
      tintDanger: Color.alphaBlend(
        danger.withValues(alpha: 0.18),
        const Color(0xFF1E1E2E),
      ),
      radius: b.radius,
      radiusSm: b.radiusSm,
      fontFamily: b.font,
    );
  }

  /// The live light/dark palettes. Getters, not constants — they follow the
  /// brand the buyer applied.
  static AppThemeColors get light => AppThemeColors.fromBrand(brand);
  static AppThemeColors get dark => AppThemeColors.darkFromBrand(brand);

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? topBarBg,
    Color? sidebarBg,
    Color? tableHeaderBg,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? border,
    Color? divider,
    Color? inputFill,
    Color? rowEven,
    Color? tagBg,
    Color? iconBgPurple,
    Color? sidebarFooter,
    Color? drawerBg,
    Color? comingSoonBadge,
    Color? purple,
    Color? accent,
    Color? info,
    Color? success,
    Color? warning,
    Color? error,
    Color? tintPrimary,
    Color? tintInfo,
    Color? tintAccent,
    Color? tintSuccess,
    Color? tintWarning,
    Color? tintDanger,
    double? radius,
    double? radiusSm,
    String? fontFamily,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      topBarBg: topBarBg ?? this.topBarBg,
      sidebarBg: sidebarBg ?? this.sidebarBg,
      tableHeaderBg: tableHeaderBg ?? this.tableHeaderBg,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      inputFill: inputFill ?? this.inputFill,
      rowEven: rowEven ?? this.rowEven,
      tagBg: tagBg ?? this.tagBg,
      iconBgPurple: iconBgPurple ?? this.iconBgPurple,
      sidebarFooter: sidebarFooter ?? this.sidebarFooter,
      drawerBg: drawerBg ?? this.drawerBg,
      comingSoonBadge: comingSoonBadge ?? this.comingSoonBadge,
      purple: purple ?? this.purple,
      accent: accent ?? this.accent,
      info: info ?? this.info,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      tintPrimary: tintPrimary ?? this.tintPrimary,
      tintInfo: tintInfo ?? this.tintInfo,
      tintAccent: tintAccent ?? this.tintAccent,
      tintSuccess: tintSuccess ?? this.tintSuccess,
      tintWarning: tintWarning ?? this.tintWarning,
      tintDanger: tintDanger ?? this.tintDanger,
      radius: radius ?? this.radius,
      radiusSm: radiusSm ?? this.radiusSm,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  @override
  AppThemeColors lerp(AppThemeColors? other, double t) {
    if (other == null) return this;
    return AppThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      topBarBg: Color.lerp(topBarBg, other.topBarBg, t)!,
      sidebarBg: Color.lerp(sidebarBg, other.sidebarBg, t)!,
      tableHeaderBg: Color.lerp(tableHeaderBg, other.tableHeaderBg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      rowEven: Color.lerp(rowEven, other.rowEven, t)!,
      tagBg: Color.lerp(tagBg, other.tagBg, t)!,
      iconBgPurple: Color.lerp(iconBgPurple, other.iconBgPurple, t)!,
      sidebarFooter: Color.lerp(sidebarFooter, other.sidebarFooter, t)!,
      drawerBg: Color.lerp(drawerBg, other.drawerBg, t)!,
      comingSoonBadge: Color.lerp(comingSoonBadge, other.comingSoonBadge, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      info: Color.lerp(info, other.info, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      tintPrimary: Color.lerp(tintPrimary, other.tintPrimary, t)!,
      tintInfo: Color.lerp(tintInfo, other.tintInfo, t)!,
      tintAccent: Color.lerp(tintAccent, other.tintAccent, t)!,
      tintSuccess: Color.lerp(tintSuccess, other.tintSuccess, t)!,
      tintWarning: Color.lerp(tintWarning, other.tintWarning, t)!,
      tintDanger: Color.lerp(tintDanger, other.tintDanger, t)!,
      radius: radius,
      radiusSm: radiusSm,
      fontFamily: fontFamily,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Global getter — for use inside Obx() where context is unavailable
// ─────────────────────────────────────────────────────────────────────────────
AppThemeColors get appColors =>
    Get.theme.extension<AppThemeColors>() ?? AppThemeColors.light;

// ─────────────────────────────────────────────────────────────────────────────
// BuildContext extension — use context.appColors inside build() methods.
// This hooks into Flutter's InheritedWidget system so widgets automatically
// rebuild when the theme changes — no Obx or setState needed.
// ─────────────────────────────────────────────────────────────────────────────
extension AppThemeColorsContext on BuildContext {
  AppThemeColors get appColors =>
      Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.light;
}

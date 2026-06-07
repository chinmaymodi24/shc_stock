import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Brand constants — never change with theme
// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primaryOrange = Color(0xFFF47B20);
  static const Color primaryPurple = Color(0xFF2B1888);
  static const Color accentPurple  = Color(0xFF4A3AFF);

  // Background
  static const Color backgroundLavender  = Color(0xFFEEECFF);
  static const Color backgroundPurpleTint = Color(0xFFDDDAFF);
  static const Color white = Color(0xFFFFFFFF);

  // Text
  static const Color textDark   = Color(0xFF1A1240);
  static const Color textMedium = Color(0xFF6B6B8A);
  static const Color textLight  = Color(0xFFAAAAAA);

  // Input
  static const Color inputBorder = Color(0xFFE0DFF5);
  static const Color inputIcon   = Color(0xFF4A3AFF);

  // Divider
  static const Color dividerPurple = Color(0xFF4A3AFF);

  // Shadow
  static const Color cardShadow = Color(0x1A4A3AFF);
}

// ─────────────────────────────────────────────────────────────────────────────
// Semantic color tokens — switch with Light / Dark theme
// ─────────────────────────────────────────────────────────────────────────────
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color background;
  final Color surface;        // card / white areas
  final Color topBarBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color border;
  final Color divider;
  final Color inputFill;
  final Color rowEven;        // table alternating rows
  final Color tagBg;          // filter chip / tag bg
  final Color iconBgPurple;   // icon container with purple tint
  final Color sidebarFooter;  // admin footer in sidebar
  final Color drawerBg;       // mobile drawer body
  final Color comingSoonBadge;

  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.topBarBg,
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
  });

  // ── Light ──────────────────────────────────────────────────────
  static const light = AppThemeColors(
    background:      Color(0xFFF8F7FF),
    surface:         Color(0xFFFFFFFF),
    topBarBg:        Color(0xFFFFFFFF),
    textPrimary:     Color(0xFF1A1240),
    textSecondary:   Color(0xFF6B6B8A),
    textHint:        Color(0xFF9B9BB4),
    border:          Color(0xFFE0DFF5),
    divider:         Color(0xFFF0EFF8),
    inputFill:       Color(0xFFFFFFFF),
    rowEven:         Color(0xFFFCFBFF),
    tagBg:           Color(0xFFF8F7FF),
    iconBgPurple:    Color(0xFFEEECFF),
    sidebarFooter:   Color(0x14000000),  // black 8%
    drawerBg:        Color(0xFFFFFFFF),
    comingSoonBadge: Color(0xFFF5F4FF),
  );

  // ── Dark ───────────────────────────────────────────────────────
  static const dark = AppThemeColors(
    background:      Color(0xFF13131F),
    surface:         Color(0xFF1E1E2E),
    topBarBg:        Color(0xFF1E1E2E),
    textPrimary:     Color(0xFFEAE8FF),
    textSecondary:   Color(0xFF9B9BB4),
    textHint:        Color(0xFF6B6B8A),
    border:          Color(0xFF2E2E4A),
    divider:         Color(0xFF252538),
    inputFill:       Color(0xFF252538),
    rowEven:         Color(0xFF1A1A2E),
    tagBg:           Color(0xFF252538),
    iconBgPurple:    Color(0xFF2A2A48),
    sidebarFooter:   Color(0x33000000),  // black 20%
    drawerBg:        Color(0xFF1E1E2E),
    comingSoonBadge: Color(0xFF252538),
  );

  @override
  AppThemeColors copyWith({
    Color? background, Color? surface, Color? topBarBg,
    Color? textPrimary, Color? textSecondary, Color? textHint,
    Color? border, Color? divider, Color? inputFill,
    Color? rowEven, Color? tagBg, Color? iconBgPurple,
    Color? sidebarFooter, Color? drawerBg, Color? comingSoonBadge,
  }) {
    return AppThemeColors(
      background:      background      ?? this.background,
      surface:         surface         ?? this.surface,
      topBarBg:        topBarBg        ?? this.topBarBg,
      textPrimary:     textPrimary     ?? this.textPrimary,
      textSecondary:   textSecondary   ?? this.textSecondary,
      textHint:        textHint        ?? this.textHint,
      border:          border          ?? this.border,
      divider:         divider         ?? this.divider,
      inputFill:       inputFill       ?? this.inputFill,
      rowEven:         rowEven         ?? this.rowEven,
      tagBg:           tagBg           ?? this.tagBg,
      iconBgPurple:    iconBgPurple    ?? this.iconBgPurple,
      sidebarFooter:   sidebarFooter   ?? this.sidebarFooter,
      drawerBg:        drawerBg        ?? this.drawerBg,
      comingSoonBadge: comingSoonBadge ?? this.comingSoonBadge,
    );
  }

  @override
  AppThemeColors lerp(AppThemeColors? other, double t) {
    if (other == null) return this;
    return AppThemeColors(
      background:      Color.lerp(background,      other.background,      t)!,
      surface:         Color.lerp(surface,         other.surface,         t)!,
      topBarBg:        Color.lerp(topBarBg,        other.topBarBg,        t)!,
      textPrimary:     Color.lerp(textPrimary,     other.textPrimary,     t)!,
      textSecondary:   Color.lerp(textSecondary,   other.textSecondary,   t)!,
      textHint:        Color.lerp(textHint,        other.textHint,        t)!,
      border:          Color.lerp(border,          other.border,          t)!,
      divider:         Color.lerp(divider,         other.divider,         t)!,
      inputFill:       Color.lerp(inputFill,       other.inputFill,       t)!,
      rowEven:         Color.lerp(rowEven,         other.rowEven,         t)!,
      tagBg:           Color.lerp(tagBg,           other.tagBg,           t)!,
      iconBgPurple:    Color.lerp(iconBgPurple,    other.iconBgPurple,    t)!,
      sidebarFooter:   Color.lerp(sidebarFooter,   other.sidebarFooter,   t)!,
      drawerBg:        Color.lerp(drawerBg,        other.drawerBg,        t)!,
      comingSoonBadge: Color.lerp(comingSoonBadge, other.comingSoonBadge, t)!,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience global getter — use appColors.tokenName anywhere
// ─────────────────────────────────────────────────────────────────────────────
AppThemeColors get appColors =>
    Get.theme.extension<AppThemeColors>() ?? AppThemeColors.light;

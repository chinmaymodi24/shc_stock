import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The whole brand, as data.
//
// Every colour, the font, the corner radius, the company name and the logo
// live here and nowhere else, so a buyer can rebrand the app from the
// Appearance screen without a rebuild. This is the Flutter equivalent of the
// CSS-custom-property root the spec describes: `AppThemeColors` (a
// ThemeExtension) is generated from this, and `AppColors` reads through to it,
// so the 350-odd existing `AppColors.primaryOrange` call sites became
// theme-driven without being touched.
//
// Tints are NOT stored. Every tinted surface is mixed from its base colour on
// demand, so changing `primary` moves its chip background with it and the two
// can never drift apart.
// ─────────────────────────────────────────────────────────────────────────────

/// Mixes [color] toward white by [amount] (0 = untouched, 1 = white).
Color tint(Color color, double amount) =>
    Color.lerp(color, Colors.white, amount)!;

/// `#RRGGBB` → Color. Returns null rather than throwing on junk, so a hex
/// field can reject bad input without losing what the user typed.
Color? colorFromHex(String input) {
  var hex = input.trim().replaceFirst('#', '');
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  if (hex.length != 6) return null;
  final value = int.tryParse(hex, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}

/// Color → `#RRGGBB`, the form the hex fields and storage use.
String hexOf(Color color) {
  final argb = color.toARGB32();
  return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// The fonts a buyer may pick. Resolved through google_fonts at runtime (see
/// [fontFamilyFor]) — nothing is bundled in pubspec, so a name alone would
/// render as the platform default.
const kBrandFonts = <String>[
  'Inter',
  'Poppins',
  'DM Sans',
  'Source Sans 3',
  'IBM Plex Sans',
  'Public Sans',
];

/// One selectable corner radius and the label its Appearance card shows.
class BrandRadius {
  final double value;
  final String label;
  const BrandRadius(this.value, this.label);
}

/// Selectable corner radii. A const Map keyed by double isn't allowed in Dart
/// (double overrides ==), hence the list.
const kBrandRadii = <BrandRadius>[
  BrandRadius(4, 'Sharp'),
  BrandRadius(10, 'Rounded'),
  BrandRadius(16, 'Soft'),
];

class BrandTheme {
  // ── Brand identity ────────────────────────────────────────────────────
  final String companyName;

  /// Up to 3 characters, drawn as the sidebar/login mark when no logo is set.
  final String shortCode;

  /// The uploaded logo as base64 PNG/JPG/SVG bytes, or null for none.
  final String? logoBase64;

  // ── Colors: Brand ─────────────────────────────────────────────────────
  final Color primary;
  final Color secondary;
  final Color info;
  final Color accent;

  // ── Colors: Status ────────────────────────────────────────────────────
  final Color success;
  final Color warning;
  final Color danger;

  // ── Colors: Surfaces ──────────────────────────────────────────────────
  final Color bg;
  final Color cardBg;
  final Color sidebarBg;
  final Color tableHeaderBg;
  final Color rowHover;
  final Color border;

  // ── Colors: Text ──────────────────────────────────────────────────────
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // ── Typography & shape ────────────────────────────────────────────────
  final String font;
  final double radius;

  /// Which preset this came from, or null once any single colour was edited
  /// by hand — the palette is "custom" from that point on.
  final String? presetName;

  const BrandTheme({
    required this.companyName,
    required this.shortCode,
    this.logoBase64,
    required this.primary,
    required this.secondary,
    required this.info,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.bg,
    required this.cardBg,
    required this.sidebarBg,
    required this.tableHeaderBg,
    required this.rowHover,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.font,
    required this.radius,
    this.presetName,
  });

  /// Secure Heat Care — the brand the app ships with, and what "Restore
  /// default" returns to.
  static const defaults = BrandTheme(
    companyName: 'Secure Heat Care',
    shortCode: 'S',
    primary: Color(0xFFF5820A),
    secondary: Color(0xFF2D1B8C),
    info: Color(0xFF2563EB),
    accent: Color(0xFF6B5CBF),
    success: Color(0xFF1E8449),
    warning: Color(0xFFF5820A),
    danger: Color(0xFFC0392B),
    bg: Color(0xFFFAF9F7),
    cardBg: Color(0xFFFFFFFF),
    sidebarBg: Color(0xFFFFFFFF),
    tableHeaderBg: Color(0xFFFAF9F7),
    rowHover: Color(0xFFF5F4F0),
    border: Color(0xFFECECEC),
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF5A5770),
    textTertiary: Color(0xFF8A8797),
    font: 'Inter',
    radius: 10,
    presetName: 'Secure Heat Care',
  );

  // ── Derived — computed, never stored ──────────────────────────────────
  Color get tintPrimary => tint(primary, 0.88);
  Color get tintSecondary => tint(secondary, 0.90);
  Color get tintInfo => tint(info, 0.90);
  Color get tintAccent => tint(accent, 0.90);
  Color get tintSuccess => tint(success, 0.88);
  Color get tintWarning => tint(warning, 0.88);
  Color get tintDanger => tint(danger, 0.90);

  /// Small chips, avatars and icon squares — proportional to [radius] so the
  /// whole app reshapes from one control.
  double get radiusSm =>
      (radius * 0.7).round().toDouble().clamp(3, double.infinity);

  BrandTheme copyWith({
    String? companyName,
    String? shortCode,
    String? logoBase64,
    bool clearLogo = false,
    Color? primary,
    Color? secondary,
    Color? info,
    Color? accent,
    Color? success,
    Color? warning,
    Color? danger,
    Color? bg,
    Color? cardBg,
    Color? sidebarBg,
    Color? tableHeaderBg,
    Color? rowHover,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    String? font,
    double? radius,
    String? presetName,
    bool clearPreset = false,
  }) => BrandTheme(
    companyName: companyName ?? this.companyName,
    shortCode: shortCode ?? this.shortCode,
    logoBase64: clearLogo ? null : (logoBase64 ?? this.logoBase64),
    primary: primary ?? this.primary,
    secondary: secondary ?? this.secondary,
    info: info ?? this.info,
    accent: accent ?? this.accent,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    danger: danger ?? this.danger,
    bg: bg ?? this.bg,
    cardBg: cardBg ?? this.cardBg,
    sidebarBg: sidebarBg ?? this.sidebarBg,
    tableHeaderBg: tableHeaderBg ?? this.tableHeaderBg,
    rowHover: rowHover ?? this.rowHover,
    border: border ?? this.border,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    font: font ?? this.font,
    radius: radius ?? this.radius,
    presetName: clearPreset ? null : (presetName ?? this.presetName),
  );

  // ── Storage ───────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'companyName': companyName,
    'shortCode': shortCode,
    'logoBase64': logoBase64,
    'primary': hexOf(primary),
    'secondary': hexOf(secondary),
    'info': hexOf(info),
    'accent': hexOf(accent),
    'success': hexOf(success),
    'warning': hexOf(warning),
    'danger': hexOf(danger),
    'bg': hexOf(bg),
    'cardBg': hexOf(cardBg),
    'sidebarBg': hexOf(sidebarBg),
    'tableHeaderBg': hexOf(tableHeaderBg),
    'rowHover': hexOf(rowHover),
    'border': hexOf(border),
    'textPrimary': hexOf(textPrimary),
    'textSecondary': hexOf(textSecondary),
    'textTertiary': hexOf(textTertiary),
    'font': font,
    'radius': radius,
    'presetName': presetName,
  };

  /// Any missing or malformed field falls back to the shipped default, so a
  /// half-written blob degrades to "mostly default" instead of refusing to
  /// load and leaving the buyer staring at a broken app.
  factory BrandTheme.fromJson(Map<String, dynamic> json) {
    Color pick(String key, Color fallback) {
      final raw = json[key];
      if (raw is! String) return fallback;
      return colorFromHex(raw) ?? fallback;
    }

    const d = defaults;
    final font = json['font'];
    final radius = json['radius'];
    return BrandTheme(
      companyName: (json['companyName'] as String?)?.trim().isNotEmpty == true
          ? (json['companyName'] as String).trim()
          : d.companyName,
      shortCode: (json['shortCode'] as String?)?.trim().isNotEmpty == true
          ? (json['shortCode'] as String).trim()
          : d.shortCode,
      logoBase64: json['logoBase64'] as String?,
      primary: pick('primary', d.primary),
      secondary: pick('secondary', d.secondary),
      info: pick('info', d.info),
      accent: pick('accent', d.accent),
      success: pick('success', d.success),
      warning: pick('warning', d.warning),
      danger: pick('danger', d.danger),
      bg: pick('bg', d.bg),
      cardBg: pick('cardBg', d.cardBg),
      sidebarBg: pick('sidebarBg', d.sidebarBg),
      tableHeaderBg: pick('tableHeaderBg', d.tableHeaderBg),
      rowHover: pick('rowHover', d.rowHover),
      border: pick('border', d.border),
      textPrimary: pick('textPrimary', d.textPrimary),
      textSecondary: pick('textSecondary', d.textSecondary),
      textTertiary: pick('textTertiary', d.textTertiary),
      font: font is String && kBrandFonts.contains(font) ? font : d.font,
      radius:
          radius is num && kBrandRadii.any((r) => r.value == radius.toDouble())
          ? radius.toDouble()
          : d.radius,
      presetName: json['presetName'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Presets
// ─────────────────────────────────────────────────────────────────────────────

/// One row of the Presets grid. Applying it sets the six brand/status colours
/// and takes `warning = primary`, leaving surfaces and text untouched — a
/// buyer picks an industry palette, not a whole new set of greys.
class BrandPreset {
  final String name;
  final String industry;
  final Color primary;
  final Color secondary;
  final Color info;
  final Color accent;
  final Color success;
  final Color danger;

  const BrandPreset({
    required this.name,
    required this.industry,
    required this.primary,
    required this.secondary,
    required this.info,
    required this.accent,
    required this.success,
    required this.danger,
  });

  BrandTheme applyTo(BrandTheme base) => base.copyWith(
    primary: primary,
    secondary: secondary,
    info: info,
    accent: accent,
    success: success,
    danger: danger,
    warning: primary,
    presetName: name,
  );
}

const kBrandPresets = <BrandPreset>[
  BrandPreset(
    name: 'Secure Heat Care',
    industry: 'Default',
    primary: Color(0xFFF5820A),
    secondary: Color(0xFF2D1B8C),
    info: Color(0xFF2563EB),
    accent: Color(0xFF6B5CBF),
    success: Color(0xFF1E8449),
    danger: Color(0xFFC0392B),
  ),
  BrandPreset(
    name: 'Steel Blue',
    industry: 'Steel & metals',
    primary: Color(0xFF1F6FEB),
    secondary: Color(0xFF0B2545),
    info: Color(0xFF0284C7),
    accent: Color(0xFF7C3AED),
    success: Color(0xFF1E8449),
    danger: Color(0xFFC0392B),
  ),
  BrandPreset(
    name: 'Cement Grey',
    industry: 'Cement & concrete',
    primary: Color(0xFF4A5568),
    secondary: Color(0xFF1A202C),
    info: Color(0xFF3182CE),
    accent: Color(0xFF805AD5),
    success: Color(0xFF276749),
    danger: Color(0xFF9B2C2C),
  ),
  BrandPreset(
    name: 'Chemical Teal',
    industry: 'Chemicals',
    primary: Color(0xFF0F766E),
    secondary: Color(0xFF134E4A),
    info: Color(0xFF0891B2),
    accent: Color(0xFF7E22CE),
    success: Color(0xFF15803D),
    danger: Color(0xFFB91C1C),
  ),
  BrandPreset(
    name: 'Industrial Green',
    industry: 'Agri & processing',
    primary: Color(0xFF3F7D20),
    secondary: Color(0xFF1F3D0C),
    info: Color(0xFF2563EB),
    accent: Color(0xFF7C3AED),
    success: Color(0xFF2F855A),
    danger: Color(0xFFC53030),
  ),
  BrandPreset(
    name: 'Power Amber',
    industry: 'Energy & power',
    primary: Color(0xFFD97706),
    secondary: Color(0xFF78350F),
    info: Color(0xFF2563EB),
    accent: Color(0xFF7C3AED),
    success: Color(0xFF15803D),
    danger: Color(0xFFB91C1C),
  ),
  BrandPreset(
    name: 'Pharma Indigo',
    industry: 'Pharma & labs',
    primary: Color(0xFF4F46E5),
    secondary: Color(0xFF312E81),
    info: Color(0xFF0EA5E9),
    accent: Color(0xFF9333EA),
    success: Color(0xFF059669),
    danger: Color(0xFFDC2626),
  ),
  BrandPreset(
    name: 'Neutral Slate',
    industry: 'Any industry',
    primary: Color(0xFF334155),
    secondary: Color(0xFF0F172A),
    info: Color(0xFF2563EB),
    accent: Color(0xFF6D28D9),
    success: Color(0xFF15803D),
    danger: Color(0xFFB91C1C),
  ),
];

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ── Shared text theme ───────────────────────────────────────────
  static TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
        displayLarge:  TextStyle(fontFamily: 'Poppins', color: primary),
        displayMedium: TextStyle(fontFamily: 'Poppins', color: primary),
        displaySmall:  TextStyle(fontFamily: 'Poppins', color: primary),
        headlineLarge: TextStyle(fontFamily: 'Poppins', color: primary),
        headlineMedium:TextStyle(fontFamily: 'Poppins', color: primary),
        headlineSmall: TextStyle(fontFamily: 'Poppins', color: primary),
        titleLarge:    TextStyle(fontFamily: 'Poppins', color: primary),
        titleMedium:   TextStyle(fontFamily: 'Poppins', color: primary),
        titleSmall:    TextStyle(fontFamily: 'Poppins', color: primary),
        bodyLarge:     TextStyle(fontFamily: 'Poppins', color: primary),
        bodyMedium:    TextStyle(fontFamily: 'Poppins', color: secondary),
        bodySmall:     TextStyle(fontFamily: 'Poppins', color: secondary),
        labelLarge:    TextStyle(fontFamily: 'Poppins', color: primary),
        labelMedium:   TextStyle(fontFamily: 'Poppins', color: secondary),
        labelSmall:    TextStyle(fontFamily: 'Poppins', color: secondary),
      );

  // ── Light Theme ─────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryPurple,
          primary: AppColors.primaryPurple,
          secondary: AppColors.primaryOrange,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppThemeColors.light.background,
        textTheme: _textTheme(
          AppThemeColors.light.textPrimary,
          AppThemeColors.light.textSecondary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppThemeColors.light.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppThemeColors.light.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppThemeColors.light.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
          ),
        ),
        dividerColor: AppThemeColors.light.divider,
        cardColor: AppThemeColors.light.surface,
        extensions: const [AppThemeColors.light],
      );

  // ── Dark Theme ──────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryPurple,
          primary: AppColors.primaryOrange,
          secondary: AppColors.primaryOrange,
          brightness: Brightness.dark,
          surface: AppThemeColors.dark.surface,
        ),
        scaffoldBackgroundColor: AppThemeColors.dark.background,
        textTheme: _textTheme(
          AppThemeColors.dark.textPrimary,
          AppThemeColors.dark.textSecondary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppThemeColors.dark.inputFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppThemeColors.dark.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppThemeColors.dark.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
          ),
        ),
        dividerColor: AppThemeColors.dark.divider,
        cardColor: AppThemeColors.dark.surface,
        extensions: const [AppThemeColors.dark],
      );
}

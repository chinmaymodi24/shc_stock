import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

/// The three things a list page can be turned into.
enum ExportFormat { excel, pdf, csv }

extension ExportFormatX on ExportFormat {
  /// Full label, as it reads in the format menu.
  String get menuLabel => switch (this) {
    ExportFormat.excel => 'Excel (.xlsx)',
    ExportFormat.pdf => 'PDF',
    ExportFormat.csv => 'CSV',
  };

  /// Short label for dropdowns and filenames.
  String get label => switch (this) {
    ExportFormat.excel => 'Excel',
    ExportFormat.pdf => 'PDF',
    ExportFormat.csv => 'CSV',
  };

  String get extension => switch (this) {
    ExportFormat.excel => 'xlsx',
    ExportFormat.pdf => 'pdf',
    ExportFormat.csv => 'csv',
  };

  String get mimeType => switch (this) {
    ExportFormat.excel =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ExportFormat.pdf => 'application/pdf',
    ExportFormat.csv => 'text/csv',
  };

  IconData get icon => switch (this) {
    ExportFormat.excel => Icons.table_view_rounded,
    ExportFormat.pdf => Icons.picture_as_pdf_rounded,
    ExportFormat.csv => Icons.description_outlined,
  };

  /// Format identity colours — the green/red every spreadsheet and PDF icon
  /// in the world uses. They are deliberately not theme tokens: a PDF row
  /// stays red in dark mode, only lightened enough to stay legible on the
  /// dark surface.
  Color color(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (this) {
      // Excel-green and PDF-red are format conventions, but they resolve
      // through the theme so a rebrand carries them and no brand hex stays
      // compiled in. Dark mode's lightening is handled by the palette itself.
      ExportFormat.excel =>
        dark ? AppThemeColors.dark.success : AppThemeColors.light.success,
      ExportFormat.pdf =>
        dark ? AppThemeColors.dark.error : AppThemeColors.light.error,
      ExportFormat.csv =>
        dark ? AppThemeColors.dark.textHint : AppThemeColors.light.textHint,
    };
  }

  /// Rough bytes per cell, used only for the dialog's size estimate.
  int get bytesPerCell => switch (this) {
    ExportFormat.excel => 26,
    ExportFormat.pdf => 14,
    ExportFormat.csv => 11,
  };
}

/// Human-readable file size — "180 KB", "1.4 MB".
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.round()} KB';
  return '${(kb / 1024).toStringAsFixed(1)} MB';
}

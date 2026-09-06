import 'dart:typed_data';

import 'package:shc_stock/app/core/export/export_format.dart';
import 'package:shc_stock/app/core/export/export_source.dart';
import 'package:shc_stock/app/core/export/writers/pdf_table_writer.dart';

/// Everything the user chose in the menu or the dialog. One object so the
/// direct-from-menu path and the "More options…" path run identical code.
class ExportRequest {
  final ExportScope scope;
  final ExportFormat format;
  final List<String> columnKeys;
  final PdfPageLayout pageLayout;
  final bool emailWhenReady;

  const ExportRequest({
    required this.scope,
    required this.format,
    required this.columnKeys,
    this.pageLayout = PdfPageLayout.landscape,
    this.emailWhenReady = false,
  });

  ExportRequest copyWith({
    ExportScope? scope,
    ExportFormat? format,
    List<String>? columnKeys,
    PdfPageLayout? pageLayout,
    bool? emailWhenReady,
  }) => ExportRequest(
    scope: scope ?? this.scope,
    format: format ?? this.format,
    columnKeys: columnKeys ?? this.columnKeys,
    pageLayout: pageLayout ?? this.pageLayout,
    emailWhenReady: emailWhenReady ?? this.emailWhenReady,
  );
}

enum ExportJobState { running, ready, failed }

/// A running or finished export. The toast stack renders these directly.
class ExportJob {
  final int id;
  final String filename;
  final ExportFormat format;
  final int totalRows;
  final ExportJobState state;
  final int processedRows;

  /// Set once the job succeeds — kept so "Download" can re-save without
  /// rebuilding the file.
  final Uint8List? bytes;

  /// Why it failed, phrased as the fix — "Too many rows for PDF — try Excel
  /// or narrow the filters".
  final String? error;

  const ExportJob({
    required this.id,
    required this.filename,
    required this.format,
    required this.totalRows,
    required this.state,
    this.processedRows = 0,
    this.bytes,
    this.error,
  });

  double get progress =>
      totalRows == 0 ? 0 : (processedRows / totalRows).clamp(0.0, 1.0);

  int get sizeBytes => bytes?.length ?? 0;

  ExportJob copyWith({
    ExportJobState? state,
    int? processedRows,
    Uint8List? bytes,
    String? error,
  }) => ExportJob(
    id: id,
    filename: filename,
    format: format,
    totalRows: totalRows,
    state: state ?? this.state,
    processedRows: processedRows ?? this.processedRows,
    bytes: bytes ?? this.bytes,
    error: error ?? this.error,
  );
}

/// A finished file in the global Downloads panel.
class DownloadEntry {
  final int id;
  final String filename;
  final ExportFormat format;
  final int rowCount;
  final Uint8List bytes;
  final DateTime createdAt;

  const DownloadEntry({
    required this.id,
    required this.filename,
    required this.format,
    required this.rowCount,
    required this.bytes,
    required this.createdAt,
  });

  int get sizeBytes => bytes.length;

  /// "just now", "2 hrs ago", "yesterday".
  String get age {
    final elapsed = DateTime.now().difference(createdAt);
    if (elapsed.inMinutes < 1) return 'just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} min ago';
    if (elapsed.inHours < 24) {
      return '${elapsed.inHours} hr${elapsed.inHours == 1 ? '' : 's'} ago';
    }
    if (elapsed.inDays == 1) return 'yesterday';
    return '${elapsed.inDays} days ago';
  }
}

/// Builds the export filename: `<entity>-<scope>-<period>.<ext>`, lowercase
/// and hyphenated — products-filtered-fy2025-26.xlsx.
String buildExportFilename({
  required String entityKey,
  required ExportScope scope,
  required String periodSlug,
  required ExportFormat format,
}) {
  String slug(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final parts = [
    slug(entityKey),
    scope.slug,
    slug(periodSlug),
  ].where((p) => p.isNotEmpty);
  return '${parts.join('-')}.${format.extension}';
}

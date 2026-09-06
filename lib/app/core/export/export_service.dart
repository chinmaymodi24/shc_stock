import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:shc_stock/app/core/export/export_format.dart';
import 'package:shc_stock/app/core/export/export_job.dart';
import 'package:shc_stock/app/core/export/export_source.dart';
import 'package:shc_stock/app/core/export/export_table.dart';
import 'package:shc_stock/app/core/export/file_saver.dart';
import 'package:shc_stock/app/core/export/writers/csv_writer.dart';
import 'package:shc_stock/app/core/export/writers/pdf_table_writer.dart';
import 'package:shc_stock/app/core/export/writers/xlsx_writer.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// One export pipeline for the whole app.
//
// Every export — from a list page's menu, from its dialog, or from a report —
// goes through [start] and lands in the same Downloads panel. Small jobs
// finish inline and skip straight to READY; large ones report progress so the
// user can keep working while a 20,000-row file is being built.
// ─────────────────────────────────────────────────────────────────────────────
class ExportService extends GetxService {
  static ExportService get to => Get.find<ExportService>();

  /// A PDF past this many rows is refused — it would be hundreds of pages and
  /// take longer to open than to regenerate as a spreadsheet.
  static const int pdfRowLimit = 2000;

  /// Under this, an export is fast enough to finish inline and hand the file
  /// straight over; above it, the job runs in the background.
  static const int syncRowLimit = 1000;

  /// How long a finished file stays in the Downloads panel.
  static const Duration retention = Duration(days: 7);

  /// Live jobs and finished-but-undismissed ones — the toast stack.
  final RxList<ExportJob> jobs = <ExportJob>[].obs;

  /// Everything exported this session, newest first.
  final RxList<DownloadEntry> downloads = <DownloadEntry>[].obs;

  /// Drives the orange dot on the header's Downloads button.
  final RxBool hasNewDownload = false.obs;

  /// Whether the right-side Downloads panel is showing.
  final RxBool panelOpen = false.obs;

  int _nextId = 1;

  /// Kept so a failed job's Retry can re-run exactly what was asked for.
  final Map<int, _JobSpec> _specs = {};

  // ── Public API ────────────────────────────────────────────────────────────

  /// Runs [request] against [source]. Returns the job so a caller can await
  /// the outcome; the toast stack and Downloads panel update on their own.
  Future<ExportJob> start(ExportSource source, ExportRequest request) {
    final filename = buildExportFilename(
      entityKey: source.entityKey,
      scope: request.scope,
      periodSlug: source.periodSlug,
      format: request.format,
    );
    return _run(_JobSpec(source: source, request: request, filename: filename));
  }

  /// Runs an already-built table — the path reports take, where the payload is
  /// a statement rather than a list query.
  Future<ExportJob> startPrebuilt({
    required String filename,
    required ExportFormat format,
    required ExportTable table,
    Uint8List Function()? renderPdf,
    PdfPageLayout pageLayout = PdfPageLayout.portrait,
  }) {
    return _run(
      _JobSpec(
        filename: filename,
        prebuilt: table,
        renderPdf: renderPdf,
        request: ExportRequest(
          scope: ExportScope.all,
          format: format,
          columnKeys: const [],
          pageLayout: pageLayout,
        ),
      ),
    );
  }

  Future<void> retry(ExportJob job) async {
    final spec = _specs[job.id];
    if (spec == null) return;
    jobs.removeWhere((j) => j.id == job.id);
    await _run(spec);
  }

  void dismiss(ExportJob job) {
    jobs.removeWhere((j) => j.id == job.id);
    _specs.remove(job.id);
  }

  /// Writes a finished export to disk / the browser's downloads.
  Future<SavedFile> save(
    String filename,
    ExportFormat format,
    Uint8List bytes,
  ) {
    return saveExportFile(filename, bytes, format.mimeType);
  }

  Future<SavedFile> saveEntry(DownloadEntry entry) =>
      save(entry.filename, entry.format, entry.bytes);

  Future<SavedFile?> saveJob(ExportJob job) async {
    final bytes = job.bytes;
    if (bytes == null) return null;
    return save(job.filename, job.format, bytes);
  }

  void togglePanel() {
    if (panelOpen.value) {
      closePanel();
    } else {
      openPanel();
    }
  }

  void openPanel() {
    // Prune on open rather than on render: mutating the list while the panel
    // is building would re-enter the rebuild it is in the middle of.
    pruneExpired();
    panelOpen.value = true;
    hasNewDownload.value = false;
  }

  void closePanel() => panelOpen.value = false;

  /// Drops anything past the retention window. Called whenever the panel is
  /// read, so the footer's "kept for 7 days" is a rule, not a caption.
  void pruneExpired() {
    final cutoff = DateTime.now().subtract(retention);
    downloads.removeWhere((entry) => entry.createdAt.isBefore(cutoff));
  }

  /// The `Generated <date, time> · <user>` line printed on every PDF.
  String generatedLine() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final stamp =
        '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} '
        '${now.year}, $hour12:${now.minute.toString().padLeft(2, '0')} '
        '${now.hour < 12 ? 'AM' : 'PM'}';
    return 'Generated $stamp · $currentActorName';
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<ExportJob> _run(_JobSpec spec) async {
    final id = _nextId++;
    _specs[id] = spec;

    final totalRows =
        spec.prebuilt?.rowCount ?? spec.source!.countOf(spec.request.scope);

    var job = ExportJob(
      id: id,
      filename: spec.filename,
      format: spec.request.format,
      totalRows: totalRows,
      state: ExportJobState.running,
    );

    if (spec.request.format == ExportFormat.pdf && totalRows > pdfRowLimit) {
      job = job.copyWith(
        state: ExportJobState.failed,
        error: 'Too many rows for PDF — try Excel or narrow the filters',
      );
      jobs.add(job);
      return job;
    }

    final background = totalRows > syncRowLimit;
    if (background) jobs.add(job);

    try {
      final table =
          spec.prebuilt ??
          await spec.source!.buildTableAsync(
            spec.request.scope,
            spec.request.columnKeys,
            onProgress: (done, total) {
              if (!background) return;
              _update(id, (j) => j.copyWith(processedRows: done));
            },
          );

      final custom = spec.request.format == ExportFormat.pdf
          ? spec.renderPdf?.call() ??
                spec.source?.renderCustomPdf(generatedLine())
          : null;
      final bytes = custom ?? _encode(table, spec.request);

      job = job.copyWith(
        state: ExportJobState.ready,
        processedRows: totalRows,
        bytes: bytes,
      );

      final entry = DownloadEntry(
        id: id,
        filename: spec.filename,
        format: spec.request.format,
        rowCount: totalRows,
        bytes: bytes,
        createdAt: DateTime.now(),
      );
      pruneExpired();
      downloads.insert(0, entry);
      hasNewDownload.value = true;

      if (background) {
        _replace(job);
      } else {
        // Small export: the file is what the user asked for, so hand it over
        // immediately and let the toast be the receipt.
        await save(spec.filename, spec.request.format, bytes);
        jobs.add(job);
      }
      return job;
    } catch (e) {
      job = job.copyWith(
        state: ExportJobState.failed,
        error: 'Could not build the file — $e',
      );
      if (background) {
        _replace(job);
      } else {
        jobs.add(job);
      }
      return job;
    }
  }

  Uint8List _encode(ExportTable table, ExportRequest request) {
    return switch (request.format) {
      ExportFormat.csv => buildCsv(table),
      ExportFormat.excel => buildXlsx(table),
      ExportFormat.pdf => buildTablePdf(
        table,
        layout: request.pageLayout,
        generatedLine: generatedLine(),
      ),
    };
  }

  void _update(int id, ExportJob Function(ExportJob) transform) {
    final index = jobs.indexWhere((j) => j.id == id);
    if (index != -1) jobs[index] = transform(jobs[index]);
  }

  void _replace(ExportJob job) {
    final index = jobs.indexWhere((j) => j.id == job.id);
    if (index != -1) {
      jobs[index] = job;
    } else {
      jobs.add(job);
    }
  }
}

class _JobSpec {
  final ExportSource? source;
  final ExportRequest request;
  final String filename;

  /// Set for report exports, where the table is composed rather than queried.
  final ExportTable? prebuilt;

  /// Lets a report render its own paper layout instead of the generic table.
  final Uint8List Function()? renderPdf;

  const _JobSpec({
    this.source,
    required this.request,
    required this.filename,
    this.prebuilt,
    this.renderPdf,
  });
}

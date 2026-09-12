import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/export/export_format.dart';
import 'package:shc_stock/app/core/export/export_job.dart';
import 'package:shc_stock/app/core/export/export_service.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// App-wide export chrome: the job toasts (bottom-right) and the Downloads
// panel (right edge).
//
// Mounted once above the router in main.dart, so an export started on
// Products keeps reporting itself after the user has navigated to Sales —
// which is the whole point of running the big ones as background jobs.
// ─────────────────────────────────────────────────────────────────────────────
class ExportOverlayHost extends StatelessWidget {
  final Widget child;
  const ExportOverlayHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ExportService>()) return child;
    return Stack(
      children: [
        child,
        // Bounded on both sides rather than given a fixed width: 400pt is
        // wider than a phone, and a fixed width there pushed the card off the
        // screen edge.
        Positioned(
          left: 16,
          right: 16,
          bottom: 20,
          child: Align(
            alignment: Alignment.bottomRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: const _ToastStack(),
            ),
          ),
        ),
        const Positioned(top: 0, bottom: 0, right: 0, child: DownloadsPanel()),
      ],
    );
  }
}

class _ToastStack extends StatelessWidget {
  const _ToastStack();

  @override
  Widget build(BuildContext context) {
    final service = ExportService.to;
    return Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final job in service.jobs)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ExportToastCard(job: job),
            ),
        ],
      ),
    );
  }
}

/// One job, in whichever of its three states it is currently in.
class ExportToastCard extends StatelessWidget {
  final ExportJob job;
  const ExportToastCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final service = ExportService.to;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: switch (job.state) {
          ExportJobState.running => _running(colors, service),
          ExportJobState.ready => _ready(colors, service),
          ExportJobState.failed => _failed(colors, service),
        },
      ),
    );
  }

  Widget _running(AppThemeColors colors, ExportService service) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            size: 17,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(width: 8),
          Expanded(child: _title('Preparing your export…', colors)),
          _closeButton(colors, () => service.dismiss(job)),
        ],
      ),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: job.progress,
          minHeight: 4,
          backgroundColor: colors.tagBg,
          valueColor: AlwaysStoppedAnimation(AppColors.primaryOrange),
        ),
      ),
      const SizedBox(height: 8),
      _subline(
        '${job.processedRows} of ${job.totalRows} rows · ${job.filename}',
        colors,
      ),
    ],
  );

  Widget _ready(AppThemeColors colors, ExportService service) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.check_circle_rounded, size: 17, color: colors.success),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _title('Export ready', colors),
            const SizedBox(height: 3),
            _subline(
              '${job.filename} · ${job.totalRows} rows · '
              '${formatFileSize(job.sizeBytes)}',
              colors,
            ),
          ],
        ),
      ),
      const SizedBox(width: 10),
      _FilledMiniButton(label: 'Download', onTap: () => service.saveJob(job)),
      const SizedBox(width: 4),
      _closeButton(colors, () => service.dismiss(job)),
    ],
  );

  Widget _failed(AppThemeColors colors, ExportService service) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.error_rounded, size: 17, color: colors.error),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _title('Export failed', colors),
            const SizedBox(height: 3),
            _subline(job.error ?? 'Something went wrong.', colors),
          ],
        ),
      ),
      const SizedBox(width: 10),
      _OutlinedMiniButton(label: 'Retry', onTap: () => service.retry(job)),
      const SizedBox(width: 4),
      _closeButton(colors, () => service.dismiss(job)),
    ],
  );

  Widget _title(String text, AppThemeColors colors) => Text(
    text,
    style: TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: colors.textPrimary,
      fontFamily: brandFontFamily,
    ),
  );

  Widget _subline(String text, AppThemeColors colors) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      color: colors.textHint,
      fontFamily: brandFontFamily,
    ),
  );

  Widget _closeButton(AppThemeColors colors, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: Padding(
      padding: const EdgeInsets.all(2),
      child: Icon(Icons.close_rounded, size: 15, color: colors.textHint),
    ),
  );
}

class _FilledMiniButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilledMiniButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: brandFontFamily,
        ),
      ),
    ),
  );
}

class _OutlinedMiniButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlinedMiniButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFamily: brandFontFamily,
          ),
        ),
      ),
    );
  }
}

// ── Downloads panel ─────────────────────────────────────────────────────────
/// The one place every export in the app lands, whichever page started it.
class DownloadsPanel extends StatelessWidget {
  const DownloadsPanel({super.key});

  static const double width = 300;

  @override
  Widget build(BuildContext context) {
    final service = ExportService.to;
    final colors = context.appColors;
    return Obx(() {
      if (!service.panelOpen.value) return const SizedBox.shrink();
      return Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(left: BorderSide(color: colors.border)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(-6, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Downloads',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          fontFamily: brandFontFamily,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: service.closePanel,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 17,
                        color: colors.textHint,
                      ),
                      splashRadius: 16,
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.divider),
              Expanded(
                child: service.downloads.isEmpty
                    ? _empty(colors)
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: service.downloads.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: colors.divider),
                        itemBuilder: (_, index) => _DownloadRow(
                          entry: service.downloads[index],
                          newest: index == 0,
                        ),
                      ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.tableHeaderBg,
                  border: Border(top: BorderSide(color: colors.divider)),
                ),
                child: Text(
                  'Exported files are kept for '
                  '${ExportService.retention.inDays} days.',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textHint,
                    fontFamily: brandFontFamily,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _empty(AppThemeColors colors) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Nothing exported yet.\nExports from any list page land here.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          height: 1.5,
          color: colors.textHint,
          fontFamily: brandFontFamily,
        ),
      ),
    ),
  );
}

class _DownloadRow extends StatelessWidget {
  final DownloadEntry entry;
  final bool newest;

  const _DownloadRow({required this.entry, required this.newest});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: () => ExportService.to.saveEntry(entry),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Icon(
              entry.format.icon,
              size: 17,
              color: entry.format.color(Theme.of(context).brightness),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.filename,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontFamily: brandFontFamily,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.rowCount} rows · ${entry.age}',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: colors.textHint,
                      fontFamily: brandFontFamily,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.download_rounded,
              size: 16,
              // The newest file is the one the user is most likely after.
              color: newest ? AppColors.primaryOrange : colors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

/// Header button that opens the panel, with a dot once something new is ready.
class DownloadsHeaderButton extends StatelessWidget {
  const DownloadsHeaderButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ExportService>()) return const SizedBox.shrink();
    final colors = context.appColors;
    final service = ExportService.to;
    final background = colors.background.computeLuminance() > 0.5
        ? const Color(0xFFF1F2F4)
        : colors.inputFill;
    return Obx(
      () => Tooltip(
        message: 'Downloads',
        child: InkWell(
          onTap: service.togglePanel,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.download_rounded,
                  color: colors.textSecondary,
                  size: 21,
                ),
              ),
              if (service.hasNewDownload.value)
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      shape: BoxShape.circle,
                      border: Border.all(color: background, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

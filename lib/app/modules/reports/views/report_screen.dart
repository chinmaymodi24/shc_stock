import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/export/export_service.dart';
import 'package:shc_stock/app/core/export/statement.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/modules/reports/controllers/report_screen_controller.dart';
import 'package:shc_stock/app/modules/reports/export/statement_export.dart';
import 'package:shc_stock/app/modules/reports/widgets/report_period_selector.dart';
import 'package:shc_stock/app/modules/reports/widgets/statement_sheet.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/export/export_menu_button.dart';
import 'package:shc_stock/app/shared/widgets/mobile_appbar_avatar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The report shell — three fixed bands, identical on every report:
//   1. breadcrumb   2. toolbar (period, range, filters, export)   3. KPI strip
// with the statement on a paper sheet beneath. A new report supplies data and
// gets this whole frame for free; nothing about the chrome is per-report.
// ─────────────────────────────────────────────────────────────────────────────
class ReportScreenView extends StatelessWidget {
  const ReportScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 700
          ? const _WebReportScreen()
          : const _MobileReportScreen(),
    );
  }
}

class _WebReportScreen extends GetView<ReportScreenController> {
  const _WebReportScreen();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          const WebSidebar(),
          Expanded(
            child: Column(
              children: [
                const WebTopBar(),
                ReportBreadcrumb(name: controller.definition.name),
                const ReportToolbar(),
                Expanded(
                  child: Container(
                    color: colors.background.computeLuminance() > 0.5
                        ? const Color(0xFFF7F6F3)
                        : colors.background,
                    child: Obx(() => _body(context)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (controller.isLoading.value) {
      return const AppLoadingIndicator(
        label: 'Building the statement...',
        padding: 96,
      );
    }
    final doc = controller.statement.value;
    if (doc.isEmpty) return ReportUnavailable(controller: controller);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: StatementSheet.maxWidth,
              ),
              child: ReportKpiStrip(kpis: doc.kpis),
            ),
          ),
          const SizedBox(height: 18),
          StatementSheet(
            doc: doc,
            generatedLine: ExportService.to.generatedLine(),
          ),
        ],
      ),
    );
  }
}

class _MobileReportScreen extends GetView<ReportScreenController> {
  const _MobileReportScreen();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background.computeLuminance() > 0.5
          ? const Color(0xFFF7F6F3)
          : colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: Get.back,
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
        ),
        title: Text(
          controller.definition.name,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        actions: const [MobileAppBarAvatar(), SizedBox(width: 8)],
      ),
      body: Column(
        children: [
          const ReportToolbar(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const AppLoadingIndicator(
                  label: 'Building the statement...',
                  padding: 64,
                );
              }
              final doc = controller.statement.value;
              if (doc.isEmpty) return ReportUnavailable(controller: controller);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                child: Column(
                  children: [
                    ReportKpiStrip(kpis: doc.kpis, columns: 2),
                    const SizedBox(height: 14),
                    StatementSheet(
                      doc: doc,
                      generatedLine: ExportService.to.generatedLine(),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Band 1: breadcrumb ──────────────────────────────────────────────────────
class ReportBreadcrumb extends StatelessWidget {
  final String name;
  const ReportBreadcrumb({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: Get.back,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 17,
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: Get.back,
            child: Text(
              'Reports',
              style: TextStyle(
                fontSize: 12.5,
                color: colors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 15,
              color: colors.textHint,
            ),
          ),
          Text(
            name,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Band 2: toolbar ─────────────────────────────────────────────────────────
class ReportToolbar extends GetView<ReportScreenController> {
  const ReportToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.background.computeLuminance() > 0.5
            ? const Color(0xFFFAF9F7)
            : colors.inputFill,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Obx(
        () => Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ReportPeriodSelector(
              label: controller.periodButtonLabel,
              current: controller.period.value,
              onChanged: controller.setPeriod,
            ),
            // The resolved window, read-only: the selector says "FY 2025-26",
            // this says exactly which dates that turned out to be.
            if (!controller.isAsOnDate)
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  controller.period.value.rangeLabel,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            if (controller.statement.value.isEmpty)
              const SizedBox.shrink()
            else
              ExportMenuButton(
                filled: true,
                showMoreOptions: false,
                source: StatementExportSource(
                  doc: controller.statement.value,
                  entityKey: controller.definition.key,
                  periodSlug: controller.period.value.slug,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Band 3: KPI strip ───────────────────────────────────────────────────────
class ReportKpiStrip extends StatelessWidget {
  final List<StatementKpi> kpis;
  final int columns;

  const ReportKpiStrip({super.key, required this.kpis, this.columns = 4});

  @override
  Widget build(BuildContext context) {
    if (kpis.isEmpty) return const SizedBox.shrink();
    final rows = <List<StatementKpi>>[];
    for (var i = 0; i < kpis.length; i += columns) {
      rows.add(kpis.sublist(i, (i + columns).clamp(0, kpis.length)));
    }
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: EdgeInsets.only(bottom: row == rows.last ? 0 : 10),
            child: Row(
              children: [
                for (final kpi in row) ...[
                  Expanded(child: _Card(kpi: kpi)),
                  if (kpi != row.last) const SizedBox(width: 10),
                ],
                // Keep the last row's cards the same width as a full row's.
                for (var i = row.length; i < columns; i++) ...[
                  const SizedBox(width: 10),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final StatementKpi kpi;
  const _Card({required this.kpi});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kpi.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: colors.textHint,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            kpi.value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: kpi.positive ? colors.success : colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty / not-yet-built state ─────────────────────────────────────────────
class ReportUnavailable extends StatelessWidget {
  final ReportScreenController controller;
  const ReportUnavailable({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final failed = controller.error.value.isNotEmpty;
    final definition = controller.definition;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              failed ? Icons.cloud_off_rounded : definition.icon,
              size: 34,
              color: colors.textHint,
            ),
            const SizedBox(height: 14),
            Text(
              failed
                  ? controller.error.value
                  : '${definition.name} has no data source yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              failed
                  ? 'Check the backend and try the period again.'
                  : 'Profit & Loss and Balance Sheet are live; this one uses '
                        'the same shell and needs only its figures wired in.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: colors.textHint,
                fontFamily: 'Poppins',
              ),
            ),
            if (failed) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: controller.load,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text(
                  'Try again',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontFamily: 'Poppins',
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

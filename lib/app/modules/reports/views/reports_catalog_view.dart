import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/app_drawer.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/modules/reports/models/report_catalog.dart';
import 'package:shc_stock/app/modules/reports/models/report_period.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/shared/widgets/mobile_appbar_avatar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reports, step one: the catalog.
//
// A searchable card grid grouped by domain. Picking one opens it full-screen
// in the shared report shell — there is deliberately no report picker on the
// statement screen itself, so a report always gets the full page width.
// ─────────────────────────────────────────────────────────────────────────────
class ReportsCatalogView extends StatefulWidget {
  const ReportsCatalogView({super.key});

  @override
  State<ReportsCatalogView> createState() => _ReportsCatalogViewState();
}

class _ReportsCatalogViewState extends State<ReportsCatalogView> {
  final _query = ''.obs;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _query.close();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ReportDefinition> get _matches {
    final q = _query.value.trim().toLowerCase();
    if (q.isEmpty) return kReportCatalog;
    return kReportCatalog
        .where(
          (r) =>
              r.name.toLowerCase().contains(q) ||
              r.description.toLowerCase().contains(q),
        )
        .toList();
  }

  void _open(ReportDefinition report) {
    Get.toNamed(AppRoutes.reportDetail, arguments: report.key);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        final colors = context.appColors;
        final body = Obx(
          () => SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 24 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (wide) ...[_header(colors), const SizedBox(height: 20)],
                if (!wide) ...[_search(colors), const SizedBox(height: 16)],
                ..._groups(wide),
              ],
            ),
          ),
        );

        if (!wide) {
          return Scaffold(
            backgroundColor: colors.background,
            // This page had no drawer, so a phone that reached the catalog
            // could only go back - every other module is a hamburger away.
            drawer: const AppDrawer(activeRoute: AppRoutes.reports),
            appBar: AppBar(
              backgroundColor: colors.surface,
              elevation: 0,
              centerTitle: true,
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    color: colors.textPrimary,
                    size: 24,
                  ),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              title: Text(
                'Reports',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: brandFontFamily,
                ),
              ),
              actions: const [MobileAppBarAvatar(), SizedBox(width: 8)],
            ),
            body: body,
          );
        }

        return Scaffold(
          backgroundColor: colors.background,
          body: Row(
            children: [
              const WebSidebar(),
              Expanded(
                child: Column(
                  children: [
                    const WebTopBar(),
                    Expanded(child: body),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(AppThemeColors colors) {
    final period = ReportPeriod.currentFinancialYear();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: brandFontFamily,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$kCompanyName · ${period.label}',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                  fontFamily: brandFontFamily,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 260, child: _search(colors)),
      ],
    );
  }

  Widget _search(AppThemeColors colors) {
    final fill = colors.background.computeLuminance() > 0.5
        ? const Color(0xFFF1F2F4)
        : colors.inputFill;
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => _query.value = v,
      style: TextStyle(
        fontSize: 13,
        fontFamily: brandFontFamily,
        color: colors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Search reports',
        hintStyle: TextStyle(
          fontSize: 13,
          color: colors.textHint,
          fontFamily: brandFontFamily,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: colors.textHint,
          size: 18,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(appColors.radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(appColors.radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(appColors.radius),
          borderSide: BorderSide(color: AppColors.primaryOrange, width: 1.5),
        ),
      ),
    );
  }

  List<Widget> _groups(bool wide) {
    final colors = context.appColors;
    final matches = _matches;
    if (matches.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Text(
              'No report matches "${_query.value}".',
              style: TextStyle(
                fontSize: 13,
                color: colors.textHint,
                fontFamily: brandFontFamily,
              ),
            ),
          ),
        ),
      ];
    }

    final widgets = <Widget>[];
    for (final group in ReportGroup.values) {
      final reports = matches.where((r) => r.group == group).toList();
      if (reports.isEmpty) continue;
      widgets
        ..add(
          Padding(
            padding: EdgeInsets.only(top: widgets.isEmpty ? 0 : 22, bottom: 10),
            child: Text(
              group.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.06 * 10.5,
                color: colors.textHint,
                fontFamily: brandFontFamily,
              ),
            ),
          ),
        )
        ..add(_grid(reports, wide ? 3 : 1));
    }
    return widgets;
  }

  Widget _grid(List<ReportDefinition> reports, int columns) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final report in reports)
              SizedBox(
                width: width,
                child: _ReportCard(report: report, onTap: () => _open(report)),
              ),
          ],
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportDefinition report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: report.available
          ? onTap
          : () => showAppToast(
              '🚧 Coming Soon',
              '${report.name} is not wired to a data source yet.',
              backgroundColor: AppColors.primaryPurple,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
            ),
      borderRadius: BorderRadius.circular(9),
      child: Opacity(
        // Dimmed rather than hidden: the catalog stays complete, and an
        // unbuilt report says so before it is opened.
        opacity: report.available ? 1 : 0.55,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: report.tint.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(report.icon, size: 16, color: report.tint),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colors.textHint,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                report.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: brandFontFamily,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.4,
                  color: colors.textHint,
                  fontFamily: brandFontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

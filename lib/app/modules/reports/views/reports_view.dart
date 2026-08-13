import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/modules/reports/controllers/reports_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reports — a consolidated snapshot over an optional date range, served by
// GET /api/stats/reports.
// ─────────────────────────────────────────────────────────────────────────────
class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  static final _dateFmt = DateFormat('dd MMM yyyy');

  /// Money lines are stored as raw numbers; everything else prints as-is.
  String _display(String label, String raw) {
    const moneyLabels = {
      'Total Sales',
      'Receivable',
      'Average Order Value',
      'Total Purchases',
      'Payable',
      'Stock Value',
    };
    if (!moneyLabels.contains(label)) return raw;
    return formatRupees(double.tryParse(raw) ?? 0);
  }

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
                Expanded(
                  child: Obx(() {
                    final loading = controller.isLoading.value;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _header(context, colors),
                          const SizedBox(height: 20),
                          // The report body loads under its own header rather
                          // than the header disappearing with it.
                          if (loading)
                            const AppLoadingIndicator(
                              label: 'Loading reports...',
                              padding: 96,
                            )
                          else ...[
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _SectionCard(
                                      title: 'Sales',
                                      icon: Icons.trending_up_rounded,
                                      accent: const Color(0xFF22C55E),
                                      lines: controller.salesLines,
                                      display: _display,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _SectionCard(
                                      title: 'Purchases',
                                      icon: Icons.shopping_cart_outlined,
                                      accent: AppColors.primaryOrange,
                                      lines: controller.purchaseLines,
                                      display: _display,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _SectionCard(
                                      title: 'Stock',
                                      icon: Icons.inventory_2_outlined,
                                      accent: const Color(0xFF4A3AFF),
                                      lines: controller.stockLines,
                                      display: _display,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _netMovementCard(colors),
                            const SizedBox(height: 16),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _RankCard(
                                      title: 'Top Products',
                                      subtitle: 'By units sold',
                                      rows: controller.topProducts,
                                      money: false,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _RankCard(
                                      title: 'Top Clients',
                                      subtitle: 'By sales value',
                                      rows: controller.topClients,
                                      money: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, AppThemeColors colors) {
    final from = controller.from.value;
    final to = controller.to.value;
    final label = from == null || to == null
        ? 'All time'
        : '${_dateFmt.format(from)} — ${_dateFmt.format(to)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Sales, purchase and stock summary — $label',
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (from != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: OutlinedButton(
                  onPressed: controller.clearRange,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontFamily: 'Poppins',
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ElevatedButton.icon(
              onPressed: () => controller.pickRange(context),
              icon: const Icon(
                Icons.date_range_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Date Range',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _netMovementCard(AppThemeColors colors) {
    final value = double.tryParse(controller.netMovement.value) ?? 0;
    final positive = value >= 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: (positive ? const Color(0xFF22C55E) : const Color(0xFFEF4444))
            .withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            positive
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 20,
            color: positive ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net Movement (Sales − Purchases)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cash movement over the range — not accounting profit; '
                  'COGS and expenses are not modelled yet.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.textHint,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatRupees(value),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: positive
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFEF4444),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final List<ReportLine> lines;
  final String Function(String, String) display;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.lines,
    required this.display,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      line.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    display(line.label, line.value),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<ReportRank> rows;
  final bool money;

  const _RankCard({
    required this.title,
    required this.subtitle,
    required this.rows,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.textHint,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No data for this range',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.textHint,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            )
          else
            for (final r in rows)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: colors.divider, width: 0.5),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.name,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                              fontFamily: 'Poppins',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            r.detail,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textHint,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      money
                          ? formatRupees(double.tryParse(r.value) ?? 0)
                          : r.value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

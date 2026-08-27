import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:shc_stock/app/modules/dashboard/models/dashboard_models.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/bar_chart.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/sales_chart.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/category_breakdown.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/app_drawer.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';

class MobileDashboardLayout extends GetView<DashboardController> {
  const MobileDashboardLayout({super.key});

  static const _statLabels = [
    'Total Stock',
    'Out of Stock',
    'Low Stock',
    'Dues',
  ];

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const AppDrawer(activeRoute: AppRoutes.dashboard),
      appBar: _buildAppBar(context),
      // Obx: the layout reads the controller's lists straight out of build(),
      // so without a reactive wrapper it rendered whatever had arrived by the
      // first frame — and stayed empty when the fetch landed after it.
      body: Obx(() {
        // The greeting stays put and the content loads under it, like every
        // other page — the loader used to replace the whole screen.
        final loading = c.dashboardStats.length < 5;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Greeting ────────────────────────────────────────────
              Text(
                'Good morning, ${c.greetingName}!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                "Here's what's happening today",
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),

              if (loading)
                const AppLoadingIndicator(
                  label: 'Loading dashboard...',
                  padding: 72,
                )
              else ...[
                // ── 2x2 stat tiles ──────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _MobileStatTile(
                        data: c.dashboardStats[0],
                        label: _statLabels[0],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MobileStatTile(
                        data: c.dashboardStats[1],
                        label: _statLabels[1],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MobileStatTile(
                        data: c.dashboardStats[2],
                        label: _statLabels[2],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MobileStatTile(
                        data: c.dashboardStats[3],
                        label: _statLabels[3],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Top selling product banner ──────────────────────────
                _TopSellingBanner(data: c.dashboardStats[4]),
                const SizedBox(height: 16),

                // ── Incoming deliveries ──────────────────────────────────
                _MobileCard(
                  title: 'Incoming deliveries',
                  child: Column(
                    children: c.incomingDeliveries
                        .take(2)
                        .map(
                          (d) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _DeliveryRow(data: d),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Charts & Trends (collapsible) ────────────────────────
                Obx(
                  () => _ChartsAccordion(
                    expanded: c.chartsExpanded.value,
                    onToggle: () =>
                        c.chartsExpanded.value = !c.chartsExpanded.value,
                    c: c,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Category breakdown ───────────────────────────────────
                _MobileCard(
                  title: 'Category breakdown',
                  child: CategoryBreakdown(
                    categories: c.categorySlices.take(2).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Low stock alerts ─────────────────────────────────────
                _MobileCard(
                  title: 'Low stock alerts',
                  child: Column(
                    children: c.lowStockAlerts
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _LowStockRow(item: item),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Quick actions grid ─────────────────────────────────
                Text(
                  'Quick actions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.6,
                  children: [
                    _QuickLinkCard(
                      icon: Icons.shopping_cart_outlined,
                      label: 'Add Purchase',
                      iconColor: const Color(0xFF3B82F6),
                      onTap: () => Get.toNamed(AppRoutes.addPurchase),
                    ),
                    _QuickLinkCard(
                      icon: Icons.sell_outlined,
                      label: 'New Sale',
                      iconColor: AppColors.primaryOrange,
                      onTap: () => Get.toNamed(AppRoutes.addSale),
                    ),
                    _QuickLinkCard(
                      icon: Icons.person_add_alt_outlined,
                      label: 'Add Client',
                      iconColor: colors.purple,
                      onTap: () => Get.toNamed(AppRoutes.addClient),
                    ),
                    _QuickLinkCard(
                      icon: Icons.bar_chart_rounded,
                      label: 'Reports',
                      iconColor: colors.success,
                      onTap: () => Get.toNamed(AppRoutes.reports),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colors = context.appColors;
    return AppBar(
      backgroundColor: colors.topBarBg,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.menu_rounded, color: colors.textPrimary, size: 24),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Image.asset('assets/logo.png', width: 80, height: 40),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _AvatarMenuBtn(),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: colors.divider),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2x2 pastel stat tile
// ─────────────────────────────────────────────────────────────────────────────
/// Same summary card the web pages use — icon boxed on the left, flat tint,
/// no border. The value drops a size because two tiles share a phone row.
class _MobileStatTile extends StatelessWidget {
  final DashboardStatData data;
  final String label;
  const _MobileStatTile({required this.data, required this.label});

  @override
  Widget build(BuildContext context) {
    return AppStatCard(
      label: label,
      value: data.value,
      icon: data.icon,
      iconColor: data.iconColor,
      smallValue: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top selling product — full-width lavender banner
// ─────────────────────────────────────────────────────────────────────────────
class _TopSellingBanner extends StatelessWidget {
  final DashboardStatData data;
  const _TopSellingBanner({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // Tint derived from the icon color, like every summary card — the
        // fixed pastel it used to carry stayed light under the dark theme.
        color: data.iconColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          // Expanded + ellipsis: the product name comes from the API, and a
          // real one ("Ceramic Fiber Blanket") overflowed the banner on a
          // phone. The value color also has to follow the theme — it was
          // pinned to near-black, which vanished on the dark tint.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Selling Product',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: data.iconColor,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
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

// ─────────────────────────────────────────────────────────────────────────────
// Generic white bordered card with a bold title
// ─────────────────────────────────────────────────────────────────────────────
class _MobileCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _MobileCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Incoming delivery row — colored bar + item/PO + warehouse/eta
// ─────────────────────────────────────────────────────────────────────────────
class _DeliveryRow extends StatelessWidget {
  final DeliveryItem data;
  const _DeliveryRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final eta = data.eta.isEmpty
        ? data.eta
        : '${data.eta[0].toUpperCase()}${data.eta.substring(1)}';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: data.accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.item} — PO #${data.poRef}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${data.warehouse} · $eta',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
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

// ─────────────────────────────────────────────────────────────────────────────
// Low stock alert row — inline warning icon + name + fraction + progress bar
// ─────────────────────────────────────────────────────────────────────────────
class _LowStockRow extends StatelessWidget {
  final LowStockAlertItem item;
  const _LowStockRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ratio = item.max == 0
        ? 0.0
        : (item.current / item.max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.warning, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.product,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${item.current}/${item.max}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.error,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: colors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(colors.error),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Charts & Trends — collapsible accordion (Purchases / Sales / New clients)
// ─────────────────────────────────────────────────────────────────────────────
class _ChartsAccordion extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final DashboardController c;
  const _ChartsAccordion({
    required this.expanded,
    required this.onToggle,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: colors.textPrimary,
      fontFamily: 'Poppins',
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: colors.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Charts & Trends',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Purchases (6 months)', style: labelStyle),
                  const SizedBox(height: 10),
                  SimpleBarChart(
                    data: c.purchasesData,
                    barColor: AppColors.primaryPurple,
                    height: 110,
                    valueFormatter: formatRupees,
                  ),
                  const SizedBox(height: 20),
                  Text('Sales (6 months)', style: labelStyle),
                  const SizedBox(height: 10),
                  SimpleBarChart(
                    data: c.salesData,
                    barColor: AppColors.primaryOrange,
                    height: 110,
                    valueFormatter: formatRupees,
                  ),
                  const SizedBox(height: 20),
                  Text('New clients (6 months)', style: labelStyle),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 90,
                    child: SalesLineChart(
                      data: c.newClientsData,
                      lineColor: context.appColors.accent,
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

// ─────────────────────────────────────────────────────────────────────────────
// Quick link card — icon chip + bold label
// ─────────────────────────────────────────────────────────────────────────────
class _QuickLinkCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
  const _QuickLinkCard({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar button — tapping it opens the Profile hub (account card + Profile /
// Notifications / Security / Preferences + Sign Out) directly, no dropdown.
// ─────────────────────────────────────────────────────────────────────────────
class _AvatarMenuBtn extends StatelessWidget {
  const _AvatarMenuBtn();

  @override
  Widget build(BuildContext context) {
    final initials = Get.isRegistered<SessionController>()
        ? Get.find<SessionController>().user.value?.initials ?? '—'
        : '—';
    return InkWell(
      onTap: () => Get.toNamed(AppRoutes.settings),
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: AppColors.primaryPurple,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}

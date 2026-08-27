import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/app_drawer.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';
import 'package:shc_stock/app/modules/sales/views/sale_details_dialog.dart';
import 'package:shc_stock/app/modules/sales/views/update_sales_status_dialog.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/shared/widgets/mobile_filter_sheet.dart';

class MobileSalesLayout extends GetView<SalesController> {
  const MobileSalesLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu_rounded, color: colors.textPrimary),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Image.asset(
          'assets/logo.png',
          height: 32,
          fit: BoxFit.fitHeight,
        ),
        centerTitle: false,
        actions: [
          Obx(
            () => MobileFilterButton(
              filters: _buildFilters(
                c,
                c.orders.map((o) => o.client).toSet().toList()..sort(),
              ),
              onClear: c.resetFilters,
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: colors.textSecondary,
                ),
                onPressed: () {},
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: const AppDrawer(activeRoute: AppRoutes.sales),
      body: Obx(() {
        final all = c.orders;
        final tabIndex = c.mobileTabIndex.value;
        final byTab = tabIndex == 0
            ? all.toList()
            : tabIndex == 1
            ? all
                  .where(
                    (o) =>
                        o.status == SalesStatus.confirmed ||
                        o.status == SalesStatus.processing,
                  )
                  .toList()
            : all.where((o) => o.status == SalesStatus.delivered).toList();

        // Same filter logic as WebSalesLayout — search + Client — layered
        // on top of the mobile-only status tab above.
        final q = c.searchQuery.value.toLowerCase();
        final clientFilters = c.clientFilters;
        final filtered = byTab.where((o) {
          if (q.isNotEmpty &&
              !o.client.toLowerCase().contains(q) &&
              !o.soNumber.toLowerCase().contains(q)) {
            return false;
          }
          if (clientFilters.isNotEmpty && !clientFilters.contains(o.client)) {
            return false;
          }
          return true;
        }).toList();

        return Column(
          children: [
            // ── Stats row ─────────────────────────────────────────
            Container(
              color: colors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _MiniStat(
                      label: 'Total Sales',
                      value: formatRupees(c.stats.value.doubleOf('salesMTD')),
                      icon: Icons.shopping_cart_outlined,
                      color: AppColors.primaryOrange,
                    ),
                    const SizedBox(width: 10),
                    _MiniStat(
                      label: 'Orders',
                      value: '${c.stats.value.intOf('totalOrders')}',
                      icon: Icons.receipt_long_outlined,
                      color: context.appColors.accent,
                    ),
                    const SizedBox(width: 10),
                    _MiniStat(
                      label: 'Amount Due',
                      value: formatRupees(c.stats.value.doubleOf('amountDue')),
                      icon: Icons.currency_rupee_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 10),
                    _MiniStat(
                      label: 'Received',
                      value: formatRupees(
                        c.stats.value.doubleOf('receivedMTD'),
                      ),
                      icon: Icons.check_circle_outline_rounded,
                      color: const Color(0xFF22C55E),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search bar — same FilterSearchField the web filter row
            // uses, instead of the ad-hoc TextField every other page used
            // to hand-roll.
            Container(
              color: colors.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: FilterSearchField(
                hint: 'Search by item or SO...',
                width: double.infinity,
                onChanged: (v) {
                  c.searchQuery.value = v;
                  c.currentPage.value = 1;
                },
              ),
            ),

            // ── Tab chips ─────────────────────────────────────────
            Container(
              color: colors.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _TabChip(
                    label: 'All',
                    active: tabIndex == 0,
                    onTap: () => c.mobileTabIndex.value = 0,
                  ),
                  const SizedBox(width: 8),
                  _TabChip(
                    label: 'Confirmed',
                    active: tabIndex == 1,
                    onTap: () => c.mobileTabIndex.value = 1,
                  ),
                  const SizedBox(width: 8),
                  _TabChip(
                    label: 'Delivered',
                    active: tabIndex == 2,
                    onTap: () => c.mobileTabIndex.value = 2,
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.divider),

            // ── Order cards ───────────────────────────────────────
            Expanded(
              child: c.isLoading.value
                  ? const AppLoadingIndicator(label: 'Loading sales orders...')
                  : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.point_of_sale_outlined,
                            size: 48,
                            color: colors.textHint,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No orders found',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textHint,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _MobileOrderCard(order: filtered[i], colors: colors),
                    ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.addSale),
        backgroundColor: AppColors.primaryOrange,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  // Same data/controller binding as WebSalesLayout's FilterBar — Client —
  // shown as a flat chip group instead of a dropdown pill (see
  // mobile_filter_sheet.dart for why).
  List<Widget> _buildFilters(SalesController c, List<String> clients) {
    return [
      MobileFilterChipGroup(
        label: 'Client',
        items: clients,
        selected: c.clientFilters,
        onToggle: (v) {
          if (c.clientFilters.contains(v)) {
            c.clientFilters.remove(v);
          } else {
            c.clientFilters.add(v);
          }
          c.currentPage.value = 1;
        },
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini Stat Chip
// ─────────────────────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  color: colors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Chip
// ─────────────────────────────────────────────────────────────────────────────
class _TabChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.primaryOrange : context.appColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : context.appColors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Order Card
// ─────────────────────────────────────────────────────────────────────────────
class _MobileOrderCard extends StatelessWidget {
  final SalesOrder order;
  final AppThemeColors colors;
  const _MobileOrderCard({required this.order, required this.colors});

  static const _months = [
    '',
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

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month]} ${d.year}';

  String _fmtAmt(double v) {
    final i = v.toInt();
    if (i >= 100000) {
      final l = i ~/ 100000;
      final r = (i % 100000) ~/ 1000;
      return '₹ $l,${r.toString().padLeft(2, '0')},${(i % 1000).toString().padLeft(3, '0')}';
    }
    final s = i.toString();
    return s.length > 3
        ? '₹ ${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}'
        : '₹ $s';
  }

  @override
  Widget build(BuildContext context) {
    final o = order;
    return Container(
      padding: const EdgeInsets.all(14),
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
          // Row 1: SO number + status badges
          Row(
            children: [
              Text(
                o.soNumber,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.accent,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              _SmallBadge(label: o.status.label, color: o.status.color),
              const SizedBox(width: 6),
              _SmallBadge(
                label: o.paymentStatus.label,
                color: o.paymentStatus.color,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Client badge + name
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: o.clientColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    o.clientBadge,
                    style: TextStyle(
                      fontSize: o.clientBadge.length > 2 ? 9 : 11,
                      fontWeight: FontWeight.w800,
                      color: o.clientColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.client,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _fmtDate(o.date),
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
          const SizedBox(height: 10),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: 10),

          // Row 3: Items + Amount + Actions
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 14,
                color: colors.textHint,
              ),
              const SizedBox(width: 4),
              Text(
                '${o.totalQtyLabel} items',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              Text(
                _fmtAmt(o.amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(width: 14),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Get.dialog(
                  SaleDetailsDialog(
                    order: o,
                    onDelete: () {
                      Get.back();
                      confirmDelete(
                        context,
                        itemName: o.soNumber,
                        itemLabel: 'Sales Order',
                        onConfirm: () =>
                            Get.find<SalesController>().deleteOrder(o.id),
                      );
                    },
                  ),
                ),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: context.appColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.remove_red_eye_outlined,
                    color: context.appColors.accent,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Get.dialog(UpdateSalesStatusDialog(order: o)),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.iconBgPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.more_vert_rounded,
                    color: colors.textSecondary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        fontFamily: 'Poppins',
      ),
    ),
  );
}

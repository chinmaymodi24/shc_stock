import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/app_drawer.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/mobile_list_scaffold.dart';
import 'package:shc_stock/app/modules/sales/views/sales_actions.dart';
import 'package:shc_stock/app/shared/widgets/mobile_order_row.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/shared/widgets/mobile_filter_sheet.dart';
import 'package:shc_stock/app/shared/widgets/mobile_appbar_avatar.dart';

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
        title: Text(
          'Sales',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          Obx(
            () => MobileFilterButton(
              filters: _buildFilters(
                c,
                c.orders.map((o) => o.client).toSet().toList()..sort(),
              ),
              onClear: c.resetFilters,
              activeCount:
                  c.clientFilters.length +
                  c.statusFilters.length +
                  c.paymentFilters.length +
                  (c.sortOption.value == 'Default' ? 0 : 1),
            ),
          ),
          const MobileAppBarAvatar(),
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

        final loading = c.isLoading.value;

        return MobileListScaffold(
          statCards: [
            MobileStatCardData(
              label: 'Total Sales',
              value: formatRupees(c.stats.value.doubleOf('salesMTD')),
              icon: Icons.shopping_cart_outlined,
              color: AppColors.primaryOrange,
            ),
            MobileStatCardData(
              label: 'Orders',
              value: '${c.stats.value.intOf('totalOrders')}',
              icon: Icons.receipt_long_outlined,
              color: context.appColors.accent,
            ),
            MobileStatCardData(
              label: 'Amount Due',
              value: formatRupees(c.stats.value.doubleOf('amountDue')),
              icon: Icons.currency_rupee_rounded,
              color: const Color(0xFFF59E0B),
            ),
            MobileStatCardData(
              label: 'Received',
              value: formatRupees(c.stats.value.doubleOf('receivedMTD')),
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF22C55E),
            ),
          ],
          search: FilterSearchField(
            hint: 'Search by item or SO...',
            width: double.infinity,
            onChanged: (v) {
              c.searchQuery.value = v;
              c.currentPage.value = 1;
            },
          ),
          pinnedExtraHeight: 34,
          pinnedExtra: Row(
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
          countLabel: loading ? null : 'Showing ${filtered.length} orders',
          sliver: loading
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppLoadingIndicator(label: 'Loading sales orders...'),
                )
              : filtered.isEmpty
              ? const MobileListEmpty(
                  icon: Icons.point_of_sale_outlined,
                  label: 'No orders found',
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _MobileSaleRow(order: filtered[i]),
                  ),
                ),
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
      borderRadius: BorderRadius.circular(999),
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
// One sale as a dense list row: what went out, to whom, and what's still to
// be collected. Built on the shared [MobileOrderRow] so Sale and Purchase
// read identically.
// ─────────────────────────────────────────────────────────────────────────────
class _MobileSaleRow extends StatelessWidget {
  final SalesOrder order;

  const _MobileSaleRow({required this.order});

  /// What was sold — the first line's product, falling back to the SO number
  /// for older records saved without their lines.
  String get _title =>
      order.items.isEmpty ? order.soNumber : order.items.first.product;

  /// "Suresh Patel · Qty 120" — the client, then how much of it went out.
  String get _subtitle {
    final qty = order.items.isEmpty ? null : 'Qty ${order.totalQtyLabel}';
    return [
      if (order.client.isNotEmpty) order.client,
      qty ?? order.soNumber,
    ].join(' · ');
  }

  /// Collection, not delivery. A Paid order is settled; anything else shows
  /// what's left against what's come in so far. Matches how /api/stats/sales
  /// splits Received from Amount Due.
  (String, Color) _settlement() {
    switch (order.paymentStatus) {
      case PaymentStatus.paid:
        return ('Received', const Color(0xFF22C55E));
      case PaymentStatus.refunded:
        return ('Refunded', const Color(0xFF9CA3AF));
      case PaymentStatus.partial:
      case PaymentStatus.pending:
        final due = order.amount - order.paidAmount;
        if (due <= 0) return ('Received', const Color(0xFF22C55E));
        return ('${formatRupees(due)} due', const Color(0xFFF59E0B));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (statusLabel, statusColor) = _settlement();

    return MobileOrderRow(
      // The client's badge is what the rest of the Sales module identifies an
      // order by (the web table and Top Clients both show it), so the row
      // keeps that rather than deriving initials from the item.
      badge: order.clientBadge.isNotEmpty
          ? order.clientBadge
          : mobileRowInitials(order.client),
      title: _title,
      subtitle: _subtitle,
      amount: formatRupees(order.amount),
      statusLabel: statusLabel,
      statusColor: statusColor,
      onTap: () => SalesActions.view(context, order),
      menuItems: [
        MobileRowMenuItem(
          icon: Icons.remove_red_eye_outlined,
          color: colors.success,
          label: 'View',
          onSelected: () => SalesActions.view(context, order),
        ),
        MobileRowMenuItem(
          icon: Icons.edit_outlined,
          color: colors.purple,
          label: 'Edit',
          onSelected: () => SalesActions.edit(order),
        ),
        MobileRowMenuItem(
          icon: Icons.copy_outlined,
          color: const Color(0xFF3B82F6),
          label: 'Duplicate',
          onSelected: () => SalesActions.duplicate(order),
        ),
        MobileRowMenuItem(
          icon: Icons.published_with_changes_rounded,
          color: colors.accent,
          label: 'Update Status',
          onSelected: () => SalesActions.updateStatus(order),
        ),
        MobileRowMenuItem(
          icon: Icons.delete_outline_rounded,
          color: const Color(0xFFEF4444),
          label: 'Delete',
          onSelected: () => SalesActions.delete(context, order),
        ),
      ],
    );
  }
}

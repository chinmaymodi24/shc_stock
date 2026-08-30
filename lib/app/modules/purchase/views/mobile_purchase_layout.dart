import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/modules/purchase/controllers/purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/models/purchase_model.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/app_drawer.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/mobile_list_scaffold.dart';
import 'package:shc_stock/app/modules/purchase/views/purchase_actions.dart';
import 'package:shc_stock/app/shared/widgets/mobile_row_actions.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/shared/widgets/mobile_filter_sheet.dart';
import 'package:shc_stock/app/shared/widgets/mobile_appbar_avatar.dart';

class MobilePurchaseLayout extends GetView<PurchaseController> {
  const MobilePurchaseLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const AppDrawer(activeRoute: AppRoutes.purchase),
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu_rounded, color: colors.textPrimary),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          'Purchase',
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
              filters: _buildFilters(c),
              onClear: c.resetFilters,
              activeCount: c.supplierFilter.value == 'Supplier: All' ? 0 : 1,
            ),
          ),
          const MobileAppBarAvatar(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colors.divider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.addPurchase),
        backgroundColor: AppColors.primaryOrange,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Obx(() {
        final all = c.orders;
        final query = c.searchQuery.value;
        final supplierFilter = c.supplierFilter.value;
        // Same filter logic as WebPurchaseLayout — search, then supplier.
        var filtered = query.isEmpty
            ? all.toList()
            : all
                  .where(
                    (o) =>
                        o.supplier.toLowerCase().contains(
                          query.toLowerCase(),
                        ) ||
                        o.poNumber.toLowerCase().contains(query.toLowerCase()),
                  )
                  .toList();
        if (supplierFilter != 'Supplier: All') {
          filtered = filtered
              .where((o) => o.supplier == supplierFilter)
              .toList();
        }

        final loading = c.isLoading.value;

        return MobileListScaffold(
          statCards: [
            MobileStatCardData(
              label: 'Total Orders',
              value: '${c.stats.value.intOf('totalOrders')}',
              icon: Icons.receipt_long_outlined,
              color: context.appColors.accent,
            ),
            MobileStatCardData(
              label: 'Purchase (MTD)',
              value: formatRupees(c.stats.value.doubleOf('purchaseMTD')),
              icon: Icons.shopping_cart_outlined,
              color: AppColors.primaryOrange,
            ),
            MobileStatCardData(
              label: 'Amount Due',
              value: formatRupees(c.stats.value.doubleOf('amountDue')),
              icon: Icons.currency_rupee_rounded,
              color: const Color(0xFFF59E0B),
            ),
            MobileStatCardData(
              label: 'Amount Paid',
              value: formatRupees(c.stats.value.doubleOf('amountPaid')),
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFF22C55E),
            ),
          ],
          search: FilterSearchField(
            controller: c.searchCtrl,
            hint: 'Search by Item or PO...',
            width: double.infinity,
            onChanged: (v) => c.searchQuery.value = v,
          ),
          countLabel: loading ? null : 'Showing ${filtered.length} purchases',
          sliver: loading
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppLoadingIndicator(
                    label: 'Loading purchase orders...',
                  ),
                )
              : filtered.isEmpty
              ? const MobileListEmpty(
                  icon: Icons.receipt_long_outlined,
                  label: 'No purchases found',
                )
              : SliverPadding(
                  padding: const EdgeInsets.only(top: 4, bottom: 88),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _MobilePurchaseCard(
                        order: filtered[i],
                        index: i,
                        colors: colors,
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                ),
        );
      }),
    );
  }

  // Same data/controller binding as WebPurchaseLayout's FilterBar —
  // Supplier — shown as a flat chip group instead of a dropdown pill (see
  // mobile_filter_sheet.dart for why).
  List<Widget> _buildFilters(PurchaseController c) {
    return [
      Obx(
        () => MobileFilterChoiceGroup(
          label: 'Supplier',
          value: c.supplierFilter.value,
          items: c.supplierNames,
          onChanged: (v) {
            c.supplierFilter.value = v;
            c.currentPage.value = 1;
          },
        ),
      ),
    ];
  }
}

class _MobilePurchaseCard extends StatelessWidget {
  final PurchaseOrder order;
  final int index;
  final AppThemeColors colors;

  const _MobilePurchaseCard({
    required this.order,
    required this.index,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final o = order;
    final dateStr =
        '${o.date.day.toString().padLeft(2, '0')} ${_month(o.date.month)} ${o.date.year}';

    Color statusBg, statusFg;
    switch (o.status) {
      case PurchaseStatus.received:
        statusBg = const Color(0xFF22C55E).withValues(alpha: 0.1);
        statusFg = const Color(0xFF22C55E);
        break;
      case PurchaseStatus.partial:
        statusBg = const Color(0xFFF59E0B).withValues(alpha: 0.1);
        statusFg = const Color(0xFFF59E0B);
        break;
      case PurchaseStatus.pending:
        statusBg = context.appColors.accent.withValues(alpha: 0.1);
        statusFg = context.appColors.accent;
        break;
      case PurchaseStatus.cancelled:
        statusBg = const Color(0xFFEF4444).withValues(alpha: 0.1);
        statusFg = const Color(0xFFEF4444);
        break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => PurchaseActions.view(context, o),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: _cardBody(context, dateStr, statusBg, statusFg),
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            // The web table's four actions, plus the mobile-only Update
            // Status shortcut.
            child: MobileActionRow(
              actions: [
                MobileActionButton.view(
                  context: context,
                  onTap: () => PurchaseActions.view(context, o),
                ),
                MobileActionButton.edit(
                  context: context,
                  onTap: () => PurchaseActions.edit(o),
                ),
                MobileActionButton.duplicate(
                  onTap: () => PurchaseActions.duplicate(o),
                ),
                MobileActionButton(
                  icon: Icons.published_with_changes_rounded,
                  color: colors.accent,
                  tooltip: 'Update Status',
                  onTap: () => PurchaseActions.updateStatus(o),
                ),
                MobileActionButton.delete(
                  onTap: () => PurchaseActions.delete(context, o),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardBody(
    BuildContext context,
    String dateStr,
    Color statusBg,
    Color statusFg,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Index badge
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryOrange,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.poNumber,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.accent,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusFg,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                order.supplier,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: colors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 12,
                    color: colors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${order.totalQtyLabel} items',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₹ ${_fmt(order.amount)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _month(int m) {
    const months = [
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
    return months[m];
  }

  String _fmt(double v) {
    final s = v.toInt();
    if (s >= 100000) {
      return '${(s / 100000).toStringAsFixed(1)}L';
    }
    if (s >= 1000) {
      final str = s.toString();
      return '${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return s.toString();
  }
}


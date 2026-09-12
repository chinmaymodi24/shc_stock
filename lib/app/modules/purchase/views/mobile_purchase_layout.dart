import 'package:shc_stock/app/core/session/app_modules.dart';
import 'package:shc_stock/app/shared/widgets/export/export_menu_button.dart';
import 'package:shc_stock/app/modules/purchase/export/purchase_export.dart';
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
import 'package:shc_stock/app/shared/widgets/mobile_order_row.dart';
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
            fontFamily: brandFontFamily,
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
          // Export reaches the phone too: the same menu the web toolbar
          // opens, as an AppBar icon.
          ExportMenuButton(source: purchaseExportConfig(c), iconOnly: true),
          const MobileAppBarAvatar(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colors.divider),
        ),
      ),
      floatingActionButton: canWriteModule('Purchase')
          ? FloatingActionButton(
              onPressed: () => Get.toNamed(AppRoutes.addPurchase),
              backgroundColor: AppColors.primaryOrange,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
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
          summaryModule: 'Purchase',
          statCards: [
            MobileStatCardData(
              label: 'Orders',
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
              label: 'Amount Paid',
              value: formatRupees(c.stats.value.doubleOf('amountPaid')),
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF22C55E),
            ),
            MobileStatCardData(
              label: 'Amount Due',
              value: formatRupees(c.stats.value.doubleOf('amountDue')),
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFF59E0B),
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _MobilePurchaseRow(order: filtered[i]),
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

// ─────────────────────────────────────────────────────────────────────────────
// One purchase as a dense list row: what was bought, who from, and what's
// still owed on it. Built on the shared [MobileOrderRow] so Purchase and Sale
// read identically.
// ─────────────────────────────────────────────────────────────────────────────
class _MobilePurchaseRow extends StatelessWidget {
  final PurchaseOrder order;

  const _MobilePurchaseRow({required this.order});

  /// What the order is for — the first line's product, falling back to the PO
  /// number for older records saved without their lines.
  String get _title =>
      order.items.isEmpty ? order.poNumber : order.items.first.product;

  /// "Ashoka Metals · INV-2201". The invoice number is what the supplier's
  /// paperwork is filed under, so it identifies the order better than the
  /// internal PO number — which is the fallback when there's no invoice.
  String get _subtitle {
    final ref = order.invoiceNo.isNotEmpty ? order.invoiceNo : order.poNumber;
    return order.supplier.isEmpty ? ref : '${order.supplier} · $ref';
  }

  /// Settlement, not delivery. A Received order is settled; anything else
  /// shows what's left against what's been paid so far. Matches how
  /// /api/stats/purchase splits Amount Paid from Amount Due.
  (String, Color) _settlement() {
    if (order.status == PurchaseStatus.cancelled) {
      return ('Cancelled', const Color(0xFF9CA3AF));
    }
    if (order.status == PurchaseStatus.received) {
      return ('Paid', const Color(0xFF22C55E));
    }
    final due = order.amount - order.paidAmount;
    if (due <= 0) return ('Paid', const Color(0xFF22C55E));
    return ('${formatRupees(due)} due', const Color(0xFFF59E0B));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (statusLabel, statusColor) = _settlement();

    return MobileOrderRow(
      badge: mobileRowInitials(_title),
      title: _title,
      subtitle: _subtitle,
      amount: formatRupees(order.amount),
      statusLabel: statusLabel,
      statusColor: statusColor,
      onTap: () => PurchaseActions.view(context, order),
      menuItems: [
        MobileRowMenuItem(
          icon: Icons.remove_red_eye_outlined,
          color: colors.success,
          label: 'View',
          onSelected: () => PurchaseActions.view(context, order),
        ),
        if (canWriteModule('Purchase')) ...[
          MobileRowMenuItem(
            icon: Icons.edit_outlined,
            color: colors.purple,
            label: 'Edit',
            onSelected: () => PurchaseActions.edit(order),
          ),
          MobileRowMenuItem(
            icon: Icons.copy_outlined,
            color: const Color(0xFF3B82F6),
            label: 'Duplicate',
            onSelected: () => PurchaseActions.duplicate(order),
          ),
          MobileRowMenuItem(
            icon: Icons.published_with_changes_rounded,
            color: colors.accent,
            label: 'Update Status',
            onSelected: () => PurchaseActions.updateStatus(order),
          ),
          MobileRowMenuItem(
            icon: Icons.delete_outline_rounded,
            color: const Color(0xFFEF4444),
            label: 'Delete',
            onSelected: () => PurchaseActions.delete(context, order),
          ),
        ],
      ],
    );
  }
}

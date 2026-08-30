import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/app_drawer.dart';
import 'package:shc_stock/app/modules/stock/controllers/stock_controller.dart';
import 'package:shc_stock/app/modules/stock/models/stock_item_model.dart';
import 'package:shc_stock/app/modules/stock/views/stock_actions.dart';
import 'package:shc_stock/app/shared/widgets/mobile_row_actions.dart';
import 'package:shc_stock/app/modules/stock/views/stock_adjustment_dialog.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/mobile_list_scaffold.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/shared/widgets/mobile_filter_sheet.dart';
import 'package:shc_stock/app/shared/widgets/mobile_appbar_avatar.dart';

/// Mobile counterpart of WebStockLayout — same data (GET /api/inventory)
/// and the same View → StockItemDetailsPanel (with edit/delete) flow, plus
/// the Adjust Stock entry point, laid out as a card list.
class MobileStockLayout extends StatelessWidget {
  const MobileStockLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<StockController>();
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const AppDrawer(activeRoute: AppRoutes.stock),
      appBar: _buildAppBar(context, c),
      body: _buildList(context, c),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.dialog(const StockAdjustmentDialog()),
        backgroundColor: AppColors.primaryOrange,
        icon: const Icon(Icons.tune_rounded, color: Colors.white),
        label: const Text(
          'Adjust Stock',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, StockController c) {
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
      title: Text(
        'Inventory',
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
            onClear: () {
              c.search.value = '';
              c.searchCtrl.clear();
              c.catFilters.clear();
              c.statFilters.clear();
              c.sortOption.value = 'Default';
              c.currentPage.value = 1;
            },
            activeCount:
                c.catFilters.length +
                c.statFilters.length +
                (c.sortOption.value == 'Default' ? 0 : 1),
          ),
        ),
        const MobileAppBarAvatar(),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: colors.divider),
      ),
    );
  }

  Widget _searchField(StockController c) => FilterSearchField(
    controller: c.searchCtrl,
    hint: 'Search by name or SKU...',
    width: double.infinity,
    onChanged: (v) {
      c.search.value = v;
      c.currentPage.value = 1;
    },
  );

  // Same data/controller bindings as WebStockLayout's FilterBar — Category,
  // Status, Sort — shown as flat chip groups instead of dropdown pills (see
  // mobile_filter_sheet.dart for why).
  List<Widget> _buildFilters(StockController c) {
    return [
      Obx(() {
        final categoryOptions = c.items.map((i) => i.category).toSet().toList()
          ..sort();
        return MobileFilterChipGroup(
          label: 'Category',
          items: categoryOptions,
          selected: c.catFilters,
          onToggle: (v) {
            if (c.catFilters.contains(v)) {
              c.catFilters.remove(v);
            } else {
              c.catFilters.add(v);
            }
            c.currentPage.value = 1;
          },
        );
      }),
      MobileFilterChipGroup(
        label: 'Status',
        items: const ['In Stock', 'Low Stock', 'Out of Stock', 'Inactive'],
        selected: c.statFilters,
        onToggle: (v) {
          if (c.statFilters.contains(v)) {
            c.statFilters.remove(v);
          } else {
            c.statFilters.add(v);
          }
          c.currentPage.value = 1;
        },
      ),
      Obx(
        () => MobileFilterChoiceGroup(
          label: 'Sort by',
          value: c.sortOption.value,
          items: StockController.sortOptions
              .where((o) => o != 'Default')
              .toList(),
          onChanged: (v) => c.sortOption.value = v,
        ),
      ),
    ];
  }

  List<MobileStatCardData> _statCards(StockController c) {
    return [
      MobileStatCardData(
        label: 'Total Items',
        value: '${c.stats.value.intOf('totalItems')}',
        icon: Icons.inventory_2_outlined,
        color: AppColors.primaryOrange,
        // Tap to drop the status filter — back to the full list.
        onTap: c.statFilters.clear,
      ),
      MobileStatCardData(
        label: 'Low Stock',
        value: '${c.stats.value.intOf('lowStock')}',
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFF59E0B),
        selected: c.statFilters.contains('Low Stock'),
        onTap: () => c.statFilters.contains('Low Stock')
            ? c.statFilters.remove('Low Stock')
            : c.statFilters.add('Low Stock'),
      ),
      MobileStatCardData(
        label: 'Out of Stock',
        value: '${c.stats.value.intOf('outOfStock')}',
        icon: Icons.block_rounded,
        color: const Color(0xFFEF4444),
        selected: c.statFilters.contains('Out of Stock'),
        onTap: () => c.statFilters.contains('Out of Stock')
            ? c.statFilters.remove('Out of Stock')
            : c.statFilters.add('Out of Stock'),
      ),
      MobileStatCardData(
        label: 'Stock Value',
        value: formatRupees(c.stats.value.doubleOf('totalValue')),
        icon: Icons.currency_rupee_rounded,
        color: const Color(0xFF22C55E),
      ),
    ];
  }

  Widget _buildList(BuildContext context, StockController c) {
    return Obx(() {
      final loading = c.isLoading.value && c.items.isEmpty;
      // Same filter + sort logic as WebStockLayout — search, category,
      // status, then the chosen sort order.
      final q = c.search.value.toLowerCase();
      final catFilters = c.catFilters;
      final statFilters = c.statFilters;
      final filtered = c.items.where((item) {
        if (q.isNotEmpty &&
            !item.name.toLowerCase().contains(q) &&
            !item.sku.toLowerCase().contains(q)) {
          return false;
        }
        if (catFilters.isNotEmpty && !catFilters.contains(item.category)) {
          return false;
        }
        if (statFilters.isNotEmpty && !statFilters.contains(item.statusLabel)) {
          return false;
        }
        return true;
      }).toList();

      switch (c.sortOption.value) {
        case 'Default':
          filtered.sort(
            (a, b) => b.effectiveModifiedAt.compareTo(a.effectiveModifiedAt),
          );
        case 'Item Name (A-Z)':
          filtered.sort((a, b) => a.name.compareTo(b.name));
        case 'Item Name (Z-A)':
          filtered.sort((a, b) => b.name.compareTo(a.name));
        case 'Qty: Low to High':
          filtered.sort((a, b) => a.stockInHand.compareTo(b.stockInHand));
        case 'Qty: High to Low':
          filtered.sort((a, b) => b.stockInHand.compareTo(a.stockInHand));
        case 'Value: Low to High':
          filtered.sort((a, b) => a.stockValue.compareTo(b.stockValue));
        case 'Value: High to Low':
          filtered.sort((a, b) => b.stockValue.compareTo(a.stockValue));
      }

      return MobileListScaffold(
        statCards: _statCards(c),
        search: _searchField(c),
        countLabel: loading ? null : 'Showing ${filtered.length} items',
        sliver: loading
            ? const SliverFillRemaining(
                hasScrollBody: false,
                child: AppLoadingIndicator(label: 'Loading inventory...'),
              )
            : filtered.isEmpty
            ? const MobileListEmpty(
                icon: Icons.inventory_2_outlined,
                label: 'No items found',
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                sliver: SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _MobileStockCard(item: filtered[i]),
                ),
              ),
      );
    });
  }
}

class _MobileStockCard extends StatelessWidget {
  final StockItemModel item;
  const _MobileStockCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => StockActions.view(context, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: item.statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: item.statusColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${item.sku} · ${item.category}',
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                fontFamily: 'Poppins',
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 13,
                  color: colors.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  'Qty: ${item.stockInHand}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.accent,
                    fontFamily: 'Poppins',
                  ),
                ),
                const Spacer(),
                Text(
                  formatRupees(item.stockValue),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: colors.divider),
            const SizedBox(height: 6),
            // Same four actions the web table offers — an inventory row is a
            // product, so Edit/Duplicate/Delete act on that product.
            MobileActionRow(
              actions: [
                MobileActionButton.view(
                  context: context,
                  onTap: () => StockActions.view(context, item),
                ),
                MobileActionButton.edit(
                  context: context,
                  onTap: () => StockActions.edit(item),
                ),
                MobileActionButton.duplicate(
                  onTap: () => StockActions.duplicate(item),
                ),
                MobileActionButton.delete(
                  onTap: () => StockActions.delete(context, item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/app_drawer.dart';
import 'package:shc_stock/app/modules/stock/controllers/stock_controller.dart';
import 'package:shc_stock/app/modules/stock/models/stock_item_model.dart';
import 'package:shc_stock/app/modules/stock/views/stock_item_details_panel.dart';
import 'package:shc_stock/app/modules/stock/views/stock_adjustment_dialog.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/views/add_product_dialog.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/shared/widgets/mobile_filter_sheet.dart';
import 'package:shc_stock/app/core/utils/stock_sync.dart';

ProductsController _productsController() {
  if (Get.isRegistered<ProductsController>()) {
    return Get.find<ProductsController>();
  }
  return Get.put(ProductsController(), permanent: true);
}

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
      body: Column(
        children: [
          _buildSearchBar(context, c),
          Expanded(child: _buildList(context, c)),
        ],
      ),
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
      actions: [
        MobileFilterButton(
          filters: _buildFilters(c),
          onClear: () {
            c.search.value = '';
            c.searchCtrl.clear();
            c.catFilters.clear();
            c.statFilters.clear();
            c.sortOption.value = 'Default';
            c.currentPage.value = 1;
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: colors.divider),
      ),
    );
  }

  // Same FilterSearchField the web filter row uses, and the same searchCtrl
  // so a Clear-all tap in the filter sheet also clears the visible text.
  Widget _buildSearchBar(BuildContext context, StockController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: FilterSearchField(
        controller: c.searchCtrl,
        hint: 'Search by name or SKU...',
        width: double.infinity,
        onChanged: (v) {
          c.search.value = v;
          c.currentPage.value = 1;
        },
      ),
    );
  }

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

  Widget _buildList(BuildContext context, StockController c) {
    final colors = context.appColors;
    return Obx(() {
      if (c.isLoading.value && c.items.isEmpty) {
        return const AppLoadingIndicator(label: 'Loading inventory...');
      }
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

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        children: [
          // IntrinsicHeight, not a fixed SizedBox — a fixed height clipped
          // AppStatCard whenever its 2-line label ("Out of Stock") plus value
          // ran taller than the guessed number, so the strip now sizes to
          // whatever the tallest card actually needs.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _MobileStatCard(
                    label: 'Total Items',
                    value: '${c.stats.value.intOf('totalItems')}',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.primaryOrange,
                  ),
                  const SizedBox(width: 10),
                  _MobileStatCard(
                    label: 'Low Stock',
                    value: '${c.stats.value.intOf('lowStock')}',
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 10),
                  _MobileStatCard(
                    label: 'Out of Stock',
                    value: '${c.stats.value.intOf('outOfStock')}',
                    icon: Icons.block_rounded,
                    color: const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 10),
                  _MobileStatCard(
                    label: 'Stock Value',
                    value: formatRupees(c.stats.value.doubleOf('totalValue')),
                    icon: Icons.currency_rupee_rounded,
                    color: const Color(0xFF22C55E),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Showing ${filtered.length} items',
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 44,
                      color: colors.textHint,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No items found',
                      style: TextStyle(
                        color: colors.textHint,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filtered.map((item) => _MobileStockCard(item: item)),
        ],
      );
    });
  }
}

class _MobileStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MobileStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: AppStatCard(
        label: label,
        value: value,
        icon: icon,
        iconColor: color,
        smallValue: true,
        showCaption: false,
      ),
    );
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
      onTap: () => Get.dialog(
        StockItemDetailsPanel(
          item: item,
          onEdit: () {
            final product = _productsController().products.firstWhereOrNull(
              (p) => p.id == item.productId.toString(),
            );
            Get.back();
            if (product != null) {
              Get.dialog(AddProductDialog(product: product));
            }
          },
          onDelete: () {
            Get.back();
            confirmDelete(
              context,
              itemName: item.name,
              itemLabel: 'Product',
              onConfirm: () async {
                await _productsController().deleteProduct(
                  item.productId.toString(),
                );
                await refreshStockViews();
              },
            );
          },
        ),
      ),
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
          ],
        ),
      ),
    );
  }
}

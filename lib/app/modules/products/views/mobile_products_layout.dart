import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/app_drawer.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/products/views/add_product_dialog.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/mobile_list_scaffold.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/shared/widgets/mobile_filter_sheet.dart';
import 'package:shc_stock/app/shared/widgets/mobile_appbar_avatar.dart';
import 'package:shc_stock/app/shared/widgets/mobile_row_actions.dart';
import 'package:shc_stock/app/modules/products/views/product_actions.dart';

class MobileProductsLayout extends StatelessWidget {
  const MobileProductsLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProductsController>();
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      drawer: const AppDrawer(activeRoute: AppRoutes.products),
      appBar: _buildAppBar(context, c),
      body: Obx(
        () => MobileListScaffold(
          statCards: _statCards(context, c),
          search: _searchField(c),
          sliver: _buildProductList(c),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.dialog(const AddProductDialog()),
        backgroundColor: AppColors.primaryOrange,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context, ProductsController c) {
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
        'Products',
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
            filters: _buildFilters(context, c),
            onClear: c.resetFilters,
            activeCount:
                c.selectedCategories.length +
                c.selectedSubCategories.length +
                (c.selectedStockStatus.value == 'All' ? 0 : 1) +
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

  // ── Stat Cards ───────────────────────────────────────────────
  // Same 4 KPIs as WebProductsLayout, laid out 2×2 by MobileListScaffold so
  // all four are on screen at once (the scrolling strip hid two behind a
  // swipe) and scroll away with the list.
  List<MobileStatCardData> _statCards(BuildContext context, ProductsController c) {
    return [
          MobileStatCardData(
            label: 'Total Products',
            value: '${c.stats.value.intOf('totalProducts')}',
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFF3B6FC9),
            // Tap to drop the stock-status filter — back to the full list.
            onTap: () => c.selectedStockStatus.value = 'All',
          ),
          MobileStatCardData(
            label: 'Low Stock',
            value: '${c.stats.value.intOf('lowStock')}',
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFC9822F),
            // Tap to filter the list to Low Stock; tap again to clear.
            selected: c.selectedStockStatus.value == 'Low Stock',
            onTap: () => c.selectedStockStatus.value =
                c.selectedStockStatus.value == 'Low Stock'
                ? 'All'
                : 'Low Stock',
          ),
          MobileStatCardData(
            label: 'Out of Stock',
            value: '${c.stats.value.intOf('outOfStock')}',
            icon: Icons.block_rounded,
            color: const Color(0xFFD1494C),
            selected: c.selectedStockStatus.value == 'Out of Stock',
            onTap: () => c.selectedStockStatus.value =
                c.selectedStockStatus.value == 'Out of Stock'
                ? 'All'
                : 'Out of Stock',
          ),
          MobileStatCardData(
            label: 'Total Value',
            value: formatRupees(c.stats.value.doubleOf('totalValue')),
            icon: Icons.currency_rupee_rounded,
            color: const Color(0xFF2E9E5B),
          ),
    ];
  }

  Widget _searchField(ProductsController c) => FilterSearchField(
    hint: 'Search products...',
    onChanged: (v) => c.searchQuery.value = v,
    width: double.infinity,
  );

  // ── Search Bar ───────────────────────────────────────────────
  // Same FilterSearchField the web filter row uses — one search box look
  // across the whole app instead of every mobile page hand-rolling its own
  // TextField decoration.
  // ── Filters ───────────────────────────────────────────────────
  // Same data/controller bindings as WebProductsLayout's _buildFiltersRow —
  // Category, Subcategory, Sort — shown as flat chip groups instead of
  // dropdown pills (see mobile_filter_sheet.dart for why).
  List<Widget> _buildFilters(BuildContext context, ProductsController c) {
    return [
      Obx(
        () => MobileFilterChipGroup(
          label: 'Category',
          selected: c.selectedCategories,
          items: c.categoryNames.where((n) => n != 'All Categories').toList(),
          onToggle: (v) {
            if (c.selectedCategories.contains(v)) {
              c.selectedCategories.remove(v);
            } else {
              c.selectedCategories.add(v);
            }
          },
        ),
      ),
      Obx(
        () => MobileFilterChipGroup(
          label: 'Subcategory',
          selected: c.selectedSubCategories,
          items: c.subCategoryNames,
          onToggle: (v) {
            if (c.selectedSubCategories.contains(v)) {
              c.selectedSubCategories.remove(v);
            } else {
              c.selectedSubCategories.add(v);
            }
          },
        ),
      ),
      Obx(
        () => MobileFilterChoiceGroup(
          label: 'Sort by',
          value: c.sortOption.value,
          items: ProductsController.sortOptions
              .where((o) => o != 'Default')
              .toList(),
          onChanged: (v) => c.sortOption.value = v,
        ),
      ),
    ];
  }

  // ── Product List ─────────────────────────────────────────────
  // A sliver, so it shares one scroll view with the KPI cards above.
  Widget _buildProductList(ProductsController c) {
    if (c.isLoading.value) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: AppLoadingIndicator(label: 'Loading products...'),
      );
    }
    final products = c.filteredProducts;
    if (products.isEmpty) {
      return const MobileListEmpty(
        icon: Icons.inventory_2_outlined,
        label: 'No products found.',
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      sliver: SliverList.separated(
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _ProductCard(product: products[i], controller: c),
      ),
    );
  }
}

// ── Product Card ──────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final ProductsController controller;
  const _ProductCard({required this.product, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isLow = product.currentStock <= product.minimumStock;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: name + stock badge ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.categoryName,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.textHint,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              // Stock status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isLow
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isLow ? 'Low Stock' : 'In Stock',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isLow
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF22C55E),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: 10),
          // ── Row: price | sub-cat ──
          Row(
            children: [
              _InfoChip(
                label: 'Price',
                value: '\u20b9${product.sellingPrice.toStringAsFixed(0)}',
              ),
              const SizedBox(width: 8),
              _InfoChip(label: 'Sub-Cat', value: product.subCategory, flex: 2),
            ],
          ),
          const SizedBox(height: 8),
          // ── Row: stock (only as wide as its own text) + the same four
          // actions the web table offers, pushed to the right ──
          MobileActionRow(
            leading: _InfoChip(
              label: 'Stock',
              value: '${product.currentStock} ${product.unit}',
              expand: false,
            ),
            actions: [
              MobileActionButton.view(
                context: context,
                onTap: () => ProductActions.view(product),
              ),
              MobileActionButton.edit(
                context: context,
                onTap: () => ProductActions.edit(product),
              ),
              MobileActionButton.duplicate(
                onTap: () => ProductActions.duplicate(product),
              ),
              MobileActionButton.delete(
                onTap: () => ProductActions.delete(context, product),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final int flex;

  /// False sizes the chip to its text instead of stretching it across the
  /// row — a short value like "0 Bag" shouldn't own half the card.
  final bool expand;

  const _InfoChip({
    required this.label,
    required this.value,
    this.flex = 1,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.tagBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: colors.textHint,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              fontFamily: 'Poppins',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
    return expand ? Expanded(flex: flex, child: chip) : chip;
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/app_drawer.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/products/views/add_product_dialog.dart';
import 'package:shc_stock/app/modules/products/widgets/product_thumbnail.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/mobile_list_scaffold.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/shared/widgets/mobile_filter_sheet.dart';
import 'package:shc_stock/app/shared/widgets/mobile_appbar_avatar.dart';
import 'package:shc_stock/app/shared/widgets/mobile_order_row.dart';
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
  List<MobileStatCardData> _statCards(
    BuildContext context,
    ProductsController c,
  ) {
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
            c.selectedStockStatus.value == 'Low Stock' ? 'All' : 'Low Stock',
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      sliver: SliverList.separated(
        itemCount: products.length,
        separatorBuilder: (_, __) => Builder(
          builder: (context) =>
              Divider(height: 1, color: context.appColors.divider),
        ),
        itemBuilder: (_, i) => _ProductRow(product: products[i]),
      ),
    );
  }
}

// ── Product Row ──────────────────────────────────────────────
// A flat list — photo, status dot + name + a one-line summary, and a kebab
// menu for the same four actions the web table offers — rather than the
// bordered per-item cards every other mobile list page uses. Products reads
// better dense: the photo already carries most of the visual weight a card's
// border/shadow would otherwise add.
class _ProductRow extends StatelessWidget {
  final ProductModel product;
  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final status = _statusOf(product);

    return InkWell(
      onTap: () => ProductActions.view(product),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ProductThumbnail(
              imageUrl: product.imageUrl,
              fallbackLabel: product.name,
              size: 56,
              radius: 12,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: status.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        status.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: status.color,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _summaryOf(product),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textHint,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            MobileRowMenu(
              items: [
                MobileRowMenuItem(
                  icon: Icons.remove_red_eye_outlined,
                  color: colors.success,
                  label: 'View',
                  onSelected: () => ProductActions.view(product),
                ),
                MobileRowMenuItem(
                  icon: Icons.edit_outlined,
                  color: colors.purple,
                  label: 'Edit',
                  onSelected: () => ProductActions.edit(product),
                ),
                MobileRowMenuItem(
                  icon: Icons.copy_outlined,
                  color: const Color(0xFF3B82F6),
                  label: 'Duplicate',
                  onSelected: () => ProductActions.duplicate(product),
                ),
                MobileRowMenuItem(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFEF4444),
                  label: 'Delete',
                  onSelected: () => ProductActions.delete(context, product),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// "₹1,240 · Ceramic Fiber Blanket · 612 Roll" — the sub-category is more
  /// specific than the top-level category and matches what the name already
  /// narrows down to; falls back to the category when a product has none.
  static String _summaryOf(ProductModel p) {
    final group = p.subCategory.isNotEmpty ? p.subCategory : p.categoryName;
    final stock = p.currentStock == 0
        ? 'Out of stock'
        : '${p.currentStock} ${p.unit}';
    return '₹${p.sellingPrice.toStringAsFixed(0)} · $group · $stock';
  }

  static _RowStatus _statusOf(ProductModel p) {
    switch (p.stockStatus) {
      case 'Out of Stock':
        return const _RowStatus('Out of Stock', Color(0xFFEF4444));
      case 'Low Stock':
        return const _RowStatus('Low Stock', Color(0xFFF59E0B));
      default:
        return const _RowStatus('Active', Color(0xFF22C55E));
    }
  }
}

class _RowStatus {
  final String label;
  final Color color;
  const _RowStatus(this.label, this.color);
}

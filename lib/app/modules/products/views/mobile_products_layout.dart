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
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/shared/widgets/mobile_filter_sheet.dart';

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
      body: Column(
        children: [
          _buildStatCards(context, c),
          _buildSearchBar(context, c),
          Expanded(child: _buildProductList(c)),
        ],
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
      actions: [
        MobileFilterButton(
          filters: _buildFilters(context, c),
          onClear: c.resetFilters,
        ),
        Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: colors.textPrimary,
                size: 24,
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
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: colors.divider),
      ),
    );
  }

  // ── Stat Cards ───────────────────────────────────────────────
  // Same 4 cards as WebProductsLayout's _buildStatCards, stacked into a
  // horizontally scrolling strip. IntrinsicHeight — not a fixed-height
  // SizedBox — so a 2-line label ("Out of Stock") sizes the strip instead
  // of overflowing a guessed fixed height (see the same fix on
  // Stock/Transactions/Clients/Users).
  Widget _buildStatCards(BuildContext context, ProductsController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Obx(
        () => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicHeight(
            child: Row(
              children: [
                _MobileStatCard(
                  label: 'Total Products',
                  value: '${c.stats.value.intOf('totalProducts')}',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF3B6FC9),
                ),
                const SizedBox(width: 10),
                _MobileStatCard(
                  label: 'Low Stock',
                  value: '${c.stats.value.intOf('lowStock')}',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFC9822F),
                ),
                const SizedBox(width: 10),
                _MobileStatCard(
                  label: 'Out of Stock',
                  value: '${c.stats.value.intOf('outOfStock')}',
                  icon: Icons.block_rounded,
                  color: const Color(0xFFD1494C),
                ),
                const SizedBox(width: 10),
                _MobileStatCard(
                  label: 'Total Value',
                  value: formatRupees(c.stats.value.doubleOf('totalValue')),
                  icon: Icons.currency_rupee_rounded,
                  color: const Color(0xFF2E9E5B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Search Bar ───────────────────────────────────────────────
  // Same FilterSearchField the web filter row uses — one search box look
  // across the whole app instead of every mobile page hand-rolling its own
  // TextField decoration.
  Widget _buildSearchBar(BuildContext context, ProductsController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: FilterSearchField(
        hint: 'Search products...',
        onChanged: (v) => c.searchQuery.value = v,
        width: double.infinity,
      ),
    );
  }

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
  Widget _buildProductList(ProductsController c) {
    return Obx(() {
      if (c.isLoading.value) {
        return const AppLoadingIndicator(label: 'Loading products...');
      }
      final products = c.filteredProducts;
      if (products.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 56,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 12),
              const Text(
                'No products found.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF9B9BB4),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) =>
            _ProductCard(product: products[i], controller: c),
      );
    });
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
          // ── Top Row: icon + name + stock badge ──
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
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
          // ── Bottom Row: price | stock | sub-cat + actions ──
          Row(
            children: [
              _InfoChip(
                label: 'Price',
                value: '\u20b9${product.sellingPrice.toStringAsFixed(0)}',
              ),
              const SizedBox(width: 8),
              _InfoChip(
                label: 'Stock',
                value: '${product.currentStock} ${product.unit}',
              ),
              const SizedBox(width: 8),
              _InfoChip(label: 'Sub-Cat', value: product.subCategory, flex: 2),
            ],
          ),
          const SizedBox(height: 12),
          // ── Action Row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _MobileActionBtn(
                icon: Icons.edit_outlined,
                // Was AppColors.primaryPurple — the icon's own background is
                // just a 10%-alpha tint of this same color, so on the dark
                // theme's already-dark surface both the icon and its tint
                // stayed dark and hard to see.
                color: colors.purple,
                onTap: () => Get.dialog(AddProductDialog(product: product)),
              ),
              const SizedBox(width: 8),
              _MobileActionBtn(
                icon: Icons.delete_outline_rounded,
                color: const Color(0xFFEF4444),
                onTap: () => confirmDelete(
                  context,
                  itemName: product.name,
                  itemLabel: 'Product',
                  onConfirm: () => controller.deleteProduct(product.id),
                ),
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
  const _InfoChip({required this.label, required this.value, this.flex = 1});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colors.tagBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
      ),
    );
  }
}

// ── Mobile Action Button ───────────────────────────────────────────────────────
class _MobileActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MobileActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
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

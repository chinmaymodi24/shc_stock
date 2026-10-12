import 'package:shc_stock/app/core/session/app_modules.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/utils/qty_format.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/products/views/add_product_dialog.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/modified_by_cell.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/products/widgets/product_thumbnail.dart';
import 'package:intl/intl.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/row_action_button.dart';
import 'package:shc_stock/app/modules/products/views/product_actions.dart';
import 'package:shc_stock/app/modules/products/export/products_export.dart';
import 'package:shc_stock/app/shared/widgets/export/export_menu_button.dart';
import 'package:shc_stock/app/shared/widgets/export/list_scope_bar.dart';

part 'web_products_layout_part1.dart';

class WebProductsLayout extends StatelessWidget {
  WebProductsLayout({super.key});

  final c = Get.find<ProductsController>();
  final _searchCtrl = TextEditingController();

  /// Built once: the config is a set of closures over the controller, so it
  /// stays live without being rebuilt on every frame.
  late final _exportSource = productsExportConfig(c);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          const WebSidebar(),
          Expanded(
            child: Column(
              children: [
                const WebTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 20),
                        if (canSeeSummary('Products')) ...[
                          _buildStatCards(c),
                          const SizedBox(height: 20),
                        ],
                        _buildFiltersRow(context, c),
                        _buildScopeBar(c),
                        const SizedBox(height: 12),
                        _buildTableSection(context, c),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Page Title Row (title + subtitle + Add button) ──────────────
  Widget _buildHeader(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Products',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: brandFontFamily,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${c.filteredProducts.length} products',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                  fontFamily: brandFontFamily,
                ),
              ),
            ],
          ),
        ),
        if (canWriteModule('Products'))
          ElevatedButton.icon(
            onPressed: () => Get.dialog(const AddProductDialog()),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            label: Text(
              'Add Product',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: brandFontFamily,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(appColors.radius),
              ),
            ),
          ),
      ],
    );
  }

  // ── Stat Cards ────────────────────────────────────────────────
  Widget _buildStatCards(ProductsController c) {
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    return Obx(
      () => AppStatCardRow(
        cards: [
          AppStatCard(
            label: 'Total Products',
            value: '${c.stats.value.intOf('totalProducts')}',
            icon: Icons.inventory_2_outlined,
            iconColor: const Color(0xFF3B6FC9),
          ),
          AppStatCard(
            label: 'Low Stock',
            value: '${c.stats.value.intOf('lowStock')}',
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFC9822F),
          ),
          AppStatCard(
            label: 'Out of Stock',
            value: '${c.stats.value.intOf('outOfStock')}',
            icon: Icons.block_rounded,
            iconColor: const Color(0xFFD1494C),
          ),
          AppStatCard(
            label: 'Total Value',
            value: '₹${fmt.format(c.stats.value.doubleOf('totalValue'))}',
            icon: Icons.currency_rupee_rounded,
            iconColor: const Color(0xFF2E9E5B),
            smallValue: true,
          ),
        ],
      ),
    );
  }

  // ── Table Section ─────────────────────────────────────────────
  Widget _buildTableSection(BuildContext context, ProductsController c) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(context),
          Divider(height: 1, color: colors.divider),
          Obx(() {
            if (c.isLoading.value) {
              return const AppLoadingIndicator(label: 'Loading products...');
            }
            final products = c.paginatedProducts;
            if (products.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(48),
                child: Center(
                  child: Text(
                    'No products found.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontFamily: brandFontFamily,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: products.asMap().entries.map((e) {
                return _ProductRow(
                  product: e.value,
                  isLast: e.key == products.length - 1,
                  controller: c,
                );
              }).toList(),
            );
          }),
          Divider(height: 1, color: colors.divider),
          _buildPagination(context, c),
        ],
      ),
    );
  }

  // ── Filters Row ───────────────────────────────────────────────
  Widget _buildFiltersRow(BuildContext context, ProductsController c) {
    return FilterBar(
      pillsVisible: () => c.products.isNotEmpty,
      search: FilterSearchField(
        controller: _searchCtrl,
        hint: 'Search products...',
        onChanged: (v) => c.searchQuery.value = v,
      ),
      pills: [
        MultiSelectFilterPill(
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
        Obx(
          () => MultiSelectFilterPill(
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
          () => SingleSelectFilterPill.sort(
            value: c.sortOption.value,
            items: ProductsController.sortOptions
                .where((o) => o != 'Default')
                .toList(),
            onChanged: (v) => c.sortOption.value = v,
          ),
        ),
      ],
      trailing: ExportMenuButton(source: _exportSource),
      clearAll: Obx(() {
        final hasActiveFilters =
            c.searchQuery.value.isNotEmpty ||
            c.selectedCategories.isNotEmpty ||
            c.selectedSubCategories.isNotEmpty ||
            c.sortOption.value != 'Default';
        if (!hasActiveFilters) return const SizedBox.shrink();
        return ClearAllButton(
          onTap: () {
            _searchCtrl.clear();
            c.resetFilters();
          },
        );
      }),
    );
  }

  // ── Scope Bar ─────────────────────────────────────────────────
  // States, in words, exactly what an export will contain.
  Widget _buildScopeBar(ProductsController c) {
    return Obx(() {
      final chips = <ListScopeChip>[
        if (c.searchQuery.value.isNotEmpty)
          ListScopeChip('Search: "${c.searchQuery.value}"', () {
            _searchCtrl.clear();
            c.searchQuery.value = '';
          }),
        for (final category in c.selectedCategories)
          ListScopeChip(category, () => c.selectedCategories.remove(category)),
        for (final sub in c.selectedSubCategories)
          ListScopeChip(sub, () => c.selectedSubCategories.remove(sub)),
        if (c.sortOption.value != 'Default')
          ListScopeChip(
            'Sorted: ${c.sortOption.value}',
            () => c.sortOption.value = 'Default',
          ),
      ];
      return ListScopeBar(
        chips: chips,
        selectedCount: c.selectedIds.length,
        onClearSelection: c.clearSelection,
      );
    });
  }

  // ── Table Header ──────────────────────────────────────────────
  Widget _buildTableHeader(BuildContext context) {
    final colors = context.appColors;
    final style = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: colors.textSecondary,
      fontFamily: brandFontFamily,
    );
    Widget sortIcon() =>
        Icon(Icons.unfold_more_rounded, size: 14, color: colors.textHint);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Obx(
              () => _SelectBox(
                checked: c.allVisibleSelected,
                onTap: c.toggleSelectAll,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Text('Product', style: style),
                const SizedBox(width: 4),
                sortIcon(),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text('Category', style: style)),
          Expanded(flex: 3, child: Text('Subcategory', style: style)),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text('Price', style: style),
                const SizedBox(width: 4),
                sortIcon(),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text('Stock', style: style),
                const SizedBox(width: 4),
                sortIcon(),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text('Modified By', style: style)),
          SizedBox(
            width: 140,
            child: Center(child: Text('Actions', style: style)),
          ),
        ],
      ),
    );
  }

  // ── Pagination ────────────────────────────────────────────────
  Widget _buildPagination(BuildContext context, ProductsController c) {
    final colors = context.appColors;
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(
              'Showing ${(c.currentPage.value - 1) * c.rowsPerPage.value + 1} to ${((c.currentPage.value) * c.rowsPerPage.value).clamp(0, c.filteredProducts.length)} of ${c.filteredProducts.length} entries',
              style: TextStyle(
                fontSize: 12.5,
                color: colors.textSecondary,
                fontFamily: brandFontFamily,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  'Rows per page: ',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.textSecondary,
                    fontFamily: brandFontFamily,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButton<int>(
                    value: c.rowsPerPage.value,
                    isDense: true,
                    underline: const SizedBox(),
                    dropdownColor: colors.surface,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textPrimary,
                      fontFamily: brandFontFamily,
                    ),
                    items: [5, 10, 20, 50]
                        .map(
                          (e) => DropdownMenuItem(value: e, child: Text('$e')),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        c.rowsPerPage.value = v;
                        c.currentPage.value = 1;
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            _PageButton(
              icon: Icons.first_page_rounded,
              onTap: () => c.currentPage.value = 1,
              enabled: c.currentPage.value > 1,
            ),
            _PageButton(
              icon: Icons.chevron_left_rounded,
              onTap: () {
                if (c.currentPage.value > 1) c.currentPage.value--;
              },
              enabled: c.currentPage.value > 1,
            ),
            ...List.generate(c.totalPages.clamp(0, 5), (i) {
              final page = i + 1;
              final isActive = c.currentPage.value == page;
              return InkWell(
                onTap: () => c.currentPage.value = page,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryOrange
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive ? AppColors.primaryOrange : colors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$page',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isActive ? Colors.white : colors.textPrimary,
                        fontFamily: brandFontFamily,
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (c.totalPages > 5) ...[
              Text('...', style: TextStyle(color: colors.textSecondary)),
              InkWell(
                onTap: () => c.currentPage.value = c.totalPages,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.border),
                  ),
                  child: Center(
                    child: Text(
                      '${c.totalPages}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.textPrimary,
                        fontFamily: brandFontFamily,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            _PageButton(
              icon: Icons.chevron_right_rounded,
              onTap: () {
                if (c.currentPage.value < c.totalPages) c.currentPage.value++;
              },
              enabled: c.currentPage.value < c.totalPages,
            ),
            _PageButton(
              icon: Icons.last_page_rounded,
              onTap: () => c.currentPage.value = c.totalPages,
              enabled: c.currentPage.value < c.totalPages,
            ),
          ],
        ),
      ),
    );
  }
}

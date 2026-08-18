import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/products/views/add_product_dialog.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/modified_by_cell.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:intl/intl.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/row_action_button.dart';

class WebProductsLayout extends StatelessWidget {
  WebProductsLayout({super.key});

  final c = Get.find<ProductsController>();
  final _searchCtrl = TextEditingController();

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
                        _buildStatCards(c),
                        const SizedBox(height: 20),
                        _buildFiltersRow(context, c),
                        const SizedBox(height: 16),
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
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${c.filteredProducts.length} products',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => Get.dialog(const AddProductDialog()),
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
          label: const Text(
            'Add Product',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
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
      () => Row(
        children: [
          Expanded(
            child: AppStatCard(
              label: 'Total Products',
              value: '${c.stats.value.intOf('totalProducts')}',
              icon: Icons.inventory_2_outlined,
              iconColor: const Color(0xFF3B6FC9),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AppStatCard(
              label: 'Low Stock',
              value: '${c.stats.value.intOf('lowStock')}',
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFC9822F),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AppStatCard(
              label: 'Out of Stock',
              value: '${c.stats.value.intOf('outOfStock')}',
              icon: Icons.block_rounded,
              iconColor: const Color(0xFFD1494C),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AppStatCard(
              label: 'Total Value',
              value: '₹${fmt.format(c.stats.value.doubleOf('totalValue'))}',
              icon: Icons.currency_rupee_rounded,
              iconColor: const Color(0xFF2E9E5B),
              smallValue: true,
            ),
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
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: products.asMap().entries.map((e) {
                return _ProductRow(
                  product: e.value,
                  isEven: e.key.isEven,
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

  // ── Table Header ──────────────────────────────────────────────
  Widget _buildTableHeader(BuildContext context) {
    final colors = context.appColors;
    final style = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: colors.textSecondary,
      fontFamily: 'Poppins',
    );
    Widget sortIcon() =>
        Icon(Icons.unfold_more_rounded, size: 14, color: colors.textHint);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
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
                fontFamily: 'Poppins',
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
                    fontFamily: 'Poppins',
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
                      fontFamily: 'Poppins',
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
                        fontFamily: 'Poppins',
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
                        fontFamily: 'Poppins',
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

// ── Product Table Row ─────────────────────────────────────────────────────────
class _ProductRow extends StatelessWidget {
  final ProductModel product;
  final bool isEven;
  final ProductsController controller;

  const _ProductRow({
    required this.product,
    required this.isEven,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    final colors = context.appColors;

    Color stockColor;
    if (product.currentStock == 0) {
      stockColor = colors.error;
    } else if (product.currentStock <= product.minimumStock) {
      stockColor = colors.warning;
    } else {
      stockColor = colors.success;
    }

    return Container(
      decoration: BoxDecoration(
        color: isEven ? colors.rowEven : colors.surface,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.sku,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colors.textHint,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                product.categoryName.replaceFirst(RegExp(r'^\d+\.\s'), ''),
                style: TextStyle(
                  fontSize: 12.5,
                  color: colors.textSecondary,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                product.subCategory,
                style: TextStyle(
                  fontSize: 12.5,
                  color: colors.textSecondary,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '₹${fmt.format(product.sellingPrice)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: stockColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${product.currentStock}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: stockColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Builder(
                builder: (_) {
                  final mod = resolveModifiedBy(
                    storedName: product.modifiedBy,
                    storedDate: product.modifiedAt,
                  );
                  if (mod == null) {
                    return ModifiedByEmpty(textHint: colors.textHint);
                  }
                  return ModifiedByCell(
                    name: mod.name,
                    date: mod.date,
                    textPrimary: colors.textPrimary,
                    textHint: colors.textHint,
                  );
                },
              ),
            ),
            SizedBox(
              width: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RowActionButton(
                    icon: Icons.remove_red_eye_outlined,
                    color: colors.success,
                    bg: colors.success.withValues(alpha: 0.10),
                    // No product-details view exists yet.
                    onTap: () {},
                  ),
                  const SizedBox(width: 6),
                  RowActionButton(
                    icon: Icons.edit_outlined,
                    color: AppColors.primaryOrange,
                    bg: AppColors.primaryOrange.withValues(alpha: 0.10),
                    onTap: () => Get.dialog(AddProductDialog(product: product)),
                  ),
                  const SizedBox(width: 6),
                  RowActionButton(
                    icon: Icons.copy_outlined,
                    color: const Color(0xFF3B82F6),
                    bg: const Color(0xFF3B82F6).withValues(alpha: 0.10),
                    onTap: () {},
                  ),
                  const SizedBox(width: 6),
                  RowActionButton(
                    icon: Icons.delete_outline_rounded,
                    iconSize: 18,
                    color: colors.error,
                    // Neutral, not red-tinted — only the icon carries the
                    // warning color.
                    bg: colors.tagBg,
                    onTap: () => Get.dialog(
                      _DeleteConfirmDialog(
                        productName: product.name,
                        onConfirm: () {
                          controller.deleteProduct(product.id);
                          Get.back();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _PageButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _PageButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.border),
          color: enabled ? colors.surface : colors.background,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? colors.textPrimary : colors.textHint,
        ),
      ),
    );
  }
}

// ── Delete Confirm Dialog ─────────────────────────────────────────────────────
class _DeleteConfirmDialog extends StatelessWidget {
  final String productName;
  final VoidCallback onConfirm;

  const _DeleteConfirmDialog({
    required this.productName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460, minWidth: 360),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 36,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: colors.error,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Delete Product?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: Get.back,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors.comingSoonBadge,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Divider(height: 1, color: colors.divider),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                            fontFamily: 'Poppins',
                            height: 1.55,
                          ),
                          children: [
                            const TextSpan(
                              text:
                                  'Are you sure you want to permanently delete ',
                            ),
                            TextSpan(
                              text: '"$productName"',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const TextSpan(
                              text: '? This action cannot be undone.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: Get.back,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colors.border),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: onConfirm,
                            icon: const Icon(
                              Icons.delete_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            label: const Text(
                              'Yes, Delete',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.error,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

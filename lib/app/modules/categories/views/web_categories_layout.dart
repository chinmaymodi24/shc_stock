import 'package:shc_stock/app/core/session/app_modules.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/categories/controllers/categories_controller.dart';
import 'package:shc_stock/app/shared/widgets/async_button.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/modules/categories/export/categories_export.dart';
import 'package:shc_stock/app/shared/widgets/export/export_menu_button.dart';
import 'package:shc_stock/app/shared/widgets/export/list_scope_bar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/modules/categories/models/category_model.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/row_action_button.dart';

part 'web_categories_layout_part1.dart';

ProductsController _productsController() {
  if (Get.isRegistered<ProductsController>()) {
    return Get.find<ProductsController>();
  }
  return Get.put(ProductsController(), permanent: true);
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Widget — sidebar list of categories + right-side detail panel
// ─────────────────────────────────────────────────────────────────────────────
class WebCategoriesLayout extends GetView<CategoriesController> {
  const WebCategoriesLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final products = _productsController();
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
                  child: Obx(() {
                    // The loader used to replace the entire page — header,
                    // summary cards and all — so every fetch (including the
                    // refetch after an add or delete) blanked the screen. The
                    // shell now stays put and only the tree area loads.
                    final loading = c.isLoading.value && c.categories.isEmpty;
                    final all = c.categories;
                    final visible = c.visibleCategories;
                    // Falls back to the first category when nothing (or a deleted
                    // category) is selected — never mutates state during build.
                    final selected = all.isEmpty
                        ? null
                        : all.firstWhere(
                            (x) => x.id == c.selectedCatId.value,
                            orElse: () => all.first,
                          );

                    int productCountFor(String categoryName) => products
                        .products
                        .where((p) => p.categoryName == categoryName)
                        .length;
                    int subProductCountFor(
                      String categoryName,
                      String subCategory,
                    ) => products.products
                        .where(
                          (p) =>
                              p.categoryName == categoryName &&
                              p.subCategory == subCategory,
                        )
                        .length;

                    final largest = all.isEmpty
                        ? null
                        : all.reduce(
                            (a, b) =>
                                a.subProducts.length >= b.subProducts.length
                                ? a
                                : b,
                          );

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Page Header ──────────────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Categories',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                      fontFamily: brandFontFamily,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${c.totalCategories} categories',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.textSecondary,
                                      fontFamily: brandFontFamily,
                                    ),
                                  ),
                                ],
                              ),
                              if (canWriteModule('Categories'))
                                ElevatedButton.icon(
                                  onPressed: () => _showAddCategoryDialog(c),
                                  icon: const Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Add Category',
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        appColors.radius,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Stat Cards ───────────────────────────────────────────
                          if (canSeeSummary('Categories')) ...[
                            AppStatCardRow(
                              cards: [
                                AppStatCard(
                                  label: 'Categories',
                                  value:
                                      '${c.stats.value.intOf('totalCategories')}',
                                  icon: Icons.category_outlined,
                                  iconColor: AppColors.primaryOrange,
                                ),
                                AppStatCard(
                                  label: 'Subcategories',
                                  value:
                                      '${c.stats.value.intOf('totalSubCategories')}',
                                  icon: Icons.account_tree_outlined,
                                  iconColor: context.appColors.accent,
                                ),
                                AppStatCard(
                                  label: 'Largest',
                                  value: largest?.name ?? '—',
                                  icon: Icons.star_border_rounded,
                                  iconColor: colors.textSecondary,
                                  smallValue: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],

                          // ── Search ────────────────────────────────────────────────
                          if (!loading && all.isNotEmpty) ...[
                            FilterBar(
                              search: FilterSearchField(
                                controller: c.searchCtrl,
                                hint: 'Search categories...',
                                onChanged: (v) => c.searchQuery.value = v,
                              ),
                              clearAll: c.hasActiveFilters
                                  ? ClearAllButton(onTap: c.resetFilters)
                                  : null,
                              trailing: ExportMenuButton(
                                source: categoriesExportConfig(c),
                              ),
                            ),
                            ListScopeBar(
                              chips: [
                                if (c.searchQuery.value.isNotEmpty)
                                  ListScopeChip(
                                    'Search: "${c.searchQuery.value}"',
                                    c.resetFilters,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── Sidebar + Detail Panel ────────────────────────────────
                          if (loading)
                            const AppLoadingIndicator(
                              label: 'Loading categories...',
                              padding: 96,
                            )
                          else if (all.isEmpty)
                            _EmptyState(
                              colors: colors,
                              onAdd: () => _showAddCategoryDialog(c),
                            )
                          else
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left: category list
                                  SizedBox(
                                    width: 260,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: colors.surface,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: colors.divider,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              14,
                                              12,
                                              8,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'CATEGORIES',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: colors.textHint,
                                                    fontFamily: brandFontFamily,
                                                    letterSpacing: 0.6,
                                                  ),
                                                ),
                                                if (canWriteModule(
                                                  'Categories',
                                                ))
                                                  Tooltip(
                                                    message: 'Add Category',
                                                    child: InkWell(
                                                      onTap: () =>
                                                          _showAddCategoryDialog(
                                                            c,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            7,
                                                          ),
                                                      child: Container(
                                                        width: 22,
                                                        height: 22,
                                                        decoration: BoxDecoration(
                                                          color: AppColors
                                                              .primaryOrange
                                                              .withValues(
                                                                alpha: 0.12,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                7,
                                                              ),
                                                        ),
                                                        child: Icon(
                                                          Icons.add_rounded,
                                                          size: 15,
                                                          color: AppColors
                                                              .primaryOrange,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          ...visible.map(
                                            (cat) => _SidebarCategoryItem(
                                              name: cat.name,
                                              count: cat.subProducts.length,
                                              selected:
                                                  cat.id ==
                                                  c.selectedCatId.value,
                                              colors: colors,
                                              onTap: () =>
                                                  c.selectedCatId.value =
                                                      cat.id,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Right: detail panel for selected category
                                  Expanded(
                                    child: selected == null
                                        ? const SizedBox.shrink()
                                        : _CategoryDetailPanel(
                                            cat: selected,
                                            globalIndex: all.indexOf(selected),
                                            skuCount: productCountFor(
                                              selected.name,
                                            ),
                                            subSkuCount: subProductCountFor,
                                            colors: colors,
                                            onEditCategory: () =>
                                                _showEditDialog(c, selected),
                                            onDeleteCategory: () =>
                                                _confirmDeleteCategory(
                                                  context,
                                                  c,
                                                  selected,
                                                ),
                                            onAddSub: () => _showAddSubDialog(
                                              c,
                                              selected.id,
                                              selected.name,
                                            ),
                                            onEditSub: (si) =>
                                                _showEditSubDialog(
                                                  c,
                                                  selected,
                                                  si,
                                                ),
                                            onDeleteSub: (si) =>
                                                _confirmDeleteSub(
                                                  context,
                                                  c,
                                                  selected,
                                                  si,
                                                ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showAddCategoryDialog(CategoriesController c) {
    if (!requireWrite('Categories')) return;
    Get.dialog(
      _SimpleFormDialog(
        title: 'Add Category',
        onSave: (name) async {
          if (await c.addCategory(name)) Get.back();
        },
      ),
    );
  }

  void _showEditDialog(CategoriesController c, CategoryModel cat) {
    if (!requireWrite('Categories')) return;
    Get.dialog(
      _SimpleFormDialog(
        title: 'Edit Category',
        initialName: cat.name,
        onSave: (name) async {
          // The simplified dialog only edits the name — pass the existing
          // description through untouched so the API PUT doesn't blank it.
          if (await c.updateCategory(cat.id, name, desc: cat.description)) {
            Get.back();
          }
        },
      ),
    );
  }

  void _showEditSubDialog(
    CategoriesController c,
    CategoryModel cat,
    int subIdx,
  ) {
    if (!requireWrite('Categories')) return;
    final currentDesc = subIdx < cat.subDescriptions.length
        ? cat.subDescriptions[subIdx]
        : '';
    Get.dialog(
      _SimpleFormDialog(
        title: 'Edit Subcategory',
        initialName: cat.subProducts[subIdx],
        onSave: (name) async {
          if (await c.updateSubCategory(
            cat.id,
            subIdx,
            name,
            desc: currentDesc,
          )) {
            Get.back();
          }
        },
      ),
    );
  }

  void _showAddSubDialog(CategoriesController c, String catId, String catName) {
    if (!requireWrite('Categories')) return;
    Get.dialog(
      _SimpleFormDialog(
        title: 'Add Subcategory',
        onSave: (name) async {
          if (await c.addSubCategory(catId, name)) Get.back();
        },
      ),
    );
  }

  void _confirmDeleteCategory(
    BuildContext context,
    CategoriesController c,
    CategoryModel cat,
  ) {
    if (!requireWrite('Categories')) return;
    _confirmDelete(
      context,
      title: 'Delete Category?',
      message:
          'Are you sure you want to permanently delete "${cat.name}"? '
          'This will also delete all ${cat.subProducts.length} sub-categories. '
          'This action cannot be undone.',
      onConfirm: () async {
        if (cat.id == c.selectedCatId.value) c.selectedCatId.value = null;
        await c.deleteCategory(cat.id);
      },
    );
  }

  void _confirmDeleteSub(
    BuildContext context,
    CategoriesController c,
    CategoryModel cat,
    int subIdx,
  ) {
    if (!requireWrite('Categories')) return;
    final subName = cat.subProducts[subIdx];
    _confirmDelete(
      context,
      title: 'Delete Sub-Category?',
      message:
          'Are you sure you want to permanently delete "$subName"? This action cannot be undone.',
      onConfirm: () => c.deleteSubCategory(cat.id, subIdx),
    );
  }

  void _confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    final colors = context.appColors;
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              appColors.radius,
                            ),
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: colors.error,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              fontFamily: brandFontFamily,
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
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: colors.textSecondary,
                        fontFamily: brandFontFamily,
                        height: 1.5,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: Get.back,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.border),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: brandFontFamily,
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            onConfirm();
                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.error,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              fontFamily: brandFontFamily,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

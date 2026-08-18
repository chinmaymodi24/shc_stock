import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/categories/controllers/categories_controller.dart';
import 'package:shc_stock/app/shared/widgets/async_button.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/modules/categories/models/category_model.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/row_action_button.dart';

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
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${c.totalCategories} categories',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.textSecondary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showAddCategoryDialog(c),
                                icon: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Add Category',
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Stat Cards ───────────────────────────────────────────
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: AppStatCard(
                                    label: 'Categories',
                                    value:
                                        '${c.stats.value.intOf('totalCategories')}',
                                    icon: Icons.category_outlined,
                                    iconColor: AppColors.primaryOrange,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppStatCard(
                                    label: 'Subcategories',
                                    value:
                                        '${c.stats.value.intOf('totalSubCategories')}',
                                    icon: Icons.account_tree_outlined,
                                    iconColor: context.appColors.accent,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppStatCard(
                                    label: 'Largest',
                                    value: largest?.name ?? '—',
                                    icon: Icons.star_border_rounded,
                                    iconColor: colors.textSecondary,
                                    smallValue: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

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
                                                    fontFamily: 'Poppins',
                                                    letterSpacing: 0.6,
                                                  ),
                                                ),
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
                                                      child: const Icon(
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
    Get.dialog(
      _SimpleFormDialog(
        title: 'Add Category',
        onSave: (name) async {
          await c.addCategory(name);
          Get.back();
        },
      ),
    );
  }

  void _showEditDialog(CategoriesController c, CategoryModel cat) {
    Get.dialog(
      _SimpleFormDialog(
        title: 'Edit Category',
        initialName: cat.name,
        onSave: (name) async {
          // The simplified dialog only edits the name — pass the existing
          // description through untouched so the API PUT doesn't blank it.
          await c.updateCategory(cat.id, name, desc: cat.description);
          Get.back();
        },
      ),
    );
  }

  void _showEditSubDialog(
    CategoriesController c,
    CategoryModel cat,
    int subIdx,
  ) {
    final currentDesc = subIdx < cat.subDescriptions.length
        ? cat.subDescriptions[subIdx]
        : '';
    Get.dialog(
      _SimpleFormDialog(
        title: 'Edit Subcategory',
        initialName: cat.subProducts[subIdx],
        onSave: (name) async {
          await c.updateSubCategory(cat.id, subIdx, name, desc: currentDesc);
          Get.back();
        },
      ),
    );
  }

  void _showAddSubDialog(CategoriesController c, String catId, String catName) {
    Get.dialog(
      _SimpleFormDialog(
        title: 'Add Subcategory',
        onSave: (name) async {
          await c.addSubCategory(catId, name);
          Get.back();
        },
      ),
    );
  }

  void _confirmDeleteCategory(
    BuildContext context,
    CategoriesController c,
    CategoryModel cat,
  ) {
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
                            borderRadius: BorderRadius.circular(10),
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
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: colors.textSecondary,
                        fontFamily: 'Poppins',
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
                              fontFamily: 'Poppins',
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
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontFamily: 'Poppins',
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

// ─────────────────────────────────────────────────────────────────────────────
// Empty state — no categories yet
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final AppThemeColors colors;
  final VoidCallback onAdd;
  const _EmptyState({required this.colors, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_outlined, size: 40, color: colors.textHint),
          const SizedBox(height: 12),
          Text(
            'No categories yet',
            style: TextStyle(
              fontSize: 14,
              color: colors.textHint,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
            label: const Text(
              'Add Category',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Left sidebar category item
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarCategoryItem extends StatelessWidget {
  final String name;
  final int count;
  final bool selected;
  final AppThemeColors colors;
  final VoidCallback onTap;

  const _SidebarCategoryItem({
    required this.name,
    required this.count,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryOrange.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: selected ? AppColors.primaryOrange : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.primaryOrange
                      : colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12.5,
                color: selected ? AppColors.primaryOrange : colors.textHint,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right detail panel — selected category's subcategories table
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryDetailPanel extends StatelessWidget {
  final CategoryModel cat;
  final int globalIndex;
  final int skuCount;
  final int Function(String categoryName, String subCategory) subSkuCount;
  final AppThemeColors colors;
  final VoidCallback onEditCategory, onDeleteCategory, onAddSub;
  final ValueChanged<int> onEditSub, onDeleteSub;

  const _CategoryDetailPanel({
    required this.cat,
    required this.globalIndex,
    required this.skuCount,
    required this.subSkuCount,
    required this.colors,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onAddSub,
    required this.onEditSub,
    required this.onDeleteSub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${cat.subProducts.length} subcategories · $skuCount SKUs',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                _HeaderActionBtn(
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  bgColor: colors.background.computeLuminance() > 0.5
                      ? const Color(0xFFF3F1EC)
                      : colors.inputFill,
                  fgColor: colors.textPrimary,
                  onTap: onEditCategory,
                ),
                const SizedBox(width: 8),
                _HeaderActionBtn(
                  icon: Icons.delete_rounded,
                  label: 'Delete',
                  bgColor: colors.error.withValues(alpha: 0.12),
                  fgColor: colors.error,
                  onTap: onDeleteCategory,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),

          // Sub-categories label
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Text(
              'SUBCATEGORIES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.textHint,
                fontFamily: 'Poppins',
                letterSpacing: 0.6,
              ),
            ),
          ),

          if (cat.subProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No subcategories yet',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textHint,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            )
          else ...[
            // Table header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Subcategory',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 76,
                    child: Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.divider),
            ...cat.subProducts.asMap().entries.map(
              (e) => _SubCategoryTableRow(
                name: e.value,
                itemCount: subSkuCount(cat.name, e.value),
                colors: colors,
                onEdit: () => onEditSub(e.key),
                onDelete: () => onDeleteSub(e.key),
              ),
            ),
          ],

          // Add subcategory
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: InkWell(
              onTap: onAddSub,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: AppColors.primaryOrange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Add subcategory',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubCategoryTableRow extends StatefulWidget {
  final String name;
  final int itemCount;
  final AppThemeColors colors;
  final VoidCallback onEdit, onDelete;

  const _SubCategoryTableRow({
    required this.name,
    required this.itemCount,
    required this.colors,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SubCategoryTableRow> createState() => _SubCategoryTableRowState();
}

class _SubCategoryTableRowState extends State<_SubCategoryTableRow> {
  // Local, widget-scoped hover flag — kept as an Rx on the persistent State
  // object (not setState) so only the row's background repaints on hover.
  final _hovered = false.obs;

  @override
  void dispose() {
    _hovered.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return MouseRegion(
      onEnter: (_) => _hovered.value = true,
      onExit: (_) => _hovered.value = false,
      child: Obx(
        () => Container(
          color: _hovered.value ? c.rowEven : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  widget.name,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${widget.itemCount}',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: c.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Row(
                  children: [
                    RowActionButton(
                      icon: Icons.edit_outlined,
                      color: AppColors.primaryOrange,
                      bg: AppColors.primaryOrange.withValues(alpha: 0.10),
                      tooltip: 'Edit',
                      onTap: widget.onEdit,
                    ),
                    const SizedBox(width: 6),
                    RowActionButton(
                      icon: Icons.delete_outline_rounded,
                      iconSize: 18,
                      color: c.error,
                      // Neutral, not red-tinted — only the icon carries the
                      // warning color.
                      bg: c.tagBg,
                      tooltip: 'Delete',
                      onTap: widget.onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header Action Button (filled Edit/Delete pill, matches target UI)
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor, fgColor;
  final VoidCallback onTap;
  const _HeaderActionBtn({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.fgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fgColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simple Name-only Form Dialog — used for Add/Edit Category and
// Add/Edit Sub-Category, matching the approved design (single "Name" field,
// Cancel/Save row).
// ─────────────────────────────────────────────────────────────────────────────
class _SimpleFormDialog extends StatefulWidget {
  final String title;
  final String initialName;

  /// Awaited, so the Save button can show its own spinner.
  final Future<void> Function(String) onSave;

  const _SimpleFormDialog({
    required this.title,
    this.initialName = '',
    required this.onSave,
  });

  @override
  State<_SimpleFormDialog> createState() => _SimpleFormDialogState();
}

class _SimpleFormDialogState extends State<_SimpleFormDialog> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) await widget.onSave(name);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                autofocus: true,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
                decoration: InputDecoration(
                  hintText: 'Name…',
                  hintStyle: TextStyle(
                    color: colors.textHint,
                    fontFamily: 'Poppins',
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.border, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.border, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.primaryOrange,
                      width: 1.5,
                    ),
                  ),
                ),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: Get.back,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: colors.background.computeLuminance() > 0.5
                              ? const Color(0xFFF3F1EC)
                              : colors.inputFill,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppAsyncButton(
                      label: 'Save',
                      onPressed: _save,
                      expand: true,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      radius: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

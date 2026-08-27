import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/shared/widgets/async_button.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/app_drawer.dart';
import 'package:shc_stock/app/modules/categories/controllers/categories_controller.dart';
import 'package:shc_stock/app/modules/categories/models/category_model.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';

ProductsController _productsController() {
  if (Get.isRegistered<ProductsController>()) {
    return Get.find<ProductsController>();
  }
  return Get.put(ProductsController(), permanent: true);
}

class MobileCategoriesLayout extends GetView<CategoriesController> {
  const MobileCategoriesLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final c = controller;
    final products = _productsController();

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const AppDrawer(activeRoute: AppRoutes.categories),
      appBar: _buildAppBar(context),
      body: Obx(() {
        // Only the list area loads — the cards above it used to be replaced
        // by the spinner, blanking the page on every fetch.
        final loading = c.isLoading.value && c.categories.isEmpty;
        final all = c.categories;
        final visible = c.visibleCategories;
        final selected = all.isEmpty
            ? null
            : all.firstWhereOrNull((x) => x.id == c.selectedCatId.value);

        int skuCountFor(String categoryName) => products.products
            .where((p) => p.categoryName == categoryName)
            .length;
        int subSkuCountFor(String categoryName, String subCategory) => products
            .products
            .where(
              (p) =>
                  p.categoryName == categoryName &&
                  p.subCategory == subCategory,
            )
            .length;

        final largest = all.isEmpty
            ? null
            : all.reduce(
                (a, b) => a.subProducts.length >= b.subProducts.length ? a : b,
              );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stat Cards ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: AppStatCard(
                      icon: Icons.category_outlined,
                      iconColor: AppColors.primaryOrange,
                      label: 'Categories',
                      value: '${c.totalCategories}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppStatCard(
                      icon: Icons.account_tree_outlined,
                      iconColor: context.appColors.accent,
                      label: 'Subcategories',
                      value: '${c.totalSubCategories}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Largest card ─────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.tagBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.divider),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_border_rounded,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Largest',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            largest?.name ?? '—',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Search — same FilterSearchField the web filter row uses.
              if (!loading && all.isNotEmpty) ...[
                FilterSearchField(
                  controller: c.searchCtrl,
                  hint: 'Search categories...',
                  width: double.infinity,
                  onChanged: (v) => c.searchQuery.value = v,
                ),
                const SizedBox(height: 16),
              ],

              // ── Accordion list — every category is its own card; tapping
              // its header expands it in place (only one open at a time,
              // tracked by the same selectedCatId the web page uses for its
              // sidebar selection) instead of navigating to a full detail
              // page. Matches the approved mobile design.
              if (loading)
                const AppLoadingIndicator(
                  label: 'Loading categories...',
                  padding: 72,
                )
              else if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      all.isEmpty ? 'No categories yet' : 'No categories found',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textHint,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: visible
                      .map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CategoryAccordionCard(
                            cat: cat,
                            skuCount: skuCountFor(cat.name),
                            subSkuCount: subSkuCountFor,
                            expanded: selected?.id == cat.id,
                            colors: colors,
                            onToggle: () => c.selectedCatId.value =
                                selected?.id == cat.id ? null : cat.id,
                            onEditCategory: () => _showEditDialog(c, cat),
                            onDeleteCategory: () =>
                                _confirmDeleteCategory(context, c, cat),
                            onAddSub: () => _showAddSubDialog(c, cat.id),
                            onEditSub: (si) => _showEditSubDialog(c, cat, si),
                            onDeleteSub: (si) =>
                                _confirmDeleteSub(context, c, cat, si),
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        );
      }),
      // Always "Add Category" — each expanded card already carries its own
      // "+ Add subcategory" link, so the FAB doesn't need to branch on
      // whatever's currently expanded.
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(c),
        backgroundColor: AppColors.primaryOrange,
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colors = context.appColors;
    return AppBar(
      backgroundColor: colors.topBarBg,
      elevation: 0,
      centerTitle: true,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.menu_rounded, color: colors.textPrimary, size: 24),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Text(
        'Categories',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
          fontFamily: 'Poppins',
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: colors.divider),
      ),
    );
  }

  void _showAddCategoryDialog(CategoriesController c) {
    final ctrl = TextEditingController();
    Get.dialog(
      _MobileFormDialog(
        title: 'Add New Category',
        hint: 'e.g. Ceramic Fiber Products',
        controller: ctrl,
        onSave: () async {
          await c.addCategory(ctrl.text);
          Get.back();
        },
      ),
    );
  }

  void _showEditDialog(CategoriesController c, CategoryModel cat) {
    final ctrl = TextEditingController(text: cat.name);
    Get.dialog(
      _MobileFormDialog(
        title: 'Edit Category',
        hint: cat.name,
        controller: ctrl,
        onSave: () async {
          await c.updateCategory(cat.id, ctrl.text);
          Get.back();
        },
      ),
    );
  }

  void _showAddSubDialog(CategoriesController c, String catId) {
    final ctrl = TextEditingController();
    Get.dialog(
      _MobileFormDialog(
        title: 'Add Sub-Category',
        hint: 'e.g. Ceramic Fiber Rope',
        controller: ctrl,
        onSave: () async {
          await c.addSubCategory(catId, ctrl.text);
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
    final ctrl = TextEditingController(text: cat.subProducts[subIdx]);
    Get.dialog(
      _MobileFormDialog(
        title: 'Edit Sub-Category',
        hint: cat.subProducts[subIdx],
        controller: ctrl,
        onSave: () async {
          await c.updateSubCategory(cat.id, subIdx, ctrl.text);
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
          'Are you sure you want to delete "${cat.name}"? This will also delete all ${cat.subProducts.length} sub-categories.',
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
      message: 'Are you sure you want to delete "$subName"?',
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
      AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 13.5,
            color: colors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: colors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category accordion card — header (name · counts · edit/delete/chevron)
// always visible; the subcategory list expands in place underneath when
// tapped, instead of navigating to a separate detail page.
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryAccordionCard extends StatelessWidget {
  final CategoryModel cat;
  final int skuCount;
  final int Function(String categoryName, String subCategory) subSkuCount;
  final bool expanded;
  final AppThemeColors colors;
  final VoidCallback onToggle, onEditCategory, onDeleteCategory, onAddSub;
  final ValueChanged<int> onEditSub, onDeleteSub;

  const _CategoryAccordionCard({
    required this.cat,
    required this.skuCount,
    required this.subSkuCount,
    required this.expanded,
    required this.colors,
    required this.onToggle,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onAddSub,
    required this.onEditSub,
    required this.onDeleteSub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${cat.subProducts.length} subcategories · $skuCount items',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  _HeaderIconBtn(
                    icon: Icons.edit_outlined,
                    color: colors.textSecondary,
                    onTap: onEditCategory,
                  ),
                  const SizedBox(width: 6),
                  _HeaderIconBtn(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: onDeleteCategory,
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 1, color: colors.divider),
                  const SizedBox(height: 12),
                  if (cat.subProducts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'No subcategories yet',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textHint,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    )
                  else
                    ...cat.subProducts.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SubCategoryInlineRow(
                          name: e.value,
                          itemCount: subSkuCount(cat.name, e.value),
                          colors: colors,
                          onEdit: () => onEditSub(e.key),
                          onDelete: () => onDeleteSub(e.key),
                        ),
                      ),
                    ),
                  InkWell(
                    onTap: onAddSub,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
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
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subcategory row — plain (no card/border) so a stack of them inside the
// expanded category reads as one list, not a card of cards.
// ─────────────────────────────────────────────────────────────────────────────
class _SubCategoryInlineRow extends StatelessWidget {
  final String name;
  final int itemCount;
  final AppThemeColors colors;
  final VoidCallback onEdit, onDelete;

  const _SubCategoryInlineRow({
    required this.name,
    required this.itemCount,
    required this.colors,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$itemCount items',
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        _HeaderIconBtn(
          icon: Icons.edit_outlined,
          color: colors.textSecondary,
          onTap: onEdit,
        ),
        _HeaderIconBtn(
          icon: Icons.delete_outline_rounded,
          color: const Color(0xFFEF4444),
          onTap: onDelete,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Helpers
// ─────────────────────────────────────────────────────────────────────────────
/// Bare icon button — no background chip — for the small edit/delete taps
/// that sit inline in a header or row rather than standing alone as an
/// action button.
class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _HeaderIconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _MobileFormDialog extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController controller;

  /// Awaited, so the Save button can show its own spinner.
  final Future<void> Function() onSave;

  const _MobileFormDialog({
    required this.title,
    required this.hint,
    required this.controller,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.primaryOrange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: TextStyle(
                fontSize: 14,
                color: colors.textPrimary,
                fontFamily: 'Poppins',
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: colors.textHint,
                  fontFamily: 'Poppins',
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                filled: true,
                fillColor: colors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: AppColors.primaryOrange,
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: (_) => onSave(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: Get.back,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AppAsyncButton(
                  label: 'Save',
                  onPressed: onSave,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  radius: 8,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

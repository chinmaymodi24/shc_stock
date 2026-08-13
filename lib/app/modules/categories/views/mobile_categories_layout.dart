import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/app_drawer.dart';
import 'package:shc_stock/app/modules/categories/controllers/categories_controller.dart';
import 'package:shc_stock/app/modules/categories/models/category_model.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';

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
                      iconColor: const Color(0xFF4A3AFF),
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

              // ── List or Detail ────────────────────────────────
              if (loading)
                const AppLoadingIndicator(
                  label: 'Loading categories...',
                  padding: 72,
                )
              else if (all.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No categories yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textHint,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                )
              else if (selected == null)
                Column(
                  children: all
                      .map(
                        (cat) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CategoryListRow(
                            cat: cat,
                            skuCount: skuCountFor(cat.name),
                            colors: colors,
                            onTap: () => c.selectedCatId.value = cat.id,
                          ),
                        ),
                      )
                      .toList(),
                )
              else
                _CategoryDetail(
                  cat: selected,
                  skuCount: skuCountFor(selected.name),
                  subSkuCount: subSkuCountFor,
                  colors: colors,
                  onBack: () => c.selectedCatId.value = null,
                  onEditCategory: () => _showEditDialog(c, selected),
                  onDeleteCategory: () =>
                      _confirmDeleteCategory(context, c, selected),
                  onAddSub: () => _showAddSubDialog(c, selected.id),
                  onEditSub: (si) => _showEditSubDialog(c, selected, si),
                  onDeleteSub: (si) =>
                      _confirmDeleteSub(context, c, selected, si),
                ),
            ],
          ),
        );
      }),
      floatingActionButton: Obx(() {
        final all = c.categories;
        final selected = all.firstWhereOrNull(
          (x) => x.id == c.selectedCatId.value,
        );
        return FloatingActionButton(
          onPressed: () => selected == null
              ? _showAddCategoryDialog(c)
              : _showAddSubDialog(c, selected.id),
          backgroundColor: AppColors.primaryOrange,
          elevation: 4,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        );
      }),
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
        onSave: () {
          c.addCategory(ctrl.text);
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
        onSave: () {
          c.updateCategory(cat.id, ctrl.text);
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
        onSave: () {
          c.addSubCategory(catId, ctrl.text);
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
        onSave: () {
          c.updateSubCategory(cat.id, subIdx, ctrl.text);
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
      onConfirm: () {
        if (cat.id == c.selectedCatId.value) c.selectedCatId.value = null;
        c.deleteCategory(cat.id);
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
// Category list row
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryListRow extends StatelessWidget {
  final CategoryModel cat;
  final int skuCount;
  final AppThemeColors colors;
  final VoidCallback onTap;

  const _CategoryListRow({
    required this.cat,
    required this.skuCount,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.divider),
        ),
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
                    '${cat.subProducts.length} subcategories · $skuCount SKUs',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category detail view
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryDetail extends StatelessWidget {
  final CategoryModel cat;
  final int skuCount;
  final int Function(String categoryName, String subCategory) subSkuCount;
  final AppThemeColors colors;
  final VoidCallback onBack, onEditCategory, onDeleteCategory, onAddSub;
  final ValueChanged<int> onEditSub, onDeleteSub;

  const _CategoryDetail({
    required this.cat,
    required this.skuCount,
    required this.subSkuCount,
    required this.colors,
    required this.onBack,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onAddSub,
    required this.onEditSub,
    required this.onDeleteSub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onBack,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.primaryOrange,
                size: 20,
              ),
              Text(
                'Categories',
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
        const SizedBox(height: 10),
        Row(
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
              label: 'Edit',
              bgColor: colors.background.computeLuminance() > 0.5
                  ? const Color(0xFFF3F1EC)
                  : colors.inputFill,
              fgColor: colors.textPrimary,
              onTap: onEditCategory,
            ),
            const SizedBox(width: 8),
            _HeaderActionBtn(
              label: 'Delete',
              bgColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
              fgColor: const Color(0xFFEF4444),
              onTap: onDeleteCategory,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'SUBCATEGORIES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors.textHint,
            fontFamily: 'Poppins',
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        if (cat.subProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
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
        else
          ...cat.subProducts.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SubCategoryRow(
                name: e.value,
                itemCount: subSkuCount(cat.name, e.value),
                colors: colors,
                onEdit: () => onEditSub(e.key),
                onDelete: () => onDeleteSub(e.key),
              ),
            ),
          ),
        const SizedBox(height: 6),
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
    );
  }
}

class _SubCategoryRow extends StatelessWidget {
  final String name;
  final int itemCount;
  final AppThemeColors colors;
  final VoidCallback onEdit, onDelete;

  const _SubCategoryRow({
    required this.name,
    required this.itemCount,
    required this.colors,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$itemCount items',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          _MiniBtn(
            icon: Icons.edit_outlined,
            color: AppColors.primaryPurple,
            onTap: onEdit,
          ),
          const SizedBox(width: 6),
          _MiniBtn(
            icon: Icons.delete_outline_rounded,
            color: const Color(0xFFEF4444),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Helpers
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderActionBtn extends StatelessWidget {
  final String label;
  final Color bgColor, fgColor;
  final VoidCallback onTap;
  const _HeaderActionBtn({
    required this.label,
    required this.bgColor,
    required this.fgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
            color: fgColor,
          ),
        ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MiniBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }
}

class _MobileFormDialog extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onSave;

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
                ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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

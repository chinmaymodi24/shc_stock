import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'dart:io' as io;
import '../controllers/categories_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/widgets/web_sidebar.dart';
import '../../dashboard/widgets/web_top_bar.dart';
import '../../products/models/product_model.dart';
import '../../products/controllers/products_controller.dart';

ProductsController _productsController() {
  if (Get.isRegistered<ProductsController>())
    return Get.find<ProductsController>();
  return Get.put(ProductsController());
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
                    final all = c.categories;
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
                                  child: _StatCard(
                                    label: 'Categories',
                                    value: '${c.totalCategories}',
                                    icon: Icons.category_outlined,
                                    iconColor: AppColors.primaryOrange,
                                    bgColor: AppColors.primaryOrange.withValues(
                                      alpha: 0.06,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Subcategories',
                                    value: '${c.totalSubCategories}',
                                    icon: Icons.account_tree_outlined,
                                    iconColor: const Color(0xFF4A3AFF),
                                    bgColor: const Color(
                                      0xFF4A3AFF,
                                    ).withValues(alpha: 0.06),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Largest',
                                    value: largest?.name ?? '—',
                                    icon: Icons.star_border_rounded,
                                    iconColor: colors.textSecondary,
                                    bgColor: colors.textSecondary.withValues(
                                      alpha: 0.06,
                                    ),
                                    isTitleValue: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Sidebar + Detail Panel ────────────────────────────────
                          if (all.isEmpty)
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
                                    width: 240,
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
                                              16,
                                              8,
                                            ),
                                            child: Text(
                                              'CATEGORIES',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: colors.textHint,
                                                fontFamily: 'Poppins',
                                                letterSpacing: 0.6,
                                              ),
                                            ),
                                          ),
                                          ...all.map(
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
      _CategoryFormDialog(
        isSubCategory: false,
        isEdit: false,
        onSave: (name, desc, bytes) {
          c.addCategory(name, desc: desc, imageBytes: bytes);
          Get.back();
        },
      ),
    );
  }

  void _showEditDialog(CategoriesController c, ProductCategory cat) {
    Get.dialog(
      _CategoryFormDialog(
        isSubCategory: false,
        isEdit: true,
        initialName: cat.name,
        initialDesc: cat.description,
        initialImageBytes: cat.imageBytes,
        onSave: (name, desc, bytes) {
          c.updateCategory(cat.id, name, desc: desc, imageBytes: bytes);
          Get.back();
        },
      ),
    );
  }

  void _showEditSubDialog(
    CategoriesController c,
    ProductCategory cat,
    int subIdx,
  ) {
    final currentDesc = subIdx < cat.subDescriptions.length
        ? cat.subDescriptions[subIdx]
        : '';
    Get.dialog(
      _CategoryFormDialog(
        isSubCategory: true,
        isEdit: true,
        parentCategoryName: cat.name,
        initialName: cat.subProducts[subIdx],
        initialDesc: currentDesc,
        onSave: (name, desc, _) {
          c.updateSubCategory(cat.id, subIdx, name, desc: desc);
          Get.back();
        },
      ),
    );
  }

  void _showAddSubDialog(CategoriesController c, String catId, String catName) {
    Get.dialog(
      _CategoryFormDialog(
        isSubCategory: true,
        isEdit: false,
        parentCategoryName: catName,
        onSave: (name, desc, _) {
          c.addSubCategory(catId, name, desc: desc);
          Get.back();
        },
      ),
    );
  }

  void _confirmDeleteCategory(
    BuildContext context,
    CategoriesController c,
    ProductCategory cat,
  ) {
    _confirmDelete(
      context,
      title: 'Delete Category?',
      message:
          'Are you sure you want to permanently delete "${cat.name}"? '
          'This will also delete all ${cat.subProducts.length} sub-categories. '
          'This action cannot be undone.',
      onConfirm: () {
        if (cat.id == c.selectedCatId.value) c.selectedCatId.value = null;
        c.deleteCategory(cat.id);
      },
    );
  }

  void _confirmDeleteSub(
    BuildContext context,
    CategoriesController c,
    ProductCategory cat,
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
  final ProductCategory cat;
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
                width: 76,
                child: Row(
                  children: [
                    _ActionBtn(
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF4A3AFF),
                      tooltip: 'Edit',
                      onTap: widget.onEdit,
                    ),
                    const SizedBox(width: 6),
                    _ActionBtn(
                      icon: Icons.delete_outline_rounded,
                      color: const Color(0xFFEF4444),
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
// Stat Card
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final bool isTitleValue;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.isTitleValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isTitleValue ? 16 : 24,
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
// Action Button
// ─────────────────────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unified Category Form Dialog
// Handles: Add Category, Edit Category, Add Sub-Category, Edit Sub-Category
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryFormDialog extends StatefulWidget {
  final bool isSubCategory;
  final bool isEdit;
  final String? parentCategoryName;
  final String initialName;
  final String initialDesc;
  final Uint8List? initialImageBytes;

  /// Called with (name, description, imageBytes) when the user taps Save.
  final void Function(String name, String desc, Uint8List? imageBytes) onSave;

  const _CategoryFormDialog({
    required this.isSubCategory,
    required this.isEdit,
    this.parentCategoryName,
    this.initialName = '',
    this.initialDesc = '',
    this.initialImageBytes,
    required this.onSave,
  });

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  // Dialog-local reactive fields — kept as Rx on the persistent State object
  // (not setState) so only the parts that depend on them repaint.
  late final RxBool _isActive;
  late final RxInt _descLen;
  final _isDragOver = false.obs;
  late final Rx<Uint8List?> _pickedImageBytes;
  final _pickedImageName = ''.obs;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _descCtrl = TextEditingController(text: widget.initialDesc);
    _isActive = true.obs;
    _descLen = _descCtrl.text.length.obs;
    _pickedImageBytes = Rx<Uint8List?>(widget.initialImageBytes);
    _descCtrl.addListener(() => _descLen.value = _descCtrl.text.length);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _isActive.close();
    _descLen.close();
    _isDragOver.close();
    _pickedImageBytes.close();
    _pickedImageName.close();
    super.dispose();
  }

  String get _title {
    if (widget.isEdit) {
      return widget.isSubCategory ? 'Edit Sub-Category' : 'Edit Category';
    }
    return widget.isSubCategory ? 'Add Sub-Category' : 'Add Category';
  }

  String get _saveLabel {
    if (widget.isEdit) {
      return widget.isSubCategory ? 'Update Sub-Category' : 'Update Category';
    }
    return widget.isSubCategory ? 'Save Sub-Category' : 'Save Category';
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // always get bytes (works on web + desktop)
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    Uint8List? bytes = f.bytes;
    if (bytes == null && f.path != null) {
      bytes = await io.File(f.path!).readAsBytes();
    }
    if (bytes != null) {
      _pickedImageBytes.value = bytes;
      _pickedImageName.value = f.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSub = widget.isSubCategory;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 22, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isSub &&
                                widget.parentCategoryName != null &&
                                !widget.isEdit) ...[
                              Text(
                                'Add a new sub-category under',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.parentCategoryName!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ] else
                              Text(
                                widget.isEdit
                                    ? 'Update the ${isSub ? "sub-" : ""}category details.'
                                    : 'Create a new product ${isSub ? "sub-" : ""}category.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
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
                Divider(height: 1, color: colors.divider),

                // ── Body ────────────────────────────────────────────────────
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      _DlgLabel(
                        isSub ? 'Sub-Category Name' : 'Category Name',
                        required: true,
                        colors: colors,
                      ),
                      const SizedBox(height: 6),
                      _DlgTF(
                        ctrl: _nameCtrl,
                        hint: isSub
                            ? 'Enter sub-category name'
                            : 'Enter category name',
                        autofocus: true,
                        colors: colors,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      _DlgLabel('Description (optional)', colors: colors),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _descCtrl,
                        maxLines: 3,
                        maxLength: 250,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: colors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter description',
                          hintStyle: TextStyle(
                            color: colors.textHint,
                            fontFamily: 'Poppins',
                            fontSize: 13.5,
                          ),
                          filled: true,
                          fillColor: colors.inputFill,
                          counterText: '',
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primaryOrange,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      Obx(
                        () => Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_descLen.value}/250',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colors.textHint,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Image upload zone
                      _DlgLabel(
                        isSub
                            ? 'Sub-Category Image (optional)'
                            : 'Category Image (optional)',
                        colors: colors,
                      ),
                      const SizedBox(height: 8),

                      // If an image has been picked, show preview + clear button
                      Obx(() {
                        final pickedBytes = _pickedImageBytes.value;
                        if (pickedBytes != null) {
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primaryOrange.withValues(
                                  alpha: 0.40,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(10),
                              color: colors.inputFill,
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    pickedBytes,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _pickedImageName.value.isNotEmpty
                                            ? _pickedImageName.value
                                            : 'Existing image',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colors.textPrimary,
                                          fontFamily: 'Poppins',
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Image selected',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primaryOrange,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    _pickedImageBytes.value = null;
                                    _pickedImageName.value = '';
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFEF4444,
                                      ).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Color(0xFFEF4444),
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        // Drag & Drop + click-to-browse zone
                        final isDragOver = _isDragOver.value;
                        return DropTarget(
                          onDragEntered: (_) => _isDragOver.value = true,
                          onDragExited: (_) => _isDragOver.value = false,
                          onDragDone: (detail) async {
                            _isDragOver.value = false;
                            if (detail.files.isNotEmpty) {
                              final bytes = await detail.files.first
                                  .readAsBytes();
                              final name = detail.files.first.name;
                              _pickedImageBytes.value = bytes;
                              _pickedImageName.value = name;
                            }
                          },
                          child: InkWell(
                            onTap: _pickImage,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: double.infinity,
                              height: 118,
                              decoration: BoxDecoration(
                                color: isDragOver
                                    ? AppColors.primaryOrange.withValues(
                                        alpha: 0.06,
                                      )
                                    : colors.inputFill,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDragOver
                                      ? AppColors.primaryOrange
                                      : colors.border,
                                  width: isDragOver ? 1.8 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryOrange.withValues(
                                        alpha: isDragOver ? 0.14 : 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isDragOver
                                          ? Icons.download_rounded
                                          : Icons.cloud_upload_outlined,
                                      size: 24,
                                      color: AppColors.primaryOrange,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text.rich(
                                    TextSpan(
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: colors.textSecondary,
                                        fontFamily: 'Poppins',
                                        height: 1.5,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: isDragOver
                                              ? 'Release to upload'
                                              : 'Drag & drop an image here\n',
                                          style: isDragOver
                                              ? const TextStyle(
                                                  color:
                                                      AppColors.primaryOrange,
                                                  fontWeight: FontWeight.w600,
                                                )
                                              : null,
                                        ),
                                        if (!isDragOver)
                                          TextSpan(
                                            text: 'or click to ',
                                            style: TextStyle(
                                              color: colors.textHint,
                                            ),
                                          ),
                                        if (!isDragOver)
                                          const TextSpan(
                                            text: 'browse',
                                            style: TextStyle(
                                              color: AppColors.primaryOrange,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 6),
                      Text(
                        'Allowed formats: JPG, PNG, WEBP (Max 2MB)',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colors.textHint,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status
                      _DlgLabel('Status', colors: colors),
                      const SizedBox(height: 8),
                      Obx(
                        () => Row(
                          children: [
                            Switch(
                              value: _isActive.value,
                              onChanged: (v) => _isActive.value = v,
                              activeColor: AppColors.primaryOrange,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isActive.value ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: colors.textPrimary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: colors.divider),

                // ── Footer ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
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
                            color: colors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          final name = _nameCtrl.text.trim();
                          if (name.isNotEmpty) {
                            widget.onSave(
                              name,
                              _descCtrl.text.trim(),
                              _pickedImageBytes.value,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
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
                          _saveLabel,
                          style: const TextStyle(
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared dialog label + text-field helpers
// ─────────────────────────────────────────────────────────────────────────────
class _DlgLabel extends StatelessWidget {
  final String label;
  final bool required;
  final AppThemeColors colors;
  const _DlgLabel(this.label, {this.required = false, required this.colors});
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFEF4444), fontSize: 13),
            ),
        ],
      ),
    );
  }
}

class _DlgTF extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool autofocus;
  final AppThemeColors colors;
  const _DlgTF({
    required this.ctrl,
    required this.hint,
    this.autofocus = false,
    required this.colors,
  });
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      autofocus: autofocus,
      style: TextStyle(
        fontSize: 13.5,
        color: colors.textPrimary,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: colors.textHint,
          fontFamily: 'Poppins',
          fontSize: 13.5,
        ),
        filled: true,
        fillColor: colors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primaryOrange,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

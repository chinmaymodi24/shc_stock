import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../dashboard/widgets/app_drawer.dart';
import '../controllers/categories_controller.dart';
import '../../products/models/product_model.dart';

class MobileCategoriesLayout extends StatefulWidget {
  const MobileCategoriesLayout({super.key});

  @override
  State<MobileCategoriesLayout> createState() => _MobileCategoriesLayoutState();
}

class _MobileCategoriesLayoutState extends State<MobileCategoriesLayout> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final c = Get.find<CategoriesController>();

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const AppDrawer(activeRoute: AppRoutes.categories),
      appBar: _buildAppBar(context),
      body: Obx(() {
        final filtered = _searchQuery.isEmpty
            ? c.categories
            : c.categories
                .where((cat) =>
                    cat.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();

        return CustomScrollView(
          slivers: [
            // ── Stat Cards ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.grid_view_rounded,
                            iconColor: AppColors.primaryOrange,
                            iconBg: AppColors.primaryOrange.withValues(alpha: 0.12),
                            label: 'Total Categories',
                            value: '${c.totalCategories}',
                            trend: '+16.7%',
                            trendUp: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.account_tree_rounded,
                            iconColor: const Color(0xFF4A3AFF),
                            iconBg: const Color(0xFF4A3AFF).withValues(alpha: 0.12),
                            label: 'Sub-Categories',
                            value: '${c.totalSubCategories}',
                            trend: '+8.3%',
                            trendUp: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.warning_amber_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            iconBg: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            label: 'Low Stock Items',
                            value: '2',
                            trend: '-33.3%',
                            trendUp: false,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.currency_rupee_rounded,
                            iconColor: const Color(0xFF22C55E),
                            iconBg: const Color(0xFF22C55E).withValues(alpha: 0.12),
                            label: 'Total Sales (MTD)',
                            value: '₹25,43,000',
                            trend: '+12.5%',
                            trendUp: true,
                            smallValue: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Search Bar ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search categories...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: colors.textHint,
                              fontFamily: 'Poppins',
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: colors.textHint,
                              size: 18,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: colors.textHint,
                                      size: 16,
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Filter button
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: colors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Section Header ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Categories',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      'Showing ${filtered.length} of ${c.categories.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Category List ───────────────────────────────────
            filtered.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: colors.textHint,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No categories found',
                            style: TextStyle(
                              fontSize: 14,
                              color: colors.textHint,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MobileCategoryCard(
                            cat: filtered[i],
                            index: c.categories.indexOf(filtered[i]),
                            controller: c,
                          ),
                        ),
                        childCount: filtered.length,
                      ),
                    ),
                  ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(Get.find<CategoriesController>()),
        backgroundColor: AppColors.primaryOrange,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Category',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            'Manage product categories',
            style: TextStyle(
              fontSize: 11,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: colors.divider),
      ),
    );
  }

  void _showAddDialog(CategoriesController c) {
    final ctrl = TextEditingController();
    Get.dialog(_MobileFormDialog(
      title: 'Add New Category',
      hint: 'e.g. Ceramic Fiber Products',
      controller: ctrl,
      onSave: () {
        c.addCategory(ctrl.text);
        Get.back();
      },
    ));
  }
}

// ── Stat Card ─────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String trend;
  final bool trendUp;
  final bool smallValue;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.trend,
    required this.trendUp,
    this.smallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: trendUp
                      ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                      : const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendUp
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 9,
                      color: trendUp
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend.replaceAll('+', '').replaceAll('-', ''),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: trendUp
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: smallValue ? 14 : 22,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${trendUp ? "+" : ""}$trend from last month',
            style: TextStyle(
              fontSize: 9,
              color: colors.textHint,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Card ─────────────────────────────────────────────
class _MobileCategoryCard extends StatefulWidget {
  final ProductCategory cat;
  final int index;
  final CategoriesController controller;

  const _MobileCategoryCard({
    required this.cat,
    required this.index,
    required this.controller,
  });

  @override
  State<_MobileCategoryCard> createState() => _MobileCategoryCardState();
}

class _MobileCategoryCardState extends State<_MobileCategoryCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  // Category icon list
  static const _icons = [
    Icons.layers_rounded,
    Icons.texture_rounded,
    Icons.view_module_rounded,
    Icons.local_fire_department_rounded,
    Icons.science_rounded,
    Icons.shield_rounded,
    Icons.build_rounded,
  ];

  IconData get _catIcon => _icons[widget.index % _icons.length];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final cat = widget.cat;
    final c = widget.controller;
    final num = widget.index + 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? AppColors.primaryOrange.withValues(alpha: 0.3)
              : colors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: _expanded
                ? AppColors.primaryOrange.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: _expanded ? 12 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  // Index badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Text(
                        '$num',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryOrange,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Category icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A3AFF).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(_catIcon,
                        color: const Color(0xFF4A3AFF), size: 18),
                  ),
                  const SizedBox(width: 10),
                  // Name + sub count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            // Sub-category count badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A3AFF)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${cat.subProducts.length} sub',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A3AFF),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Status
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF22C55E),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  _MiniBtn(
                    icon: Icons.add_rounded,
                    color: const Color(0xFF22C55E),
                    onTap: () {
                      _showAddSubDialog(c, cat.id);
                      setState(() => _expanded = true);
                    },
                  ),
                  const SizedBox(width: 5),
                  _MiniBtn(
                    icon: Icons.edit_outlined,
                    color: AppColors.primaryPurple,
                    onTap: () => _showEditDialog(c, cat),
                  ),
                  const SizedBox(width: 5),
                  _MiniBtn(
                    icon: Icons.delete_outline_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: () => _confirmDelete(c, cat),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Sub-categories ───────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? Container(
                    decoration: BoxDecoration(
                      color: colors.rowEven,
                      border: Border(
                          top: BorderSide(color: colors.divider, width: 1)),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(14)),
                    ),
                    child: cat.subProducts.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'No sub-categories yet. Tap + to add one.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textHint,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: cat.subProducts
                                .asMap()
                                .entries
                                .map((e) => _SubRow(
                                      name: e.value,
                                      index: e.key,
                                      categoryId: cat.id,
                                      controller: c,
                                      isLast:
                                          e.key == cat.subProducts.length - 1,
                                    ))
                                .toList(),
                          ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _showAddSubDialog(CategoriesController c, String catId) {
    final ctrl = TextEditingController();
    Get.dialog(_MobileFormDialog(
      title: 'Add Sub-Category',
      hint: 'e.g. Ceramic Fiber Rope',
      controller: ctrl,
      onSave: () {
        c.addSubCategory(catId, ctrl.text);
        Get.back();
      },
    ));
  }

  void _showEditDialog(CategoriesController c, ProductCategory cat) {
    final ctrl = TextEditingController(text: cat.name);
    Get.dialog(_MobileFormDialog(
      title: 'Edit Category',
      hint: cat.name,
      controller: ctrl,
      onSave: () {
        c.updateCategory(cat.id, ctrl.text);
        Get.back();
      },
    ));
  }

  void _confirmDelete(CategoriesController c, ProductCategory cat) {
    Get.dialog(AlertDialog(
      backgroundColor: context.appColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Delete Category?',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
          color: context.appColors.textPrimary,
        ),
      ),
      content: Text(
        'Are you sure you want to delete "${cat.name}"? This will also delete all ${cat.subProducts.length} sub-categories.',
        style: TextStyle(
          fontSize: 13.5,
          color: context.appColors.textSecondary,
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
                color: context.appColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            c.deleteCategory(cat.id);
            Get.back();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text(
            'Delete',
            style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
          ),
        ),
      ],
    ));
  }
}

// ── Sub-category Row ──────────────────────────────────────────
class _SubRow extends StatelessWidget {
  final String name;
  final int index;
  final String categoryId;
  final CategoriesController controller;
  final bool isLast;

  const _SubRow({
    required this.name,
    required this.index,
    required this.categoryId,
    required this.controller,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colors.divider, width: 0.8)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12.5,
                color: colors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          _MiniBtn(
            icon: Icons.edit_outlined,
            color: AppColors.primaryPurple,
            onTap: () {
              final ctrl = TextEditingController(text: name);
              Get.dialog(_MobileFormDialog(
                title: 'Edit Sub-Category',
                hint: name,
                controller: ctrl,
                onSave: () {
                  controller.updateSubCategory(categoryId, index, ctrl.text);
                  Get.back();
                },
              ));
            },
          ),
          const SizedBox(width: 6),
          _MiniBtn(
            icon: Icons.delete_outline_rounded,
            color: const Color(0xFFEF4444),
            onTap: () => Get.dialog(
              AlertDialog(
                backgroundColor: colors.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Text(
                  'Delete Sub-Category?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: colors.textPrimary,
                  ),
                ),
                content: Text(
                  'Are you sure you want to delete "$name"?',
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
                          fontFamily: 'Poppins', color: colors.textSecondary),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      controller.deleteSubCategory(categoryId, index);
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Delete',
                      style:
                          TextStyle(fontFamily: 'Poppins', color: Colors.white),
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

// ── Shared Helpers ────────────────────────────────────────────
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
    return GestureDetector(
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
                  child: const Icon(Icons.edit_note_rounded,
                      color: AppColors.primaryOrange, size: 18),
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
                hintStyle:
                    TextStyle(color: colors.textHint, fontFamily: 'Poppins'),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                      color: AppColors.primaryOrange, width: 1.5),
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
                        fontFamily: 'Poppins', color: colors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
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

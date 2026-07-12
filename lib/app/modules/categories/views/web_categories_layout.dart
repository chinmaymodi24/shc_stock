import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../controllers/categories_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/widgets/web_sidebar.dart';
import '../../products/models/product_model.dart';

// ── Column layout constants (header + category row + sub-category row MUST match)
const double _kDragW  = 22.0;  // drag-handle indicator column width
const double _kNumW   = 36.0;  // # badge width
const double _kIconW  = 36.0;  // category icon/image box width
const double _kGapW   = 12.0;  // gap between fixed-width columns
const int    _kNameF  = 26;    // Category / Sub-Category name flex
const int    _kTypeF  = 18;    // Type badge flex
const int    _kProdF  = 10;    // Products count flex (center)
const int    _kStatF  = 13;    // Status badge flex (center)
const int    _kDateF  = 18;    // Created On flex
const int    _kActF   = 11;    // Actions flex

// ── Seed display data ──────────────────────────────────────────────────────
const _kCatDates = [
  '01 May 2024', '02 May 2024', '03 May 2024',
  '03 May 2024', '04 May 2024', '05 May 2024', '05 May 2024',
];

const _kCatProducts = [120, 85, 60, 40, 28, 22, 35];

const _kSubProducts = [
  [45, 32, 28, 15, 12, 9],
  [45, 25, 15],
  [25, 20, 15],
  [15, 12, 8, 5],
  [12, 10, 6],
  [12, 10],
  [8, 7, 6, 5, 5],
];

const _kSubDates = [
  ['01 May 2024','02 May 2024','02 May 2024','03 May 2024','04 May 2024','04 May 2024'],
  ['02 May 2024','02 May 2024','03 May 2024'],
  ['03 May 2024','03 May 2024','04 May 2024'],
  ['03 May 2024','04 May 2024','04 May 2024','05 May 2024'],
  ['04 May 2024','04 May 2024','05 May 2024'],
  ['05 May 2024','05 May 2024'],
  ['05 May 2024','05 May 2024','06 May 2024','06 May 2024','06 May 2024'],
];


// ─────────────────────────────────────────────────────────────────────────────
// Main Widget
// ─────────────────────────────────────────────────────────────────────────────
class WebCategoriesLayout extends StatefulWidget {
  const WebCategoriesLayout({super.key});
  @override
  State<WebCategoriesLayout> createState() => _WebCategoriesLayoutState();
}

class _WebCategoriesLayoutState extends State<WebCategoriesLayout> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _rowsPerPage = 10;
  int _currentPage = 1;

  // First category expanded by default (matches screenshot)
  final Set<String> _expanded = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggle(String id) => setState(() =>
      _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id));

  @override
  Widget build(BuildContext context) {
    final c      = Get.find<CategoriesController>();
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Row(children: [
        const WebSidebar(),
        Expanded(child: Column(children: [
          _WebTopBar(colors: colors),
          Expanded(child: Obx(() {
            final all      = c.categories;
            final filtered = _searchQuery.isEmpty
                ? all.toList()
                : all.where((cat) => cat.name.toLowerCase()
                    .contains(_searchQuery.toLowerCase())).toList();

            final totalPages = filtered.isEmpty ? 1 : (filtered.length / _rowsPerPage).ceil();
            final startIdx   = (_currentPage - 1) * _rowsPerPage;
            final endIdx     = math.min(startIdx + _rowsPerPage, filtered.length);
            final pageItems  = filtered.isEmpty
                ? <ProductCategory>[]
                : filtered.sublist(startIdx, endIdx);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Page Header ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Categories', style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700,
                          color: colors.textPrimary, fontFamily: 'Poppins')),
                        const SizedBox(height: 3),
                        Text('Manage product categories and their sub-categories.',
                          style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Poppins')),
                      ]),
                      ElevatedButton.icon(
                        onPressed: () => _showAddCategoryDialog(c),
                        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        label: const Text('Add Category', style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: Colors.white, fontFamily: 'Poppins')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange, elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                        Expanded(child: _StatCard(
                          label: 'Total Categories',
                          value: '${c.totalCategories}',
                          icon: Icons.grid_view_rounded,
                          iconColor: AppColors.primaryOrange,
                          trend: '+16.7%', trendUp: true,
                          spark: const [0.4, 0.5, 0.3, 0.6, 0.5, 0.7, 0.6],
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _StatCard(
                          label: 'Total Sub-Categories',
                          value: '${c.totalSubCategories}',
                          icon: Icons.account_tree_outlined,
                          iconColor: const Color(0xFF4A3AFF),
                          trend: '+8.3%', trendUp: true,
                          spark: const [0.3, 0.4, 0.5, 0.4, 0.6, 0.55, 0.65],
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _StatCard(
                          label: 'Low Stock Items',
                          value: '2',
                          icon: Icons.warning_amber_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          trend: '-33.3%', trendUp: false,
                          spark: const [0.7, 0.6, 0.55, 0.4, 0.5, 0.35, 0.4],
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _StatCard(
                          label: 'Total Sales (MTD)',
                          value: '₹ 25,43,000',
                          icon: Icons.currency_rupee_rounded,
                          iconColor: const Color(0xFF22C55E),
                          trend: '+12.5%', trendUp: true,
                          spark: const [0.3, 0.35, 0.5, 0.45, 0.6, 0.7, 0.8],
                          smallValue: true,
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Table Card ───────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.divider),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8, offset: const Offset(0, 2),
                      )],
                    ),
                    child: Column(children: [
                      // Toolbar
                      _TableToolbar(
                        colors: colors, searchCtrl: _searchCtrl,
                        onSearch: (v) => setState(() { _searchQuery = v; _currentPage = 1; }),
                      ),
                      Divider(height: 1, color: colors.divider),

                      // Column Header
                      _TableColumnHeader(colors: colors),
                      Divider(height: 1, color: colors.divider),

                      // Rows
                      if (pageItems.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(48),
                          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.search_off_rounded, size: 40, color: colors.textHint),
                            const SizedBox(height: 10),
                            Text('No categories found', style: TextStyle(
                              fontSize: 14, color: colors.textHint, fontFamily: 'Poppins')),
                          ])),
                        )
                      else
                        ReorderableListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          proxyDecorator: (child, _, animation) {
                            return AnimatedBuilder(
                              animation: animation,
                              builder: (ctx, ch) => Material(
                                color: Colors.transparent,
                                elevation: 4 * animation.value,
                                shadowColor: Colors.black26,
                                borderRadius: BorderRadius.circular(12),
                                child: ch,
                              ),
                              child: child,
                            );
                          },
                          onReorder: (oldIdx, newIdx) {
                            if (_searchQuery.isEmpty) {
                              c.reorderCategory(startIdx + oldIdx, startIdx + newIdx);
                            }
                          },
                          children: _buildCategoryBlocks(pageItems, colors, c),
                        ),

                      // Footer
                      Divider(height: 1, color: colors.divider),
                      _TableFooter(
                        total: filtered.length,
                        startDisplay: filtered.isEmpty ? 0 : startIdx + 1,
                        endDisplay: endIdx,
                        currentPage: _currentPage,
                        totalPages: totalPages,
                        rowsPerPage: _rowsPerPage,
                        colors: colors,
                        onPageChanged: (p) => setState(() => _currentPage = p),
                        onRowsChanged: (r) => setState(() { _rowsPerPage = r; _currentPage = 1; }),
                      ),
                    ]),
                  ),
                ],
              ),
            );
          })),
        ])),
      ]),
    );
  }

  // ── Build category blocks (keyed, one per category) for ReorderableListView ─
  List<Widget> _buildCategoryBlocks(
      List<ProductCategory> pageItems, AppThemeColors colors, CategoriesController c) {
    return pageItems.asMap().entries.map((entry) {
      final i      = entry.key;
      final cat    = entry.value;
      final gIdx   = c.categories.indexOf(cat);
      final isExp  = _expanded.contains(cat.id);
      final isLast = i == pageItems.length - 1;

      return KeyedSubtree(
        key: ValueKey(cat.id),
        child: _CatBlock(
          pageIndex: i,
          cat: cat,
          globalIndex: gIdx,
          isExpanded: isExp,
          isLastCat: isLast,
          colors: colors,
          onToggle:   () => _toggle(cat.id),
          onEdit:     () => _showEditDialog(c, cat),
          onDelete:   () => _confirmDelete(c, cat),
          onInfo:     () => _showInfoDialog(cat, gIdx),
          onAddSub:   () => _showAddSubDialog(c, cat.id, cat.name),
          onEditSub:  (si) => _showEditSubDialog(c, cat, si),
          onDeleteSub: (si) { c.deleteSubCategory(cat.id, si); setState(() {}); },
          onInfoSub:  (si) => _showSubInfoDialog(cat, si, gIdx),
          onReorderSub: (oldSi, newSi) => c.reorderSubCategory(cat.id, oldSi, newSi),
        ),
      );
    }).toList();
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showAddCategoryDialog(CategoriesController c) {
    Get.dialog(_CategoryFormDialog(
      isSubCategory: false, isEdit: false,
      onSave: (name, desc, bytes) { c.addCategory(name, desc: desc, imageBytes: bytes); Get.back(); },
    ));
  }

  void _showEditDialog(CategoriesController c, ProductCategory cat) {
    Get.dialog(_CategoryFormDialog(
      isSubCategory: false, isEdit: true,
      initialName: cat.name,
      initialDesc: cat.description,
      initialImageBytes: cat.imageBytes,
      onSave: (name, desc, bytes) { c.updateCategory(cat.id, name, desc: desc, imageBytes: bytes); Get.back(); },
    ));
  }

  void _showEditSubDialog(CategoriesController c, ProductCategory cat, int subIdx) {
    final currentDesc = subIdx < cat.subDescriptions.length
        ? cat.subDescriptions[subIdx] : '';
    Get.dialog(_CategoryFormDialog(
      isSubCategory: true, isEdit: true,
      parentCategoryName: cat.name,
      initialName: cat.subProducts[subIdx],
      initialDesc: currentDesc,
      onSave: (name, desc, _) {
        c.updateSubCategory(cat.id, subIdx, name, desc: desc);
        Get.back();
      },
    ));
  }

  void _showAddSubDialog(CategoriesController c, String catId, String catName) {
    Get.dialog(_CategoryFormDialog(
      isSubCategory: true, isEdit: false,
      parentCategoryName: catName,
      onSave: (name, desc, _) { c.addSubCategory(catId, name, desc: desc); Get.back(); },
    ));
  }

  void _showInfoDialog(ProductCategory cat, int globalIndex) {
    Get.dialog(_CategoryInfoDialog(
      isSubCategory: false,
      name: cat.name,
      description: cat.description,
      subCategories: cat.subProducts,
      globalIndex: globalIndex,
    ));
  }

  void _showSubInfoDialog(ProductCategory cat, int subIdx, int globalIndex) {
    final desc = subIdx < cat.subDescriptions.length
        ? cat.subDescriptions[subIdx] : '';
    Get.dialog(_CategoryInfoDialog(
      isSubCategory: true,
      name: cat.subProducts[subIdx],
      description: desc,
      parentName: cat.name,
      globalIndex: globalIndex,
      subIndex: subIdx,
    ));
  }

  void _confirmDelete(CategoriesController c, ProductCategory cat) {
    final colors = context.appColors;
    Get.dialog(Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 32, offset: const Offset(0, 8))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.delete_outline_rounded, color: colors.error, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('Delete Category?', style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700,
                  color: colors.textPrimary, fontFamily: 'Poppins'))),
                InkWell(
                  onTap: Get.back,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: colors.comingSoonBadge,
                      borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.close_rounded, size: 18, color: colors.textSecondary),
                  ),
                ),
              ]),
            ),
            Padding(padding: const EdgeInsets.only(top: 16),
              child: Divider(height: 1, color: colors.divider)),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Are you sure you want to permanently delete "${cat.name}"? '
                'This will also delete all ${cat.subProducts.length} sub-categories. '
                'This action cannot be undone.',
                style: TextStyle(fontSize: 13.5, color: colors.textSecondary,
                  fontFamily: 'Poppins', height: 1.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(
                  onPressed: Get.back,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: Text('Cancel', style: TextStyle(
                    fontFamily: 'Poppins', color: colors.textSecondary, fontSize: 14)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () { c.deleteCategory(cat.id); Get.back(); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.error, elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Delete', style: TextStyle(
                    fontFamily: 'Poppins', color: Colors.white,
                    fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ]),
            ),
          ]),
        ),
      )),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Block — category row + optional draggable sub-categories
// ─────────────────────────────────────────────────────────────────────────────
class _CatBlock extends StatelessWidget {
  final int pageIndex, globalIndex;
  final ProductCategory cat;
  final bool isExpanded, isLastCat;
  final AppThemeColors colors;
  final VoidCallback onToggle, onEdit, onDelete, onInfo, onAddSub;
  final ValueChanged<int> onEditSub, onDeleteSub, onInfoSub;
  final ReorderCallback onReorderSub;

  const _CatBlock({
    required this.pageIndex, required this.globalIndex,
    required this.cat, required this.isExpanded, required this.isLastCat,
    required this.colors,
    required this.onToggle, required this.onEdit, required this.onDelete,
    required this.onInfo,
    required this.onAddSub, required this.onEditSub, required this.onDeleteSub,
    required this.onInfoSub,
    required this.onReorderSub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Category row — wrapped so the parent ReorderableListView can drag it
        ReorderableDragStartListener(
          index: pageIndex,
          child: _CategoryRow(
            cat: cat, globalIndex: globalIndex,
            isExpanded: isExpanded,
            isLast: !isExpanded && isLastCat,
            colors: colors,
            onToggle: onToggle, onEdit: onEdit, onDelete: onDelete,
            onInfo: onInfo,
          ),
        ),
        // Expanded sub-categories with their own drag & drop
        if (isExpanded) ...[
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            proxyDecorator: (child, _, animation) => AnimatedBuilder(
              animation: animation,
              builder: (ctx, ch) => Material(
                color: Colors.transparent,
                elevation: 3 * animation.value,
                shadowColor: Colors.black12,
                borderRadius: BorderRadius.circular(8),
                child: ch,
              ),
              child: child,
            ),
            onReorder: onReorderSub,
            children: cat.subProducts.asMap().entries.map((e) {
              final si = e.key;
              return KeyedSubtree(
                key: ValueKey('${cat.id}_sub_$si'),
                child: ReorderableDragStartListener(
                  index: si,
                  child: _SubCategoryRow(
                    name: e.value,
                    catIndex: globalIndex, subIndex: si,
                    colors: colors,
                    onEdit:   () => onEditSub(si),
                    onDelete: () => onDeleteSub(si),
                    onInfo:   () => onInfoSub(si),
                  ),
                ),
              );
            }).toList(),
          ),
          _AddSubRow(colors: colors, isLast: isLastCat, onTap: onAddSub),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────
class _WebTopBar extends StatelessWidget {
  final AppThemeColors colors;
  const _WebTopBar({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colors.topBarBg,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(children: [
        Container(
          width: 320, height: 38,
          decoration: BoxDecoration(
            color: colors.inputFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border)),
          child: Row(children: [
            const SizedBox(width: 10),
            Icon(Icons.search_rounded, color: colors.textHint, size: 17),
            const SizedBox(width: 8),
            Expanded(child: Text('Search anything...', style: TextStyle(
              fontSize: 13, color: colors.textHint, fontFamily: 'Poppins'))),
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: colors.divider, borderRadius: BorderRadius.circular(5)),
              child: Text('Ctrl + K', style: TextStyle(
                fontSize: 10, color: colors.textSecondary, fontFamily: 'Poppins')),
            ),
          ]),
        ),
        const Spacer(),
        _TopIconBtn(icon: Icons.notifications_outlined, badge: '3', colors: colors),
        const SizedBox(width: 8),
        _TopIconBtn(icon: Icons.chat_bubble_outline_rounded, badge: '2', colors: colors),
        const SizedBox(width: 8),
        _TopIconBtn(icon: Icons.calendar_today_outlined, colors: colors),
        const SizedBox(width: 14),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
          label: Row(children: const [
            Text('Quick Action', style: TextStyle(
              fontSize: 13, color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
          ]),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange, elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
        const SizedBox(width: 14),
        Container(width: 1, height: 30, color: colors.divider),
        const SizedBox(width: 14),
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15),
          child: const Icon(Icons.person_rounded, color: AppColors.primaryOrange, size: 18),
        ),
        const SizedBox(width: 8),
        Text('Admin', style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: colors.textPrimary, fontFamily: 'Poppins')),
        Icon(Icons.keyboard_arrow_down_rounded, color: colors.textSecondary, size: 18),
      ]),
    );
  }
}

class _TopIconBtn extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final AppThemeColors colors;
  const _TopIconBtn({required this.icon, this.badge, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: colors.inputFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border)),
        child: Icon(icon, color: colors.textSecondary, size: 19),
      ),
      if (badge != null)
        Positioned(top: 0, right: 0,
          child: Container(
            width: 17, height: 17,
            decoration: const BoxDecoration(color: AppColors.primaryOrange, shape: BoxShape.circle),
            child: Center(child: Text(badge!, style: const TextStyle(
              fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Poppins'))),
          )),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value, trend;
  final IconData icon;
  final Color iconColor;
  final bool trendUp, smallValue;
  final List<double> spark;

  const _StatCard({
    required this.label, required this.value, required this.icon,
    required this.iconColor, required this.trend, required this.trendUp,
    required this.spark, this.smallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 12),
              Text(label, style: TextStyle(
                fontSize: 12, color: colors.textSecondary,
                fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(
                fontSize: smallValue ? 18 : 26, fontWeight: FontWeight.w700,
                color: colors.textPrimary, fontFamily: 'Poppins')),
              const SizedBox(height: 6),
              Row(children: [
                Icon(trendUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 11,
                  color: trendUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
                const SizedBox(width: 2),
                Text(trend, style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: trendUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  fontFamily: 'Poppins')),
                const SizedBox(width: 4),
                Flexible(child: Text('from last month', style: TextStyle(
                  fontSize: 11, color: colors.textHint, fontFamily: 'Poppins'),
                  overflow: TextOverflow.ellipsis)),
              ]),
            ],
          )),
          SizedBox(
            width: 64, height: 52,
            child: CustomPaint(painter: _SparklinePainter(points: spark, color: iconColor)),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;
  const _SparklinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final lp = Paint()..color = color..strokeWidth = 2.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final fp = Paint()..color = color.withValues(alpha: 0.10)..style = PaintingStyle.fill;
    final path = Path();
    final fill = Path();
    final stepX = size.width / (points.length - 1);
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - (points[i] * size.height * 0.8) - size.height * 0.05;
      if (i == 0) {
        path.moveTo(x, y); fill.moveTo(0, size.height); fill.lineTo(x, y);
      } else {
        final px = (i - 1) * stepX;
        final py = size.height - (points[i - 1] * size.height * 0.8) - size.height * 0.05;
        final cx = (px + x) / 2;
        path.cubicTo(cx, py, cx, y, x, y);
        fill.cubicTo(cx, py, cx, y, x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();
    canvas.drawPath(fill, fp);
    canvas.drawPath(path, lp);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Table Toolbar — search + Status dropdown + Category dropdown + Filter + grid
// ─────────────────────────────────────────────────────────────────────────────
class _TableToolbar extends StatelessWidget {
  final AppThemeColors colors;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  const _TableToolbar({required this.colors, required this.searchCtrl, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        // Search
        SizedBox(
          width: 270, height: 38,
          child: TextField(
            controller: searchCtrl,
            onChanged: onSearch,
            style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Poppins'),
            decoration: InputDecoration(
              hintText: 'Search categories or sub-categories...',
              hintStyle: TextStyle(fontSize: 13, color: colors.textHint, fontFamily: 'Poppins'),
              prefixIcon: Icon(Icons.search_rounded, color: colors.textHint, size: 17),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              filled: true, fillColor: colors.inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5)),
            ),
          ),
        ),
        const Spacer(),

        // Status dropdown
        _DropdownFilter(label: 'All Status', items: const ['All Status', 'Active', 'Inactive'], colors: colors),
        const SizedBox(width: 8),

        // Category dropdown
        _DropdownFilter(label: 'All Categories', items: const ['All Categories', 'Category', 'Sub-Category'], colors: colors),
        const SizedBox(width: 8),

        // Filter button
        OutlinedButton.icon(
          onPressed: () {},
          icon: Icon(Icons.tune_rounded, size: 15, color: colors.textSecondary),
          label: Text('Filter', style: TextStyle(fontSize: 13, fontFamily: 'Poppins', color: colors.textSecondary)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            side: BorderSide(color: colors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
        const SizedBox(width: 8),

        // Grid icon button
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: colors.inputFill,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.table_chart_outlined, size: 17, color: colors.textSecondary),
        ),
      ]),
    );
  }
}

// Dropdown filter chip
class _DropdownFilter extends StatefulWidget {
  final String label;
  final List<String> items;
  final AppThemeColors colors;
  const _DropdownFilter({required this.label, required this.items, required this.colors});
  @override State<_DropdownFilter> createState() => _DropdownFilterState();
}

class _DropdownFilterState extends State<_DropdownFilter> {
  late String _selected;
  @override void initState() { super.initState(); _selected = widget.label; }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.inputFill,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selected,
          isDense: true,
          style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Poppins'),
          dropdownColor: colors.surface,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: colors.textSecondary),
          items: widget.items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) { if (v != null) setState(() => _selected = v); },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table Column Header
// ─────────────────────────────────────────────────────────────────────────────
class _TableColumnHeader extends StatelessWidget {
  final AppThemeColors colors;
  const _TableColumnHeader({required this.colors});

  TextStyle get _s => TextStyle(
    fontSize: 12.5, fontWeight: FontWeight.w600,
    color: colors.textSecondary, fontFamily: 'Poppins', letterSpacing: 0.1);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        // Drag-handle hint column — matches the drag indicator in rows
        Tooltip(
          message: 'Drag rows to reorder',
          child: SizedBox(width: _kDragW,
            child: Icon(Icons.drag_indicator_rounded,
              size: 15, color: colors.textHint.withValues(alpha: 0.5))),
        ),
        SizedBox(width: _kNumW, child: Text('#', style: _s)),
        const SizedBox(width: _kGapW),
        const SizedBox(width: _kIconW), // icon/image placeholder
        const SizedBox(width: _kGapW),
        Expanded(flex: _kNameF, child: Text('Category / Sub-Category', style: _s)),
        Expanded(flex: _kTypeF, child: Center(child: Text('Type', style: _s))),
        Expanded(flex: _kProdF, child: Center(child: Text('Products', style: _s))),
        Expanded(flex: _kStatF, child: Center(child: Text('Status', style: _s))),
        Expanded(flex: _kDateF, child: Text('Created On', style: _s)),
        Expanded(flex: _kActF, child: Center(child: Text('Actions', style: _s))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Row (expandable)
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryRow extends StatefulWidget {
  final ProductCategory cat;
  final int globalIndex;
  final bool isExpanded, isLast;
  final AppThemeColors colors;
  final VoidCallback onToggle, onEdit, onDelete, onInfo;

  const _CategoryRow({
    required this.cat, required this.globalIndex,
    required this.isExpanded, required this.isLast,
    required this.colors, required this.onToggle,
    required this.onEdit, required this.onDelete, required this.onInfo,
  });

  @override State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c          = widget.colors;
    final cat        = widget.cat;
    final idx        = widget.globalIndex;
    final date       = idx < _kCatDates.length ? _kCatDates[idx] : '01 Jun 2024';
    final products   = idx < _kCatProducts.length ? _kCatProducts[idx] : cat.subProducts.length * 12;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: widget.isExpanded
              ? AppColors.primaryOrange.withValues(alpha: 0.03)
              : (_hovered ? c.rowEven : c.surface),
          border: widget.isLast
              ? null
              : Border(bottom: BorderSide(color: c.divider, width: 0.8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

            // ── Drag handle indicator (makes reorder discoverable) ──────
            MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: SizedBox(
                width: _kDragW,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _hovered ? 0.8 : 0.35,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(Icons.drag_indicator_rounded,
                      size: 18, color: c.textSecondary),
                  ),
                ),
              ),
            ),

            // ── # orange badge ───────────────────────────────────────────
            Container(
              width: _kNumW, height: _kNumW,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(7)),
              child: Center(child: Text('${idx + 1}', style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: AppColors.primaryOrange, fontFamily: 'Poppins'))),
            ),
            const SizedBox(width: _kGapW),

            // ── Category image (user-picked) or initials avatar ──────────
            _buildCategoryAvatar(cat, c),
            const SizedBox(width: _kGapW),

            // Category name + sub-count chip
            Expanded(flex: _kNameF, child: Row(children: [
              Flexible(child: Text(cat.name, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: c.textPrimary, fontFamily: 'Poppins'),
                overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.comingSoonBadge,
                  borderRadius: BorderRadius.circular(20)),
                child: Text('${cat.subProducts.length} sub-categories',
                  style: TextStyle(fontSize: 10.5, color: c.textSecondary, fontFamily: 'Poppins')),
              ),
            ])),

            // Type: "Category" badge (purple)
            Expanded(flex: _kTypeF, child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF4A3AFF).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20)),
              child: const Text('Category', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: Color(0xFF4A3AFF), fontFamily: 'Poppins')),
            ))),

            // Products count
            Expanded(flex: _kProdF, child: Center(child: Text('$products',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: c.textPrimary, fontFamily: 'Poppins')))),

            // Status: Active (green)
            Expanded(flex: _kStatF, child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20)),
              child: const Text('Active', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: Color(0xFF22C55E), fontFamily: 'Poppins')),
            ))),

            // Created On
            Expanded(flex: _kDateF, child: Text(date,
              style: TextStyle(fontSize: 13, color: c.textSecondary, fontFamily: 'Poppins'))),

            // Actions: info + edit + delete + expand toggle
            Expanded(flex: _kActF, child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionBtn(icon: Icons.info_outline_rounded, color: const Color(0xFF0EA5E9),
                  tooltip: 'Info', onTap: widget.onInfo),
                const SizedBox(width: 5),
                _ActionBtn(icon: Icons.edit_outlined, color: const Color(0xFF4A3AFF),
                  tooltip: 'Edit', onTap: widget.onEdit),
                const SizedBox(width: 5),
                _ActionBtn(icon: Icons.delete_outline_rounded, color: const Color(0xFFEF4444),
                  tooltip: 'Delete', onTap: widget.onDelete),
                const SizedBox(width: 5),
                // Expand/Collapse chevron
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: c.iconBgPurple,
                        borderRadius: BorderRadius.circular(7)),
                      child: Icon(
                        widget.isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18, color: c.textSecondary),
                    ),
                  ),
                ),
              ],
            )),
          ]),
        ),
      ),
    );
  }

  /// Builds the 36x36 category image/avatar box.
  Widget _buildCategoryAvatar(ProductCategory cat, AppThemeColors c) {
    final hue = (cat.name.codeUnits.fold(0, (h, v) => h + v) * 37) % 360;
    final accent = HSLColor.fromAHSL(1, hue.toDouble(), 0.58, 0.44).toColor();
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: _kIconW, height: _kIconW,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(9),
        ),
        child: cat.imageBytes != null
          ? Image.memory(cat.imageBytes!, fit: BoxFit.cover, width: _kIconW, height: _kIconW)
          : Center(
              child: Text(
                cat.name.trim().split(' ')
                  .where((w) => w.isNotEmpty)
                  .take(2)
                  .map((w) => w[0].toUpperCase())
                  .join(),
                style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w800,
                  color: accent, fontFamily: 'Poppins'),
              ),
            ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-Category Row (inline, shown when parent is expanded)
// ─────────────────────────────────────────────────────────────────────────────
class _SubCategoryRow extends StatefulWidget {
  final String name;
  final int catIndex, subIndex;
  final AppThemeColors colors;
  final VoidCallback onEdit, onDelete, onInfo;

  const _SubCategoryRow({
    required this.name, required this.catIndex, required this.subIndex,
    required this.colors, required this.onEdit, required this.onDelete,
    required this.onInfo,
  });

  @override State<_SubCategoryRow> createState() => _SubCategoryRowState();
}

class _SubCategoryRowState extends State<_SubCategoryRow> {
  bool _hovered = false;

  int get _products {
    final ci = widget.catIndex;
    final si = widget.subIndex;
    return (ci < _kSubProducts.length && si < _kSubProducts[ci].length)
        ? _kSubProducts[ci][si] : 5;
  }

  String get _date {
    final ci = widget.catIndex;
    final si = widget.subIndex;
    return (ci < _kSubDates.length && si < _kSubDates[ci].length)
        ? _kSubDates[ci][si] : '01 May 2024';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          // Very subtle light tint for sub-category rows
          color: _hovered ? c.rowEven : c.background.withValues(alpha: 0.4),
          border: Border(bottom: BorderSide(color: c.divider, width: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

            // ── Drag handle (aligns with _kDragW in category rows) ───────────
            MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: SizedBox(
                width: _kDragW,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _hovered ? 0.8 : 0.4,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(Icons.drag_indicator_rounded,
                      size: 16, color: c.textHint),
                  ),
                ),
              ),
            ),

            // Empty space matching _kNumW # badge column
            const SizedBox(width: _kNumW),
            const SizedBox(width: _kGapW),

            // Empty icon placeholder — keeps alignment with category rows
            const SizedBox(width: _kIconW),
            const SizedBox(width: _kGapW),

            // Sub-category name
            Expanded(flex: _kNameF, child: Text(widget.name,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500,
                color: c.textPrimary, fontFamily: 'Poppins'),
              overflow: TextOverflow.ellipsis)),

            // Type: "Sub-Category" badge (green)
            Expanded(flex: _kTypeF, child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20)),
              child: const Text('Sub-Category', style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: Color(0xFF22C55E), fontFamily: 'Poppins')),
            ))),

            // Products count
            Expanded(flex: _kProdF, child: Center(child: Text('$_products',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                color: c.textPrimary, fontFamily: 'Poppins')))),

            // Status: Active
            Expanded(flex: _kStatF, child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20)),
              child: const Text('Active', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: Color(0xFF22C55E), fontFamily: 'Poppins')),
            ))),

            // Created On
            Expanded(flex: _kDateF, child: Text(_date,
              style: TextStyle(fontSize: 13, color: c.textSecondary, fontFamily: 'Poppins'))),

            // Actions: info + edit + delete (no chevron for sub-categories)
            Expanded(flex: _kActF, child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionBtn(icon: Icons.info_outline_rounded, color: const Color(0xFF0EA5E9),
                  tooltip: 'Info', onTap: widget.onInfo),
                const SizedBox(width: 5),
                _ActionBtn(icon: Icons.edit_outlined, color: const Color(0xFF4A3AFF),
                  tooltip: 'Edit', onTap: widget.onEdit),
                const SizedBox(width: 5),
                _ActionBtn(icon: Icons.delete_outline_rounded, color: const Color(0xFFEF4444),
                  tooltip: 'Delete', onTap: widget.onDelete),
              ],
            )),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// "Add Sub-Category" inline row (bottom of expanded section)
// ─────────────────────────────────────────────────────────────────────────────
class _AddSubRow extends StatelessWidget {
  final AppThemeColors colors;
  final bool isLast;
  final VoidCallback onTap;
  const _AddSubRow({required this.colors, required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      decoration: BoxDecoration(
        color: c.background.withValues(alpha: 0.4),
        border: isLast ? null : Border(bottom: BorderSide(color: c.divider, width: 0.8)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(children: [
        // Indent to align with sub-category name column
        SizedBox(width: _kNumW + _kGapW + _kIconW + _kGapW),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: Row(children: [
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.add_rounded, color: AppColors.primaryOrange, size: 15),
              ),
              const SizedBox(width: 8),
              const Text('Add Sub-Category', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.primaryOrange, fontFamily: 'Poppins')),
            ]),
          ),
        ),
      ]),
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
  const _ActionBtn({required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(7)),
          child: Icon(icon, color: color, size: 15),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table Footer
// ─────────────────────────────────────────────────────────────────────────────
class _TableFooter extends StatelessWidget {
  final int total, startDisplay, endDisplay, currentPage, totalPages, rowsPerPage;
  final AppThemeColors colors;
  final ValueChanged<int> onPageChanged, onRowsChanged;

  const _TableFooter({
    required this.total, required this.startDisplay, required this.endDisplay,
    required this.currentPage, required this.totalPages, required this.rowsPerPage,
    required this.colors, required this.onPageChanged, required this.onRowsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Text('Showing $startDisplay to $endDisplay of $total categories',
          style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontFamily: 'Poppins')),
        const Spacer(),
        Text('Rows per page:', style: TextStyle(
          fontSize: 12.5, color: colors.textSecondary, fontFamily: 'Poppins')),
        const SizedBox(width: 8),
        Container(
          height: 32, padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(6),
            color: colors.surface),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: rowsPerPage, isDense: true,
              style: TextStyle(fontSize: 12.5, color: colors.textPrimary, fontFamily: 'Poppins'),
              dropdownColor: colors.surface,
              items: [5, 10, 20, 50].map((v) =>
                DropdownMenuItem(value: v, child: Text('$v'))).toList(),
              onChanged: (v) { if (v != null) onRowsChanged(v); },
            ),
          ),
        ),
        const SizedBox(width: 16),
        _PageBtn(icon: Icons.first_page_rounded, enabled: currentPage > 1, colors: colors, onTap: () => onPageChanged(1)),
        const SizedBox(width: 4),
        _PageBtn(icon: Icons.chevron_left_rounded, enabled: currentPage > 1, colors: colors, onTap: () => onPageChanged(currentPage - 1)),
        const SizedBox(width: 6),
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: AppColors.primaryOrange, borderRadius: BorderRadius.circular(7)),
          child: Center(child: Text('$currentPage', style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins'))),
        ),
        const SizedBox(width: 6),
        _PageBtn(icon: Icons.chevron_right_rounded, enabled: currentPage < totalPages, colors: colors, onTap: () => onPageChanged(currentPage + 1)),
        const SizedBox(width: 4),
        _PageBtn(icon: Icons.last_page_rounded, enabled: currentPage < totalPages, colors: colors, onTap: () => onPageChanged(totalPages)),
      ]),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final AppThemeColors colors;
  final VoidCallback onTap;
  const _PageBtn({required this.icon, required this.enabled, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(6),
          color: colors.surface),
        child: Icon(icon, size: 17, color: enabled ? colors.textPrimary : colors.textHint),
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
  late bool _isActive;
  int _descLen = 0;
  bool _isDragOver = false;
  Uint8List? _pickedImageBytes;
  String _pickedImageName = '';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _descCtrl = TextEditingController(text: widget.initialDesc);
    _isActive = true;
    _descLen = _descCtrl.text.length;
    _pickedImageBytes = widget.initialImageBytes;
    _descCtrl.addListener(() => setState(() => _descLen = _descCtrl.text.length));
  }

  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

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
      setState(() { _pickedImageBytes = bytes; _pickedImageName = f.name; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSub  = widget.isSubCategory;
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
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 40, offset: const Offset(0, 10))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 22, 16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_title, style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: colors.textPrimary, fontFamily: 'Poppins')),
                      const SizedBox(height: 4),
                      if (isSub && widget.parentCategoryName != null && !widget.isEdit) ...[
                        Text('Add a new sub-category under', style: TextStyle(
                          fontSize: 13, color: colors.textSecondary, fontFamily: 'Poppins')),
                        const SizedBox(height: 2),
                        Text(widget.parentCategoryName!, style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: colors.textPrimary, fontFamily: 'Poppins')),
                      ] else
                        Text(
                          widget.isEdit
                            ? 'Update the ${isSub ? "sub-" : ""}category details.'
                            : 'Create a new product ${isSub ? "sub-" : ""}category.',
                          style: TextStyle(
                            fontSize: 13, color: colors.textSecondary, fontFamily: 'Poppins')),
                    ],
                  )),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: Get.back,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: colors.comingSoonBadge,
                        borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.close_rounded, size: 18, color: colors.textSecondary)),
                  ),
                ]),
              ),
              Divider(height: 1, color: colors.divider),

              // ── Body ────────────────────────────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Name
                  _DlgLabel(isSub ? 'Sub-Category Name' : 'Category Name',
                    required: true, colors: colors),
                  const SizedBox(height: 6),
                  _DlgTF(
                    ctrl: _nameCtrl,
                    hint: isSub ? 'Enter sub-category name' : 'Enter category name',
                    autofocus: true, colors: colors),
                  const SizedBox(height: 16),

                  // Description
                  _DlgLabel('Description (optional)', colors: colors),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    maxLength: 250,
                    style: TextStyle(fontSize: 13.5, color: colors.textPrimary, fontFamily: 'Poppins'),
                    decoration: InputDecoration(
                      hintText: 'Enter description',
                      hintStyle: TextStyle(color: colors.textHint, fontFamily: 'Poppins', fontSize: 13.5),
                      filled: true, fillColor: colors.inputFill,
                      counterText: '',
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5)),
                    ),
                  ),
                  Align(alignment: Alignment.centerRight,
                    child: Text('$_descLen/250', style: TextStyle(
                      fontSize: 11.5, color: colors.textHint, fontFamily: 'Poppins'))),
                  const SizedBox(height: 16),

                  // Image upload zone
                  _DlgLabel(
                    isSub ? 'Sub-Category Image (optional)' : 'Category Image (optional)',
                    colors: colors),
                  const SizedBox(height: 8),

                  // If an image has been picked, show preview + clear button
                  if (_pickedImageBytes != null) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.40)),
                        borderRadius: BorderRadius.circular(10),
                        color: colors.inputFill,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_pickedImageBytes!,
                            width: 72, height: 72, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            _pickedImageName.isNotEmpty
                              ? _pickedImageName
                              : 'Existing image',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: colors.textPrimary, fontFamily: 'Poppins'),
                            overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('Image selected', style: TextStyle(
                            fontSize: 11, color: AppColors.primaryOrange, fontFamily: 'Poppins')),
                        ])),
                        InkWell(
                          onTap: () => setState(() { _pickedImageBytes = null; _pickedImageName = ''; }),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6)),
                            child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 14)),
                        ),
                      ]),
                    ),
                  ] else ...[
                    // Drag & Drop + click-to-browse zone
                    DropTarget(
                      onDragEntered: (_) => setState(() => _isDragOver = true),
                      onDragExited:  (_) => setState(() => _isDragOver = false),
                      onDragDone: (detail) async {
                        _isDragOver = false;
                        if (detail.files.isNotEmpty) {
                          final bytes = await detail.files.first.readAsBytes();
                          final name  = detail.files.first.name;
                          setState(() { _pickedImageBytes = bytes; _pickedImageName = name; });
                        } else {
                          setState(() {});
                        }
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: double.infinity,
                            height: 118,
                            decoration: BoxDecoration(
                              color: _isDragOver
                                ? AppColors.primaryOrange.withValues(alpha: 0.06)
                                : colors.inputFill,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isDragOver ? AppColors.primaryOrange : colors.border,
                                width: _isDragOver ? 1.8 : 1),
                            ),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryOrange.withValues(
                                    alpha: _isDragOver ? 0.14 : 0.08),
                                  borderRadius: BorderRadius.circular(10)),
                                child: Icon(
                                  _isDragOver
                                    ? Icons.download_rounded
                                    : Icons.cloud_upload_outlined,
                                  size: 24, color: AppColors.primaryOrange),
                              ),
                              const SizedBox(height: 10),
                              Text.rich(TextSpan(
                                style: TextStyle(
                                  fontSize: 12.5, color: colors.textSecondary,
                                  fontFamily: 'Poppins', height: 1.5),
                                children: [
                                  TextSpan(
                                    text: _isDragOver
                                      ? 'Release to upload'
                                      : 'Drag & drop an image here\n',
                                    style: _isDragOver
                                      ? const TextStyle(color: AppColors.primaryOrange,
                                          fontWeight: FontWeight.w600)
                                      : null,
                                  ),
                                  if (!_isDragOver)
                                    TextSpan(text: 'or click to ', style: TextStyle(
                                      color: colors.textHint)),
                                  if (!_isDragOver)
                                    const TextSpan(text: 'browse', style: TextStyle(
                                      color: AppColors.primaryOrange,
                                      fontWeight: FontWeight.w600)),
                                ],
                              ), textAlign: TextAlign.center),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text('Allowed formats: JPG, PNG, WEBP (Max 2MB)',
                    style: TextStyle(fontSize: 11.5, color: colors.textHint, fontFamily: 'Poppins')),
                  const SizedBox(height: 16),

                  // Status
                  _DlgLabel('Status', colors: colors),
                  const SizedBox(height: 8),
                  Row(children: [
                    Switch(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeColor: AppColors.primaryOrange,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    Text(_isActive ? 'Active' : 'Inactive', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: colors.textPrimary, fontFamily: 'Poppins')),
                  ]),
                ]),
              ),
              Divider(height: 1, color: colors.divider),

              // ── Footer ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  OutlinedButton(
                    onPressed: Get.back,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: Text('Cancel', style: TextStyle(
                      fontFamily: 'Poppins', color: colors.textPrimary, fontSize: 14)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      final name = _nameCtrl.text.trim();
                      if (name.isNotEmpty) {
                        widget.onSave(name, _descCtrl.text.trim(), _pickedImageBytes);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange, elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: Text(_saveLabel, style: const TextStyle(
                      fontFamily: 'Poppins', color: Colors.white,
                      fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category / Sub-Category Info Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryInfoDialog extends StatelessWidget {
  final bool isSubCategory;
  final String name;
  final String description;
  final String? parentName;
  final List<String>? subCategories;
  final int globalIndex;
  final int subIndex;

  const _CategoryInfoDialog({
    required this.isSubCategory,
    required this.name,
    required this.description,
    this.parentName,
    this.subCategories,
    required this.globalIndex,
    this.subIndex = 0,
  });

  String get _createdOn {
    if (!isSubCategory) {
      return globalIndex < _kCatDates.length ? _kCatDates[globalIndex] : '01 May 2024';
    }
    final ci = globalIndex, si = subIndex;
    return (ci < _kSubDates.length && si < _kSubDates[ci].length)
        ? _kSubDates[ci][si] : '01 May 2024';
  }

  int get _products {
    if (!isSubCategory) {
      return globalIndex < _kCatProducts.length ? _kCatProducts[globalIndex] : 0;
    }
    final ci = globalIndex, si = subIndex;
    return (ci < _kSubProducts.length && si < _kSubProducts[ci].length)
        ? _kSubProducts[ci][si] : 0;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const accent  = Color(0xFF0EA5E9); // info blue
    const orange  = AppColors.primaryOrange;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 40, offset: const Offset(0, 10))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                child: Row(children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.info_outline_rounded, color: accent, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isSubCategory ? 'Sub-Category Info' : 'Category Info',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                        color: colors.textPrimary, fontFamily: 'Poppins')),
                    Text(isSubCategory ? 'Sub-category details' : 'Category details',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Poppins')),
                  ])),
                  InkWell(
                    onTap: Get.back,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(color: colors.comingSoonBadge, borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.close_rounded, size: 16, color: colors.textSecondary)),
                  ),
                ]),
              ),
              Divider(height: 1, color: colors.divider),

              // ── Body ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Name
                  _InfoRow(
                    label: isSubCategory ? 'Sub-Category Name' : 'Category Name',
                    colors: colors,
                    child: Text(name, style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: colors.textPrimary, fontFamily: 'Poppins')),
                  ),
                  const SizedBox(height: 14),

                  // Parent category (sub-categories only)
                  if (isSubCategory && parentName != null) ...[
                    _InfoRow(
                      label: 'Parent Category',
                      colors: colors,
                      child: Text(parentName!, style: TextStyle(
                        fontSize: 13.5, color: orange,
                        fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Type badge
                  _InfoRow(
                    label: 'Type',
                    colors: colors,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSubCategory
                          ? const Color(0xFF22C55E).withValues(alpha: 0.10)
                          : const Color(0xFF4A3AFF).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20)),
                      child: Text(isSubCategory ? 'Sub-Category' : 'Category',
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Poppins',
                          color: isSubCategory ? const Color(0xFF22C55E) : const Color(0xFF4A3AFF))),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Products + Status row
                  Row(children: [
                    Expanded(child: _InfoRow(
                      label: 'Products',
                      colors: colors,
                      child: Text('$_products', style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: colors.textPrimary, fontFamily: 'Poppins')),
                    )),
                    const SizedBox(width: 24),
                    Expanded(child: _InfoRow(
                      label: 'Status',
                      colors: colors,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20)),
                        child: const Text('Active', style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: Color(0xFF22C55E), fontFamily: 'Poppins')),
                      ),
                    )),
                  ]),
                  const SizedBox(height: 14),

                  // Created On
                  _InfoRow(
                    label: 'Created On',
                    colors: colors,
                    child: Text(_createdOn, style: TextStyle(
                      fontSize: 13.5, color: colors.textPrimary, fontFamily: 'Poppins')),
                  ),
                  const SizedBox(height: 16),

                  // Description section
                  Divider(height: 1, color: colors.divider),
                  const SizedBox(height: 14),
                  Text('Description', style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: colors.textSecondary, fontFamily: 'Poppins',
                    letterSpacing: 0.4)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.inputFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.border)),
                    child: description.isEmpty
                      ? Row(children: [
                          Icon(Icons.info_outline, size: 15,
                            color: colors.textHint),
                          const SizedBox(width: 6),
                          Text('No description added', style: TextStyle(
                            fontSize: 13, color: colors.textHint,
                            fontStyle: FontStyle.italic, fontFamily: 'Poppins')),
                        ])
                      : Text(description, style: TextStyle(
                          fontSize: 13.5, color: colors.textPrimary,
                          fontFamily: 'Poppins', height: 1.55)),
                  ),

                  // Sub-categories list (for parent categories only)
                  if (!isSubCategory && subCategories != null && subCategories!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Divider(height: 1, color: colors.divider),
                    const SizedBox(height: 14),
                    Row(children: [
                      Text('Sub-Categories', style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600,
                        color: colors.textSecondary, fontFamily: 'Poppins',
                        letterSpacing: 0.4)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: orange.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20)),
                        child: Text('${subCategories!.length}', style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: orange, fontFamily: 'Poppins')),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: subCategories!.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: colors.comingSoonBadge,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.border)),
                        child: Text(s, style: TextStyle(
                          fontSize: 12, color: colors.textPrimary, fontFamily: 'Poppins')),
                      )).toList(),
                    ),
                  ],
                ]),
              ),
              Divider(height: 1, color: colors.divider),

              // ── Footer ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  ElevatedButton(
                    onPressed: Get.back,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange, elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Close', style: TextStyle(
                      fontFamily: 'Poppins', color: Colors.white,
                      fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// Helper for _CategoryInfoDialog
class _InfoRow extends StatelessWidget {
  final String label;
  final Widget child;
  final AppThemeColors colors;
  const _InfoRow({required this.label, required this.child, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(
        fontSize: 11.5, fontWeight: FontWeight.w600,
        color: colors.textSecondary, fontFamily: 'Poppins',
        letterSpacing: 0.3)),
      const SizedBox(height: 5),
      child,
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared dialog label + text-field helpers
// ─────────────────────────────────────────────────────────────────────────────
class _DlgLabel extends StatelessWidget {
  final String label; final bool required; final AppThemeColors colors;
  const _DlgLabel(this.label, {this.required = false, required this.colors});
  @override
  Widget build(BuildContext context) {
    return RichText(text: TextSpan(children: [
      TextSpan(text: label, style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w500,
        color: colors.textPrimary, fontFamily: 'Poppins')),
      if (required) const TextSpan(text: ' *', style: TextStyle(
        color: Color(0xFFEF4444), fontSize: 13)),
    ]));
  }
}

class _DlgTF extends StatelessWidget {
  final TextEditingController ctrl; final String hint;
  final bool autofocus; final AppThemeColors colors;
  const _DlgTF({required this.ctrl, required this.hint,
    this.autofocus = false, required this.colors});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl, autofocus: autofocus,
      style: TextStyle(fontSize: 13.5, color: colors.textPrimary, fontFamily: 'Poppins'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textHint, fontFamily: 'Poppins', fontSize: 13.5),
        filled: true, fillColor: colors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5)),
      ),
    );
  }
}


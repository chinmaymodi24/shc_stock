import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controllers/categories_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/widgets/web_sidebar.dart';
import '../../products/models/product_model.dart';

// Seed display dates (matching screenshot)
const _kSeedDates = [
  '01 May 2024',
  '02 May 2024',
  '03 May 2024',
  '03 May 2024',
  '04 May 2024',
  '05 May 2024',
  '05 May 2024',
];

// Category icons
const _kCatIcons = [
  Icons.layers_rounded,
  Icons.texture_rounded,
  Icons.view_module_rounded,
  Icons.local_fire_department_rounded,
  Icons.science_rounded,
  Icons.shield_rounded,
  Icons.build_rounded,
];

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CategoriesController>();
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          // ── Left Sidebar (unchanged) ─────────────────────────
          const WebSidebar(),

          // ── Main Content ─────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top bar
                _WebTopBar(colors: colors),

                // Page body
                Expanded(
                  child: Obx(() {
                    final all = c.categories;
                    final filtered = _searchQuery.isEmpty
                        ? all.toList()
                        : all
                            .where((cat) => cat.name
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()))
                            .toList();

                    final totalPages = filtered.isEmpty
                        ? 1
                        : (filtered.length / _rowsPerPage).ceil();
                    final startIdx = (_currentPage - 1) * _rowsPerPage;
                    final endIdx =
                        math.min(startIdx + _rowsPerPage, filtered.length);
                    final pageItems = filtered.isEmpty
                        ? <ProductCategory>[]
                        : filtered.sublist(startIdx, endIdx);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Page Header ──────────────────────
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
                                    'Manage product categories and their sub-categories.',
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
                                icon: const Icon(Icons.add_rounded,
                                    color: Colors.white, size: 18),
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
                                      horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Stat Cards ───────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'Total Categories',
                                  value: '${c.totalCategories}',
                                  icon: Icons.grid_view_rounded,
                                  iconColor: AppColors.primaryOrange,
                                  trend: '+16.7%',
                                  trendUp: true,
                                  spark: const [
                                    0.4, 0.5, 0.3, 0.6, 0.5, 0.7, 0.6
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  label: 'Total Sub-Categories',
                                  value: '${c.totalSubCategories}',
                                  icon: Icons.account_tree_outlined,
                                  iconColor: const Color(0xFF4A3AFF),
                                  trend: '+8.3%',
                                  trendUp: true,
                                  spark: const [
                                    0.3, 0.4, 0.5, 0.4, 0.6, 0.55, 0.65
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  label: 'Low Stock Items',
                                  value: '2',
                                  icon: Icons.warning_amber_rounded,
                                  iconColor: const Color(0xFFF59E0B),
                                  trend: '-33.3%',
                                  trendUp: false,
                                  spark: const [
                                    0.7, 0.6, 0.55, 0.4, 0.5, 0.35, 0.4
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  label: 'Total Sales (MTD)',
                                  value: '₹ 25,43,000',
                                  icon: Icons.currency_rupee_rounded,
                                  iconColor: const Color(0xFF22C55E),
                                  trend: '+12.5%',
                                  trendUp: true,
                                  spark: const [
                                    0.3, 0.35, 0.5, 0.45, 0.6, 0.7, 0.8
                                  ],
                                  smallValue: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Table Card ───────────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.divider),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Search + filter row
                                _TableToolbar(
                                  colors: colors,
                                  searchCtrl: _searchCtrl,
                                  onSearch: (v) => setState(() {
                                    _searchQuery = v;
                                    _currentPage = 1;
                                  }),
                                ),
                                Divider(height: 1, color: colors.divider),

                                // Column headers
                                _TableColumnHeader(colors: colors),
                                Divider(height: 1, color: colors.divider),

                                // Data rows
                                if (pageItems.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(48),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.search_off_rounded,
                                              size: 40,
                                              color: colors.textHint),
                                          const SizedBox(height: 10),
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
                                else
                                  ...pageItems.asMap().entries.map((e) {
                                    final globalIdx =
                                        c.categories.indexOf(e.value);
                                    return _CategoryTableRow(
                                      cat: e.value,
                                      globalIndex: globalIdx,
                                      controller: c,
                                      colors: colors,
                                      isLast: e.key == pageItems.length - 1,
                                      onEdit: () =>
                                          _showEditDialog(c, e.value),
                                      onDelete: () =>
                                          _confirmDelete(c, e.value),
                                      onAddSub: () =>
                                          _showAddSubDialog(c, e.value.id),
                                    );
                                  }),

                                // Footer with pagination
                                Divider(height: 1, color: colors.divider),
                                _TableFooter(
                                  total: filtered.length,
                                  startDisplay:
                                      filtered.isEmpty ? 0 : startIdx + 1,
                                  endDisplay: endIdx,
                                  currentPage: _currentPage,
                                  totalPages: totalPages,
                                  rowsPerPage: _rowsPerPage,
                                  colors: colors,
                                  onPageChanged: (p) =>
                                      setState(() => _currentPage = p),
                                  onRowsChanged: (r) => setState(() {
                                    _rowsPerPage = r;
                                    _currentPage = 1;
                                  }),
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

  // ── Dialogs ───────────────────────────────────────────────────
  void _showAddCategoryDialog(CategoriesController c) {
    Get.dialog(
      _AddCategoryDialog(
        onSave: (name) {
          c.addCategory(name);
          Get.back();
        },
      ),
    );
  }

  void _showEditDialog(CategoriesController c, ProductCategory cat) {
    final ctrl = TextEditingController(text: cat.name);
    Get.dialog(_FormDialog(
      title: 'Edit Category',
      hint: cat.name,
      controller: ctrl,
      onSave: () {
        c.updateCategory(cat.id, ctrl.text);
        Get.back();
      },
    ));
  }

  void _showAddSubDialog(CategoriesController c, String catId) {
    final ctrl = TextEditingController();
    Get.dialog(_FormDialog(
      title: 'Add Sub-Category',
      hint: 'e.g. Ceramic Fiber Rope',
      controller: ctrl,
      onSave: () {
        c.addSubCategory(catId, ctrl.text);
        Get.back();
      },
    ));
  }

  void _confirmDelete(CategoriesController c, ProductCategory cat) {
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
                  )
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
                          child: Icon(Icons.delete_outline_rounded,
                              color: colors.error, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Delete Category?',
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
                            child: Icon(Icons.close_rounded,
                                size: 18, color: colors.textSecondary),
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
                      'Are you sure you want to permanently delete "${cat.name}"? '
                      'This will also delete all ${cat.subProducts.length} sub-categories. '
                      'This action cannot be undone.',
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
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
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
                            c.deleteCategory(cat.id);
                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.error,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
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
// Top Bar  (search + notifications + quick action + admin)
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
      child: Row(
        children: [
          // Search bar
          Container(
            width: 320,
            height: 38,
            decoration: BoxDecoration(
              color: colors.inputFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(Icons.search_rounded, color: colors.textHint, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Search anything...',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textHint,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'Ctrl + K',
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Notification icons
          _TopIconBtn(icon: Icons.notifications_outlined, badge: '3', colors: colors),
          const SizedBox(width: 8),
          _TopIconBtn(icon: Icons.chat_bubble_outline_rounded, badge: '2', colors: colors),
          const SizedBox(width: 8),
          _TopIconBtn(icon: Icons.calendar_today_outlined, colors: colors),
          const SizedBox(width: 14),

          // Quick Action
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
            label: Row(
              children: const [
                Text(
                  'Quick Action',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white, size: 16),
              ],
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 14),

          // Vertical divider
          Container(width: 1, height: 30, color: colors.divider),
          const SizedBox(width: 14),

          // Admin
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15),
            child: const Icon(Icons.person_rounded,
                color: AppColors.primaryOrange, size: 18),
          ),
          const SizedBox(width: 8),
          Text(
            'Admin',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: colors.textSecondary, size: 18),
        ],
      ),
    );
  }
}

class _TopIconBtn extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final AppThemeColors colors;
  const _TopIconBtn(
      {required this.icon, this.badge, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.inputFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Icon(icon, color: colors.textSecondary, size: 19),
        ),
        if (badge != null)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 17,
              height: 17,
              decoration: const BoxDecoration(
                color: AppColors.primaryOrange,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Card with Sparkline
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String trend;
  final bool trendUp;
  final List<double> spark;
  final bool smallValue;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.trend,
    required this.trendUp,
    required this.spark,
    this.smallValue = false,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: icon + label + value + trend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: smallValue ? 18 : 26,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      trendUp
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 11,
                      color: trendUp
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: trendUp
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'from last month',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textHint,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Right: sparkline chart
          SizedBox(
            width: 64,
            height: 52,
            child: CustomPaint(
              painter: _SparklinePainter(
                points: spark,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sparkline CustomPainter
class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color color;
  const _SparklinePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fill = Path();

    final stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - (points[i] * size.height * 0.8) - size.height * 0.05;

      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(0, size.height);
        fill.lineTo(x, y);
      } else {
        final px = (i - 1) * stepX;
        final py = size.height - (points[i - 1] * size.height * 0.8) - size.height * 0.05;
        final cpx = (px + x) / 2;
        path.cubicTo(cpx, py, cpx, y, x, y);
        fill.cubicTo(cpx, py, cpx, y, x, y);
      }
    }

    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(fill, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Table Toolbar (search + filter + view toggle)
// ─────────────────────────────────────────────────────────────────────────────
class _TableToolbar extends StatefulWidget {
  final AppThemeColors colors;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  const _TableToolbar(
      {required this.colors,
      required this.searchCtrl,
      required this.onSearch});

  @override
  State<_TableToolbar> createState() => _TableToolbarState();
}

class _TableToolbarState extends State<_TableToolbar> {
  bool _listView = true;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Search
          SizedBox(
            width: 270,
            height: 38,
            child: TextField(
              controller: widget.searchCtrl,
              onChanged: widget.onSearch,
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
                prefixIcon:
                    Icon(Icons.search_rounded, color: colors.textHint, size: 17),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                filled: true,
                fillColor: colors.inputFill,
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
                  borderSide:
                      const BorderSide(color: AppColors.primaryOrange, width: 1.5),
                ),
              ),
            ),
          ),
          const Spacer(),

          // Filter button
          OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.tune_rounded, size: 15, color: colors.textSecondary),
            label: Text(
              'Filter',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Poppins',
                color: colors.textSecondary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              side: BorderSide(color: colors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),

          // View toggle: grid | list
          _ToggleBtn(
            icon: Icons.grid_view_rounded,
            isActive: !_listView,
            colors: colors,
            onTap: () => setState(() => _listView = false),
          ),
          const SizedBox(width: 4),
          _ToggleBtn(
            icon: Icons.format_list_bulleted_rounded,
            isActive: _listView,
            colors: colors,
            onTap: () => setState(() => _listView = true),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final AppThemeColors colors;
  final VoidCallback onTap;
  const _ToggleBtn(
      {required this.icon,
      required this.isActive,
      required this.colors,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryOrange.withValues(alpha: 0.1)
              : colors.inputFill,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isActive
                ? AppColors.primaryOrange.withValues(alpha: 0.3)
                : colors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 17,
          color: isActive ? AppColors.primaryOrange : colors.textSecondary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table Column Header Row
// ─────────────────────────────────────────────────────────────────────────────
class _TableColumnHeader extends StatelessWidget {
  final AppThemeColors colors;
  const _TableColumnHeader({required this.colors});

  TextStyle get _style => TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
        fontFamily: 'Poppins',
        letterSpacing: 0.1,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('#', style: _style)),
          const SizedBox(width: 10),
          const SizedBox(width: 38), // icon placeholder
          const SizedBox(width: 12),
          Expanded(flex: 30, child: Text('Category Name', style: _style)),
          Expanded(
            flex: 18,
            child: Center(child: Text('Sub-Categories', style: _style)),
          ),
          Expanded(
            flex: 14,
            child: Center(child: Text('Status', style: _style)),
          ),
          Expanded(
            flex: 18,
            child: Text('Created On', style: _style),
          ),
          Expanded(
            flex: 18,
            child: Center(child: Text('Actions', style: _style)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Table Row
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryTableRow extends StatefulWidget {
  final ProductCategory cat;
  final int globalIndex;
  final CategoriesController controller;
  final AppThemeColors colors;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddSub;

  const _CategoryTableRow({
    required this.cat,
    required this.globalIndex,
    required this.controller,
    required this.colors,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
    required this.onAddSub,
  });

  @override
  State<_CategoryTableRow> createState() => _CategoryTableRowState();
}

class _CategoryTableRowState extends State<_CategoryTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final cat = widget.cat;
    final idx = widget.globalIndex;
    final catIcon = _kCatIcons[idx % _kCatIcons.length];
    final date = idx < _kSeedDates.length ? _kSeedDates[idx] : '01 Jun 2024';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hovered ? colors.rowEven : colors.surface,
          border: widget.isLast
              ? null
              : Border(
                  bottom: BorderSide(color: colors.divider, width: 0.8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              // # number badge
              SizedBox(
                width: 28,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOrange,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Category icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A3AFF).withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(catIcon,
                    color: const Color(0xFF4A3AFF), size: 18),
              ),
              const SizedBox(width: 12),

              // Category name + sub count
              Expanded(
                flex: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      '${cat.subProducts.length} sub-categories',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),

              // Sub-categories count badge
              Expanded(
                flex: 18,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A3AFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${cat.subProducts.length}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A3AFF),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),

              // Status badge
              Expanded(
                flex: 14,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF22C55E),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),

              // Created On
              Expanded(
                flex: 18,
                child: Text(
                  date,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),

              // Actions: edit | delete | more
              Expanded(
                flex: 18,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(width: 6),
                    _ActionBtn(
                      icon: Icons.more_vert_rounded,
                      color: colors.textSecondary,
                      tooltip: 'More',
                      onTap: () {},
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
// Action Button
// ─────────────────────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.color,
      required this.tooltip,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table Footer with Pagination
// ─────────────────────────────────────────────────────────────────────────────
class _TableFooter extends StatelessWidget {
  final int total;
  final int startDisplay;
  final int endDisplay;
  final int currentPage;
  final int totalPages;
  final int rowsPerPage;
  final AppThemeColors colors;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onRowsChanged;

  const _TableFooter({
    required this.total,
    required this.startDisplay,
    required this.endDisplay,
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
    required this.colors,
    required this.onPageChanged,
    required this.onRowsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // "Showing X to Y of Z categories"
          Text(
            'Showing $startDisplay to $endDisplay of $total categories',
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const Spacer(),

          // Rows per page
          Text(
            'Rows per page:',
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(6),
              color: colors.surface,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: rowsPerPage,
                isDense: true,
                style: TextStyle(
                  fontSize: 12.5,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
                dropdownColor: colors.surface,
                items: [5, 10, 20, 50]
                    .map((v) => DropdownMenuItem(
                          value: v,
                          child: Text('$v'),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onRowsChanged(v);
                },
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Pagination
          _PageBtn(
            icon: Icons.first_page_rounded,
            enabled: currentPage > 1,
            colors: colors,
            onTap: () => onPageChanged(1),
          ),
          const SizedBox(width: 4),
          _PageBtn(
            icon: Icons.chevron_left_rounded,
            enabled: currentPage > 1,
            colors: colors,
            onTap: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 6),
          // Current page number pill
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(
                '$currentPage',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _PageBtn(
            icon: Icons.chevron_right_rounded,
            enabled: currentPage < totalPages,
            colors: colors,
            onTap: () => onPageChanged(currentPage + 1),
          ),
          const SizedBox(width: 4),
          _PageBtn(
            icon: Icons.last_page_rounded,
            enabled: currentPage < totalPages,
            colors: colors,
            onTap: () => onPageChanged(totalPages),
          ),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final AppThemeColors colors;
  final VoidCallback onTap;
  const _PageBtn(
      {required this.icon,
      required this.enabled,
      required this.colors,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(6),
          color: colors.surface,
        ),
        child: Icon(
          icon,
          size: 17,
          color: enabled ? colors.textPrimary : colors.textHint,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _FormDialog extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onSave;
  const _FormDialog(
      {required this.title,
      required this.hint,
      required this.controller,
      required this.onSave});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, minWidth: 380),
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
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_note_rounded,
                            color: AppColors.primaryOrange, size: 22),
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
                          child: Icon(Icons.close_rounded,
                              size: 18, color: colors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Divider(height: 1, color: colors.divider),
                ),
                // Body
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Name',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
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
                              color: colors.textHint, fontFamily: 'Poppins'),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
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
                    ],
                  ),
                ),
                // Footer buttons
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
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
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
                        onPressed: onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Save',
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rich Add Category Dialog  (matches screenshot exactly)
// ─────────────────────────────────────────────────────────────────────────────
class _AddCategoryDialog extends StatefulWidget {
  final void Function(String name) onSave;
  const _AddCategoryDialog({required this.onSave});

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _selectedIcon = 0;
  bool _isActive = true;
  int _descLen = 0;

  // 8 icons shown in dialog (matching screenshot grid)
  static const _pickerIcons = [
    Icons.grid_view_rounded,
    Icons.label_outline_rounded,
    Icons.shield_outlined,
    Icons.local_fire_department_outlined,
    Icons.inventory_2_outlined,
    Icons.warning_amber_outlined,
    Icons.group_outlined,
    Icons.construction_outlined,
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, minWidth: 400),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Category',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Create a new product category.',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Close X button
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
                          child: Icon(Icons.close_rounded,
                              size: 18, color: colors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Divider(height: 1, color: colors.divider),
                ),

                // ── Form Body ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Name
                      RichText(
                        text: TextSpan(
                          text: 'Category Name ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                          children: const [
                            TextSpan(
                              text: '*',
                              style: TextStyle(color: Color(0xFFEF4444)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameCtrl,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: colors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter category name',
                          hintStyle: TextStyle(
                              color: colors.textHint, fontFamily: 'Poppins', fontSize: 13.5),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
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
                      ),
                      const SizedBox(height: 18),

                      // Description
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          TextField(
                            controller: _descCtrl,
                            maxLines: 3,
                            maxLength: 250,
                            onChanged: (v) =>
                                setState(() => _descLen = v.length),
                            style: TextStyle(
                              fontSize: 13.5,
                              color: colors.textPrimary,
                              fontFamily: 'Poppins',
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter description (optional)',
                              hintStyle: TextStyle(
                                  color: colors.textHint,
                                  fontFamily: 'Poppins',
                                  fontSize: 13.5),
                              isDense: true,
                              counterText: '', // hide default counter
                              contentPadding: const EdgeInsets.fromLTRB(
                                  14, 12, 14, 28),
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
                                    width: 1.5),
                              ),
                            ),
                          ),
                          // Custom counter bottom-right
                          Positioned(
                            bottom: 8,
                            right: 12,
                            child: Text(
                              '$_descLen/250',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textHint,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Icon Picker
                      Text(
                        'Icon',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: _pickerIcons.asMap().entries.map((e) {
                          final isSelected = e.key == _selectedIcon;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedIcon = e.key),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryOrange.withValues(alpha: 0.12)
                                      : colors.iconBgPurple,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryOrange
                                        : colors.border,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Icon(
                                  e.value,
                                  size: 18,
                                  color: isSelected
                                      ? AppColors.primaryOrange
                                      : colors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                      // Browse more icons
                      GestureDetector(
                        onTap: () {},
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.grid_view_outlined,
                                size: 14,
                                color: AppColors.primaryOrange),
                            const SizedBox(width: 5),
                            Text(
                              'Browse more icons',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.primaryOrange,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Status toggle
                      Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                setState(() => _isActive = !_isActive),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _isActive
                                    ? AppColors.primaryOrange
                                    : colors.border,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                children: [
                                  AnimatedPositioned(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    left: _isActive ? 22 : 2,
                                    top: 2,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: _isActive
                                  ? AppColors.primaryOrange
                                  : colors.textSecondary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Footer Buttons ───────────────────────────────
                Divider(height: 1, color: colors.divider),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: Get.back,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colors.border),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9)),
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
                      ElevatedButton(
                        onPressed: () {
                          if (_nameCtrl.text.trim().isNotEmpty) {
                            widget.onSave(_nameCtrl.text.trim());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9)),
                        ),
                        child: const Text(
                          'Save Category',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Poppins',
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

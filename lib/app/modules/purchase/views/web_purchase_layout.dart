import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controllers/purchase_controller.dart';
import '../models/purchase_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/widgets/web_sidebar.dart';
import '../../dashboard/widgets/modified_by_cell.dart';
import '../../../routes/app_routes.dart';

// ── Table column constants (header + row MUST match) ──────────────────────
const double _kIdxW = 32.0; // # badge
const double _kGap = 16.0; // column gap after # badge
const int _kPoFlex = 16; // PO Number
const int _kSupFlex = 24; // Supplier
const int _kDateFlex = 14; // Date
const int _kItemFlex = 8; // Items
const int _kAmtFlex = 14; // Amount
const int _kStsFlex = 12; // Status
const int _kModFlex = 18; // Modified By
const int _kActFlex = 10; // Actions

// ─────────────────────────────────────────────────────────────────────────────
class WebPurchaseLayout extends GetView<PurchaseController> {
  const WebPurchaseLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          const WebSidebar(),
          Expanded(
            child: Column(
              children: [
                _WebTopBar(colors: colors),
                Expanded(
                  child: Obx(() {
                    final all = c.orders;
                    final searchQuery = c.searchQuery.value;
                    final supplierFilter = c.supplierFilter.value;
                    final rowsPerPage = c.rowsPerPage.value;
                    final currentPage = c.currentPage.value;

                    var filtered = all.toList();

                    // Search filter
                    if (searchQuery.isNotEmpty) {
                      filtered = filtered
                          .where(
                            (o) =>
                                o.supplier.toLowerCase().contains(
                                  searchQuery.toLowerCase(),
                                ) ||
                                o.poNumber.toLowerCase().contains(
                                  searchQuery.toLowerCase(),
                                ),
                          )
                          .toList();
                    }

                    // Supplier filter
                    if (supplierFilter != 'Supplier: All') {
                      filtered = filtered
                          .where((o) => o.supplier == supplierFilter)
                          .toList();
                    }

                    final totalPages = filtered.isEmpty
                        ? 1
                        : (filtered.length / rowsPerPage).ceil();
                    final startIdx = (currentPage - 1) * rowsPerPage;
                    final endIdx = math.min(
                      startIdx + rowsPerPage,
                      filtered.length,
                    );
                    final pageItems = filtered.isEmpty
                        ? <PurchaseOrder>[]
                        : filtered.sublist(startIdx, endIdx);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Page Header ──────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Purchases',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Manage all purchase orders and track your inventory purchases.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.textSecondary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    Get.toNamed(AppRoutes.addPurchase),
                                icon: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  'New Purchase',
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

                          // ── 4 Stat Cards ─────────────────────────────────
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'Orders',
                                    value: '${c.totalOrders}',
                                    icon: Icons.receipt_long_outlined,
                                    iconColor: const Color(0xFF4A3AFF),
                                    cardBg: const Color(0xFF4A3AFF).withValues(alpha: 0.06),
                                    trend: '+12.5% vs last month',
                                    trendUp: true,
                                    spark: const [
                                      0.3,
                                      0.5,
                                      0.4,
                                      0.6,
                                      0.5,
                                      0.7,
                                      0.65,
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Purchase (MTD)',
                                    value: _formatAmt(c.totalPurchaseMTD),
                                    icon: Icons.shopping_cart_outlined,
                                    iconColor: AppColors.primaryOrange,
                                    cardBg: AppColors.primaryOrange.withValues(alpha: 0.06),
                                    trend: '+18.6% vs last month',
                                    trendUp: true,
                                    spark: const [
                                      0.2,
                                      0.4,
                                      0.5,
                                      0.6,
                                      0.5,
                                      0.7,
                                      0.8,
                                    ],
                                    smallValue: true,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Amount Paid',
                                    value: _formatAmt(c.totalAmountPaid),
                                    icon: Icons.check_circle_outline_rounded,
                                    iconColor: const Color(0xFF22C55E),
                                    cardBg: const Color(0xFF22C55E).withValues(alpha: 0.06),
                                    trend: '+15.3% vs last month',
                                    trendUp: true,
                                    spark: const [
                                      0.25,
                                      0.4,
                                      0.5,
                                      0.55,
                                      0.6,
                                      0.7,
                                      0.75,
                                    ],
                                    smallValue: true,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Amount Due',
                                    value: _formatAmt(c.totalAmountDue),
                                    icon: Icons.currency_rupee_rounded,
                                    iconColor: const Color(0xFFF59E0B),
                                    cardBg: const Color(0xFFF59E0B).withValues(alpha: 0.06),
                                    trend: '-8.3% vs last month',
                                    trendUp: false,
                                    spark: const [
                                      0.7,
                                      0.6,
                                      0.55,
                                      0.5,
                                      0.4,
                                      0.45,
                                      0.35,
                                    ],
                                    smallValue: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Body: Table + Right Panel ─────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── LEFT: Table Card ──────────────────────────
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: colors.divider),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Toolbar
                                      _TableToolbar(
                                        colors: colors,
                                        controller: c,
                                        onSearch: (v) {
                                          c.searchQuery.value = v;
                                          c.currentPage.value = 1;
                                        },
                                      ),
                                      Divider(
                                        height: 1,
                                        color: colors.divider,
                                      ),

                                      // Column Headers
                                      _ColumnHeader(colors: colors),
                                      Divider(
                                        height: 1,
                                        color: colors.divider,
                                      ),

                                      // Data rows
                                      if (pageItems.isEmpty)
                                        _EmptyState(colors: colors)
                                      else
                                        ...pageItems.asMap().entries.map((e) {
                                          final globalIdx = startIdx + e.key;
                                          return _PurchaseRow(
                                            order: e.value,
                                            index: globalIdx,
                                            colors: colors,
                                            isLast:
                                                e.key == pageItems.length - 1,
                                            onDelete: () =>
                                                c.deleteOrder(e.value.id),
                                          );
                                        }),

                                      // Footer
                                      Divider(
                                        height: 1,
                                        color: colors.divider,
                                      ),
                                      _TableFooter(
                                        total: filtered.length,
                                        startDisplay: filtered.isEmpty
                                            ? 0
                                            : startIdx + 1,
                                        endDisplay: endIdx,
                                        currentPage: currentPage,
                                        totalPages: totalPages,
                                        rowsPerPage: rowsPerPage,
                                        colors: colors,
                                        onPageChanged: (p) =>
                                            c.currentPage.value = p,
                                        onRowsChanged: (r) {
                                          c.rowsPerPage.value = r;
                                          c.currentPage.value = 1;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // ── RIGHT: Panel ──────────────────────────────
                              SizedBox(
                                width: 272,
                                child: Column(
                                  children: [
                                    _PurchaseSummaryCard(
                                      colors: colors,
                                      c: c,
                                    ),
                                    const SizedBox(height: 14),
                                    _TopSuppliersCard(colors: colors, c: c),
                                  ],
                                ),
                              ),
                            ],
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

  static String _formatAmt(double v) {
    if (v >= 100000) {
      final lakh = v ~/ 100000;
      final thousands = (v % 100000) ~/ 1000;
      final rem = (v % 1000).toInt();
      if (thousands > 0) {
        return '₹$lakh,${thousands.toString().padLeft(2, '0')},${rem.toString().padLeft(3, '0')}';
      }
      return '₹$lakh,${rem.toString().padLeft(5, '0')}';
    }
    final s = v.toInt();
    if (s >= 1000) {
      final str = s.toString();
      return '₹${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return '₹$s';
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
      child: Row(
        children: [
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
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
          _TopIconBtn(
            icon: Icons.notifications_outlined,
            badge: '3',
            colors: colors,
          ),
          const SizedBox(width: 8),
          _TopIconBtn(
            icon: Icons.chat_bubble_outline_rounded,
            badge: '2',
            colors: colors,
          ),
          const SizedBox(width: 8),
          _TopIconBtn(icon: Icons.calendar_today_outlined, colors: colors),
          const SizedBox(width: 14),
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
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 30, color: colors.divider),
          const SizedBox(width: 14),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primaryOrange,
              size: 18,
            ),
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
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colors.textSecondary,
            size: 18,
          ),
        ],
      ),
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
  /// The full-card tinted background — pass iconColor.withValues(alpha:0.08)
  final Color cardBg;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.trend,
    required this.trendUp,
    required this.spark,
    required this.cardBg,
    this.smallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 17),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: iconColor.withValues(alpha: 0.8),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: smallValue ? 20 : 26,
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
                    Flexible(
                      child: Text(
                        trend,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: trendUp
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
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
          SizedBox(
            width: 56,
            height: 44,
            child: CustomPaint(
              painter: _SparklinePainter(points: spark, color: iconColor),
            ),
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
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    final path = Path();
    final fill = Path();
    final stepX = size.width / (points.length - 1);
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y =
          size.height - (points[i] * size.height * 0.8) - size.height * 0.05;
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(0, size.height);
        fill.lineTo(x, y);
      } else {
        final px = (i - 1) * stepX;
        final py =
            size.height -
            (points[i - 1] * size.height * 0.8) -
            size.height * 0.05;
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


// Table Toolbar
// ─────────────────────────────────────────────────────────────────────────────
class _TableToolbar extends StatefulWidget {
  final AppThemeColors colors;
  final PurchaseController controller;
  final ValueChanged<String> onSearch;
  const _TableToolbar({
    required this.colors,
    required this.controller,
    required this.onSearch,
  });

  @override
  State<_TableToolbar> createState() => _TableToolbarState();
}

class _TableToolbarState extends State<_TableToolbar> {
  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final c = widget.controller;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Search — same style as Stock module (height 40, vertical padding 10)
          SizedBox(
            width: 260,
            height: 40,
            child: TextField(
              onChanged: widget.onSearch,
              style: TextStyle(
                fontSize: 13,
                color: colors.textPrimary,
                fontFamily: 'Poppins',
              ),
              decoration: InputDecoration(
                hintText: 'Search by Item or PO...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: colors.textHint,
                  fontFamily: 'Poppins',
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colors.textHint,
                  size: 17,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                  borderSide: const BorderSide(
                    color: AppColors.primaryOrange,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Supplier filter pill — rounded chip with overlay (matches Stock module style)
          _SupplierPill(
            colors: colors,
            selected: c.supplierFilter.value,
            options: c.supplierNames,
            onChanged: (v) {
              c.supplierFilter.value = v;
              c.currentPage.value = 1;
            },
          ),

          const Spacer(),

          // Export
          OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(
              Icons.upload_outlined,
              size: 15,
              color: colors.textSecondary,
            ),
            label: Text(
              'Export',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Poppins',
                color: colors.textSecondary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              side: BorderSide(color: colors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // View toggle icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.inputFill,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              Icons.table_chart_outlined,
              size: 17,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supplier Filter Pill — rounded chip with overlay dropdown
// ─────────────────────────────────────────────────────────────────────────────
class _SupplierPill extends StatefulWidget {
  final AppThemeColors colors;
  final String selected;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _SupplierPill({
    required this.colors,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  State<_SupplierPill> createState() => _SupplierPillState();
}

class _SupplierPillState extends State<_SupplierPill> {
  final _overlayController = OverlayPortalController();
  final _link = LayerLink();

  bool get _isFiltered => widget.selected != 'Supplier: All';

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final pillBg = colors.background.computeLuminance() > 0.5
        ? const Color(0xFFF1F2F4)
        : colors.inputFill;
    final activeBg =
        _isFiltered ? AppColors.primaryOrange.withValues(alpha: 0.10) : pillBg;
    final activeTextColor =
        _isFiltered ? AppColors.primaryOrange : colors.textPrimary;
    final activeIconColor =
        _isFiltered ? AppColors.primaryOrange : colors.textSecondary;

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (ctx) => Positioned(
          width: 220,
          child: CompositedTransformFollower(
            link: _link,
            offset: const Offset(0, 46),
            child: TapRegion(
              onTapOutside: (_) => _overlayController.hide(),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PillOption(
                        label: 'All Suppliers',
                        isSelected: !_isFiltered,
                        colors: colors,
                        onTap: () {
                          widget.onChanged('Supplier: All');
                          _overlayController.hide();
                        },
                      ),
                      ...widget.options.map(
                        (s) => _PillOption(
                          label: s,
                          isSelected: widget.selected == s,
                          colors: colors,
                          onTap: () {
                            widget.onChanged(s);
                            _overlayController.hide();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        child: InkWell(
          onTap: _overlayController.toggle,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: activeBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tune_rounded, size: 14, color: activeIconColor),
                const SizedBox(width: 6),
                Text(
                  _isFiltered ? widget.selected : 'Supplier',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: activeTextColor,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: activeIconColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final AppThemeColors colors;
  final VoidCallback onTap;

  const _PillOption({
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: isSelected ? AppColors.primaryOrange : colors.textHint,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  color: isSelected
                      ? AppColors.primaryOrange
                      : colors.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Column Headers
// ─────────────────────────────────────────────────────────────────────────────
class _ColumnHeader extends StatelessWidget {
  final AppThemeColors colors;
  const _ColumnHeader({required this.colors});

  TextStyle get _s => TextStyle(
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
          SizedBox(width: _kIdxW, child: Text('#', style: _s)),
          const SizedBox(width: _kGap),
          Expanded(flex: _kPoFlex, child: Text('PO Number', style: _s)),
          Expanded(flex: _kSupFlex, child: Text('Supplier', style: _s)),
          Expanded(flex: _kDateFlex, child: Text('Date', style: _s)),
          Expanded(
            flex: _kItemFlex,
            child: Center(child: Text('Items', style: _s)),
          ),
          Expanded(flex: _kAmtFlex, child: Text('Amount', style: _s)),
          Expanded(
            flex: _kStsFlex,
            child: Center(child: Text('Status', style: _s)),
          ),
          Expanded(flex: _kModFlex, child: Text('Modified By', style: _s)),
          Expanded(
            flex: _kActFlex,
            child: Center(child: Text('Actions', style: _s)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Purchase Row
// ─────────────────────────────────────────────────────────────────────────────
class _PurchaseRow extends StatefulWidget {
  final PurchaseOrder order;
  final int index;
  final AppThemeColors colors;
  final bool isLast;
  final VoidCallback onDelete;

  const _PurchaseRow({
    required this.order,
    required this.index,
    required this.colors,
    required this.isLast,
    required this.onDelete,
  });

  @override
  State<_PurchaseRow> createState() => _PurchaseRowState();
}

class _PurchaseRowState extends State<_PurchaseRow> {
  final _hovered = false.obs;

  @override
  void dispose() {
    _hovered.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final colors = widget.colors;
    final dateStr =
        '${o.date.day.toString().padLeft(2, '0')} ${_month(o.date.month)} ${o.date.year}';

    // Resolve modified by
    final mod = resolveModifiedBy(
      seedId: o.id,
      storedName: o.modifiedBy,
      storedDate: o.modifiedAt,
    );

    return MouseRegion(
      onEnter: (_) => _hovered.value = true,
      onExit: (_) => _hovered.value = false,
      child: Obx(
        () => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _hovered.value ? colors.rowEven : colors.surface,
            border: widget.isLast
                ? null
                : Border(
                    bottom: BorderSide(color: colors.divider, width: 0.8),
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // # badge
                Container(
                  width: _kIdxW,
                  height: _kIdxW,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOrange,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: _kGap),

                // PO Number
                Expanded(
                  flex: _kPoFlex,
                  child: Text(
                    o.poNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A3AFF),
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Supplier
                Expanded(
                  flex: _kSupFlex,
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A3AFF).withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.business_outlined,
                          color: Color(0xFF4A3AFF),
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          o.supplier,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Date
                Expanded(
                  flex: _kDateFlex,
                  child: Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

                // Items
                Expanded(
                  flex: _kItemFlex,
                  child: Center(
                    child: Text(
                      '${o.itemCount}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),

                // Amount
                Expanded(
                  flex: _kAmtFlex,
                  child: Text(
                    _formatAmount(o.amount),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

                // Status badge
                Expanded(
                  flex: _kStsFlex,
                  child: Center(child: _StatusBadge(status: o.status)),
                ),

                // Modified By
                Expanded(
                  flex: _kModFlex,
                  child: ModifiedByCell(
                    name: mod.name,
                    date: mod.date,
                    textPrimary: colors.textPrimary,
                    textHint: colors.textHint,
                  ),
                ),

                // Actions: View, Edit, Delete
                Expanded(
                  flex: _kActFlex,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActBtn(
                        icon: Icons.remove_red_eye_outlined,
                        color: const Color(0xFF4A3AFF),
                        tooltip: 'View',
                        onTap: () {},
                      ),
                      const SizedBox(width: 5),
                      _ActBtn(
                        icon: Icons.edit_outlined,
                        color: const Color(0xFFF59E0B),
                        tooltip: 'Edit',
                        onTap: () {},
                      ),
                      const SizedBox(width: 5),
                      _ActBtn(
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
      ),
    );
  }

  String _month(int m) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m];
  }

  String _formatAmount(double v) {
    if (v >= 100000) {
      final lakh = v ~/ 100000;
      final thousands = (v % 100000) ~/ 1000;
      final rem = (v % 1000).toInt();
      if (thousands > 0) {
        return '₹$lakh,${thousands.toString().padLeft(2, '0')},${rem.toString().padLeft(3, '0')}';
      }
      return '₹$lakh,${rem.toString().padLeft(5, '0')}';
    }
    final s = v.toInt();
    if (s >= 1000) {
      final str = s.toString();
      return '₹${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return '₹$s';
  }
}

class _ActBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActBtn({
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
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
      ),
    );
  }
}

// Status Badge
class _StatusBadge extends StatelessWidget {
  final PurchaseStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case PurchaseStatus.received:
        bg = const Color(0xFF22C55E).withValues(alpha: 0.1);
        fg = const Color(0xFF22C55E);
        break;
      case PurchaseStatus.partial:
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.1);
        fg = const Color(0xFFF59E0B);
        break;
      case PurchaseStatus.pending:
        bg = const Color(0xFF4A3AFF).withValues(alpha: 0.1);
        fg = const Color(0xFF4A3AFF);
        break;
      case PurchaseStatus.cancelled:
        bg = const Color(0xFFEF4444).withValues(alpha: 0.1);
        fg = const Color(0xFFEF4444);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

// Empty State
class _EmptyState extends StatelessWidget {
  final AppThemeColors colors;
  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 40, color: colors.textHint),
            const SizedBox(height: 10),
            Text(
              'No purchases found',
              style: TextStyle(
                fontSize: 14,
                color: colors.textHint,
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
// Table Footer + Pagination
// ─────────────────────────────────────────────────────────────────────────────
class _TableFooter extends StatelessWidget {
  final int total,
      startDisplay,
      endDisplay,
      currentPage,
      totalPages,
      rowsPerPage;
  final AppThemeColors colors;
  final ValueChanged<int> onPageChanged, onRowsChanged;

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
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onRowsChanged(v);
                },
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Showing $startDisplay–$endDisplay of $total',
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: 12),
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
          ..._buildPageNums(),
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

  List<Widget> _buildPageNums() {
    final items = <Widget>[];
    final pages = <int>[];
    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        pages.add(i);
      }
    } else {
      pages.addAll([1, 2, 3]);
      if (currentPage > 4) pages.add(-1);
      if (currentPage > 3 && currentPage < totalPages - 1) {
        pages.add(currentPage);
      }
      pages.add(totalPages);
    }

    for (int i = 0; i < pages.length; i++) {
      final p = pages[i];
      if (i > 0) items.add(const SizedBox(width: 4));
      if (p == -1) {
        items.add(
          Text(
            '...',
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        );
      } else {
        final isActive = p == currentPage;
        items.add(
          InkWell(
            onTap: () => onPageChanged(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryOrange : colors.surface,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isActive ? AppColors.primaryOrange : colors.border,
                ),
              ),
              child: Center(
                child: Text(
                  '$p',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return items;
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final AppThemeColors colors;
  final VoidCallback onTap;
  const _PageBtn({
    required this.icon,
    required this.enabled,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
// Right Panel — Purchase Summary Card
// ─────────────────────────────────────────────────────────────────────────────
class _PurchaseSummaryCard extends StatelessWidget {
  final AppThemeColors colors;
  final PurchaseController c;
  const _PurchaseSummaryCard({required this.colors, required this.c});

  String _fmt(double v) {
    if (v >= 100000) {
      final lakh = v ~/ 100000;
      final thousands = (v % 100000) ~/ 1000;
      final rem = (v % 1000).toInt();
      if (thousands > 0) {
        return '₹$lakh,${thousands.toString().padLeft(2, '0')},${rem.toString().padLeft(3, '0')}';
      }
      return '₹$lakh,${rem.toString().padLeft(5, '0')}';
    }
    final s = v.toInt();
    if (s >= 1000) {
      final str = s.toString();
      return '₹${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return '₹$s';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Text(
                'Purchase Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            Divider(height: 1, color: colors.divider),
            _SumRow(
              label: 'Total Purchase Orders',
              value: '${c.totalOrders}',
              colors: colors,
            ),
            _SumRow(
              label: 'Total Purchase Amount',
              value: _fmt(c.totalPurchaseMTD),
              colors: colors,
            ),
            _SumRow(
              label: 'Total Paid',
              value: _fmt(c.totalAmountPaid),
              colors: colors,
              valueColor: const Color(0xFF22C55E),
            ),
            _SumRow(
              label: 'Total Due',
              value: _fmt(c.totalAmountDue),
              colors: colors,
              valueColor: const Color(0xFFEF4444),
            ),
            _SumRow(
              label: 'Average Order Value',
              value: _fmt(c.averageOrderValue),
              colors: colors,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  final String label, value;
  final AppThemeColors colors;
  final Color? valueColor;
  final bool isLast;
  const _SumRow({
    required this.label,
    required this.value,
    required this.colors,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.divider, width: 0.5),
              ),
            ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: colors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right Panel — Top Suppliers Card
// ─────────────────────────────────────────────────────────────────────────────
class _TopSuppliersCard extends StatelessWidget {
  final AppThemeColors colors;
  final PurchaseController c;
  const _TopSuppliersCard({required this.colors, required this.c});

  String _fmt(double v) {
    if (v >= 100000) {
      final lakh = v ~/ 100000;
      final thousands = (v % 100000) ~/ 1000;
      final rem = (v % 1000).toInt();
      if (thousands > 0) {
        return '₹$lakh,${thousands.toString().padLeft(2, '0')},${rem.toString().padLeft(3, '0')}';
      }
      return '₹$lakh,${rem.toString().padLeft(5, '0')}';
    }
    final s = v.toInt();
    if (s >= 1000) {
      final str = s.toString();
      return '₹${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return '₹$s';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final top = c.topSuppliers;
      return Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Top Suppliers',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  Text(
                    'View All',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.divider),
            ...top.asMap().entries.map((e) {
              final supplier = e.value.key;
              final amount = e.value.value;
              final isLast = e.key == top.length - 1;
              final orderCount = c.orders
                  .where((o) => o.supplier == supplier)
                  .length;

              return Container(
                decoration: isLast
                    ? null
                    : BoxDecoration(
                        border: Border(
                          bottom:
                              BorderSide(color: colors.divider, width: 0.5),
                        ),
                      ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A3AFF).withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _initials(supplier),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4A3AFF),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supplier,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: colors.textPrimary,
                              fontFamily: 'Poppins',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$orderCount Orders',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textHint,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _fmt(amount),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}

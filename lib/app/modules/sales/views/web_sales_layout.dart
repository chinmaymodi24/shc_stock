import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controllers/sales_controller.dart';
import '../models/sales_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/widgets/web_sidebar.dart';
import '../../../routes/app_routes.dart';

// ═════════════════════════════════════════════════════════════════════════════
// TABLE COLUMN CONSTANTS — used by BOTH _TableHeader and _SalesRow
// so they are always perfectly aligned.
// ═════════════════════════════════════════════════════════════════════════════
const double _kIdxWidth = 28.0; // # badge — fixed
const double _kColGap = 10.0; // gap between # badge and first flex col
const int _kSoFlex = 18; // SO Number
const int _kClientFlex = 26; // Client badge + name
const int _kDateFlex = 14; // Date
const int _kItemsFlex = 8; // Items (center)
const int _kAmtFlex = 16; // Amount
const int _kStatusFlex = 13; // Status badge (center)
const int _kPayFlex = 14; // Payment Status badge (center)
const int _kActFlex = 11; // Actions (center)

// ─────────────────────────────────────────────────────────────────────────────
// Sales List Page
// ─────────────────────────────────────────────────────────────────────────────
class WebSalesLayout extends GetView<SalesController> {
  const WebSalesLayout({super.key});

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
                _TopBar(colors: colors),
                Expanded(
                  child: Obx(() {
                    final all = c.orders;
                    final searchQuery = c.searchQuery.value;
                    final rowsPerPage = c.rowsPerPage.value;
                    final currentPage = c.currentPage.value;
                    final filtered = searchQuery.isEmpty
                        ? all.toList()
                        : all
                              .where(
                                (o) =>
                                    o.client.toLowerCase().contains(
                                      searchQuery.toLowerCase(),
                                    ) ||
                                    o.soNumber.toLowerCase().contains(
                                      searchQuery.toLowerCase(),
                                    ),
                              )
                              .toList();

                    final totalPages = filtered.isEmpty
                        ? 1
                        : (filtered.length / rowsPerPage).ceil();
                    final startIdx = (currentPage - 1) * rowsPerPage;
                    final endIdx = math.min(
                      startIdx + rowsPerPage,
                      filtered.length,
                    );
                    final pageItems = filtered.isEmpty
                        ? <SalesOrder>[]
                        : filtered.sublist(startIdx, endIdx);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Page Header ─────────────────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sales',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Manage all your sales orders and track your business performance.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colors.textSecondary,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _PrimaryBtn(
                                label: 'New Sales Order',
                                icon: Icons.add_rounded,
                                onTap: () => Get.toNamed(AppRoutes.addSale),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Stat Cards row ──────────────────────────────
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'Total Sales (MTD)',
                                    value: '₹ 24,85,600',
                                    icon: Icons.shopping_cart_outlined,
                                    iconColor: AppColors.primaryOrange,
                                    trend: '+18.6%',
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
                                    small: true,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Total Sales Orders',
                                    value: '${c.totalOrders}',
                                    icon: Icons.receipt_long_outlined,
                                    iconColor: const Color(0xFF4A3AFF),
                                    trend: '+12.5%',
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
                                    label: 'Total Amount Due',
                                    value: '₹ 3,25,400',
                                    icon: Icons.currency_rupee_rounded,
                                    iconColor: const Color(0xFFF59E0B),
                                    trend: '-8.3%',
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
                                    small: true,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Total Received (MTD)',
                                    value: '₹ 21,60,200',
                                    icon: Icons.check_circle_outline_rounded,
                                    iconColor: const Color(0xFF22C55E),
                                    trend: '+15.2%',
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
                                    small: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Body row: table + right panel ───────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── LEFT: Table card ────────────────────────
                              Expanded(
                                child: _TableCard(
                                  colors: colors,
                                  onSearch: (v) {
                                    c.searchQuery.value = v;
                                    c.currentPage.value = 1;
                                  },
                                  pageItems: pageItems,
                                  startIdx: startIdx,
                                  isLast: (i) => i == pageItems.length - 1,
                                  total: filtered.length,
                                  startDisplay: filtered.isEmpty
                                      ? 0
                                      : startIdx + 1,
                                  endDisplay: endIdx,
                                  currentPage: currentPage,
                                  totalPages: totalPages,
                                  rowsPerPage: rowsPerPage,
                                  onPageChanged: (p) => c.currentPage.value = p,
                                  onRowsChanged: (r) {
                                    c.rowsPerPage.value = r;
                                    c.currentPage.value = 1;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),

                              // ── RIGHT: Panel ─────────────────────────────
                              SizedBox(
                                width: 272,
                                child: Column(
                                  children: [
                                    _SalesSummaryCard(
                                      colors: colors,
                                      controller: c,
                                    ),
                                    const SizedBox(height: 14),
                                    _TopClientsCard(
                                      colors: colors,
                                      controller: c,
                                    ),
                                    const SizedBox(height: 14),
                                    _QuickActionsCard(colors: colors),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final AppThemeColors colors;
  const _TopBar({required this.colors});

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
          // Search box
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
          // Quick Action button
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
  final String label, value, trend;
  final IconData icon;
  final Color iconColor;
  final bool trendUp, small;
  final List<double> spark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.trend,
    required this.trendUp,
    required this.spark,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: small ? 16 : 24,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 5),
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
                          fontSize: 10,
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
    final lp = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fp = Paint()
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
// Table Card (toolbar + header + rows + footer)
// ─────────────────────────────────────────────────────────────────────────────
class _TableCard extends StatelessWidget {
  final AppThemeColors colors;
  final ValueChanged<String> onSearch;
  final List<SalesOrder> pageItems;
  final int startIdx,
      total,
      startDisplay,
      endDisplay,
      currentPage,
      totalPages,
      rowsPerPage;
  final bool Function(int) isLast;
  final ValueChanged<int> onPageChanged, onRowsChanged;

  const _TableCard({
    required this.colors,
    required this.onSearch,
    required this.pageItems,
    required this.startIdx,
    required this.isLast,
    required this.total,
    required this.startDisplay,
    required this.endDisplay,
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
    required this.onPageChanged,
    required this.onRowsChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          // Toolbar
          _Toolbar(colors: colors, onSearch: onSearch),
          Divider(height: 1, color: colors.divider),

          // Header
          _TableHeader(colors: colors),
          Divider(height: 1, color: colors.divider),

          // Rows
          if (pageItems.isEmpty)
            _EmptyState(colors: colors)
          else
            ...pageItems.asMap().entries.map(
              (e) => _SalesRow(
                order: e.value,
                displayIndex: startIdx + e.key + 1,
                colors: colors,
                isLast: isLast(e.key),
              ),
            ),

          // Footer
          Divider(height: 1, color: colors.divider),
          _Footer(
            colors: colors,
            total: total,
            startDisplay: startDisplay,
            endDisplay: endDisplay,
            currentPage: currentPage,
            totalPages: totalPages,
            rowsPerPage: rowsPerPage,
            onPageChanged: onPageChanged,
            onRowsChanged: onRowsChanged,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toolbar
// ─────────────────────────────────────────────────────────────────────────────
class _Toolbar extends StatelessWidget {
  final AppThemeColors colors;
  final ValueChanged<String> onSearch;
  const _Toolbar({required this.colors, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Search
          SizedBox(
            width: 240,
            height: 38,
            child: TextField(
              onChanged: onSearch,
              style: TextStyle(
                fontSize: 13,
                color: colors.textPrimary,
                fontFamily: 'Poppins',
              ),
              decoration: InputDecoration(
                hintText: 'Search sales orders...',
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
                  borderSide: const BorderSide(
                    color: AppColors.primaryOrange,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          _OutlineBtn(
            label: 'Filters',
            icon: Icons.tune_rounded,
            colors: colors,
          ),
          const SizedBox(width: 8),
          // Date range
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: colors.inputFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.date_range_rounded,
                  size: 15,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '01 May 2024 - 31 May 2024',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _OutlineBtn(
            label: 'Export',
            icon: Icons.upload_outlined,
            colors: colors,
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
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

class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final AppThemeColors colors;
  const _OutlineBtn({
    required this.label,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 15, color: colors.textSecondary),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontFamily: 'Poppins',
          color: colors.textSecondary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table Header — uses the same constants as _SalesRow
// ─────────────────────────────────────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  final AppThemeColors colors;
  const _TableHeader({required this.colors});

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
          // # column
          SizedBox(
            width: _kIdxWidth,
            child: Text('#', style: _s),
          ),
          SizedBox(width: _kColGap),
          // SO Number
          Expanded(
            flex: _kSoFlex,
            child: Text('SO Number', style: _s),
          ),
          // Client
          Expanded(
            flex: _kClientFlex,
            child: Text('Client', style: _s),
          ),
          // Date
          Expanded(
            flex: _kDateFlex,
            child: Text('Date', style: _s),
          ),
          // Items (center)
          Expanded(
            flex: _kItemsFlex,
            child: Center(child: Text('Items', style: _s)),
          ),
          // Amount
          Expanded(
            flex: _kAmtFlex,
            child: Text('Amount', style: _s),
          ),
          // Status (center)
          Expanded(
            flex: _kStatusFlex,
            child: Center(child: Text('Status', style: _s)),
          ),
          // Payment Status (center)
          Expanded(
            flex: _kPayFlex,
            child: Center(
              child: Text('Payment Status', style: _s.copyWith(fontSize: 11.5)),
            ),
          ),
          // Actions (center)
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
// Sales Row — uses the SAME constants as _TableHeader
// ─────────────────────────────────────────────────────────────────────────────
class _SalesRow extends StatefulWidget {
  final SalesOrder order;
  final int displayIndex;
  final AppThemeColors colors;
  final bool isLast;

  const _SalesRow({
    required this.order,
    required this.displayIndex,
    required this.colors,
    required this.isLast,
  });

  @override
  State<_SalesRow> createState() => _SalesRowState();
}

class _SalesRowState extends State<_SalesRow> {
  // Local, widget-scoped hover flag — kept as an Rx on the persistent State
  // object (not setState) so only the row's background repaints on hover.
  final _hovered = false.obs;

  @override
  void dispose() {
    _hovered.close();
    super.dispose();
  }

  static const _months = [
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

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month]} ${d.year}';

  String _fmtAmount(double v) {
    final i = v.toInt();
    if (i >= 100000) {
      final lakh = i ~/ 100000;
      final rest = i % 100000;
      final thou = rest ~/ 1000;
      final sub = rest % 1000;
      return '₹ $lakh,${thou.toString().padLeft(2, '0')},${sub.toString().padLeft(3, '0')}';
    }
    if (i >= 10000) {
      final s = i.toString();
      return '₹ ${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
    }
    return '₹ $i';
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final c = widget.colors;

    return MouseRegion(
      onEnter: (_) => _hovered.value = true,
      onExit: (_) => _hovered.value = false,
      child: Obx(
        () => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _hovered.value ? c.rowEven : c.surface,
            border: widget.isLast
                ? null
                : Border(bottom: BorderSide(color: c.divider, width: 0.8)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // # badge
                SizedBox(
                  width: _kIdxWidth,
                  child: Container(
                    width: _kIdxWidth,
                    height: _kIdxWidth,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.displayIndex}',
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
                SizedBox(width: _kColGap),

                // SO Number
                Expanded(
                  flex: _kSoFlex,
                  child: Text(
                    o.soNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A3AFF),
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Client
                Expanded(
                  flex: _kClientFlex,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: o.clientColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            o.clientBadge,
                            style: TextStyle(
                              fontSize: o.clientBadge.length > 2 ? 9.5 : 11,
                              fontWeight: FontWeight.w700,
                              color: o.clientColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          o.client,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: c.textPrimary,
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
                    _fmtDate(o.date),
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

                // Items
                Expanded(
                  flex: _kItemsFlex,
                  child: Center(
                    child: Text(
                      '${o.itemCount}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),

                // Amount
                Expanded(
                  flex: _kAmtFlex,
                  child: Text(
                    _fmtAmount(o.amount),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

                // Status badge
                Expanded(
                  flex: _kStatusFlex,
                  child: Center(
                    child: _Badge(label: o.status.label, color: o.status.color),
                  ),
                ),

                // Payment Status badge
                Expanded(
                  flex: _kPayFlex,
                  child: Center(
                    child: _Badge(
                      label: o.paymentStatus.label,
                      color: o.paymentStatus.color,
                    ),
                  ),
                ),

                // Actions
                Expanded(
                  flex: _kActFlex,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActionBtn(
                        icon: Icons.remove_red_eye_outlined,
                        color: const Color(0xFF4A3AFF),
                        bg: const Color(0xFF4A3AFF),
                        onTap: () {},
                      ),
                      const SizedBox(width: 6),
                      _ActionBtn(
                        icon: Icons.more_vert_rounded,
                        color: c.textSecondary,
                        bg: c.iconBgPurple,
                        onTap: () {},
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: color,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: icon == Icons.more_vert_rounded ? 'More' : 'View',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: bg.withValues(
              alpha: icon == Icons.more_vert_rounded ? 1.0 : 0.10,
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
      ),
    );
  }
}

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
            Icon(
              Icons.point_of_sale_outlined,
              size: 40,
              color: colors.textHint,
            ),
            const SizedBox(height: 10),
            Text(
              'No sales orders found',
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
// Table Footer
// ─────────────────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final AppThemeColors colors;
  final int total,
      startDisplay,
      endDisplay,
      currentPage,
      totalPages,
      rowsPerPage;
  final ValueChanged<int> onPageChanged, onRowsChanged;

  const _Footer({
    required this.colors,
    required this.total,
    required this.startDisplay,
    required this.endDisplay,
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
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
            'Showing $startDisplay to $endDisplay of $total sales orders',
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const Spacer(),
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
                dropdownColor: colors.surface,
                style: TextStyle(
                  fontSize: 12.5,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
                items: [5, 10, 20, 50]
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onRowsChanged(v);
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
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
          // numbered page buttons (up to 3 visible)
          ...List.generate(math.min(totalPages, 3), (i) {
            final page = i + 1;
            final isActive = page == currentPage;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                onTap: () => onPageChanged(page),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryOrange : colors.surface,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: isActive ? AppColors.primaryOrange : colors.border,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$page',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isActive ? Colors.white : colors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          // ellipsis
          if (totalPages > 3) ...[
            Text(
              '...',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => onPageChanged(totalPages),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: currentPage == totalPages
                      ? AppColors.primaryOrange
                      : colors.surface,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: currentPage == totalPages
                        ? AppColors.primaryOrange
                        : colors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$totalPages',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: currentPage == totalPages
                          ? Colors.white
                          : colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
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
// RIGHT PANEL — Sales Summary
// ─────────────────────────────────────────────────────────────────────────────
class _SalesSummaryCard extends StatelessWidget {
  final AppThemeColors colors;
  final SalesController controller;
  const _SalesSummaryCard({required this.colors, required this.controller});

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      colors: colors,
      title: 'Sales Summary',
      child: Column(
        children: [
          _SummaryRow(
            label: 'Total Sales Orders',
            value: '${controller.totalOrders}',
            colors: colors,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Total Sales Amount',
            value: '₹ 24,85,600',
            colors: colors,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Total Received',
            value: '₹ 21,60,200',
            colors: colors,
          ),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Total Due', value: '₹ 3,25,400', colors: colors),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Average Order Value',
            value: '₹ 15,932',
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final AppThemeColors colors;
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT PANEL — Top Clients
// ─────────────────────────────────────────────────────────────────────────────
class _TopClientsCard extends StatelessWidget {
  final AppThemeColors colors;
  final SalesController controller;
  const _TopClientsCard({required this.colors, required this.controller});

  String _fmtAmt(double v) {
    final i = v.toInt();
    if (i >= 100000) {
      final l = i ~/ 100000;
      final r = (i % 100000) ~/ 1000;
      return '₹ $l,${r.toString().padLeft(2, '0')},${((i % 1000)).toString().padLeft(3, '0')}';
    }
    final s = i.toString();
    return '₹ ${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      colors: colors,
      title: 'Top Clients',
      action: InkWell(
        onTap: () {},
        child: const Text(
          'View All',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryOrange,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      child: Column(
        children: controller.topClients
            .map(
              (tc) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Badge circle
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: tc.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          tc.badge,
                          style: TextStyle(
                            fontSize: tc.badge.length > 2 ? 9 : 11,
                            fontWeight: FontWeight.w800,
                            color: tc.color,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Name + orders
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tc.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                              fontFamily: 'Poppins',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${tc.orderCount} Orders',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Total amount
                    Text(
                      _fmtAmt(tc.totalAmount),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT PANEL — Quick Actions
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionsCard extends StatelessWidget {
  final AppThemeColors colors;
  const _QuickActionsCard({required this.colors});

  static const _actions = [
    (Icons.add_circle_outline_rounded, 'New Sales Order'),
    (Icons.receipt_outlined, 'Sales Invoice'),
    (Icons.local_shipping_outlined, 'Delivery Challan'),
    (Icons.undo_rounded, 'Sales Return'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      colors: colors,
      title: 'Quick Actions',
      child: Column(
        children: _actions.asMap().entries.map((e) {
          final isLast = e.key == _actions.length - 1;
          final item = e.value;
          return Column(
            children: [
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(item.$1, size: 18, color: colors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: colors.textHint,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast) Divider(height: 1, color: colors.divider),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// Shared panel card shell
class _PanelCard extends StatelessWidget {
  final AppThemeColors colors;
  final String title;
  final Widget child;
  final Widget? action;
  const _PanelCard({
    required this.colors,
    required this.title,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Primary Button helper
// ─────────────────────────────────────────────────────────────────────────────
class _PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        label,
        style: const TextStyle(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

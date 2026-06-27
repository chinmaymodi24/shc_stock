import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controllers/purchase_controller.dart';
import '../models/purchase_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/widgets/web_sidebar.dart';
import 'web_new_purchase_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
class WebPurchaseLayout extends StatefulWidget {
  const WebPurchaseLayout({super.key});

  @override
  State<WebPurchaseLayout> createState() => _WebPurchaseLayoutState();
}

class _WebPurchaseLayoutState extends State<WebPurchaseLayout> {
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
    final c = Get.find<PurchaseController>();
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
                    final filtered = _searchQuery.isEmpty
                        ? all.toList()
                        : all
                            .where((o) =>
                                o.supplier.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                o.poNumber.toLowerCase().contains(_searchQuery.toLowerCase()))
                            .toList();

                    final totalPages = filtered.isEmpty
                        ? 1
                        : (filtered.length / _rowsPerPage).ceil();
                    final startIdx = (_currentPage - 1) * _rowsPerPage;
                    final endIdx =
                        math.min(startIdx + _rowsPerPage, filtered.length);
                    final pageItems = filtered.isEmpty
                        ? <PurchaseOrder>[]
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
                                onPressed: () => Get.to(
                                  () => const WebNewPurchaseLayout(),
                                  transition: Transition.fadeIn,
                                ),
                                icon: const Icon(Icons.add_rounded,
                                    color: Colors.white, size: 18),
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
                                      horizontal: 20, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Stat Cards ────────────────────
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'Total Purchase Orders',
                                    value: '${c.totalOrders}',
                                    icon: Icons.receipt_long_outlined,
                                    iconColor: const Color(0xFF4A3AFF),
                                    trend: '+12.5%',
                                    trendUp: true,
                                    spark: const [0.3, 0.5, 0.4, 0.6, 0.5, 0.7, 0.65],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Total Purchase (MTD)',
                                    value: '₹ 12,45,000',
                                    icon: Icons.shopping_cart_outlined,
                                    iconColor: AppColors.primaryOrange,
                                    trend: '+18.6%',
                                    trendUp: true,
                                    spark: const [0.2, 0.4, 0.5, 0.6, 0.5, 0.7, 0.8],
                                    smallValue: true,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Total Amount Paid',
                                    value: '₹ 11,26,500',
                                    icon: Icons.check_circle_outline_rounded,
                                    iconColor: const Color(0xFF22C55E),
                                    trend: '+15.3%',
                                    trendUp: true,
                                    spark: const [0.25, 0.4, 0.5, 0.55, 0.6, 0.7, 0.75],
                                    smallValue: true,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Total Amount Due',
                                    value: '₹ 1,18,500',
                                    icon: Icons.currency_rupee_rounded,
                                    iconColor: const Color(0xFFF59E0B),
                                    trend: '-8.3%',
                                    trendUp: false,
                                    spark: const [0.7, 0.6, 0.55, 0.5, 0.4, 0.45, 0.35],
                                    smallValue: true,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Items Received (MTD)',
                                    value: '156',
                                    icon: Icons.inventory_2_outlined,
                                    iconColor: const Color(0xFF4A3AFF),
                                    trend: '+15.2%',
                                    trendUp: true,
                                    spark: const [0.3, 0.35, 0.5, 0.45, 0.6, 0.7, 0.75],
                                  ),
                                ),
                              ],
                            ),
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
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Toolbar row
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
                                _ColumnHeader(colors: colors),
                                Divider(height: 1, color: colors.divider),

                                // Data rows
                                if (pageItems.isEmpty)
                                  _EmptyState(colors: colors)
                                else
                                  ...pageItems.asMap().entries.map((e) {
                                    final globalIdx =
                                        startIdx + e.key;
                                    return _PurchaseRow(
                                      order: e.value,
                                      index: globalIdx,
                                      colors: colors,
                                      isLast: e.key == pageItems.length - 1,
                                    );
                                  }),

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
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'Ctrl + K',
                    style: TextStyle(
                        fontSize: 10,
                        color: colors.textSecondary,
                        fontFamily: 'Poppins'),
                  ),
                ),
              ],
            ),
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
              Text('Quick Action',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500)),
              SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
            ]),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
          Text('Admin',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins')),
          Icon(Icons.keyboard_arrow_down_rounded, color: colors.textSecondary, size: 18),
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
                  color: AppColors.primaryOrange, shape: BoxShape.circle),
              child: Center(
                child: Text(badge!,
                    style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins')),
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
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(value,
                    style: TextStyle(
                        fontSize: smallValue ? 16 : 24,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontFamily: 'Poppins')),
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
                    Text(trend,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: trendUp
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFEF4444),
                            fontFamily: 'Poppins')),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text('from last month',
                          style: TextStyle(
                              fontSize: 10,
                              color: colors.textHint,
                              fontFamily: 'Poppins'),
                          overflow: TextOverflow.ellipsis),
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
      final y = size.height -
          (points[i] * size.height * 0.8) -
          size.height * 0.05;
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(0, size.height);
        fill.lineTo(x, y);
      } else {
        final px = (i - 1) * stepX;
        final py = size.height -
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

// ─────────────────────────────────────────────────────────────────────────────
// Table Toolbar
// ─────────────────────────────────────────────────────────────────────────────
class _TableToolbar extends StatelessWidget {
  final AppThemeColors colors;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  const _TableToolbar(
      {required this.colors,
      required this.searchCtrl,
      required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Search
          SizedBox(
            width: 260,
            height: 38,
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearch,
              style: TextStyle(
                  fontSize: 13, color: colors.textPrimary, fontFamily: 'Poppins'),
              decoration: InputDecoration(
                hintText: 'Search purchases...',
                hintStyle: TextStyle(
                    fontSize: 13, color: colors.textHint, fontFamily: 'Poppins'),
                prefixIcon: Icon(Icons.search_rounded, color: colors.textHint, size: 17),
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

          // Filters button
          OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.tune_rounded, size: 15, color: colors.textSecondary),
            label: Text('Filters',
                style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    color: colors.textSecondary)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              side: BorderSide(color: colors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),

          // Date range picker chip
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
                Icon(Icons.date_range_rounded,
                    size: 15, color: colors.textSecondary),
                const SizedBox(width: 6),
                Text('01 May 2024 - 31 May 2024',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                        fontFamily: 'Poppins')),
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: colors.textSecondary),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Export
          OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.upload_outlined, size: 15, color: colors.textSecondary),
            label: Text('Export',
                style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    color: colors.textSecondary)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              side: BorderSide(color: colors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),

          // View toggle
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.inputFill,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(Icons.table_chart_outlined,
                size: 17, color: colors.textSecondary),
          ),
        ],
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
      letterSpacing: 0.1);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('#', style: _s)),
          const SizedBox(width: 10),
          Expanded(flex: 22, child: Text('PO Number', style: _s)),
          Expanded(flex: 30, child: Text('Supplier', style: _s)),
          Expanded(flex: 18, child: Text('Date', style: _s)),
          Expanded(
              flex: 10,
              child: Center(child: Text('Items', style: _s))),
          Expanded(
              flex: 18,
              child: Text('Amount', style: _s)),
          Expanded(
              flex: 14,
              child: Center(child: Text('Status', style: _s))),
          Expanded(
              flex: 14,
              child: Center(child: Text('Actions', style: _s))),
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

  const _PurchaseRow({
    required this.order,
    required this.index,
    required this.colors,
    required this.isLast,
  });

  @override
  State<_PurchaseRow> createState() => _PurchaseRowState();
}

class _PurchaseRowState extends State<_PurchaseRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final colors = widget.colors;
    final dateStr =
        '${o.date.day.toString().padLeft(2, '0')} ${_month(o.date.month)} ${o.date.year}';

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
              // # badge
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
              ),
              const SizedBox(width: 10),

              // PO Number
              Expanded(
                flex: 22,
                child: Text(
                  o.poNumber,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4A3AFF),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),

              // Supplier
              Expanded(
                flex: 30,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A3AFF).withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.business_outlined,
                          color: Color(0xFF4A3AFF), size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        o.supplier,
                        style: TextStyle(
                          fontSize: 13.5,
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
                flex: 18,
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),

              // Items
              Expanded(
                flex: 10,
                child: Center(
                  child: Text(
                    '${o.itemCount}',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),

              // Amount
              Expanded(
                flex: 18,
                child: Text(
                  '₹ ${_formatAmount(o.amount)}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),

              // Status badge
              Expanded(
                flex: 14,
                child: Center(child: _StatusBadge(status: o.status)),
              ),

              // Actions
              Expanded(
                flex: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Tooltip(
                      message: 'View',
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(7),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A3AFF).withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(Icons.remove_red_eye_outlined,
                              color: Color(0xFF4A3AFF), size: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'More',
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(7),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: colors.iconBgPurple,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(Icons.more_vert_rounded,
                              color: colors.textSecondary, size: 16),
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
    );
  }

  String _month(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m];
  }

  String _formatAmount(double v) {
    if (v >= 100000) {
      return '${(v / 100000).toStringAsFixed(0)},${((v % 100000) ~/ 1000).toString().padLeft(2, '0')},${(v % 1000).toInt().toString().padLeft(3, '0')}';
    }
    // simple comma for thousands
    final s = v.toInt();
    if (s >= 10000) {
      final str = s.toString();
      return '${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return s.toString();
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12.5,
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
            Text('No purchases found',
                style: TextStyle(
                    fontSize: 14, color: colors.textHint, fontFamily: 'Poppins')),
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
  final int total, startDisplay, endDisplay, currentPage, totalPages, rowsPerPage;
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
            'Showing $startDisplay to $endDisplay of $total purchases',
            style: TextStyle(
                fontSize: 12.5,
                color: colors.textSecondary,
                fontFamily: 'Poppins'),
          ),
          const Spacer(),
          Text('Rows per page:',
              style: TextStyle(
                  fontSize: 12.5,
                  color: colors.textSecondary,
                  fontFamily: 'Poppins')),
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
                    fontFamily: 'Poppins'),
                dropdownColor: colors.surface,
                items: [5, 10, 20, 50]
                    .map((v) =>
                        DropdownMenuItem(value: v, child: Text('$v')))
                    .toList(),
                onChanged: (v) { if (v != null) onRowsChanged(v); },
              ),
            ),
          ),
          const SizedBox(width: 16),
          _PageBtn(
              icon: Icons.first_page_rounded,
              enabled: currentPage > 1,
              colors: colors,
              onTap: () => onPageChanged(1)),
          const SizedBox(width: 4),
          _PageBtn(
              icon: Icons.chevron_left_rounded,
              enabled: currentPage > 1,
              colors: colors,
              onTap: () => onPageChanged(currentPage - 1)),
          const SizedBox(width: 6),
          // Page number buttons
          ...List.generate(math.min(totalPages, 3), (i) {
            final page = i + 1;
            final isActive = page == currentPage;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => onPageChanged(page),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryOrange : colors.surface,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                        color: isActive
                            ? AppColors.primaryOrange
                            : colors.border),
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
          const SizedBox(width: 2),
          _PageBtn(
              icon: Icons.chevron_right_rounded,
              enabled: currentPage < totalPages,
              colors: colors,
              onTap: () => onPageChanged(currentPage + 1)),
          const SizedBox(width: 4),
          _PageBtn(
              icon: Icons.last_page_rounded,
              enabled: currentPage < totalPages,
              colors: colors,
              onTap: () => onPageChanged(totalPages)),
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
        child: Icon(icon,
            size: 17,
            color: enabled ? colors.textPrimary : colors.textHint),
      ),
    );
  }
}

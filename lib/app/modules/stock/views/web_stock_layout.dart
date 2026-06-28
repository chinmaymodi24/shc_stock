import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controllers/stock_controller.dart';
import '../models/stock_item_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/widgets/web_sidebar.dart';

// ── Column width constants ─────────────────────────────────────────────────
const double _kIdxW   = 36.0;
const double _kGap    = 10.0;
const int    _kCodeF  = 10;
const int    _kNameF  = 22;
const int    _kCatF   = 16;
const int    _kUnitF  = 7;
const int    _kSihF   = 9;
const int    _kAvailF = 9;
const int    _kValF   = 12;
const int    _kStatF  = 10;
const int    _kActF   = 7;

// ─────────────────────────────────────────────────────────────────────────────
String _fmtNum(int v) {
  if (v == 0) return '0';
  final s = v.toString();
  if (v >= 10000) return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
  return s;
}

String _fmtAmt(double v) {
  final i = v.toInt();
  if (i == 0) return '₹ 0';
  final s = i.toString();
  if (s.length <= 3) return '₹ $s';
  if (s.length == 4) return '₹ ${s[0]},${s.substring(1)}';
  if (s.length == 5) return '₹ ${s.substring(0,2)},${s.substring(2)}';
  if (s.length == 6) return '₹ ${s.substring(0,1)},${s.substring(1,3)},${s.substring(3)}';
  if (s.length == 7) return '₹ ${s.substring(0,2)},${s.substring(2,4)},${s.substring(4)}';
  return '₹ $s';
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Widget
// ─────────────────────────────────────────────────────────────────────────────
class WebStockLayout extends StatefulWidget {
  const WebStockLayout({super.key});
  @override
  State<WebStockLayout> createState() => _WebStockLayoutState();
}

class _WebStockLayoutState extends State<WebStockLayout> {
  final _searchCtrl  = TextEditingController();
  String _search     = '';
  String _catFilter  = 'All Categories';
  String _statFilter = 'All Status';
  String _unitFilter = 'All Units';
  int    _rowsPerPage = 10;
  int    _currentPage = 1;

  static const _kStatuses = ['All Status', 'In Stock', 'Low Stock', 'Out of Stock', 'Inactive'];

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Row(children: [
        const WebSidebar(),
        Expanded(child: Column(children: [
          _TopBar(colors: colors),
          Expanded(child: Obx(() {
            final c = Get.find<StockController>();
            final all = c.items.toList();
            final filtered = all.where((item) {
              final q = _search.toLowerCase();
              if (q.isNotEmpty && !item.name.toLowerCase().contains(q) &&
                  !item.code.toLowerCase().contains(q) &&
                  !item.sku.toLowerCase().contains(q)) { return false; }
              if (_catFilter != 'All Categories' && item.category != _catFilter) { return false; }
              if (_statFilter != 'All Status' && item.statusLabel != _statFilter) { return false; }
              if (_unitFilter != 'All Units' && item.unit != _unitFilter) { return false; }
              return true;
            }).toList();

            final totalPages = filtered.isEmpty ? 1 : (filtered.length / _rowsPerPage).ceil();
            final startIdx   = (_currentPage - 1) * _rowsPerPage;
            final endIdx     = math.min(startIdx + _rowsPerPage, filtered.length);
            final pageItems  = filtered.isEmpty ? <StockItemModel>[] : filtered.sublist(startIdx, endIdx);

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
                        Text('Stock', style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700,
                          color: colors.textPrimary, fontFamily: 'Poppins')),
                        const SizedBox(height: 3),
                        Text('View and manage your stock items and inventory levels.',
                          style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Poppins')),
                      ]),
                      Row(children: [
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 17),
                          label: const Text('Add New Item', style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange, elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.upload_outlined, size: 17, color: colors.textSecondary),
                          label: Text('Import Stock', style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w500,
                            color: colors.textPrimary, fontFamily: 'Poppins')),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.border),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── 5 Stat Cards ─────────────────────────────────────────
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _StatCard(
                          label: 'Total Items', value: '${c.totalItems}',
                          icon: Icons.inventory_2_outlined,
                          iconColor: const Color(0xFF4A3AFF),
                          trend: '+12.5%', trendUp: true,
                          spark: const [0.3,0.45,0.4,0.55,0.5,0.65,0.7],
                        )),
                        const SizedBox(width: 14),
                        Expanded(child: _StatCard(
                          label: 'Total Stock Value', value: _fmtAmt(c.totalValue),
                          icon: Icons.currency_rupee_rounded,
                          iconColor: const Color(0xFF22C55E),
                          trend: '+18.4%', trendUp: true,
                          spark: const [0.3,0.35,0.5,0.5,0.6,0.7,0.8],
                          smallValue: true,
                        )),
                        const SizedBox(width: 14),
                        Expanded(child: _StatCard(
                          label: 'Low Stock Items', value: '${c.lowStockCount}',
                          icon: Icons.warning_amber_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          trend: '-8.3%', trendUp: false,
                          spark: const [0.7,0.6,0.55,0.5,0.45,0.4,0.35],
                        )),
                        const SizedBox(width: 14),
                        Expanded(child: _StatCard(
                          label: 'Out of Stock Items', value: '${c.outOfStockCount}',
                          icon: Icons.remove_shopping_cart_outlined,
                          iconColor: const Color(0xFFEF4444),
                          trend: '-14.3%', trendUp: false,
                          spark: const [0.6,0.55,0.5,0.45,0.4,0.35,0.3],
                        )),
                        const SizedBox(width: 14),
                        Expanded(child: _StatCard(
                          label: 'Stock in Hand (Qty)', value: _fmtNum(c.totalQty),
                          icon: Icons.warehouse_outlined,
                          iconColor: const Color(0xFF14B8A6),
                          trend: '+10.1%', trendUp: true,
                          spark: const [0.3,0.4,0.45,0.5,0.55,0.6,0.65],
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Body: Table + Right Panel ────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── LEFT: Table Card ──────────────────────────────────
                      Expanded(child: Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.divider),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Column(children: [
                          _Toolbar(
                            colors: colors,
                            searchCtrl: _searchCtrl,
                            onSearch: (v) => setState(() { _search = v; _currentPage = 1; }),
                            categories: c.categories,
                            units: c.units,
                            statuses: _kStatuses,
                            catFilter: _catFilter,
                            statFilter: _statFilter,
                            unitFilter: _unitFilter,
                            onCat: (v) => setState(() { _catFilter = v ?? _catFilter; _currentPage = 1; }),
                            onStat: (v) => setState(() { _statFilter = v ?? _statFilter; _currentPage = 1; }),
                            onUnit: (v) => setState(() { _unitFilter = v ?? _unitFilter; _currentPage = 1; }),
                          ),
                          Divider(height: 1, color: colors.divider),
                          _ColHeader(colors: colors),
                          Divider(height: 1, color: colors.divider),

                          if (pageItems.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(48),
                              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.inventory_2_outlined, size: 40, color: colors.textHint),
                                const SizedBox(height: 10),
                                Text('No stock items found', style: TextStyle(fontSize: 14, color: colors.textHint, fontFamily: 'Poppins')),
                              ])),
                            )
                          else
                            ...pageItems.asMap().entries.map((e) => _StockRow(
                              item: e.value,
                              displayIndex: startIdx + e.key + 1,
                              colors: colors,
                              isLast: e.key == pageItems.length - 1,
                            )),

                          Divider(height: 1, color: colors.divider),
                          _Footer(
                            total: filtered.length,
                            start: filtered.isEmpty ? 0 : startIdx + 1,
                            end: endIdx,
                            currentPage: _currentPage,
                            totalPages: totalPages,
                            rowsPerPage: _rowsPerPage,
                            colors: colors,
                            onPage: (p) => setState(() => _currentPage = p),
                            onRows: (r) => setState(() { _rowsPerPage = r; _currentPage = 1; }),
                          ),
                        ]),
                      )),

                      const SizedBox(width: 16),

                      // ── RIGHT: Panel ──────────────────────────────────────
                      SizedBox(width: 272, child: Column(children: [
                        _StockSummaryCard(c: c, colors: colors),
                        const SizedBox(height: 14),
                        _StockStatusCard(c: c, colors: colors),
                        const SizedBox(height: 14),
                        _QuickActionsCard(colors: colors),
                        const SizedBox(height: 14),
                        _PromoCard(),
                      ])),
                    ],
                  ),
                ],
              ),
            );
          })),
        ])),
      ]),
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
      decoration: BoxDecoration(color: colors.topBarBg, border: Border(bottom: BorderSide(color: colors.divider))),
      child: Row(children: [
        Container(
          width: 320, height: 38,
          decoration: BoxDecoration(color: colors.inputFill, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.border)),
          child: Row(children: [
            const SizedBox(width: 10),
            Icon(Icons.search_rounded, color: colors.textHint, size: 17),
            const SizedBox(width: 8),
            Expanded(child: Text('Search anything...', style: TextStyle(fontSize: 13, color: colors.textHint, fontFamily: 'Poppins'))),
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: colors.divider, borderRadius: BorderRadius.circular(5)),
              child: Text('Ctrl + K', style: TextStyle(fontSize: 10, color: colors.textSecondary, fontFamily: 'Poppins')),
            ),
          ]),
        ),
        const Spacer(),
        _IBtn(icon: Icons.notifications_outlined, badge: '3', colors: colors),
        const SizedBox(width: 8),
        _IBtn(icon: Icons.chat_bubble_outline_rounded, badge: '2', colors: colors),
        const SizedBox(width: 8),
        _IBtn(icon: Icons.calendar_today_outlined, colors: colors),
        const SizedBox(width: 14),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
          label: Row(children: const [
            Text('Quick Action', style: TextStyle(fontSize: 13, color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
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
        CircleAvatar(radius: 16,
          backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15),
          child: const Icon(Icons.person_rounded, color: AppColors.primaryOrange, size: 18)),
        const SizedBox(width: 8),
        Text('Admin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary, fontFamily: 'Poppins')),
        Icon(Icons.keyboard_arrow_down_rounded, color: colors.textSecondary, size: 18),
      ]),
    );
  }
}

class _IBtn extends StatelessWidget {
  final IconData icon; final String? badge; final AppThemeColors colors;
  const _IBtn({required this.icon, this.badge, required this.colors});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(width: 38, height: 38,
        decoration: BoxDecoration(color: colors.inputFill, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.border)),
        child: Icon(icon, color: colors.textSecondary, size: 19)),
      if (badge != null)
        Positioned(top: 0, right: 0, child: Container(
          width: 17, height: 17,
          decoration: const BoxDecoration(color: AppColors.primaryOrange, shape: BoxShape.circle),
          child: Center(child: Text(badge!, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Poppins'))))),
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
  const _StatCard({required this.label, required this.value, required this.icon,
    required this.iconColor, required this.trend, required this.trendUp,
    required this.spark, this.smallValue = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 38, height: 38,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 19)),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 11.5, color: colors.textSecondary, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: smallValue ? 16 : 22, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins')),
          const SizedBox(height: 5),
          Row(children: [
            Icon(trendUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 10, color: trendUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
            const SizedBox(width: 2),
            Text(trend, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600,
              color: trendUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444), fontFamily: 'Poppins')),
            const SizedBox(width: 3),
            Flexible(child: Text('from last month', style: TextStyle(fontSize: 10.5, color: colors.textHint, fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis)),
          ]),
        ])),
        SizedBox(width: 56, height: 44,
          child: CustomPaint(painter: _SparkPainter(points: spark, color: iconColor))),
      ]),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> points; final Color color;
  const _SparkPainter({required this.points, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final lp = Paint()..color = color..strokeWidth = 2.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final fp = Paint()..color = color.withValues(alpha: 0.10)..style = PaintingStyle.fill;
    final path = Path(); final fill = Path();
    final stepX = size.width / (points.length - 1);
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX; final y = size.height - (points[i] * size.height * 0.8) - size.height * 0.05;
      if (i == 0) { path.moveTo(x, y); fill.moveTo(0, size.height); fill.lineTo(x, y); }
      else {
        final px = (i-1)*stepX; final py = size.height - (points[i-1]*size.height*0.8) - size.height*0.05; final cx = (px+x)/2;
        path.cubicTo(cx, py, cx, y, x, y); fill.cubicTo(cx, py, cx, y, x, y);
      }
    }
    fill.lineTo(size.width, size.height); fill.close();
    canvas.drawPath(fill, fp); canvas.drawPath(path, lp);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Table Toolbar
// ─────────────────────────────────────────────────────────────────────────────
class _Toolbar extends StatelessWidget {
  final AppThemeColors colors;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final List<String> categories, units, statuses;
  final String catFilter, statFilter, unitFilter;
  final ValueChanged<String?> onCat, onStat, onUnit;

  const _Toolbar({
    required this.colors, required this.searchCtrl, required this.onSearch,
    required this.categories, required this.units, required this.statuses,
    required this.catFilter, required this.statFilter, required this.unitFilter,
    required this.onCat, required this.onStat, required this.onUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        SizedBox(
          width: 240, height: 36,
          child: TextField(
            controller: searchCtrl, onChanged: onSearch,
            style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Poppins'),
            decoration: InputDecoration(
              hintText: 'Search by product name, code, or SKU...',
              hintStyle: TextStyle(fontSize: 12, color: colors.textHint, fontFamily: 'Poppins'),
              prefixIcon: Icon(Icons.search_rounded, color: colors.textHint, size: 16),
              isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 8),
              filled: true, fillColor: colors.inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _DDBtn(value: catFilter, items: categories, onChanged: onCat, colors: colors),
        const SizedBox(width: 8),
        _DDBtn(value: statFilter, items: statuses, onChanged: onStat, colors: colors),
        const SizedBox(width: 8),
        _DDBtn(value: unitFilter, items: units, onChanged: onUnit, colors: colors),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () {},
          icon: Icon(Icons.tune_rounded, size: 14, color: colors.textSecondary),
          label: Text('Filters', style: TextStyle(fontSize: 12.5, fontFamily: 'Poppins', color: colors.textSecondary)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            side: BorderSide(color: colors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () {},
          icon: Icon(Icons.upload_outlined, size: 14, color: colors.textSecondary),
          label: Text('Export', style: TextStyle(fontSize: 12.5, fontFamily: 'Poppins', color: colors.textSecondary)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            side: BorderSide(color: colors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ]),
    );
  }
}

class _DDBtn extends StatelessWidget {
  final String value; final List<String> items; final ValueChanged<String?> onChanged; final AppThemeColors colors;
  const _DDBtn({required this.value, required this.items, required this.onChanged, required this.colors});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36, padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: colors.inputFill, border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isDense: true,
          style: TextStyle(fontSize: 12.5, color: colors.textPrimary, fontFamily: 'Poppins'),
          dropdownColor: colors.surface,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: colors.textSecondary),
          items: items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Column Header
// ─────────────────────────────────────────────────────────────────────────────
class _ColHeader extends StatelessWidget {
  final AppThemeColors colors;
  const _ColHeader({required this.colors});
  TextStyle get _s => TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary, fontFamily: 'Poppins', letterSpacing: 0.1);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        SizedBox(width: _kIdxW, child: Text('#', style: _s)),
        const SizedBox(width: _kGap),
        Expanded(flex: _kCodeF, child: Text('Item Code', style: _s)),
        Expanded(flex: _kNameF, child: Text('Item Name', style: _s)),
        Expanded(flex: _kCatF,  child: Text('Category', style: _s)),
        Expanded(flex: _kUnitF, child: Text('Unit', style: _s)),
        Expanded(flex: _kSihF,  child: Text('Stock In Hand', style: _s)),
        Expanded(flex: _kAvailF,child: Text('Available Stock', style: _s)),
        Expanded(flex: _kValF,  child: Text('Stock Value (₹)', style: _s)),
        Expanded(flex: _kStatF, child: Center(child: Text('Status', style: _s))),
        Expanded(flex: _kActF,  child: Center(child: Text('Actions', style: _s))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stock Table Row
// ─────────────────────────────────────────────────────────────────────────────
class _StockRow extends StatefulWidget {
  final StockItemModel item; final int displayIndex; final AppThemeColors colors; final bool isLast;
  const _StockRow({required this.item, required this.displayIndex, required this.colors, required this.isLast});
  @override State<_StockRow> createState() => _StockRowState();
}

class _StockRowState extends State<_StockRow> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final item = widget.item; final c = widget.colors;
    final availColor = item.status == StockStatus.inStock
        ? const Color(0xFF22C55E)
        : item.status == StockStatus.lowStock
            ? const Color(0xFFF59E0B)
            : item.status == StockStatus.outOfStock
                ? const Color(0xFFEF4444)
                : c.textHint;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hovered ? c.rowEven : c.surface,
          border: widget.isLast ? null : Border(bottom: BorderSide(color: c.divider, width: 0.8))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

            // # Badge
            Container(width: _kIdxW, height: _kIdxW,
              decoration: BoxDecoration(color: AppColors.primaryOrange.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(7)),
              child: Center(child: Text('${widget.displayIndex}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryOrange, fontFamily: 'Poppins')))),
            const SizedBox(width: _kGap),

            // Item Code (purple)
            Expanded(flex: _kCodeF, child: Text(item.code, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF4A3AFF), fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis)),

            // Item Name + SKU + thumbnail
            Expanded(flex: _kNameF, child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: c.comingSoonBadge, borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.inventory_2_outlined, size: 16, color: c.textHint)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(item.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.textPrimary, fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis),
                Text('SKU: ${item.sku}', style: TextStyle(fontSize: 11, color: c.textHint, fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis),
              ])),
            ])),

            // Category
            Expanded(flex: _kCatF, child: Text(item.category, style: TextStyle(fontSize: 12.5, color: c.textSecondary, fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis)),

            // Unit
            Expanded(flex: _kUnitF, child: Text(item.unit, style: TextStyle(fontSize: 13, color: c.textSecondary, fontFamily: 'Poppins'))),

            // Stock In Hand
            Expanded(flex: _kSihF, child: Text(_fmtNum(item.stockInHand), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary, fontFamily: 'Poppins'))),

            // Available Stock (colored)
            Expanded(flex: _kAvailF, child: Text(_fmtNum(item.availableStock), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: availColor, fontFamily: 'Poppins'))),

            // Stock Value
            Expanded(flex: _kValF, child: Text(_fmtAmt(item.stockValue), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.textPrimary, fontFamily: 'Poppins'))),

            // Status Badge
            Expanded(flex: _kStatF, child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: item.statusColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
              child: Text(item.statusLabel, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: item.statusColor, fontFamily: 'Poppins')),
            ))),

            // Actions
            Expanded(flex: _kActF, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _ActBtn(icon: Icons.remove_red_eye_outlined, color: const Color(0xFF4A3AFF), tooltip: 'View', colors: c),
              const SizedBox(width: 6),
              _ActBtn(icon: Icons.more_vert_rounded, color: c.textSecondary, tooltip: 'More', colors: c),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _ActBtn extends StatelessWidget {
  final IconData icon; final Color color; final String tooltip; final AppThemeColors colors;
  const _ActBtn({required this.icon, required this.color, required this.tooltip, required this.colors});
  @override
  Widget build(BuildContext context) {
    return Tooltip(message: tooltip,
      child: InkWell(onTap: () {}, borderRadius: BorderRadius.circular(7),
        child: Container(width: 30, height: 30,
          decoration: BoxDecoration(color: colors.iconBgPurple, borderRadius: BorderRadius.circular(7)),
          child: Icon(icon, color: color, size: 15))));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer Pagination
// ─────────────────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final int total, start, end, currentPage, totalPages, rowsPerPage;
  final AppThemeColors colors;
  final ValueChanged<int> onPage, onRows;
  const _Footer({required this.total, required this.start, required this.end,
    required this.currentPage, required this.totalPages, required this.rowsPerPage,
    required this.colors, required this.onPage, required this.onRows});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        Text('Showing $start to $end of $total items',
          style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontFamily: 'Poppins')),
        const Spacer(),
        Text('Rows per page:', style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontFamily: 'Poppins')),
        const SizedBox(width: 8),
        Container(height: 32, padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(6), color: colors.surface),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(value: rowsPerPage, isDense: true,
              style: TextStyle(fontSize: 12.5, color: colors.textPrimary, fontFamily: 'Poppins'),
              dropdownColor: colors.surface,
              items: [5,10,20,50].map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
              onChanged: (v) { if (v != null) onRows(v); }))),
        const SizedBox(width: 16),
        _PBtn(icon: Icons.first_page_rounded, enabled: currentPage > 1, colors: colors, onTap: () => onPage(1)),
        const SizedBox(width: 4),
        _PBtn(icon: Icons.chevron_left_rounded, enabled: currentPage > 1, colors: colors, onTap: () => onPage(currentPage - 1)),
        const SizedBox(width: 6),
        ..._buildPages(),
        const SizedBox(width: 6),
        _PBtn(icon: Icons.chevron_right_rounded, enabled: currentPage < totalPages, colors: colors, onTap: () => onPage(currentPage + 1)),
        const SizedBox(width: 4),
        _PBtn(icon: Icons.last_page_rounded, enabled: currentPage < totalPages, colors: colors, onTap: () => onPage(totalPages)),
      ]),
    );
  }

  List<Widget> _buildPages() {
    final result = <Widget>[];
    final pages = <int>[];
    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) { pages.add(i); }
    } else {
      pages.addAll([1,2,3]);
      if (currentPage > 4) pages.add(-1);
      if (currentPage > 3 && currentPage < totalPages - 1) pages.add(currentPage);
      pages.add(totalPages);
    }
    for (int i = 0; i < pages.length; i++) {
      if (i > 0) result.add(const SizedBox(width: 4));
      final p = pages[i];
      if (p == -1) {
        result.add(Text('...', style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Poppins')));
      } else {
        final isA = p == currentPage;
        result.add(GestureDetector(onTap: () => onPage(p),
          child: AnimatedContainer(duration: const Duration(milliseconds: 150),
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: isA ? AppColors.primaryOrange : colors.surface,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: isA ? AppColors.primaryOrange : colors.border)),
            child: Center(child: Text('$p', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: isA ? Colors.white : colors.textPrimary, fontFamily: 'Poppins'))))));
      }
    }
    return result;
  }
}

class _PBtn extends StatelessWidget {
  final IconData icon; final bool enabled; final AppThemeColors colors; final VoidCallback onTap;
  const _PBtn({required this.icon, required this.enabled, required this.colors, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: enabled ? onTap : null,
      child: Container(width: 30, height: 30,
        decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(6), color: colors.surface),
        child: Icon(icon, size: 17, color: enabled ? colors.textPrimary : colors.textHint)));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right Panel — Stock Summary
// ─────────────────────────────────────────────────────────────────────────────
class _StockSummaryCard extends StatelessWidget {
  final StockController c; final AppThemeColors colors;
  const _StockSummaryCard({required this.c, required this.colors});
  @override
  Widget build(BuildContext context) {
    return _RCard(title: 'Stock Summary', colors: colors, child: Column(children: [
      _SR(label: 'Total Items', value: '${c.totalItems}', colors: colors),
      _SR(label: 'Stock In Hand (Qty)', value: _fmtNum(c.totalQty), colors: colors),
      _SR(label: 'Total Stock Value', value: _fmtAmt(c.totalValue), colors: colors),
      _SR(label: 'Low Stock Items', value: '${c.lowStockCount}', colors: colors, valueColor: const Color(0xFFF59E0B)),
      _SR(label: 'Out of Stock Items', value: '${c.outOfStockCount}', colors: colors, valueColor: const Color(0xFFEF4444), isLast: true),
    ]));
  }
}

class _SR extends StatelessWidget {
  final String label, value; final AppThemeColors colors; final Color? valueColor; final bool isLast;
  const _SR({required this.label, required this.value, required this.colors, this.valueColor, this.isLast = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isLast ? null : BoxDecoration(border: Border(bottom: BorderSide(color: colors.divider, width: 0.5))),
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontFamily: 'Poppins'))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? colors.textPrimary, fontFamily: 'Poppins')),
      ]));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right Panel — Stock Status (Donut Chart)
// ─────────────────────────────────────────────────────────────────────────────
class _StockStatusCard extends StatelessWidget {
  final StockController c; final AppThemeColors colors;
  const _StockStatusCard({required this.c, required this.colors});
  @override
  Widget build(BuildContext context) {
    return _RCard(title: 'Stock Status', colors: colors, child: Column(children: [
      // Donut
      SizedBox(
        height: 160,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(
            size: const Size(140, 140),
            painter: _DonutPainter(
              inStock: c.inStockCount, lowStock: c.lowStockCount,
              outOfStock: c.outOfStockCount, inactive: c.inactiveCount,
              total: c.totalItems)),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${c.totalItems}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.textPrimary, fontFamily: 'Poppins')),
            Text('Total Items', style: TextStyle(fontSize: 11, color: colors.textHint, fontFamily: 'Poppins')),
          ]),
        ]),
      ),
      const SizedBox(height: 10),
      // Legend
      _legRow('In Stock',    c.inStockCount,    c.totalItems, const Color(0xFF22C55E)),
      _legRow('Low Stock',   c.lowStockCount,   c.totalItems, const Color(0xFFF59E0B)),
      _legRow('Out of Stock',c.outOfStockCount, c.totalItems, const Color(0xFFEF4444)),
      _legRow('Inactive',    c.inactiveCount,   c.totalItems, const Color(0xFF94A3B8)),
    ]));
  }

  Widget _legRow(String label, int count, int total, Color color) {
    final pct = total == 0 ? 0.0 : (count / total) * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontFamily: 'Poppins'))),
        Text('$count', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins')),
        const SizedBox(width: 4),
        Text('(${pct.toStringAsFixed(1)}%)', style: TextStyle(fontSize: 11, color: colors.textHint, fontFamily: 'Poppins')),
      ]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final int inStock, lowStock, outOfStock, inactive, total;
  const _DonutPainter({required this.inStock, required this.lowStock, required this.outOfStock, required this.inactive, required this.total});
  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    const strokeW = 22.0;
    final rect = Rect.fromCenter(center: Offset(size.width/2, size.height/2), width: size.width - strokeW, height: size.height - strokeW);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = strokeW..strokeCap = StrokeCap.butt;
    double start = -math.pi / 2;
    void arc(int n, Color color) {
      if (n <= 0) return;
      final sweep = (n / total) * math.pi * 2;
      paint.color = color;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
    arc(inStock,    const Color(0xFF22C55E));
    arc(lowStock,   const Color(0xFFF59E0B));
    arc(outOfStock, const Color(0xFFEF4444));
    arc(inactive,   const Color(0xFF94A3B8));
    // Remaining (if any)
    final remaining = total - inStock - lowStock - outOfStock - inactive;
    if (remaining > 0) { arc(remaining, const Color(0xFFE2E8F0)); }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Right Panel — Quick Actions
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionsCard extends StatelessWidget {
  final AppThemeColors colors;
  const _QuickActionsCard({required this.colors});
  @override
  Widget build(BuildContext context) {
    return _RCard(title: 'Quick Actions', colors: colors, child: Column(children: [
      _QA(icon: Icons.add_box_outlined, label: 'Add New Item', iconColor: AppColors.primaryOrange, colors: colors),
      _QA(icon: Icons.tune_rounded, label: 'Stock Adjustment', iconColor: const Color(0xFF4A3AFF), colors: colors),
      _QA(icon: Icons.swap_horiz_rounded, label: 'Stock Transfer', iconColor: const Color(0xFF22C55E), colors: colors),
      _QA(icon: Icons.upload_file_outlined, label: 'Import Stock', iconColor: const Color(0xFF14B8A6), colors: colors),
      _QA(icon: Icons.assessment_outlined, label: 'Stock Report', iconColor: const Color(0xFFF59E0B), colors: colors, isLast: true),
    ]));
  }
}

class _QA extends StatefulWidget {
  final IconData icon; final String label; final Color iconColor; final AppThemeColors colors; final bool isLast;
  const _QA({required this.icon, required this.label, required this.iconColor, required this.colors, this.isLast = false});
  @override State<_QA> createState() => _QAState();
}
class _QAState extends State<_QA> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hov = true), onExit: (_) => setState(() => _hov = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(color: _hov ? widget.colors.rowEven : Colors.transparent),
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          Icon(widget.icon, color: widget.iconColor, size: 17),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: widget.colors.textPrimary, fontFamily: 'Poppins'))),
          Icon(Icons.chevron_right_rounded, color: widget.colors.textHint, size: 17),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right Panel — Promo Card (blue)
// ─────────────────────────────────────────────────────────────────────────────
class _PromoCard extends StatelessWidget {
  const _PromoCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A3AFF), Color(0xFF6366F1)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Keep your stock updated', style: TextStyle(
            fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins')),
          const SizedBox(height: 6),
          Text('Regular stock updates help you manage inventory better.',
            style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.8), fontFamily: 'Poppins', height: 1.4)),
        ])),
        const SizedBox(width: 10),
        Icon(Icons.inventory_2_rounded, color: Colors.white.withValues(alpha: 0.85), size: 40),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Right Panel Card Shell
// ─────────────────────────────────────────────────────────────────────────────
class _RCard extends StatelessWidget {
  final String title; final Widget child; final AppThemeColors colors;
  const _RCard({required this.title, required this.child, required this.colors});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins'))),
        Divider(height: 1, color: colors.divider),
        Padding(padding: const EdgeInsets.all(14), child: child),
      ]));
  }
}

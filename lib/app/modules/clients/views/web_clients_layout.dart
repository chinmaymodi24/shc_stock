import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controllers/clients_controller.dart';
import '../models/client_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../dashboard/widgets/web_sidebar.dart';

// ── Table column constants (header + row MUST match) ──────────────────────
const double _kIdxW     = 36.0;  // # badge
const double _kGap      = 10.0;  // column gap
const int    _kCodeFlex = 12;    // CLT-0001
const int    _kNameFlex = 22;    // Client Name + badge
const int    _kContFlex = 15;    // Contact Person
const int    _kMailFlex = 22;    // Email
const int    _kPhonFlex = 15;    // Phone
const int    _kOutFlex  = 15;    // Outstanding (₹)
const int    _kStatFlex = 10;    // Status badge
const int    _kActFlex  = 8;     // Actions

// ─────────────────────────────────────────────────────────────────────────────
// Main Widget
// ─────────────────────────────────────────────────────────────────────────────
class WebClientsLayout extends StatefulWidget {
  const WebClientsLayout({super.key});
  @override
  State<WebClientsLayout> createState() => _WebClientsLayoutState();
}

class _WebClientsLayoutState extends State<WebClientsLayout> {
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
    final c      = Get.find<ClientsController>();
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Row(children: [
        const WebSidebar(),
        Expanded(child: Column(children: [
          _TopBar(colors: colors),
          Expanded(child: Obx(() {
            final all      = c.clients;
            final filtered = _searchQuery.isEmpty
                ? all.toList()
                : all.where((cl) =>
                    cl.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    cl.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    cl.contactPerson.toLowerCase().contains(_searchQuery.toLowerCase()))
                  .toList();

            final totalPages = filtered.isEmpty ? 1 : (filtered.length / _rowsPerPage).ceil();
            final startIdx   = (_currentPage - 1) * _rowsPerPage;
            final endIdx     = math.min(startIdx + _rowsPerPage, filtered.length);
            final pageItems  = filtered.isEmpty
                ? <ClientModel>[]
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
                        Text('Clients', style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700,
                          color: colors.textPrimary, fontFamily: 'Poppins')),
                        const SizedBox(height: 3),
                        Text('Manage your clients and track their business relationship.',
                          style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Poppins')),
                      ]),
                      ElevatedButton.icon(
                        onPressed: () => Get.toNamed(AppRoutes.addClient),
                        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        label: const Text('Add New Client', style: TextStyle(
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
                          label: 'Total Clients',
                          value: '${c.totalClients}',
                          icon: Icons.people_outline_rounded,
                          iconColor: AppColors.primaryOrange,
                          trend: '+18.6%', trendUp: true,
                          spark: const [0.3, 0.5, 0.4, 0.6, 0.55, 0.7, 0.65],
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _StatCard(
                          label: 'Active Clients',
                          value: '${c.activeClients}',
                          icon: Icons.person_outline_rounded,
                          iconColor: const Color(0xFF4A3AFF),
                          trend: '+12.3%', trendUp: true,
                          spark: const [0.3, 0.4, 0.5, 0.45, 0.6, 0.55, 0.7],
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _StatCard(
                          label: 'Total Sales (MTD)',
                          value: _fmtAmt(c.totalSalesMTD),
                          icon: Icons.work_outline_rounded,
                          iconColor: const Color(0xFF22C55E),
                          trend: '+15.2%', trendUp: true,
                          spark: const [0.3, 0.35, 0.5, 0.45, 0.6, 0.7, 0.8],
                          smallValue: true,
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _StatCard(
                          label: 'Outstanding Amount',
                          value: _fmtAmt(c.totalOutstanding),
                          icon: Icons.currency_rupee_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          trend: '-8.3%', trendUp: false,
                          spark: const [0.7, 0.65, 0.55, 0.5, 0.4, 0.45, 0.35],
                          smallValue: true,
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Body: Table + Right Panel ────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── LEFT: Table Card ─────────────────────────────────
                      Expanded(child: Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.divider),
                          boxShadow: [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Column(children: [
                          // Toolbar
                          _Toolbar(
                            colors: colors, searchCtrl: _searchCtrl,
                            onSearch: (v) => setState(() { _searchQuery = v; _currentPage = 1; }),
                          ),
                          Divider(height: 1, color: colors.divider),

                          // Column Header
                          _ColumnHeader(colors: colors),
                          Divider(height: 1, color: colors.divider),

                          // Rows
                          if (pageItems.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(48),
                              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.person_search_rounded, size: 40, color: colors.textHint),
                                const SizedBox(height: 10),
                                Text('No clients found', style: TextStyle(
                                  fontSize: 14, color: colors.textHint, fontFamily: 'Poppins')),
                              ])),
                            )
                          else
                            ...pageItems.asMap().entries.map((e) => _ClientRow(
                              client: e.value,
                              displayIndex: startIdx + e.key + 1,
                              colors: colors,
                              isLast: e.key == pageItems.length - 1,
                            )),

                          // Footer
                          Divider(height: 1, color: colors.divider),
                          _Footer(
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
                      )),

                      const SizedBox(width: 16),

                      // ── RIGHT: Panel ─────────────────────────────────────
                      SizedBox(width: 272, child: Column(children: [
                        _ClientSummaryCard(colors: colors, c: c),
                        const SizedBox(height: 14),
                        _TopClientsCard(colors: colors, c: c),
                        const SizedBox(height: 14),
                        _QuickActionsCard(colors: colors),
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
// Amount formatter
// ─────────────────────────────────────────────────────────────────────────────
String _fmtAmt(double v) {
  final i = v.toInt();
  if (i == 0) return '₹ 0';
  if (i >= 1000000) {
    final l = i ~/ 100000;
    final r = i % 100000;
    final t = r ~/ 1000;
    final s = r % 1000;
    return '₹ $l,${t.toString().padLeft(2,'0')},${s.toString().padLeft(3,'0')}';
  }
  if (i >= 100000) {
    final l = i ~/ 100000;
    final r = i % 100000;
    final t = r ~/ 1000;
    final s = r % 1000;
    return '₹ $l,${t.toString().padLeft(2,'0')},${s.toString().padLeft(3,'0')}';
  }
  if (i >= 10000) {
    final s = i.toString();
    return '₹ ${s.substring(0,s.length-3)},${s.substring(s.length-3)}';
  }
  return '₹ $i';
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
        border: Border(bottom: BorderSide(color: colors.divider))),
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
        _IconBtn(icon: Icons.notifications_outlined, badge: '3', colors: colors),
        const SizedBox(width: 8),
        _IconBtn(icon: Icons.chat_bubble_outline_rounded, badge: '2', colors: colors),
        const SizedBox(width: 8),
        _IconBtn(icon: Icons.calendar_today_outlined, colors: colors),
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
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15),
          child: const Icon(Icons.person_rounded, color: AppColors.primaryOrange, size: 18),
        ),
        const SizedBox(width: 8),
        Text('Admin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary, fontFamily: 'Poppins')),
        Icon(Icons.keyboard_arrow_down_rounded, color: colors.textSecondary, size: 18),
      ]),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final AppThemeColors colors;
  const _IconBtn({required this.icon, this.badge, required this.colors});

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
                  size: 11, color: trendUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
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
            child: CustomPaint(painter: _SparkPainter(points: spark, color: iconColor)),
          ),
        ],
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> points;
  final Color color;
  const _SparkPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final lp = Paint()..color = color..strokeWidth = 2.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final fp = Paint()..color = color.withValues(alpha: 0.10)..style = PaintingStyle.fill;
    final path = Path(); final fill = Path();
    final stepX = size.width / (points.length - 1);
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - (points[i] * size.height * 0.8) - size.height * 0.05;
      if (i == 0) { path.moveTo(x, y); fill.moveTo(0, size.height); fill.lineTo(x, y); }
      else {
        final px = (i-1)*stepX;
        final py = size.height - (points[i-1]*size.height*0.8) - size.height*0.05;
        final cx = (px+x)/2;
        path.cubicTo(cx, py, cx, y, x, y);
        fill.cubicTo(cx, py, cx, y, x, y);
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
class _Toolbar extends StatefulWidget {
  final AppThemeColors colors;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  const _Toolbar({required this.colors, required this.searchCtrl, required this.onSearch});
  @override State<_Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<_Toolbar> {
  String _clientType = 'Client Type: All';

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        // Search
        SizedBox(
          width: 250, height: 38,
          child: TextField(
            controller: widget.searchCtrl,
            onChanged: widget.onSearch,
            style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Poppins'),
            decoration: InputDecoration(
              hintText: 'Search clients...',
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

        // Filters button
        OutlinedButton.icon(
          onPressed: () {},
          icon: Icon(Icons.tune_rounded, size: 15, color: colors.textSecondary),
          label: Text('Filters', style: TextStyle(fontSize: 13, fontFamily: 'Poppins', color: colors.textSecondary)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            side: BorderSide(color: colors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
        const SizedBox(width: 8),

        // Client Type dropdown
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colors.inputFill,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _clientType,
              isDense: true,
              style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Poppins'),
              dropdownColor: colors.surface,
              icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: colors.textSecondary),
              items: ['Client Type: All', 'Active', 'Inactive']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) { if (v != null) setState(() => _clientType = v); },
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Export button
        OutlinedButton.icon(
          onPressed: () {},
          icon: Icon(Icons.upload_outlined, size: 15, color: colors.textSecondary),
          label: Text('Export', style: TextStyle(fontSize: 13, fontFamily: 'Poppins', color: colors.textSecondary)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            side: BorderSide(color: colors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
        const SizedBox(width: 8),

        // Grid icon
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

// ─────────────────────────────────────────────────────────────────────────────
// Table Column Header
// ─────────────────────────────────────────────────────────────────────────────
class _ColumnHeader extends StatelessWidget {
  final AppThemeColors colors;
  const _ColumnHeader({required this.colors});

  TextStyle get _s => TextStyle(
    fontSize: 12.5, fontWeight: FontWeight.w600,
    color: colors.textSecondary, fontFamily: 'Poppins', letterSpacing: 0.1);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: [
        SizedBox(width: _kIdxW, child: Text('#', style: _s)),
        const SizedBox(width: _kGap),
        Expanded(flex: _kCodeFlex, child: Text('Client Code', style: _s)),
        Expanded(flex: _kNameFlex, child: Text('Client Name', style: _s)),
        Expanded(flex: _kContFlex, child: Text('Contact Person', style: _s)),
        Expanded(flex: _kMailFlex, child: Text('Email', style: _s)),
        Expanded(flex: _kPhonFlex, child: Text('Phone', style: _s)),
        Expanded(flex: _kOutFlex, child: Text('Outstanding (₹)', style: _s)),
        Expanded(flex: _kStatFlex, child: Center(child: Text('Status', style: _s))),
        Expanded(flex: _kActFlex, child: Center(child: Text('Actions', style: _s))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Client Table Row
// ─────────────────────────────────────────────────────────────────────────────
class _ClientRow extends StatefulWidget {
  final ClientModel client;
  final int displayIndex;
  final AppThemeColors colors;
  final bool isLast;
  const _ClientRow({required this.client, required this.displayIndex, required this.colors, required this.isLast});
  @override State<_ClientRow> createState() => _ClientRowState();
}

class _ClientRowState extends State<_ClientRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cl = widget.client;
    final c  = widget.colors;
    final outstandingColor = cl.outstanding > 0
        ? const Color(0xFFEF4444)
        : const Color(0xFF22C55E);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _hovered ? c.rowEven : c.surface,
          border: widget.isLast ? null
              : Border(bottom: BorderSide(color: c.divider, width: 0.8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

            // # badge
            Container(
              width: _kIdxW, height: _kIdxW,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(7)),
              child: Center(child: Text('${widget.displayIndex}', style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: AppColors.primaryOrange, fontFamily: 'Poppins'))),
            ),
            const SizedBox(width: _kGap),

            // Client Code
            Expanded(flex: _kCodeFlex, child: Text(cl.code, style: const TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w600,
              color: Color(0xFF4A3AFF), fontFamily: 'Poppins'),
              overflow: TextOverflow.ellipsis)),

            // Client Name + initials badge
            Expanded(flex: _kNameFlex, child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: cl.badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(cl.initials, style: TextStyle(
                  fontSize: cl.initials.length > 2 ? 9.5 : 11,
                  fontWeight: FontWeight.w700,
                  color: cl.badgeColor, fontFamily: 'Poppins'))),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(cl.name, style: TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w500,
                color: c.textPrimary, fontFamily: 'Poppins'),
                overflow: TextOverflow.ellipsis)),
            ])),

            // Contact Person
            Expanded(flex: _kContFlex, child: Text(cl.contactPerson, style: TextStyle(
              fontSize: 13, color: c.textSecondary, fontFamily: 'Poppins'),
              overflow: TextOverflow.ellipsis)),

            // Email
            Expanded(flex: _kMailFlex, child: Text(cl.email, style: TextStyle(
              fontSize: 12.5, color: c.textSecondary, fontFamily: 'Poppins'),
              overflow: TextOverflow.ellipsis)),

            // Phone
            Expanded(flex: _kPhonFlex, child: Text(cl.phone, style: TextStyle(
              fontSize: 12.5, color: c.textSecondary, fontFamily: 'Poppins'))),

            // Outstanding (₹) — colored
            Expanded(flex: _kOutFlex, child: Text(
              cl.outstanding == 0 ? '₹ 0' : _fmtAmt(cl.outstanding),
              style: TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w600,
                color: outstandingColor, fontFamily: 'Poppins'))),

            // Status badge
            Expanded(flex: _kStatFlex, child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cl.isActive
                    ? const Color(0xFF22C55E).withValues(alpha: 0.10)
                    : c.comingSoonBadge,
                borderRadius: BorderRadius.circular(20)),
              child: Text(cl.isActive ? 'Active' : 'Inactive', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: cl.isActive ? const Color(0xFF22C55E) : c.textSecondary,
                fontFamily: 'Poppins')),
            ))),

            // Actions
            Expanded(flex: _kActFlex, child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActBtn(icon: Icons.remove_red_eye_outlined, color: const Color(0xFF4A3AFF), tooltip: 'View', onTap: () {}),
                const SizedBox(width: 6),
                _ActBtn(icon: Icons.more_vert_rounded, color: c.textSecondary, tooltip: 'More', onTap: () {}),
              ],
            )),
          ]),
        ),
      ),
    );
  }
}

class _ActBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActBtn({required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: colors.iconBgPurple,
            borderRadius: BorderRadius.circular(7)),
          child: Icon(icon, color: color, size: 15),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table Footer with Pagination
// ─────────────────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final int total, startDisplay, endDisplay, currentPage, totalPages, rowsPerPage;
  final AppThemeColors colors;
  final ValueChanged<int> onPageChanged, onRowsChanged;

  const _Footer({
    required this.total, required this.startDisplay, required this.endDisplay,
    required this.currentPage, required this.totalPages, required this.rowsPerPage,
    required this.colors, required this.onPageChanged, required this.onRowsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Text('Showing $startDisplay to $endDisplay of $total clients',
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
        _PBtn(icon: Icons.first_page_rounded, enabled: currentPage > 1, colors: colors, onTap: () => onPageChanged(1)),
        const SizedBox(width: 4),
        _PBtn(icon: Icons.chevron_left_rounded, enabled: currentPage > 1, colors: colors, onTap: () => onPageChanged(currentPage - 1)),
        const SizedBox(width: 6),
        ..._buildPageNums(),
        const SizedBox(width: 6),
        _PBtn(icon: Icons.chevron_right_rounded, enabled: currentPage < totalPages, colors: colors, onTap: () => onPageChanged(currentPage + 1)),
        const SizedBox(width: 4),
        _PBtn(icon: Icons.last_page_rounded, enabled: currentPage < totalPages, colors: colors, onTap: () => onPageChanged(totalPages)),
      ]),
    );
  }

  List<Widget> _buildPageNums() {
    final items = <Widget>[];
    // Show up to 3 page numbers + ellipsis + last page
    final pages = <int>[];
    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) { pages.add(i); }
    } else {
      pages.addAll([1, 2, 3]);
      if (currentPage > 4) pages.add(-1); // ellipsis
      if (currentPage > 3 && currentPage < totalPages - 1) pages.add(currentPage);
      pages.add(totalPages);
    }

    for (int i = 0; i < pages.length; i++) {
      final p = pages[i];
      if (i > 0) items.add(const SizedBox(width: 4));
      if (p == -1) {
        items.add(Text('...', style: TextStyle(
          fontSize: 13, color: colors.textSecondary, fontFamily: 'Poppins')));
      } else {
        final isActive = p == currentPage;
        items.add(GestureDetector(
          onTap: () => onPageChanged(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryOrange : colors.surface,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: isActive ? AppColors.primaryOrange : colors.border)),
            child: Center(child: Text('$p', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : colors.textPrimary,
              fontFamily: 'Poppins'))),
          ),
        ));
      }
    }
    return items;
  }
}

class _PBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final AppThemeColors colors;
  final VoidCallback onTap;
  const _PBtn({required this.icon, required this.enabled, required this.colors, required this.onTap});

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
// Right Panel — Client Summary Card
// ─────────────────────────────────────────────────────────────────────────────
class _ClientSummaryCard extends StatelessWidget {
  final AppThemeColors colors;
  final ClientsController c;
  const _ClientSummaryCard({required this.colors, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Text('Client Summary', style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: colors.textPrimary, fontFamily: 'Poppins')),
        ),
        Divider(height: 1, color: colors.divider),
        _SumRow(label: 'Total Clients', value: '${c.totalClients}', colors: colors),
        _SumRow(label: 'Active Clients', value: '${c.activeClients}', colors: colors),
        _SumRow(label: 'Inactive Clients', value: '${c.inactiveClients}', colors: colors),
        _SumRow(label: 'Outstanding Amount', value: _fmtAmt(c.totalOutstanding), colors: colors, valueColor: const Color(0xFFEF4444)),
        _SumRow(label: 'Total Sales (MTD)', value: _fmtAmt(c.totalSalesMTD), colors: colors, valueColor: const Color(0xFF22C55E)),
        _SumRow(label: 'Average Order Value', value: _fmtAmt(c.avgOrderValue), colors: colors, isLast: true),
      ]),
    );
  }
}

class _SumRow extends StatelessWidget {
  final String label, value;
  final AppThemeColors colors;
  final Color? valueColor;
  final bool isLast;
  const _SumRow({required this.label, required this.value, required this.colors, this.valueColor, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isLast ? null : BoxDecoration(border: Border(bottom: BorderSide(color: colors.divider, width: 0.5))),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(
          fontSize: 12.5, color: colors.textSecondary, fontFamily: 'Poppins'))),
        Text(value, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: valueColor ?? colors.textPrimary, fontFamily: 'Poppins')),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right Panel — Top Clients Card
// ─────────────────────────────────────────────────────────────────────────────
class _TopClientsCard extends StatelessWidget {
  final AppThemeColors colors;
  final ClientsController c;
  const _TopClientsCard({required this.colors, required this.c});

  @override
  Widget build(BuildContext context) {
    final top = c.topClients;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Top Clients', style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: colors.textPrimary, fontFamily: 'Poppins')),
              Text('By Sales MTD', style: TextStyle(
                fontSize: 11, color: colors.textHint, fontFamily: 'Poppins')),
            ])),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Text('View All', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.primaryOrange, fontFamily: 'Poppins')),
            ),
          ]),
        ),
        Divider(height: 1, color: colors.divider),
        ...top.asMap().entries.map((e) {
          final cl = e.value;
          return Container(
            decoration: e.key == top.length - 1 ? null : BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.divider, width: 0.5))),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: cl.badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(cl.initials, style: TextStyle(
                  fontSize: cl.initials.length > 2 ? 9.0 : 10.5,
                  fontWeight: FontWeight.w700,
                  color: cl.badgeColor, fontFamily: 'Poppins'))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(cl.name, style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w500,
                color: colors.textPrimary, fontFamily: 'Poppins'),
                overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 6),
              Text(_fmtAmt(cl.salesMTD), style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: colors.textPrimary, fontFamily: 'Poppins')),
            ]),
          );
        }),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right Panel — Quick Actions Card
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionsCard extends StatelessWidget {
  final AppThemeColors colors;
  const _QuickActionsCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Text('Quick Actions', style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: colors.textPrimary, fontFamily: 'Poppins')),
        ),
        Divider(height: 1, color: colors.divider),
        _QAction(icon: Icons.person_add_outlined, label: 'Add New Client', iconColor: AppColors.primaryOrange, colors: colors),
        Divider(height: 1, color: colors.divider),
        _QAction(icon: Icons.receipt_long_outlined, label: 'Client Ledger Report', iconColor: const Color(0xFF4A3AFF), colors: colors),
        Divider(height: 1, color: colors.divider),
        _QAction(icon: Icons.warning_amber_rounded, label: 'Outstanding Report', iconColor: const Color(0xFFF59E0B), colors: colors, isLast: true),
      ]),
    );
  }
}

class _QAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final AppThemeColors colors;
  final bool isLast;
  const _QAction({required this.icon, required this.label, required this.iconColor, required this.colors, this.isLast = false});
  @override State<_QAction> createState() => _QActionState();
}

class _QActionState extends State<_QAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: _hovered ? c.rowEven : Colors.transparent,
          borderRadius: widget.isLast
              ? const BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14))
              : BorderRadius.zero),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Icon(widget.icon, color: widget.iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: c.textPrimary, fontFamily: 'Poppins'))),
          Icon(Icons.chevron_right_rounded, color: c.textHint, size: 18),
        ]),
      ),
    );
  }
}

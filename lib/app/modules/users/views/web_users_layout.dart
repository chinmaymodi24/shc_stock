import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controllers/users_controller.dart';
import '../models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../dashboard/widgets/web_sidebar.dart';
import '../../dashboard/widgets/modified_by_cell.dart';

// ── Table column flex constants ────────────────────────────────────────────
const double _kIdxW = 36.0;
const double _kGap = 10.0;
const int _kCodeFlex = 11;
const int _kNameFlex = 20;
const int _kMailFlex = 18;
const int _kPhonFlex = 12;
const int _kRoleFlex = 14;
const int _kLoginFlex = 14;
const int _kStatFlex = 9;
const int _kModFlex = 16;
const int _kActFlex = 8;

// ─────────────────────────────────────────────────────────────────────────────
// Main Widget
// ─────────────────────────────────────────────────────────────────────────────
class WebUsersLayout extends GetView<UsersController> {
  const WebUsersLayout({super.key});

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
                    final all = c.users;
                    final searchQuery = c.searchQuery.value;
                    final filterRole = c.filterRole.value;
                    final filterStatus = c.filterStatus.value;
                    final rowsPerPage = c.rowsPerPage.value;
                    final currentPage = c.currentPage.value;

                    // Apply search + role + status filter
                    final filtered = all.where((u) {
                      final q = searchQuery.toLowerCase();
                      final matchSearch =
                          q.isEmpty ||
                          u.name.toLowerCase().contains(q) ||
                          u.code.toLowerCase().contains(q) ||
                          u.email.toLowerCase().contains(q) ||
                          u.role.label.toLowerCase().contains(q);
                      final matchRole =
                          filterRole == 'All Roles' ||
                          u.role.label == filterRole;
                      final matchStatus =
                          filterStatus == 'All Status' ||
                          (filterStatus == 'Active' && u.isActive) ||
                          (filterStatus == 'Inactive' && !u.isActive);
                      return matchSearch && matchRole && matchStatus;
                    }).toList();

                    final totalPages = filtered.isEmpty
                        ? 1
                        : (filtered.length / rowsPerPage).ceil();
                    final startIdx = (currentPage - 1) * rowsPerPage;
                    final endIdx = math.min(
                      startIdx + rowsPerPage,
                      filtered.length,
                    );
                    final pageItems = filtered.isEmpty
                        ? <UserModel>[]
                        : filtered.sublist(startIdx, endIdx);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Page Header ────────────────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Employees',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Manage employees and their access roles.',
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
                                    Get.toNamed(AppRoutes.addEmployee),
                                icon: const Icon(
                                  Icons.person_add_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Add New Employee',
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

                          // ── Stat Cards ─────────────────────────────────────────────
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    label: 'Total Employees',
                                    value: '${c.totalUsers}',
                                    icon: Icons.group_outlined,
                                    iconColor: AppColors.primaryOrange,
                                    trend: '+12.5%',
                                    trendUp: true,
                                    spark: const [
                                      0.4,
                                      0.55,
                                      0.5,
                                      0.65,
                                      0.6,
                                      0.75,
                                      0.7,
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Active Employees',
                                    value: '${c.activeUsers}',
                                    icon: Icons.person_outline_rounded,
                                    iconColor: const Color(0xFF22C55E),
                                    trend: '+8.3%',
                                    trendUp: true,
                                    spark: const [
                                      0.3,
                                      0.4,
                                      0.5,
                                      0.45,
                                      0.6,
                                      0.55,
                                      0.7,
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Admins',
                                    value: '${c.adminCount}',
                                    icon: Icons.admin_panel_settings_outlined,
                                    iconColor: const Color(0xFF4A3AFF),
                                    trend: '0.0%',
                                    trendUp: true,
                                    spark: const [
                                      0.5,
                                      0.5,
                                      0.5,
                                      0.5,
                                      0.5,
                                      0.5,
                                      0.5,
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Inactive Employees',
                                    value: '${c.inactiveUsers}',
                                    icon: Icons.person_off_outlined,
                                    iconColor: const Color(0xFFEF4444),
                                    trend: '-5.0%',
                                    trendUp: false,
                                    spark: const [
                                      0.6,
                                      0.55,
                                      0.5,
                                      0.45,
                                      0.4,
                                      0.38,
                                      0.35,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Body: Table + Right Panel ──────────────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── LEFT: Table Card ─────────────────────────────────
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
                                      _Toolbar(
                                        colors: colors,
                                        searchCtrl: c.searchCtrl,
                                        filterRole: filterRole,
                                        filterStatus: filterStatus,
                                        onSearch: (v) {
                                          c.searchQuery.value = v;
                                          c.currentPage.value = 1;
                                        },
                                        onRoleChanged: (v) {
                                          c.filterRole.value = v;
                                          c.currentPage.value = 1;
                                        },
                                        onStatusChanged: (v) {
                                          c.filterStatus.value = v;
                                          c.currentPage.value = 1;
                                        },
                                      ),
                                      Divider(height: 1, color: colors.divider),

                                      // Column header
                                      _ColumnHeader(colors: colors),
                                      Divider(height: 1, color: colors.divider),

                                      // Rows
                                      if (pageItems.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.all(48),
                                          child: Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.manage_search_rounded,
                                                  size: 40,
                                                  color: colors.textHint,
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  'No employees found',
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
                                        ...pageItems.asMap().entries.map(
                                          (e) => _UserRow(
                                            user: e.value,
                                            displayIndex: startIdx + e.key + 1,
                                            colors: colors,
                                            isLast:
                                                e.key == pageItems.length - 1,
                                          ),
                                        ),

                                      // Footer / pagination
                                      Divider(height: 1, color: colors.divider),
                                      _Footer(
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

                              // ── RIGHT: Panel ─────────────────────────────────────
                              SizedBox(
                                width: 272,
                                child: Column(
                                  children: [
                                    _UserSummaryCard(colors: colors, c: c),
                                    const SizedBox(height: 14),
                                    _RoleBreakdownCard(colors: colors, c: c),
                                    const SizedBox(height: 14),
                                    _QuickActionsCard(
                                      colors: colors,
                                      onAddUser: () =>
                                          Get.toNamed(AppRoutes.addEmployee),
                                    ),
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
// Dialog Text Field
// ─────────────────────────────────────────────────────────────────────────────
class _DialogField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final AppThemeColors colors;
  const _DialogField({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: TextStyle(
            fontSize: 13,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: colors.textHint,
              fontFamily: 'Poppins',
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
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
      ],
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
          Container(
            width: 300,
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
          _IconBtn(
            icon: Icons.notifications_outlined,
            badge: '3',
            colors: colors,
          ),
          const SizedBox(width: 8),
          _IconBtn(
            icon: Icons.chat_bubble_outline_rounded,
            badge: '2',
            colors: colors,
          ),
          const SizedBox(width: 8),
          _IconBtn(icon: Icons.calendar_today_outlined, colors: colors),
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

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final AppThemeColors colors;
  const _IconBtn({required this.icon, this.badge, required this.colors});

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
// Stat Card
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value, trend;
  final IconData icon;
  final Color iconColor;
  final bool trendUp;
  final List<double> spark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.trend,
    required this.trendUp,
    required this.spark,
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
                    fontSize: 26,
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
          SizedBox(
            width: 64,
            height: 52,
            child: CustomPaint(
              painter: _SparkPainter(points: spark, color: iconColor),
            ),
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
    final lp = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
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
// Toolbar
// ─────────────────────────────────────────────────────────────────────────────
class _Toolbar extends StatelessWidget {
  final AppThemeColors colors;
  final TextEditingController searchCtrl;
  final String filterRole, filterStatus;
  final ValueChanged<String> onSearch, onRoleChanged, onStatusChanged;

  const _Toolbar({
    required this.colors,
    required this.searchCtrl,
    required this.filterRole,
    required this.filterStatus,
    required this.onSearch,
    required this.onRoleChanged,
    required this.onStatusChanged,
  });

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
              controller: searchCtrl,
              onChanged: onSearch,
              style: TextStyle(
                fontSize: 13,
                color: colors.textPrimary,
                fontFamily: 'Poppins',
              ),
              decoration: InputDecoration(
                hintText: 'Search employees...',
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

          // Role filter
          _DropFilter(
            value: filterRole,
            items: ['All Roles', ...UserRole.values.map((r) => r.label)],
            colors: colors,
            onChanged: onRoleChanged,
          ),
          const SizedBox(width: 8),

          // Status filter
          _DropFilter(
            value: filterStatus,
            items: const ['All Status', 'Active', 'Inactive'],
            colors: colors,
            onChanged: onStatusChanged,
          ),
          const SizedBox(width: 8),

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
        ],
      ),
    );
  }
}

class _DropFilter extends StatelessWidget {
  final String value;
  final List<String> items;
  final AppThemeColors colors;
  final ValueChanged<String> onChanged;
  const _DropFilter({
    required this.value,
    required this.items,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.inputFill,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: TextStyle(
            fontSize: 13,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
          dropdownColor: colors.surface,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: colors.textSecondary,
          ),
          items: items
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
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
          SizedBox(
            width: _kIdxW,
            child: Text('#', style: _s),
          ),
          const SizedBox(width: _kGap),
          Expanded(
            flex: _kCodeFlex,
            child: Text('User Code', style: _s),
          ),
          Expanded(
            flex: _kNameFlex,
            child: Text('Name', style: _s),
          ),
          Expanded(
            flex: _kMailFlex,
            child: Text('Email', style: _s),
          ),
          Expanded(
            flex: _kPhonFlex,
            child: Text('Phone', style: _s),
          ),
          Expanded(
            flex: _kRoleFlex,
            child: Text('Role', style: _s),
          ),
          Expanded(
            flex: _kLoginFlex,
            child: Text('Last Login', style: _s),
          ),
          Expanded(
            flex: _kStatFlex,
            child: Center(child: Text('Status', style: _s)),
          ),
          Expanded(
            flex: _kModFlex,
            child: Text('Modified By', style: _s),
          ),
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
// User Table Row
// ─────────────────────────────────────────────────────────────────────────────
class _UserRow extends StatefulWidget {
  final UserModel user;
  final int displayIndex;
  final AppThemeColors colors;
  final bool isLast;
  const _UserRow({
    required this.user,
    required this.displayIndex,
    required this.colors,
    required this.isLast,
  });
  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
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
    final u = widget.user;
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // # badge
                Container(
                  width: _kIdxW,
                  height: _kIdxW,
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
                const SizedBox(width: _kGap),

                // User code
                Expanded(
                  flex: _kCodeFlex,
                  child: Text(
                    u.code,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A3AFF),
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Name + initials avatar
                Expanded(
                  flex: _kNameFlex,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: u.badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            u.initials,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: u.badgeColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          u.name,
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

                // Email
                Expanded(
                  flex: _kMailFlex,
                  child: Text(
                    u.email,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: c.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Phone
                Expanded(
                  flex: _kPhonFlex,
                  child: Text(
                    u.phone,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: c.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

                // Role badge
                Expanded(
                  flex: _kRoleFlex,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: u.role.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(u.role.icon, size: 12, color: u.role.color),
                            const SizedBox(width: 5),
                            Text(
                              u.role.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: u.role.color,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Last Login
                Expanded(
                  flex: _kLoginFlex,
                  child: Text(
                    u.lastLogin,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Status badge
                Expanded(
                  flex: _kStatFlex,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: u.isActive
                            ? const Color(0xFF22C55E).withValues(alpha: 0.10)
                            : c.comingSoonBadge,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        u.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: u.isActive
                              ? const Color(0xFF22C55E)
                              : c.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ),

                // Modified By
                Expanded(
                  flex: _kModFlex,
                  child: Builder(
                    builder: (_) {
                      final mod = resolveModifiedBy(
                        seedId: u.id,
                        storedName: u.modifiedBy,
                        storedDate: u.modifiedAt,
                      );
                      return ModifiedByCell(
                        name: mod.name,
                        date: mod.date,
                        textPrimary: c.textPrimary,
                        textHint: c.textHint,
                      );
                    },
                  ),
                ),

                // Actions
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
                      const SizedBox(width: 6),
                      _ActBtn(
                        icon: Icons.edit_outlined,
                        color: AppColors.primaryOrange,
                        tooltip: 'Edit',
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
    final colors = context.appColors;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: colors.iconBgPurple,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table Footer / Pagination
// ─────────────────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final int total,
      startDisplay,
      endDisplay,
      currentPage,
      totalPages,
      rowsPerPage;
  final AppThemeColors colors;
  final ValueChanged<int> onPageChanged, onRowsChanged;

  const _Footer({
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
            'Showing $startDisplay to $endDisplay of $total employees',
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
          const SizedBox(width: 16),
          _PBtn(
            icon: Icons.first_page_rounded,
            enabled: currentPage > 1,
            colors: colors,
            onTap: () => onPageChanged(1),
          ),
          const SizedBox(width: 4),
          _PBtn(
            icon: Icons.chevron_left_rounded,
            enabled: currentPage > 1,
            colors: colors,
            onTap: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 6),
          ..._buildPageNums(),
          const SizedBox(width: 6),
          _PBtn(
            icon: Icons.chevron_right_rounded,
            enabled: currentPage < totalPages,
            colors: colors,
            onTap: () => onPageChanged(currentPage + 1),
          ),
          const SizedBox(width: 4),
          _PBtn(
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
      if (currentPage > 3 && currentPage < totalPages - 1)
        pages.add(currentPage);
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

class _PBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final AppThemeColors colors;
  final VoidCallback onTap;
  const _PBtn({
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
// Right Panel — Employee Summary Card
// ─────────────────────────────────────────────────────────────────────────────
class _UserSummaryCard extends StatelessWidget {
  final AppThemeColors colors;
  final UsersController c;
  const _UserSummaryCard({required this.colors, required this.c});

  @override
  Widget build(BuildContext context) {
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
            child: Text(
              'Employee Summary',
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
            label: 'Total Employees',
            value: '${c.totalUsers}',
            colors: colors,
          ),
          _SumRow(
            label: 'Active Employees',
            value: '${c.activeUsers}',
            colors: colors,
            valueColor: const Color(0xFF22C55E),
          ),
          _SumRow(
            label: 'Inactive Employees',
            value: '${c.inactiveUsers}',
            colors: colors,
            valueColor: const Color(0xFFEF4444),
          ),
          _SumRow(
            label: 'Admins',
            value: '${c.adminCount}',
            colors: colors,
            valueColor: AppColors.primaryOrange,
            isLast: true,
          ),
        ],
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
// Right Panel — Role Breakdown Card
// ─────────────────────────────────────────────────────────────────────────────
class _RoleBreakdownCard extends StatelessWidget {
  final AppThemeColors colors;
  final UsersController c;
  const _RoleBreakdownCard({required this.colors, required this.c});

  @override
  Widget build(BuildContext context) {
    final breakdown = c.roleBreakdown;
    final total = c.totalUsers;

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
            child: Text(
              'Role Breakdown',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Divider(height: 1, color: colors.divider),
          ...UserRole.values.asMap().entries.map((e) {
            final role = e.value;
            final count = breakdown[role] ?? 0;
            final pct = total == 0 ? 0.0 : count / total;
            final isLast = e.key == UserRole.values.length - 1;

            return Container(
              decoration: isLast
                  ? null
                  : BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colors.divider, width: 0.5),
                      ),
                    ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: role.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          role.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colors.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: colors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(role.color),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right Panel — Quick Actions Card
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionsCard extends StatelessWidget {
  final AppThemeColors colors;
  final VoidCallback onAddUser;
  const _QuickActionsCard({required this.colors, required this.onAddUser});

  @override
  Widget build(BuildContext context) {
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
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Divider(height: 1, color: colors.divider),
          _QAction(
            icon: Icons.person_add_outlined,
            label: 'Add New Employee',
            iconColor: AppColors.primaryOrange,
            colors: colors,
            onTap: onAddUser,
          ),
          Divider(height: 1, color: colors.divider),
          _QAction(
            icon: Icons.upload_outlined,
            label: 'Export Employee List',
            iconColor: const Color(0xFF4A3AFF),
            colors: colors,
            onTap: () {},
          ),
          Divider(height: 1, color: colors.divider),
          _QAction(
            icon: Icons.lock_reset_outlined,
            label: 'Reset Permissions',
            iconColor: const Color(0xFFF59E0B),
            colors: colors,
            onTap: () {},
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _QAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final AppThemeColors colors;
  final VoidCallback onTap;
  final bool isLast;
  const _QAction({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.colors,
    required this.onTap,
    this.isLast = false,
  });
  @override
  State<_QAction> createState() => _QActionState();
}

class _QActionState extends State<_QAction> {
  // Local, widget-scoped hover flag — kept as an Rx on the persistent State
  // object (not setState) so only the background repaints on hover.
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
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _hovered.value = true,
      onExit: (_) => _hovered.value = false,
      child: InkWell(
        onTap: widget.onTap,
        child: Obx(
          () => AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: _hovered.value ? c.rowEven : Colors.transparent,
              borderRadius: widget.isLast
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    )
                  : BorderRadius.zero,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(widget.icon, color: widget.iconColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.textHint, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:shc_stock/app/modules/users/controllers/users_controller.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/modules/users/models/user_model.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/modified_by_cell.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/table_footer.dart';
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';

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
const int _kActFlex = 18; // View + Edit + Delete (Delete added later)

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
                const WebTopBar(),
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
                                  child: AppStatCard(
                                    label: 'Total Employees',
                                    value: '${c.totalUsers}',
                                    icon: Icons.group_outlined,
                                    iconColor: AppColors.primaryOrange,
                                    trend: c.stats.value.trendLabel(
                                      'totalUsers',
                                    ),
                                    trendUp: c.stats.value.trendUp(
                                      'totalUsers',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppStatCard(
                                    label: 'Active Employees',
                                    value: '${c.activeUsers}',
                                    icon: Icons.person_outline_rounded,
                                    iconColor: const Color(0xFF22C55E),
                                    trend: c.stats.value.trendLabel(
                                      'activeUsers',
                                    ),
                                    trendUp: c.stats.value.trendUp(
                                      'activeUsers',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppStatCard(
                                    label: 'Admins',
                                    value: '${c.adminCount}',
                                    icon: Icons.admin_panel_settings_outlined,
                                    iconColor: const Color(0xFF4A3AFF),
                                    trend: c.stats.value.trendLabel(
                                      'adminCount',
                                    ),
                                    trendUp: c.stats.value.trendUp(
                                      'adminCount',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppStatCard(
                                    label: 'Inactive Employees',
                                    value: '${c.inactiveUsers}',
                                    icon: Icons.person_off_outlined,
                                    iconColor: const Color(0xFFEF4444),
                                    trend: c.stats.value.trendLabel(
                                      'inactiveUsers',
                                    ),
                                    trendUp: c.stats.value.trendUp(
                                      'inactiveUsers',
                                    ),
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
                                      if (c.isLoading.value)
                                        const AppLoadingIndicator(
                                          label: 'Loading employees...',
                                          padding: 40,
                                        )
                                      else if (pageItems.isEmpty)
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
                                      AppTableFooter(
                                        summaryText:
                                            'Showing ${filtered.isEmpty ? 0 : startIdx + 1} to $endIdx of ${filtered.length} employees',
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
      child: FilterBar(
        search: FilterSearchField(
          controller: searchCtrl,
          hint: 'Search employees...',
          width: 240,
          onChanged: onSearch,
        ),
        pills: [
          SingleSelectFilterPill(
            value: filterRole,
            items: ['All Roles', ...UserRole.values.map((r) => r.label)],
            onChanged: onRoleChanged,
          ),
          SingleSelectFilterPill(
            value: filterStatus,
            items: const ['All Status', 'Active', 'Inactive'],
            onChanged: onStatusChanged,
          ),
        ],
        clearAll: Obx(() {
          final c = Get.find<UsersController>();
          if (!c.hasActiveFilters) return const SizedBox.shrink();
          return ClearAllButton(onTap: c.resetFilters);
        }),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                side: BorderSide(color: colors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
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
                      Flexible(
                        child: Container(
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
                              Flexible(
                                child: Text(
                                  u.role.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: u.role.color,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
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

                // Status badge — tap to activate / deactivate
                Expanded(
                  flex: _kStatFlex,
                  child: Center(
                    child: Tooltip(
                      message: u.isActive
                          ? 'Deactivate employee'
                          : 'Activate employee',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => Get.find<UsersController>().setActive(
                          u.id,
                          !u.isActive,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: u.isActive
                                ? const Color(
                                    0xFF22C55E,
                                  ).withValues(alpha: 0.10)
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
                  ),
                ),

                // Modified By
                Expanded(
                  flex: _kModFlex,
                  child: Builder(
                    builder: (_) {
                      final mod = resolveModifiedBy(
                        storedName: u.modifiedBy,
                        storedDate: u.modifiedAt,
                      );
                      if (mod == null) {
                        return ModifiedByEmpty(textHint: c.textHint);
                      }
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
                      const SizedBox(width: 4),
                      _ActBtn(
                        icon: Icons.edit_outlined,
                        color: AppColors.primaryOrange,
                        tooltip: 'Edit',
                        onTap: () {},
                      ),
                      const SizedBox(width: 4),
                      _ActBtn(
                        icon: Icons.delete_outline_rounded,
                        color: const Color(0xFFEF4444),
                        tooltip: 'Delete',
                        onTap: () => confirmDelete(
                          context,
                          itemName: u.name,
                          itemLabel: 'Employee',
                          onConfirm: () =>
                              Get.find<UsersController>().deleteUser(u.id),
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

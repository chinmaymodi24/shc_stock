import 'package:shc_stock/app/core/session/app_modules.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:shc_stock/app/modules/users/controllers/users_controller.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/modules/users/models/user_model.dart';
import 'package:shc_stock/app/modules/users/views/employee_actions.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/modified_by_cell.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/table_footer.dart';
import 'package:shc_stock/app/shared/widgets/row_action_button.dart';

part 'web_users_layout_part1.dart';
part 'web_users_layout_part2.dart';

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
const int _kActFlex = 22; // View + Edit + Duplicate + Delete

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
                                      fontFamily: brandFontFamily,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Manage employees and their access roles.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.textSecondary,
                                      fontFamily: brandFontFamily,
                                    ),
                                  ),
                                ],
                              ),
                              if (canWriteModule('Employee'))
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      Get.toNamed(AppRoutes.addEmployee),
                                  icon: const Icon(
                                    Icons.person_add_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Add New Employee',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontFamily: brandFontFamily,
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
                                      borderRadius: BorderRadius.circular(
                                        appColors.radius,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Stat Cards ─────────────────────────────────────────────
                          if (canSeeSummary('Employee')) ...[
                            AppStatCardRow(
                              cards: [
                                AppStatCard(
                                  label: 'Total Employees',
                                  value: '${c.totalUsers}',
                                  icon: Icons.group_outlined,
                                  iconColor: AppColors.primaryOrange,
                                  trend: c.stats.value.trendLabel('totalUsers'),
                                  trendUp: c.stats.value.trendUp('totalUsers'),
                                  showCaption: false,
                                ),
                                AppStatCard(
                                  label: 'Active Employees',
                                  value: '${c.activeUsers}',
                                  icon: Icons.person_outline_rounded,
                                  iconColor: AppColors.success,
                                  trend: c.stats.value.trendLabel(
                                    'activeUsers',
                                  ),
                                  trendUp: c.stats.value.trendUp('activeUsers'),
                                  showCaption: false,
                                ),
                                AppStatCard(
                                  label: 'Admins',
                                  value: '${c.adminCount}',
                                  icon: Icons.admin_panel_settings_outlined,
                                  iconColor: context.appColors.accent,
                                  trend: c.stats.value.trendLabel('adminCount'),
                                  trendUp: c.stats.value.trendUp('adminCount'),
                                  showCaption: false,
                                ),
                                AppStatCard(
                                  label: 'Inactive Employees',
                                  value: '${c.inactiveUsers}',
                                  icon: Icons.person_off_outlined,
                                  iconColor: AppColors.danger,
                                  trend: c.stats.value.trendLabel(
                                    'inactiveUsers',
                                  ),
                                  trendUp: c.stats.value.trendUp(
                                    'inactiveUsers',
                                  ),
                                  showCaption: false,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],

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
                                                    fontFamily: brandFontFamily,
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

                              // ── RIGHT: Panel ─────────────────────────────────────
                              // Summary cards need the Employee summary right;
                              // Quick Actions shows only what this person may do.
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 272,
                                child: Column(
                                  children: [
                                    if (canSeeSummary('Employee')) ...[
                                      _UserSummaryCard(colors: colors, c: c),
                                      const SizedBox(height: 14),
                                      _RoleBreakdownCard(colors: colors, c: c),
                                      const SizedBox(height: 14),
                                    ],
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
        pillsVisible: () => Get.find<UsersController>().users.isNotEmpty,
        search: FilterSearchField(
          controller: searchCtrl,
          hint: 'Search employees...',
          width: 240,
          onChanged: onSearch,
        ),
        pills: [
          SingleSelectFilterPill(
            value: filterRole,
            items: ['All Roles', ...Get.find<UsersController>().roleNames],
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
                  fontFamily: brandFontFamily,
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
    fontFamily: brandFontFamily,
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

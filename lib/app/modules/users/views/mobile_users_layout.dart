import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/app_drawer.dart';
import 'package:shc_stock/app/modules/users/controllers/users_controller.dart';
import 'package:shc_stock/app/modules/users/models/user_model.dart';
import 'package:shc_stock/app/modules/users/views/employee_actions.dart';
import 'package:shc_stock/app/shared/widgets/mobile_row_actions.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/mobile_list_scaffold.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/shared/widgets/mobile_filter_sheet.dart';
import 'package:shc_stock/app/shared/widgets/mobile_appbar_avatar.dart';

/// Mobile counterpart of WebUsersLayout — same data/actions (Add employee,
/// toggle Active/Inactive, Delete via confirmDelete), card list instead of
/// a table — view/edit/duplicate/delete all go through EmployeeActions, the
/// same helper the web table uses.
class MobileUsersLayout extends StatelessWidget {
  const MobileUsersLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<UsersController>();
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const AppDrawer(activeRoute: AppRoutes.users),
      appBar: _buildAppBar(context, c),
      body: _buildList(context, c),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.addEmployee),
        backgroundColor: AppColors.primaryOrange,
        child: const Icon(Icons.person_add_outlined, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, UsersController c) {
    final colors = context.appColors;
    return AppBar(
      backgroundColor: colors.topBarBg,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.menu_rounded, color: colors.textPrimary, size: 24),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Text(
        'Employees',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
          fontFamily: 'Poppins',
        ),
      ),
      centerTitle: true,
      actions: [
        Obx(
          () => MobileFilterButton(
            filters: _buildFilters(c),
            onClear: c.resetFilters,
            activeCount:
                (c.filterRole.value == 'All Roles' ? 0 : 1) +
                (c.filterStatus.value == 'All Status' ? 0 : 1),
          ),
        ),
        const MobileAppBarAvatar(),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: colors.divider),
      ),
    );
  }

  // Same FilterSearchField the web filter row uses, and the same searchCtrl
  // so a Clear-all tap in the filter sheet also clears the visible text.
  Widget _searchField(UsersController c) => FilterSearchField(
    controller: c.searchCtrl,
    hint: 'Search employees...',
    width: double.infinity,
    onChanged: (v) {
      c.searchQuery.value = v;
      c.currentPage.value = 1;
    },
  );

  List<MobileStatCardData> _statCards(BuildContext context, UsersController c) {
    return [
      MobileStatCardData(
        label: 'Total',
        value: '${c.totalUsers}',
        icon: Icons.group_outlined,
        color: AppColors.primaryOrange,
        onTap: () {
          c.filterRole.value = 'All Roles';
          c.filterStatus.value = 'All Status';
        },
      ),
      MobileStatCardData(
        label: 'Active',
        value: '${c.activeUsers}',
        icon: Icons.person_outline_rounded,
        color: const Color(0xFF22C55E),
        selected: c.filterStatus.value == 'Active',
        onTap: () => c.filterStatus.value =
            c.filterStatus.value == 'Active' ? 'All Status' : 'Active',
      ),
      MobileStatCardData(
        label: 'Admins',
        value: '${c.adminCount}',
        icon: Icons.admin_panel_settings_outlined,
        color: context.appColors.accent,
        selected: c.filterRole.value == 'Admin',
        onTap: () => c.filterRole.value =
            c.filterRole.value == 'Admin' ? 'All Roles' : 'Admin',
      ),
      MobileStatCardData(
        label: 'Inactive',
        value: '${c.inactiveUsers}',
        icon: Icons.person_off_outlined,
        color: const Color(0xFFEF4444),
        selected: c.filterStatus.value == 'Inactive',
        onTap: () => c.filterStatus.value =
            c.filterStatus.value == 'Inactive' ? 'All Status' : 'Inactive',
      ),
    ];
  }

  // Same data/controller bindings as WebUsersLayout's FilterBar — Role,
  // Status — shown as flat chip groups instead of dropdown pills (see
  // mobile_filter_sheet.dart for why).
  List<Widget> _buildFilters(UsersController c) {
    return [
      Obx(
        () => MobileFilterChoiceGroup(
          label: 'Role',
          value: c.filterRole.value,
          items: ['All Roles', ...UserRole.values.map((r) => r.label)],
          onChanged: (v) => c.filterRole.value = v,
        ),
      ),
      Obx(
        () => MobileFilterChoiceGroup(
          label: 'Status',
          value: c.filterStatus.value,
          items: const ['All Status', 'Active', 'Inactive'],
          onChanged: (v) => c.filterStatus.value = v,
        ),
      ),
    ];
  }

  Widget _buildList(BuildContext context, UsersController c) {
    return Obx(() {
      final loading = c.isLoading.value && c.users.isEmpty;
      // Same filter logic as WebUsersLayout — search, role, status.
      final q = c.searchQuery.value.toLowerCase();
      final filterRole = c.filterRole.value;
      final filterStatus = c.filterStatus.value;
      final filtered = c.users.where((u) {
        final matchSearch =
            q.isEmpty ||
            u.name.toLowerCase().contains(q) ||
            u.code.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.role.label.toLowerCase().contains(q);
        final matchRole =
            filterRole == 'All Roles' || u.role.label == filterRole;
        final matchStatus =
            filterStatus == 'All Status' ||
            (filterStatus == 'Active' && u.isActive) ||
            (filterStatus == 'Inactive' && !u.isActive);
        return matchSearch && matchRole && matchStatus;
      }).toList();

      return MobileListScaffold(
        statCards: _statCards(context, c),
        search: _searchField(c),
        countLabel: loading ? null : 'Showing ${filtered.length} employees',
        sliver: loading
            ? const SliverFillRemaining(
                hasScrollBody: false,
                child: AppLoadingIndicator(label: 'Loading employees...'),
              )
            : filtered.isEmpty
            ? const MobileListEmpty(
                icon: Icons.manage_search_rounded,
                label: 'No employees found',
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                sliver: SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _MobileUserCard(user: filtered[i]),
                ),
              ),
      );
    });
  }
}

class _MobileUserCard extends StatelessWidget {
  final UserModel user;
  const _MobileUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final u = user;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: u.badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      u.code,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: context.appColors.accent,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              // Status — tap to activate / deactivate, same as web's badge.
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () =>
                    Get.find<UsersController>().setActive(u.id, !u.isActive),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: u.isActive
                        ? const Color(0xFF22C55E).withValues(alpha: 0.10)
                        : colors.comingSoonBadge,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    u.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: u.isActive
                          ? const Color(0xFF22C55E)
                          : colors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.mail_outline_rounded,
                size: 13,
                color: colors.textHint,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  u.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(u.role.icon, size: 13, color: u.role.color),
              const SizedBox(width: 4),
              Text(
                u.role.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: u.role.color,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              Text(
                'Last login: ${u.lastLogin}',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textHint,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: 6),
          // Same four actions the web table offers.
          MobileActionRow(
            actions: [
              MobileActionButton.view(
                context: context,
                onTap: () => EmployeeActions.view(context, u),
              ),
              MobileActionButton.edit(
                context: context,
                onTap: () => EmployeeActions.edit(u),
              ),
              MobileActionButton.duplicate(
                onTap: () => EmployeeActions.duplicate(u),
              ),
              MobileActionButton.delete(
                onTap: () => EmployeeActions.delete(context, u),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


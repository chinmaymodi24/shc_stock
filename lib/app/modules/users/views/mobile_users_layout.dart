import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/app_drawer.dart';
import 'package:shc_stock/app/modules/users/controllers/users_controller.dart';
import 'package:shc_stock/app/modules/users/models/user_model.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/shared/widgets/mobile_filter_sheet.dart';

/// Mobile counterpart of WebUsersLayout — same data/actions (Add employee,
/// toggle Active/Inactive, Delete via confirmDelete), card list instead of
/// a table. (View/Edit/Duplicate are no-ops on web too — not carried over.)
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
      body: Column(
        children: [
          _buildSearchBar(context, c),
          Expanded(child: _buildList(context, c)),
        ],
      ),
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
      actions: [
        MobileFilterButton(filters: _buildFilters(c), onClear: c.resetFilters),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: colors.divider),
      ),
    );
  }

  // Same FilterSearchField the web filter row uses, and the same searchCtrl
  // so a Clear-all tap in the filter sheet also clears the visible text.
  Widget _buildSearchBar(BuildContext context, UsersController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: FilterSearchField(
        controller: c.searchCtrl,
        hint: 'Search employees...',
        width: double.infinity,
        onChanged: (v) {
          c.searchQuery.value = v;
          c.currentPage.value = 1;
        },
      ),
    );
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
    final colors = context.appColors;
    return Obx(() {
      if (c.isLoading.value && c.users.isEmpty) {
        return const AppLoadingIndicator(label: 'Loading employees...');
      }
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

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        children: [
          // IntrinsicHeight, not a fixed SizedBox — sizes to whatever the
          // tallest card actually needs instead of a guessed fixed height
          // (see the same overflow this fixed elsewhere: stock/transactions/
          // clients).
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _MobileStatCard(
                    label: 'Total',
                    value: '${c.totalUsers}',
                    icon: Icons.group_outlined,
                    color: AppColors.primaryOrange,
                  ),
                  const SizedBox(width: 10),
                  _MobileStatCard(
                    label: 'Active',
                    value: '${c.activeUsers}',
                    icon: Icons.person_outline_rounded,
                    color: const Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 10),
                  _MobileStatCard(
                    label: 'Admins',
                    value: '${c.adminCount}',
                    icon: Icons.admin_panel_settings_outlined,
                    color: context.appColors.accent,
                  ),
                  const SizedBox(width: 10),
                  _MobileStatCard(
                    label: 'Inactive',
                    value: '${c.inactiveUsers}',
                    icon: Icons.person_off_outlined,
                    color: const Color(0xFFEF4444),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Showing ${filtered.length} employees',
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.manage_search_rounded,
                      size: 44,
                      color: colors.textHint,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No employees found',
                      style: TextStyle(
                        color: colors.textHint,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filtered.map((u) => _MobileUserCard(user: u)),
        ],
      );
    });
  }
}

class _MobileStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MobileStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: AppStatCard(
        label: label,
        value: value,
        icon: icon,
        iconColor: color,
        smallValue: true,
        showCaption: false,
      ),
    );
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActBtn(
                icon: Icons.delete_outline_rounded,
                color: const Color(0xFFEF4444),
                tooltip: 'Delete',
                onTap: () => confirmDelete(
                  context,
                  itemName: u.name,
                  itemLabel: 'Employee',
                  onConfirm: () => Get.find<UsersController>().deleteUser(u.id),
                ),
              ),
            ],
          ),
        ],
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
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
      ),
    );
  }
}

part of 'web_users_layout.dart';

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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOrange,
                        fontFamily: brandFontFamily,
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
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.accent,
                      fontFamily: brandFontFamily,
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
                              fontFamily: brandFontFamily,
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
                            fontFamily: brandFontFamily,
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
                      fontFamily: brandFontFamily,
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
                      fontFamily: brandFontFamily,
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
                                    fontFamily: brandFontFamily,
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
                      fontFamily: brandFontFamily,
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
                        onTap: canWriteModule('Employee')
                            ? () => Get.find<UsersController>().setActive(
                                u.id,
                                !u.isActive,
                              )
                            : null,
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
                                  ? AppColors.success
                                  : c.textSecondary,
                              fontFamily: brandFontFamily,
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
                      RowActionButton(
                        icon: Icons.remove_red_eye_outlined,
                        color: context.appColors.success,
                        bg: context.appColors.success.withValues(alpha: 0.10),
                        tooltip: 'View',
                        onTap: () => EmployeeActions.view(context, u),
                      ),
                      if (canWriteModule('Employee')) ...[
                        const SizedBox(width: 4),
                        RowActionButton(
                          icon: Icons.edit_outlined,
                          color: AppColors.primaryOrange,
                          bg: AppColors.primaryOrange.withValues(alpha: 0.10),
                          tooltip: 'Edit',
                          onTap: () => EmployeeActions.edit(u),
                        ),
                        const SizedBox(width: 4),
                        RowActionButton(
                          icon: Icons.copy_outlined,
                          color: AppColors.info,
                          bg: AppColors.info.withValues(alpha: 0.10),
                          tooltip: 'Duplicate',
                          onTap: () => EmployeeActions.duplicate(u),
                        ),
                        const SizedBox(width: 4),
                        RowActionButton(
                          icon: Icons.delete_outline_rounded,
                          iconSize: 18,
                          color: context.appColors.error,
                          // Neutral, not red-tinted — only the icon carries
                          // the warning color.
                          bg: context.appColors.tagBg,
                          tooltip: 'Delete',
                          onTap: () => EmployeeActions.delete(context, u),
                        ),
                      ],
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
                fontFamily: brandFontFamily,
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
            valueColor: AppColors.success,
          ),
          _SumRow(
            label: 'Inactive Employees',
            value: '${c.inactiveUsers}',
            colors: colors,
            valueColor: AppColors.danger,
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
                fontFamily: brandFontFamily,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? colors.textPrimary,
              fontFamily: brandFontFamily,
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
    final roles = breakdown.keys.toList();
    final total = breakdown.values.fold<int>(0, (a, b) => a + b);

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
                fontFamily: brandFontFamily,
              ),
            ),
          ),
          Divider(height: 1, color: colors.divider),
          ...roles.asMap().entries.map((e) {
            final role = e.value;
            final count = breakdown[role] ?? 0;
            final pct = total == 0 ? 0.0 : count / total;
            final isLast = e.key == roles.length - 1;

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
                          role.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colors.textSecondary,
                            fontFamily: brandFontFamily,
                          ),
                        ),
                      ),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          fontFamily: brandFontFamily,
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

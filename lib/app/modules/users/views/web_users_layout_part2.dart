part of 'web_users_layout.dart';

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
                fontFamily: brandFontFamily,
              ),
            ),
          ),
          // Adding and resetting change data — write access only.
          if (canWriteModule('Employee')) ...[
            Divider(height: 1, color: colors.divider),
            _QAction(
              icon: Icons.person_add_outlined,
              label: 'Add New Employee',
              iconColor: AppColors.primaryOrange,
              colors: colors,
              onTap: onAddUser,
            ),
          ],
          Divider(height: 1, color: colors.divider),
          _QAction(
            icon: Icons.upload_outlined,
            label: 'Export Employee List',
            iconColor: context.appColors.accent,
            colors: colors,
            onTap: () {},
            isLast: !canWriteModule('Employee'),
          ),
          if (canWriteModule('Employee')) ...[
            Divider(height: 1, color: colors.divider),
            _QAction(
              icon: Icons.lock_reset_outlined,
              label: 'Reset Permissions',
              iconColor: AppColors.warning,
              colors: colors,
              onTap: () {},
              isLast: true,
            ),
          ],
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
                      fontFamily: brandFontFamily,
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

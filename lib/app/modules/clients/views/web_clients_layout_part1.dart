part of 'web_clients_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Right Panel — Quick Stats Card (Avg. Order Value / Repeat Clients)
// ─────────────────────────────────────────────────────────────────────────────
class _QuickStatsCard extends StatelessWidget {
  final ClientsController c;
  const _QuickStatsCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
              'Quick Stats',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                fontFamily: brandFontFamily,
              ),
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Obx(
            () => _SumRow(
              label: 'Avg. Order Value',
              value: '₹${c.avgOrderValue.value.round()}',
              colors: colors,
            ),
          ),
          _SumRow(
            label: 'Repeat Clients',
            value: '${c.repeatClientsPct.value}%',
            colors: colors,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right Panel — New This Month Card
// ─────────────────────────────────────────────────────────────────────────────
class _NewThisMonthCard extends StatelessWidget {
  final AppThemeColors colors;
  final ClientsController c;
  const _NewThisMonthCard({required this.colors, required this.c});

  @override
  Widget build(BuildContext context) {
    final recent = c.newThisMonth;
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
              'New This Month',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                fontFamily: brandFontFamily,
              ),
            ),
          ),
          Divider(height: 1, color: colors.divider),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No new clients yet this month.',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textHint,
                  fontFamily: brandFontFamily,
                ),
              ),
            )
          else
            ...recent.asMap().entries.map((e) {
              final cl = e.value;
              return InkWell(
                onTap: () {
                  // The panel row is a lightweight summary; pull the full
                  // client out of the loaded list to show its details.
                  final full = c.clients.firstWhereOrNull((x) => x.id == cl.id);
                  if (full == null) return;
                  ClientActions.view(context, full);
                },
                child: Container(
                  decoration: e.key == recent.length - 1
                      ? null
                      : BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: colors.divider,
                              width: 0.5,
                            ),
                          ),
                        ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: cl.badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            cl.initials,
                            style: TextStyle(
                              fontSize: cl.initials.length > 2 ? 9 : 10.5,
                              fontWeight: FontWeight.w700,
                              color: cl.badgeColor,
                              fontFamily: brandFontFamily,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cl.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                            fontFamily: brandFontFamily,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  final String label, value;
  final AppThemeColors colors;
  final bool isLast;
  const _SumRow({
    required this.label,
    required this.value,
    required this.colors,
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
              color: colors.textPrimary,
              fontFamily: brandFontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right Panel — Top States Card
// ─────────────────────────────────────────────────────────────────────────────
class _TopClientsCard extends StatelessWidget {
  final AppThemeColors colors;
  final ClientsController c;
  const _TopClientsCard({required this.colors, required this.c});

  @override
  Widget build(BuildContext context) {
    final top = c.topStates;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top States',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: brandFontFamily,
                  ),
                ),
                Text(
                  'By Client Count',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textHint,
                    fontFamily: brandFontFamily,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          ...top.asMap().entries.map((e) {
            final state = e.value.state;
            final count = e.value.count;
            return Container(
              decoration: e.key == top.length - 1
                  ? null
                  : BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colors.divider, width: 0.5),
                      ),
                    ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                        fontFamily: brandFontFamily,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontFamily: brandFontFamily,
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
  const _QuickActionsCard({required this.colors});

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
          if (canWriteModule('Clients')) ...[
            Divider(height: 1, color: colors.divider),
            _QAction(
              icon: Icons.person_add_outlined,
              label: 'Add New Client',
              iconColor: AppColors.primaryOrange,
              colors: colors,
              onTap: () => Get.toNamed(AppRoutes.addClient),
            ),
          ],
          Divider(height: 1, color: colors.divider),
          _QAction(
            icon: Icons.receipt_long_outlined,
            label: 'Client Ledger Report',
            iconColor: context.appColors.accent,
            colors: colors,
          ),
          Divider(height: 1, color: colors.divider),
          _QAction(
            icon: Icons.history_rounded,
            label: 'All Transactions History',
            iconColor: colors.purple,
            colors: colors,
            // The route guard would bounce anyone without Transactions.
            onTap: canReadModule('Transactions')
                ? () => Get.toNamed(AppRoutes.transactions)
                : null,
          ),
          Divider(height: 1, color: colors.divider),
          _QAction(
            icon: Icons.warning_amber_rounded,
            label: 'Outstanding Report',
            iconColor: AppColors.warning,
            colors: colors,
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
  final bool isLast;
  final VoidCallback? onTap;
  const _QAction({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.colors,
    this.isLast = false,
    this.onTap,
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
      child: GestureDetector(
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

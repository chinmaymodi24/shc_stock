part of 'mobile_dashboard_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Incoming delivery row — colored bar + item/PO + warehouse/eta
// ─────────────────────────────────────────────────────────────────────────────
class _DeliveryRow extends StatelessWidget {
  final DeliveryItem data;
  const _DeliveryRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final eta = data.eta.isEmpty
        ? data.eta
        : '${data.eta[0].toUpperCase()}${data.eta.substring(1)}';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: data.accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.item} — PO #${data.poRef}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    fontFamily: brandFontFamily,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${data.warehouse} · $eta',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontFamily: brandFontFamily,
                  ),
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
// Low stock alert row — inline warning icon + name + fraction + progress bar
// ─────────────────────────────────────────────────────────────────────────────
class _LowStockRow extends StatelessWidget {
  final LowStockAlertItem item;
  const _LowStockRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ratio = item.max == 0
        ? 0.0
        : (item.current / item.max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.warning, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.product,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  fontFamily: brandFontFamily,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${fmtStockQty(item.current)}/${fmtStockQty(item.max)}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.error,
                fontFamily: brandFontFamily,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: colors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(colors.error),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Charts & Trends — collapsible accordion (Purchases / Sales / New clients)
// ─────────────────────────────────────────────────────────────────────────────
class _ChartsAccordion extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final DashboardController c;
  const _ChartsAccordion({
    required this.expanded,
    required this.onToggle,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: colors.textPrimary,
      fontFamily: brandFontFamily,
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: colors.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Charts & Trends',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontFamily: brandFontFamily,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Purchases (6 months)', style: labelStyle),
                  const SizedBox(height: 10),
                  SimpleBarChart(
                    data: c.purchasesData,
                    barColor: AppColors.primaryPurple,
                    height: 110,
                    valueFormatter: formatRupees,
                  ),
                  const SizedBox(height: 20),
                  Text('Sales (6 months)', style: labelStyle),
                  const SizedBox(height: 10),
                  SimpleBarChart(
                    data: c.salesData,
                    barColor: AppColors.primaryOrange,
                    height: 110,
                    valueFormatter: formatRupees,
                  ),
                  const SizedBox(height: 20),
                  Text('New clients (6 months)', style: labelStyle),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 90,
                    child: SalesLineChart(
                      data: c.newClientsData,
                      lineColor: context.appColors.accent,
                    ),
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
// Quick link card — icon chip + bold label
// ─────────────────────────────────────────────────────────────────────────────
class _QuickLinkCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
  const _QuickLinkCard({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: brandFontFamily,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

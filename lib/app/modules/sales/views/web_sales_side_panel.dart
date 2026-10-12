part of 'web_sales_layout.dart';

// The right-hand rail: summary, billing and top-clients cards — part of web_sales_layout.dart.

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT PANEL — Sales Summary
// ─────────────────────────────────────────────────────────────────────────────
class _SalesSummaryCard extends StatelessWidget {
  final AppThemeColors colors;
  final SalesController controller;
  const _SalesSummaryCard({required this.colors, required this.controller});

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      colors: colors,
      title: 'Sales Summary',
      child: Column(
        children: [
          _SummaryRow(
            label: 'Total Sales Orders',
            value: '${controller.stats.value.intOf('totalOrders')}',
            colors: colors,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Total Sales Amount',
            value: formatRupees(controller.stats.value.doubleOf('totalSales')),
            colors: colors,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Total Received',
            value: formatRupees(
              controller.stats.value.doubleOf('totalReceived'),
            ),
            colors: colors,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Total Due',
            value: formatRupees(controller.stats.value.doubleOf('amountDue')),
            colors: colors,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Average Order Value',
            value: formatRupees(
              controller.stats.value.doubleOf('avgOrderValue'),
            ),
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final AppThemeColors colors;
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textSecondary,
              fontFamily: brandFontFamily,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT PANEL — Billing
//
// How much of the sales list has actually been billed, and a way straight to
// the most recent invoice.
// ─────────────────────────────────────────────────────────────────────────────
class _BillingCard extends StatelessWidget {
  final AppThemeColors colors;
  const _BillingCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<BillingSummaryController>()) {
      Get.put(BillingSummaryController(), permanent: true);
    }
    final billing = BillingSummaryController.to;
    return _PanelCard(
      colors: colors,
      title: 'Billing',
      child: Obx(() {
        final s = billing.summary.value;
        return Column(
          children: [
            _SummaryRow(
              label: 'Bills generated',
              value: '${s.generated}',
              colors: colors,
            ),
            const SizedBox(height: 10),
            _SummaryRow(
              label: 'Pending billing',
              value: '${s.pending}',
              colors: colors,
            ),
            const SizedBox(height: 10),
            _SummaryRow(
              label: 'e-Invoice IRN',
              value: '${s.irnRegistered} of ${s.irnTotal}',
              colors: colors,
            ),
            // Hidden rather than shown-and-refused: with no bill to open, the
            // button could only answer with a toast saying so.
            if (s.latestSalesOrderId != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: _PrimaryBtn(
                  label: 'Open latest bill',
                  icon: Icons.receipt_long_rounded,
                  onTap: () => Get.toNamed(
                    AppRoutes.saleBill,
                    arguments: s.latestSalesOrderId.toString(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            InkWell(
              onTap: () => Get.toNamed(AppRoutes.settings),
              child: Text(
                'Bill format settings',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryOrange,
                  fontFamily: brandFontFamily,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT PANEL — Top Clients
// ─────────────────────────────────────────────────────────────────────────────
class _TopClientsCard extends StatelessWidget {
  final AppThemeColors colors;
  final SalesController controller;
  const _TopClientsCard({required this.colors, required this.controller});

  // Shared Indian-grouped formatter — the hand-rolled version here crashed
  // with a RangeError for any total under ₹1,000 (s.length - 3 went negative).
  String _fmtAmt(double v) => formatRupees(v);

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      colors: colors,
      title: 'Top Clients',
      action: InkWell(
        onTap: () {},
        child: Text(
          'View All',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryOrange,
            fontFamily: brandFontFamily,
          ),
        ),
      ),
      child: Column(
        children: controller.topClients
            .map(
              (tc) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Badge circle
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: tc.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          tc.badge,
                          style: TextStyle(
                            fontSize: tc.badge.length > 2 ? 9 : 11,
                            fontWeight: FontWeight.w800,
                            color: tc.color,
                            fontFamily: brandFontFamily,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Name + orders
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tc.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                              fontFamily: brandFontFamily,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${tc.orderCount} Orders',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                              fontFamily: brandFontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Total amount
                    Text(
                      _fmtAmt(tc.totalAmount),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontFamily: brandFontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT PANEL — Quick Actions
// ─────────────────────────────────────────────────────────────────────────────
class _PanelCard extends StatelessWidget {
  final AppThemeColors colors;
  final String title;
  final Widget child;
  final Widget? action;
  const _PanelCard({
    required this.colors,
    required this.title,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The title flexes so a long one plus an action button can't
          // overflow the 272px side panel.
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: brandFontFamily,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (action != null) ...[const SizedBox(width: 8), action!],
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Primary Button helper
// ─────────────────────────────────────────────────────────────────────────────
class _PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(
        label,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(appColors.radius),
        ),
      ),
    );
  }
}

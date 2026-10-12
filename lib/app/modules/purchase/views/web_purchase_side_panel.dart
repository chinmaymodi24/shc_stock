part of 'web_purchase_layout.dart';

// The right-hand rail: summary card, its rows and the top suppliers — part of web_purchase_layout.dart.

// ─────────────────────────────────────────────────────────────────────────────
// Right Panel — Purchase Summary Card
// ─────────────────────────────────────────────────────────────────────────────
class _PurchaseSummaryCard extends StatelessWidget {
  final AppThemeColors colors;
  final PurchaseController c;
  const _PurchaseSummaryCard({required this.colors, required this.c});

  String _fmt(double v) => formatRupees(v);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
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
                'Purchase Summary',
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
              label: 'Total Purchase Orders',
              value: '${c.totalOrders}',
              colors: colors,
            ),
            _SumRow(
              label: 'Total Purchase Amount',
              value: _fmt(c.totalPurchaseMTD),
              colors: colors,
            ),
            _SumRow(
              label: 'Total Paid',
              value: _fmt(c.totalAmountPaid),
              colors: colors,
              valueColor: AppColors.success,
            ),
            _SumRow(
              label: 'Total Due',
              value: _fmt(c.totalAmountDue),
              colors: colors,
              valueColor: AppColors.danger,
            ),
            _SumRow(
              label: 'Average Order Value',
              value: _fmt(c.averageOrderValue),
              colors: colors,
              isLast: true,
            ),
          ],
        ),
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
// Right Panel — Top Suppliers Card
// ─────────────────────────────────────────────────────────────────────────────
class _TopSuppliersCard extends StatelessWidget {
  final AppThemeColors colors;
  final PurchaseController c;
  const _TopSuppliersCard({required this.colors, required this.c});

  String _fmt(double v) => formatRupees(v);

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final top = c.topSuppliers;
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Top Suppliers',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontFamily: brandFontFamily,
                      ),
                    ),
                  ),
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                      fontFamily: brandFontFamily,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.divider),
            ...top.asMap().entries.map((e) {
              final supplier = e.value.key;
              final amount = e.value.value;
              final isLast = e.key == top.length - 1;
              final orderCount = c.orders
                  .where((o) => o.supplier == supplier)
                  .length;

              return Container(
                decoration: isLast
                    ? null
                    : BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: colors.divider, width: 0.5),
                        ),
                      ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: context.appColors.accent.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _initials(supplier),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: context.appColors.accent,
                            fontFamily: brandFontFamily,
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
                            supplier,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: colors.textPrimary,
                              fontFamily: brandFontFamily,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$orderCount Orders',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textHint,
                              fontFamily: brandFontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _fmt(amount),
                      style: TextStyle(
                        fontSize: 12.5,
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
    });
  }
}

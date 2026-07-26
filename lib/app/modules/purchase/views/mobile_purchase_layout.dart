import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/purchase_controller.dart';
import '../models/purchase_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';

class MobilePurchaseLayout extends GetView<PurchaseController> {
  const MobilePurchaseLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu_rounded, color: colors.textPrimary),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          'Purchases',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: AppColors.primaryOrange),
            onPressed: () => Get.toNamed(AppRoutes.addPurchase),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colors.divider),
        ),
      ),
      body: Obx(() {
        final all = c.orders;
        final query = c.searchQuery.value;
        final filtered = query.isEmpty
            ? all.toList()
            : all
                  .where(
                    (o) =>
                        o.supplier.toLowerCase().contains(
                          query.toLowerCase(),
                        ) ||
                        o.poNumber.toLowerCase().contains(query.toLowerCase()),
                  )
                  .toList();

        return CustomScrollView(
          slivers: [
            // Stat cards strip
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    _MobileStatCard(
                      label: 'Total Orders',
                      value: '${c.totalOrders}',
                      icon: Icons.receipt_long_outlined,
                      color: const Color(0xFF4A3AFF),
                    ),
                    const SizedBox(width: 10),
                    _MobileStatCard(
                      label: 'Purchase (MTD)',
                      value: '₹12,45,000',
                      icon: Icons.shopping_cart_outlined,
                      color: AppColors.primaryOrange,
                    ),
                    const SizedBox(width: 10),
                    _MobileStatCard(
                      label: 'Amount Due',
                      value: '₹1,18,500',
                      icon: Icons.currency_rupee_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 10),
                    _MobileStatCard(
                      label: 'Items (MTD)',
                      value: '156',
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF22C55E),
                    ),
                  ],
                ),
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: TextField(
                  onChanged: (v) => c.searchQuery.value = v,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search purchases...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: colors.textHint,
                      fontFamily: 'Poppins',
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colors.textHint,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    filled: true,
                    fillColor: colors.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.primaryOrange,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Showing count
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Showing ${filtered.length} purchases',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),

            // Purchase cards
            if (filtered.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: colors.textHint,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No purchases found',
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
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _MobilePurchaseCard(
                    order: filtered[i],
                    index: i,
                    colors: colors,
                  ),
                  childCount: filtered.length,
                ),
              ),
          ],
        );
      }),
    );
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
    final colors = context.appColors;
    return Container(
      width: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _MobilePurchaseCard extends StatelessWidget {
  final PurchaseOrder order;
  final int index;
  final AppThemeColors colors;

  const _MobilePurchaseCard({
    required this.order,
    required this.index,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final o = order;
    final dateStr =
        '${o.date.day.toString().padLeft(2, '0')} ${_month(o.date.month)} ${o.date.year}';

    Color statusBg, statusFg;
    switch (o.status) {
      case PurchaseStatus.received:
        statusBg = const Color(0xFF22C55E).withValues(alpha: 0.1);
        statusFg = const Color(0xFF22C55E);
        break;
      case PurchaseStatus.partial:
        statusBg = const Color(0xFFF59E0B).withValues(alpha: 0.1);
        statusFg = const Color(0xFFF59E0B);
        break;
      case PurchaseStatus.pending:
        statusBg = const Color(0xFF4A3AFF).withValues(alpha: 0.1);
        statusFg = const Color(0xFF4A3AFF);
        break;
      case PurchaseStatus.cancelled:
        statusBg = const Color(0xFFEF4444).withValues(alpha: 0.1);
        statusFg = const Color(0xFFEF4444);
        break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        o.poNumber,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A3AFF),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        o.status.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusFg,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  o.supplier,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: colors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 12,
                      color: colors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${o.itemCount} items',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹ ${_fmt(o.amount)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _month(int m) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m];
  }

  String _fmt(double v) {
    final s = v.toInt();
    if (s >= 100000) {
      return '${(s / 100000).toStringAsFixed(1)}L';
    }
    if (s >= 1000) {
      final str = s.toString();
      return '${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return s.toString();
  }
}

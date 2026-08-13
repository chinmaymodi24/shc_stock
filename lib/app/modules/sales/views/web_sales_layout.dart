import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/modules/sales/views/sale_details_dialog.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/table_footer.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/status_update_dialog_shell.dart';
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';

// ═════════════════════════════════════════════════════════════════════════════
// TABLE COLUMN CONSTANTS — used by BOTH _TableHeader and _SalesRow
// so they are always perfectly aligned.
// ═════════════════════════════════════════════════════════════════════════════
const double _kIdxWidth = 28.0; // # badge — fixed
const double _kColGap = 10.0; // gap between # badge and first flex col
const int _kSoFlex = 18; // SO Number
const int _kClientFlex = 26; // Client badge + name
const int _kDateFlex = 14; // Date
const int _kItemsFlex = 8; // Items (center)
const int _kAmtFlex = 16; // Amount
const int _kStatusFlex = 13; // Status badge (center)
const int _kPayFlex = 14; // Payment Status badge (center)
const int _kActFlex = 11; // Actions (center)

// ─────────────────────────────────────────────────────────────────────────────
// Sales List Page
// ─────────────────────────────────────────────────────────────────────────────
class WebSalesLayout extends GetView<SalesController> {
  const WebSalesLayout({super.key});

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
                    final all = c.orders;
                    final searchQuery = c.searchQuery.value;
                    final statusFilters = c.statusFilters;
                    final paymentFilters = c.paymentFilters;
                    final sortOption = c.sortOption.value;
                    final rowsPerPage = c.rowsPerPage.value;
                    final currentPage = c.currentPage.value;
                    final filtered = all.where((o) {
                      final q = searchQuery.toLowerCase();
                      if (q.isNotEmpty &&
                          !o.client.toLowerCase().contains(q) &&
                          !o.soNumber.toLowerCase().contains(q)) {
                        return false;
                      }
                      if (statusFilters.isNotEmpty &&
                          !statusFilters.contains(o.status.label)) {
                        return false;
                      }
                      if (paymentFilters.isNotEmpty &&
                          !paymentFilters.contains(o.paymentStatus.label)) {
                        return false;
                      }
                      return true;
                    }).toList();

                    switch (sortOption) {
                      case 'Date: Newest First':
                        filtered.sort((a, b) => b.date.compareTo(a.date));
                      case 'Date: Oldest First':
                        filtered.sort((a, b) => a.date.compareTo(b.date));
                      case 'Amount: Low to High':
                        filtered.sort((a, b) => a.amount.compareTo(b.amount));
                      case 'Amount: High to Low':
                        filtered.sort((a, b) => b.amount.compareTo(a.amount));
                    }

                    final totalPages = filtered.isEmpty
                        ? 1
                        : (filtered.length / rowsPerPage).ceil();
                    final startIdx = (currentPage - 1) * rowsPerPage;
                    final endIdx = math.min(
                      startIdx + rowsPerPage,
                      filtered.length,
                    );
                    final pageItems = filtered.isEmpty
                        ? <SalesOrder>[]
                        : filtered.sublist(startIdx, endIdx);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Page Header ─────────────────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sales',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Manage all your sales orders and track your business performance.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colors.textSecondary,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _PrimaryBtn(
                                label: 'New Sales Order',
                                icon: Icons.add_rounded,
                                onTap: () => Get.toNamed(AppRoutes.addSale),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Stat Cards row ──────────────────────────────
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: AppStatCard(
                                    label: 'Total Sales (MTD)',
                                    value: formatRupees(
                                      c.stats.value.doubleOf('salesMTD'),
                                    ),
                                    icon: Icons.shopping_cart_outlined,
                                    iconColor: AppColors.primaryOrange,
                                    trend: c.stats.value.trendLabel('salesMTD'),
                                    trendUp: c.stats.value.trendUp('salesMTD'),
                                    showCaption: false,
                                    smallValue: true,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: AppStatCard(
                                    label: 'Total Sales Orders',
                                    value:
                                        '${c.stats.value.intOf('totalOrders')}',
                                    icon: Icons.receipt_long_outlined,
                                    iconColor: const Color(0xFF4A3AFF),
                                    trend: c.stats.value.trendLabel(
                                      'totalOrders',
                                    ),
                                    trendUp: c.stats.value.trendUp(
                                      'totalOrders',
                                    ),
                                    showCaption: false,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: AppStatCard(
                                    label: 'Total Amount Due',
                                    value: formatRupees(
                                      c.stats.value.doubleOf('amountDue'),
                                    ),
                                    icon: Icons.currency_rupee_rounded,
                                    iconColor: const Color(0xFFF59E0B),
                                    trend: c.stats.value.trendLabel(
                                      'amountDue',
                                    ),
                                    trendUp: c.stats.value.trendUp('amountDue'),
                                    showCaption: false,
                                    smallValue: true,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: AppStatCard(
                                    label: 'Total Received (MTD)',
                                    value: formatRupees(
                                      c.stats.value.doubleOf('receivedMTD'),
                                    ),
                                    icon: Icons.check_circle_outline_rounded,
                                    iconColor: const Color(0xFF22C55E),
                                    trend: c.stats.value.trendLabel(
                                      'receivedMTD',
                                    ),
                                    trendUp: c.stats.value.trendUp(
                                      'receivedMTD',
                                    ),
                                    showCaption: false,
                                    smallValue: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Body row: table + right panel ───────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── LEFT: Table card ────────────────────────
                              Expanded(
                                child: _TableCard(
                                  colors: colors,
                                  onSearch: (v) {
                                    c.searchQuery.value = v;
                                    c.currentPage.value = 1;
                                  },
                                  pageItems: pageItems,
                                  startIdx: startIdx,
                                  isLast: (i) => i == pageItems.length - 1,
                                  total: filtered.length,
                                  startDisplay: filtered.isEmpty
                                      ? 0
                                      : startIdx + 1,
                                  endDisplay: endIdx,
                                  currentPage: currentPage,
                                  totalPages: totalPages,
                                  rowsPerPage: rowsPerPage,
                                  onPageChanged: (p) => c.currentPage.value = p,
                                  onRowsChanged: (r) {
                                    c.rowsPerPage.value = r;
                                    c.currentPage.value = 1;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),

                              // ── RIGHT: Panel ─────────────────────────────
                              SizedBox(
                                width: 272,
                                child: Column(
                                  children: [
                                    _SalesSummaryCard(
                                      colors: colors,
                                      controller: c,
                                    ),
                                    const SizedBox(height: 14),
                                    _TopClientsCard(
                                      colors: colors,
                                      controller: c,
                                    ),
                                    const SizedBox(height: 14),
                                    _QuickActionsCard(colors: colors),
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
class _TableCard extends StatelessWidget {
  final AppThemeColors colors;
  final ValueChanged<String> onSearch;
  final List<SalesOrder> pageItems;
  final int startIdx,
      total,
      startDisplay,
      endDisplay,
      currentPage,
      totalPages,
      rowsPerPage;
  final bool Function(int) isLast;
  final ValueChanged<int> onPageChanged, onRowsChanged;

  const _TableCard({
    required this.colors,
    required this.onSearch,
    required this.pageItems,
    required this.startIdx,
    required this.isLast,
    required this.total,
    required this.startDisplay,
    required this.endDisplay,
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
    required this.onPageChanged,
    required this.onRowsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          // Toolbar
          _Toolbar(
            colors: colors,
            onSearch: onSearch,
            controller: Get.find<SalesController>(),
          ),
          Divider(height: 1, color: colors.divider),

          // Header
          _TableHeader(colors: colors),
          Divider(height: 1, color: colors.divider),

          // Rows
          Obx(() {
            if (Get.find<SalesController>().isLoading.value) {
              return const AppLoadingIndicator(
                label: 'Loading sales orders...',
              );
            }
            if (pageItems.isEmpty) return _EmptyState(colors: colors);
            return Column(
              children: pageItems
                  .asMap()
                  .entries
                  .map(
                    (e) => _SalesRow(
                      order: e.value,
                      displayIndex: startIdx + e.key + 1,
                      colors: colors,
                      isLast: isLast(e.key),
                    ),
                  )
                  .toList(),
            );
          }),

          // Footer
          Divider(height: 1, color: colors.divider),
          AppTableFooter(
            colors: colors,
            summaryText:
                'Showing $startDisplay to $endDisplay of $total sales orders',
            currentPage: currentPage,
            totalPages: totalPages,
            rowsPerPage: rowsPerPage,
            onPageChanged: onPageChanged,
            onRowsChanged: onRowsChanged,
            legacyPageNumbers: true,
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
  final ValueChanged<String> onSearch;
  final SalesController controller;
  const _Toolbar({
    required this.colors,
    required this.onSearch,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: FilterBar(
        search: FilterSearchField(
          hint: 'Search sales orders...',
          width: 240,
          onChanged: onSearch,
        ),
        pills: [
          MultiSelectFilterPill(
            label: 'Status',
            items: SalesController.statusOptions,
            selected: c.statusFilters,
            onToggle: (v) {
              if (c.statusFilters.contains(v)) {
                c.statusFilters.remove(v);
              } else {
                c.statusFilters.add(v);
              }
              c.currentPage.value = 1;
            },
          ),
          MultiSelectFilterPill(
            label: 'Payment',
            items: SalesController.paymentOptions,
            selected: c.paymentFilters,
            onToggle: (v) {
              if (c.paymentFilters.contains(v)) {
                c.paymentFilters.remove(v);
              } else {
                c.paymentFilters.add(v);
              }
              c.currentPage.value = 1;
            },
          ),
          Obx(
            () => SingleSelectFilterPill.sort(
              value: c.sortOption.value,
              items: SalesController.sortOptions
                  .where((o) => o != 'Default')
                  .toList(),
              onChanged: (v) => c.sortOption.value = v,
            ),
          ),
        ],
        clearAll: Obx(() {
          final hasActiveFilters =
              c.searchQuery.value.isNotEmpty ||
              c.statusFilters.isNotEmpty ||
              c.paymentFilters.isNotEmpty ||
              c.sortOption.value != 'Default';
          if (!hasActiveFilters) return const SizedBox.shrink();
          return ClearAllButton(onTap: c.resetFilters);
        }),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date range
            Container(
              height: kFilterPillHeight,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.date_range_rounded,
                    size: 15,
                    color: colors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '01 May 2024 - 31 May 2024',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: colors.textPrimary,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Export
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(100),
              child: Container(
                height: kFilterPillHeight,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.upload_outlined,
                      size: 15,
                      color: colors.textPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Export',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colors.inputFill,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                Icons.table_chart_outlined,
                size: 17,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table Header — uses the same constants as _SalesRow
// ─────────────────────────────────────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  final AppThemeColors colors;
  const _TableHeader({required this.colors});

  TextStyle get _s => TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: colors.textSecondary,
    fontFamily: 'Poppins',
    letterSpacing: 0.1,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          // # column
          SizedBox(
            width: _kIdxWidth,
            child: Text('#', style: _s),
          ),
          SizedBox(width: _kColGap),
          // SO Number
          Expanded(
            flex: _kSoFlex,
            child: Text('SO Number', style: _s),
          ),
          // Client
          Expanded(
            flex: _kClientFlex,
            child: Text('Client', style: _s),
          ),
          // Date
          Expanded(
            flex: _kDateFlex,
            child: Text('Date', style: _s),
          ),
          // Items (center)
          Expanded(
            flex: _kItemsFlex,
            child: Center(child: Text('Items', style: _s)),
          ),
          // Amount
          Expanded(
            flex: _kAmtFlex,
            child: Text('Amount', style: _s),
          ),
          // Status (center)
          Expanded(
            flex: _kStatusFlex,
            child: Center(child: Text('Status', style: _s)),
          ),
          // Payment Status (center)
          Expanded(
            flex: _kPayFlex,
            child: Center(
              child: Text('Payment Status', style: _s.copyWith(fontSize: 11.5)),
            ),
          ),
          // Actions (center)
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
// Sales Row — uses the SAME constants as _TableHeader
// ─────────────────────────────────────────────────────────────────────────────
class _SalesRow extends StatefulWidget {
  final SalesOrder order;
  final int displayIndex;
  final AppThemeColors colors;
  final bool isLast;

  const _SalesRow({
    required this.order,
    required this.displayIndex,
    required this.colors,
    required this.isLast,
  });

  @override
  State<_SalesRow> createState() => _SalesRowState();
}

class _SalesRowState extends State<_SalesRow> {
  // Local, widget-scoped hover flag — kept as an Rx on the persistent State
  // object (not setState) so only the row's background repaints on hover.
  final _hovered = false.obs;

  @override
  void dispose() {
    _hovered.close();
    super.dispose();
  }

  static const _months = [
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

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month]} ${d.year}';

  String _fmtAmount(double v) {
    final i = v.toInt();
    if (i >= 100000) {
      final lakh = i ~/ 100000;
      final rest = i % 100000;
      final thou = rest ~/ 1000;
      final sub = rest % 1000;
      return '₹ $lakh,${thou.toString().padLeft(2, '0')},${sub.toString().padLeft(3, '0')}';
    }
    if (i >= 10000) {
      final s = i.toString();
      return '₹ ${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
    }
    return '₹ $i';
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // # badge
                SizedBox(
                  width: _kIdxWidth,
                  child: Container(
                    width: _kIdxWidth,
                    height: _kIdxWidth,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.displayIndex}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryOrange,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: _kColGap),

                // SO Number
                Expanded(
                  flex: _kSoFlex,
                  child: Text(
                    o.soNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A3AFF),
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Client
                Expanded(
                  flex: _kClientFlex,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: o.clientColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            o.clientBadge,
                            style: TextStyle(
                              fontSize: o.clientBadge.length > 2 ? 9.5 : 11,
                              fontWeight: FontWeight.w700,
                              color: o.clientColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          o.client,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: c.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Date
                Expanded(
                  flex: _kDateFlex,
                  child: Text(
                    _fmtDate(o.date),
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

                // Items
                Expanded(
                  flex: _kItemsFlex,
                  child: Center(
                    child: Text(
                      '${o.itemCount}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),

                // Amount
                Expanded(
                  flex: _kAmtFlex,
                  child: Text(
                    _fmtAmount(o.amount),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

                // Status badge
                Expanded(
                  flex: _kStatusFlex,
                  child: Center(
                    child: _Badge(label: o.status.label, color: o.status.color),
                  ),
                ),

                // Payment Status badge
                Expanded(
                  flex: _kPayFlex,
                  child: Center(
                    child: _Badge(
                      label: o.paymentStatus.label,
                      color: o.paymentStatus.color,
                    ),
                  ),
                ),

                // Actions
                Expanded(
                  flex: _kActFlex,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActionBtn(
                        icon: Icons.remove_red_eye_outlined,
                        color: const Color(0xFF4A3AFF),
                        bg: const Color(0xFF4A3AFF),
                        onTap: () => Get.dialog(
                          SaleDetailsDialog(
                            order: widget.order,
                            onDelete: () {
                              Get.back();
                              confirmDelete(
                                context,
                                itemName: widget.order.soNumber,
                                itemLabel: 'Sales Order',
                                onConfirm: () => Get.find<SalesController>()
                                    .deleteOrder(widget.order.id),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _ActionBtn(
                        icon: Icons.more_vert_rounded,
                        color: c.textSecondary,
                        bg: c.iconBgPurple,
                        onTap: () => Get.dialog(
                          _UpdateSalesStatusDialog(order: widget.order),
                        ),
                      ),
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: color,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: icon == Icons.more_vert_rounded ? 'More' : 'View',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: bg.withValues(
              alpha: icon == Icons.more_vert_rounded ? 1.0 : 0.10,
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Update Status Dialog — the row's "⋮" action, wired to
// SalesController.updateStatus (PATCH /sales-orders/:id/status).
// ─────────────────────────────────────────────────────────────────────────────
class _UpdateSalesStatusDialog extends StatefulWidget {
  final SalesOrder order;
  const _UpdateSalesStatusDialog({required this.order});

  @override
  State<_UpdateSalesStatusDialog> createState() =>
      _UpdateSalesStatusDialogState();
}

class _UpdateSalesStatusDialogState extends State<_UpdateSalesStatusDialog> {
  late final Rx<SalesStatus> _status = widget.order.status.obs;
  late final Rx<PaymentStatus> _payment = widget.order.paymentStatus.obs;

  @override
  void dispose() {
    _status.close();
    _payment.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatusUpdateDialogShell(
      title: 'Update Status',
      subtitle: widget.order.soNumber,
      width: 360,
      onSave: () => Get.find<SalesController>().updateStatus(
        widget.order.id,
        status: _status.value,
        paymentStatus: _payment.value,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusRadioGroup<SalesStatus>(
            label: 'Order Status',
            options: SalesStatus.values,
            selected: _status,
            labelOf: (s) => s.label,
          ),
          const SizedBox(height: 10),
          StatusRadioGroup<PaymentStatus>(
            label: 'Payment Status',
            options: PaymentStatus.values,
            selected: _payment,
            labelOf: (p) => p.label,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppThemeColors colors;
  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.point_of_sale_outlined,
              size: 40,
              color: colors.textHint,
            ),
            const SizedBox(height: 10),
            Text(
              'No sales orders found',
              style: TextStyle(
                fontSize: 14,
                color: colors.textHint,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
              fontFamily: 'Poppins',
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
            fontFamily: 'Poppins',
          ),
        ),
      ],
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

  String _fmtAmt(double v) {
    final i = v.toInt();
    if (i >= 100000) {
      final l = i ~/ 100000;
      final r = (i % 100000) ~/ 1000;
      return '₹ $l,${r.toString().padLeft(2, '0')},${((i % 1000)).toString().padLeft(3, '0')}';
    }
    final s = i.toString();
    return '₹ ${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      colors: colors,
      title: 'Top Clients',
      action: InkWell(
        onTap: () {},
        child: const Text(
          'View All',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryOrange,
            fontFamily: 'Poppins',
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
                            fontFamily: 'Poppins',
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
                              fontFamily: 'Poppins',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${tc.orderCount} Orders',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                              fontFamily: 'Poppins',
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
                        fontFamily: 'Poppins',
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
class _QuickActionsCard extends StatelessWidget {
  final AppThemeColors colors;
  const _QuickActionsCard({required this.colors});

  static const _actions = [
    (Icons.add_circle_outline_rounded, 'New Sales Order'),
    (Icons.receipt_outlined, 'Sales Invoice'),
    (Icons.local_shipping_outlined, 'Delivery Challan'),
    (Icons.undo_rounded, 'Sales Return'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      colors: colors,
      title: 'Quick Actions',
      child: Column(
        children: _actions.asMap().entries.map((e) {
          final isLast = e.key == _actions.length - 1;
          final item = e.value;
          return Column(
            children: [
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(item.$1, size: 18, color: colors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: colors.textHint,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast) Divider(height: 1, color: colors.divider),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// Shared panel card shell
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
                    fontFamily: 'Poppins',
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
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: 'Poppins',
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryOrange,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

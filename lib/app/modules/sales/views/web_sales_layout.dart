import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/controllers/add_sale_controller.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/modified_by_cell.dart';
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
import 'package:shc_stock/app/shared/widgets/row_action_button.dart';

// ═════════════════════════════════════════════════════════════════════════════
// TABLE COLUMN CONSTANTS — used by BOTH _TableHeader and _SalesRow
// so they are always perfectly aligned.
// ═════════════════════════════════════════════════════════════════════════════
const double _kIdxWidth = 28.0; // # badge — fixed
const double _kColGap = 10.0; // gap between # badge and first flex col
// Flex ratios follow the design's grid:
// 1fr SO · 1.15fr Client · 0.7 Date · 0.55 Items · 0.8 Amount · 0.85 Status
// · 0.85 Payment · 1fr Modified By · 0.6 Actions
const int _kSoFlex = 20; // SO Number
const int _kClientFlex = 23; // Client badge + name
const int _kDateFlex = 14; // Date
const int _kItemsFlex = 11; // Items (center)
const int _kAmtFlex = 16; // Amount
const int _kStatusFlex = 17; // Status badge (center)
const int _kPayFlex = 17; // Payment badge (center)
const int _kModFlex = 20; // Modified By
const int _kActFlex = 20; // Actions (center) — View + Edit + Duplicate + Delete

// ── KPI palette, straight from the design's tokens ──────────────────────────
// The card tints itself from these: background at 10%, icon chip at 18%.
const Color kKpiBlue = Color(0xFF2D1B8C);
const Color kKpiPurple = Color(0xFF6B5CBF);
const Color kKpiAmber = Color(0xFFA05A00);
const Color kKpiGreen = Color(0xFF1E8449);

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
                    final clientFilters = c.clientFilters;
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
                      if (clientFilters.isNotEmpty &&
                          !clientFilters.contains(o.client)) {
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
                                      'Sale',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    // Live count and value, per the design —
                                    // it replaced a static marketing line.
                                    Text(
                                      '${filtered.length} '
                                      '${filtered.length == 1 ? 'sale' : 'sales'}'
                                      ' · ${formatRupees(filtered.fold<double>(0, (t, o) => t + o.amount))} total',
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
                                label: 'Add Sale',
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
                                    iconColor: kKpiBlue,
                                    trend: c.stats.value.trendLabel('salesMTD'),
                                    trendUp: c.stats.value.trendUp('salesMTD'),
                                    showCaption: false,
                                    smallValue: true,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: AppStatCard(
                                    label: 'Orders',
                                    value:
                                        '${c.stats.value.intOf('totalOrders')}',
                                    icon: Icons.receipt_long_outlined,
                                    iconColor: context.appColors.accent,
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
                                    icon: Icons.warning_amber_rounded,
                                    iconColor: kKpiAmber,
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
                                    iconColor: kKpiGreen,
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
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _Toolbar(
                                      colors: colors,
                                      onSearch: (v) {
                                        c.searchQuery.value = v;
                                        c.currentPage.value = 1;
                                      },
                                      controller: c,
                                      clients:
                                          all
                                              .map((o) => o.client)
                                              .toSet()
                                              .toList()
                                            ..sort(),
                                    ),
                                    const SizedBox(height: 14),
                                    _TableCard(
                                      colors: colors,
                                      pageItems: pageItems,
                                      startIdx: startIdx,
                                      isLast: (i) => i == pageItems.length - 1,
                                    ),
                                    const SizedBox(height: 14),
                                    _PagerRow(
                                      colors: colors,
                                      currentPage: currentPage,
                                      totalPages: totalPages,
                                      rowsPerPage: rowsPerPage,
                                      onPageChanged: (p) =>
                                          c.currentPage.value = p,
                                      onRowsChanged: (r) {
                                        c.rowsPerPage.value = r;
                                        c.currentPage.value = 1;
                                      },
                                    ),
                                  ],
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
  final List<SalesOrder> pageItems;
  final int startIdx;
  final bool Function(int) isLast;

  const _TableCard({
    required this.colors,
    required this.pageItems,
    required this.startIdx,
    required this.isLast,
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
          // Header — the design puts the toolbar above the card and the
          // pager below it, so the card itself is just header + rows.
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

  /// Every client that appears in the list, for the filter menu.
  final List<String> clients;

  const _Toolbar({
    required this.colors,
    required this.onSearch,
    required this.controller,
    required this.clients,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;
    // The design's toolbar is one line: a search box and a Client filter,
    // with a Reset pill appearing only once something is filtered. FilterBar
    // owns the row's height and lets the pill strip scroll, which a bare Row
    // does not — that overflowed by the width of the whole client list.
    return FilterBar(
      search: FilterSearchField(
        hint: 'Search by item or SO...',
        width: 240,
        onChanged: onSearch,
      ),
      pills: [
        MultiSelectFilterPill(
          label: 'Client',
          items: clients,
          selected: c.clientFilters,
          onToggle: (v) {
            if (c.clientFilters.contains(v)) {
              c.clientFilters.remove(v);
            } else {
              c.clientFilters.add(v);
            }
            c.currentPage.value = 1;
          },
        ),
      ],
      clearAll: Obx(() {
        final active =
            c.searchQuery.value.isNotEmpty || c.clientFilters.isNotEmpty;
        if (!active) return const SizedBox.shrink();
        return ClearAllButton(onTap: c.resetFilters);
      }),
    );
  }
}

/// Rows-per-page on the left, page navigation on the right — the design puts
/// this under the table card rather than inside it.
class _PagerRow extends StatelessWidget {
  final AppThemeColors colors;
  final int currentPage, totalPages, rowsPerPage;
  final ValueChanged<int> onPageChanged, onRowsChanged;

  const _PagerRow({
    required this.colors,
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
    required this.onPageChanged,
    required this.onRowsChanged,
  });

  @override
  Widget build(BuildContext context) {
    // summaryText omitted: the design's footer is just "Rows per page" and
    // the pager, with no "Showing 1 to 10 of …" line.
    return AppTableFooter(
      colors: colors,
      currentPage: currentPage,
      totalPages: totalPages,
      rowsPerPage: rowsPerPage,
      onPageChanged: onPageChanged,
      onRowsChanged: onRowsChanged,
      legacyPageNumbers: true,
    );
  }
}

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
          // Payment (center)
          Expanded(
            flex: _kPayFlex,
            child: Center(child: Text('Payment', style: _s)),
          ),
          // Modified By
          Expanded(
            flex: _kModFlex,
            child: Text('Modified By', style: _s),
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
                    // The design paints the order number in the brand orange.
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
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
                    // Units, not lines — see the purchase list for why.
                    child: Tooltip(
                      message: o.itemCount == 1
                          ? '1 line item'
                          : '${o.itemCount} line items',
                      child: Text(
                        o.totalQtyLabel,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                          fontFamily: 'Poppins',
                        ),
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

                // Status badge — tap to change just the status, now that the
                // row's third action is Delete.
                Expanded(
                  flex: _kStatusFlex,
                  child: Center(
                    child: Tooltip(
                      message: 'Update status',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Get.dialog(
                          _UpdateSalesStatusDialog(order: widget.order),
                        ),
                        child: _Badge(
                          label: o.status.label,
                          color: o.status.color,
                        ),
                      ),
                    ),
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

                // Modified By — same cell the Purchase table uses.
                Expanded(
                  flex: _kModFlex,
                  child: Builder(
                    builder: (context) {
                      final mod = resolveModifiedBy(
                        storedName: o.modifiedBy,
                        storedDate: o.modifiedAt,
                      );
                      return mod == null
                          ? ModifiedByEmpty(textHint: c.textHint)
                          : ModifiedByCell(
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
                      RowActionButton(
                        icon: Icons.edit_outlined,
                        color: AppColors.primaryOrange,
                        bg: AppColors.primaryOrange.withValues(alpha: 0.10),
                        tooltip: 'Edit',
                        // Opens the same form Add Sale uses, pre-filled from
                        // this order; saving updates it in place.
                        onTap: () => Get.toNamed(
                          AppRoutes.addSale,
                          arguments: widget.order,
                        ),
                      ),
                      const SizedBox(width: 6),
                      RowActionButton(
                        icon: Icons.copy_outlined,
                        color: const Color(0xFF3B82F6),
                        bg: const Color(0xFF3B82F6).withValues(alpha: 0.10),
                        tooltip: 'Duplicate',
                        // Opens Add Sale pre-filled from this order, but as a
                        // new draft — saving creates a new record and never
                        // touches the one duplicated from.
                        onTap: () => Get.toNamed(
                          AppRoutes.addSale,
                          arguments: DuplicateSalesOrder(widget.order),
                        ),
                      ),
                      const SizedBox(width: 6),
                      RowActionButton(
                        icon: Icons.delete_outline_rounded,
                        iconSize: 18,
                        color: context.appColors.error,
                        // Neutral, not red-tinted — only the icon carries
                        // the warning color.
                        bg: context.appColors.tagBg,
                        tooltip: 'Delete',
                        onTap: () => confirmDelete(
                          context,
                          itemName: widget.order.soNumber,
                          itemLabel: 'Sales Order',
                          onConfirm: () =>
                              Get.find<SalesController>().deleteOrder(o.id),
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

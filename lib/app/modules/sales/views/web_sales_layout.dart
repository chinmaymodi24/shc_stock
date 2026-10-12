import 'package:shc_stock/app/core/session/app_modules.dart';
import 'package:shc_stock/app/core/utils/app_date.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/modified_by_cell.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/modules/sales/views/sales_actions.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/modules/billing/controllers/billing_summary_controller.dart';
import 'package:shc_stock/app/modules/sales/export/sales_export.dart';
import 'package:shc_stock/app/shared/widgets/export/export_menu_button.dart';
import 'package:shc_stock/app/shared/widgets/export/list_scope_bar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/table_footer.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/modules/sales/views/update_sales_status_dialog.dart';
import 'package:shc_stock/app/shared/widgets/row_action_button.dart';

part 'web_sales_side_panel.dart';

part 'web_sales_row.dart';

// ═════════════════════════════════════════════════════════════════════════════
// TABLE COLUMN CONSTANTS — used by BOTH _TableHeader and _SalesRow
// so they are always perfectly aligned.
// ═════════════════════════════════════════════════════════════════════════════
const double _kIdxWidth = 28.0; // # badge — fixed
const double _kColGap = 10.0; // gap between # badge and first flex col
// Flex ratios follow the design's grid:
// 1fr SO · 1.15fr Client · 0.7 Date · 0.55 Items · 0.8 Amount · 0.85 Status
// · 0.85 Payment · 1fr Modified By · 0.6 Actions
const int _kSoFlex = 18; // SO Number
const int _kClientFlex = 21; // Client badge + name
const int _kDateFlex = 14; // Date
const int _kItemsFlex = 11; // Items (center)
const int _kAmtFlex = 16; // Amount
const int _kStatusFlex = 17; // Status badge (center)
const int _kPayFlex = 17; // Payment badge (center)
const int _kModFlex = 14; // Modified By
// Actions (center) — Bill + View + Edit + Duplicate + Delete.
// Five 28px buttons with 6px between them need 164px. The share here was
// still sized for the four this column held before Bill arrived, so at a
// 1440px window the row overflowed by 61px and the last button was clipped
// behind the striped overflow bar. The width comes back out of Modified By
// and SO Number, which had the most slack.
const int _kActFlex = 34;

// ── KPI palette — the brand's tokens, not fixed hexes ───────────────────────
// The card tints itself from these: background at 10%, icon chip at 18%.
// Getters rather than consts so a rebrand recolours the cards with everything
// else; these used to be the design's literal hexes.
Color get kKpiBlue => appColors.purple;
Color get kKpiPurple => appColors.accent;
Color get kKpiAmber => appColors.warning;
Color get kKpiGreen => appColors.success;

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
                    final rowsPerPage = c.rowsPerPage.value;
                    final currentPage = c.currentPage.value;
                    // One source of truth: the table, the scope line and
                    // the Export menu all read the controller's query.
                    final filtered = c.filteredOrders;

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
                                        fontFamily: brandFontFamily,
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
                                        fontFamily: brandFontFamily,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (canWriteModule('Sales'))
                                _PrimaryBtn(
                                  label: 'Add Sale',
                                  icon: Icons.add_rounded,
                                  onTap: () => Get.toNamed(AppRoutes.addSale),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Stat Cards row ──────────────────────────────
                          if (canSeeSummary('Sales')) ...[
                            AppStatCardRow(
                              cards: [
                                AppStatCard(
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
                                AppStatCard(
                                  label: 'Orders',
                                  value:
                                      '${c.stats.value.intOf('totalOrders')}',
                                  icon: Icons.receipt_long_outlined,
                                  iconColor: context.appColors.accent,
                                  trend: c.stats.value.trendLabel(
                                    'totalOrders',
                                  ),
                                  trendUp: c.stats.value.trendUp('totalOrders'),
                                  showCaption: false,
                                ),
                                AppStatCard(
                                  label: 'Total Amount Due',
                                  value: formatRupees(
                                    c.stats.value.doubleOf('amountDue'),
                                  ),
                                  icon: Icons.warning_amber_rounded,
                                  iconColor: kKpiAmber,
                                  trend: c.stats.value.trendLabel('amountDue'),
                                  trendUp: c.stats.value.trendUp('amountDue'),
                                  showCaption: false,
                                  smallValue: true,
                                ),
                                AppStatCard(
                                  label: 'Total Received (MTD)',
                                  value: formatRupees(
                                    c.stats.value.doubleOf('receivedMTD'),
                                  ),
                                  icon: Icons.check_circle_outline_rounded,
                                  iconColor: kKpiGreen,
                                  trend: c.stats.value.trendLabel(
                                    'receivedMTD',
                                  ),
                                  trendUp: c.stats.value.trendUp('receivedMTD'),
                                  showCaption: false,
                                  smallValue: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],

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
                                    ListScopeBar(
                                      chips: [
                                        if (c.searchQuery.value.isNotEmpty)
                                          ListScopeChip(
                                            'Search: "${c.searchQuery.value}"',
                                            () => c.searchQuery.value = '',
                                          ),
                                        for (final client in c.clientFilters)
                                          ListScopeChip(
                                            client,
                                            () =>
                                                c.clientFilters.remove(client),
                                          ),
                                        for (final status in c.statusFilters)
                                          ListScopeChip(
                                            status,
                                            () =>
                                                c.statusFilters.remove(status),
                                          ),
                                        for (final pay in c.paymentFilters)
                                          ListScopeChip(
                                            pay,
                                            () => c.paymentFilters.remove(pay),
                                          ),
                                        if (c.sortOption.value != 'Default')
                                          ListScopeChip(
                                            'Sorted: ${c.sortOption.value}',
                                            () =>
                                                c.sortOption.value = 'Default',
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
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
                              // ── RIGHT: Panel ─────────────────────────────
                              // All three cards are business figures — the Sales
                              // summary right, and something to have figures
                              // about. Without either the table takes the full
                              // width. Gated on the whole list, not the
                              // filtered one, so a search that matches nothing
                              // does not make the page jump about.
                              if (canSeeSummary('Sales') &&
                                  c.orders.isNotEmpty) ...[
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 272,
                                  child: Column(
                                    children: [
                                      _SalesSummaryCard(
                                        colors: colors,
                                        controller: c,
                                      ),
                                      const SizedBox(height: 14),
                                      _BillingCard(colors: colors),
                                      const SizedBox(height: 14),
                                      _TopClientsCard(
                                        colors: colors,
                                        controller: c,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
      pillsVisible: () => c.orders.isNotEmpty,
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
      trailing: ExportMenuButton(source: salesExportConfig(controller)),
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
    fontFamily: brandFontFamily,
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
          fontFamily: brandFontFamily,
        ),
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
                fontFamily: brandFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

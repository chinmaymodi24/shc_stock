import 'package:shc_stock/app/core/session/app_modules.dart';
import 'package:shc_stock/app/core/utils/app_date.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:shc_stock/app/modules/purchase/controllers/purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/models/purchase_model.dart';
import 'package:shc_stock/app/modules/purchase/views/purchase_actions.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/modules/purchase/export/purchase_export.dart';
import 'package:shc_stock/app/shared/widgets/export/export_menu_button.dart';
import 'package:shc_stock/app/shared/widgets/export/list_scope_bar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/modified_by_cell.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/modules/purchase/views/update_purchase_status_dialog.dart';
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';
import 'package:shc_stock/app/shared/widgets/row_action_button.dart';
import 'package:shc_stock/app/shared/widgets/table_footer.dart';

part 'web_purchase_side_panel.dart';

part 'web_purchase_row.dart';

// ── Table column constants (header + row MUST match) ──────────────────────
const double _kIdxW = 32.0; // # badge
const double _kGap = 16.0; // column gap after # badge
const int _kPoFlex = 14; // PO Number
const int _kSupFlex = 16; // Supplier
const int _kDateFlex = 13; // Date
const int _kExpFlex = 14; // Expected Delivery
const int _kItemFlex = 7; // Items
const int _kAmtFlex = 12; // Amount
const int _kStsFlex = 11; // Status
const int _kModFlex = 16; // Modified By
const int _kActFlex = 20; // Actions — View + Edit + Duplicate + Delete

// ─────────────────────────────────────────────────────────────────────────────
class WebPurchaseLayout extends GetView<PurchaseController> {
  const WebPurchaseLayout({super.key});

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
                        ? <PurchaseOrder>[]
                        : filtered.sublist(startIdx, endIdx);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Page Header ──────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Purchases',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                      fontFamily: brandFontFamily,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Manage all purchase orders and track your inventory purchases.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.textSecondary,
                                      fontFamily: brandFontFamily,
                                    ),
                                  ),
                                ],
                              ),
                              if (canWriteModule('Purchase'))
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      Get.toNamed(AppRoutes.addPurchase),
                                  icon: const Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'New Purchase',
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        appColors.radius,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── 4 Stat Cards ─────────────────────────────────
                          if (canSeeSummary('Purchase')) ...[
                            AppStatCardRow(
                              cards: [
                                AppStatCard(
                                  label: 'Orders',
                                  value:
                                      '${c.stats.value.intOf('totalOrders')}',
                                  icon: Icons.receipt_long_outlined,
                                  iconColor: context.appColors.accent,
                                  trend: c.stats.value.trendLabel(
                                    'totalOrders',
                                  ),
                                  showCaption: false,
                                ),
                                AppStatCard(
                                  label: 'Purchase (MTD)',
                                  value: formatRupees(
                                    c.stats.value.doubleOf('purchaseMTD'),
                                  ),
                                  icon: Icons.shopping_cart_outlined,
                                  iconColor: AppColors.primaryOrange,
                                  trend: c.stats.value.trendLabel(
                                    'purchaseMTD',
                                  ),
                                  showCaption: false,
                                  smallValue: true,
                                ),
                                AppStatCard(
                                  label: 'Amount Paid',
                                  value: formatRupees(
                                    c.stats.value.doubleOf('amountPaid'),
                                  ),
                                  icon: Icons.check_circle_outline_rounded,
                                  iconColor: AppColors.success,
                                  trend: c.stats.value.trendLabel('amountPaid'),
                                  showCaption: false,
                                  smallValue: true,
                                ),
                                AppStatCard(
                                  label: 'Amount Due',
                                  value: formatRupees(
                                    c.stats.value.doubleOf('amountDue'),
                                  ),
                                  icon: Icons.currency_rupee_rounded,
                                  iconColor: AppColors.warning,
                                  trend: c.stats.value.trendLabel('amountDue'),
                                  trendUp: false,
                                  showCaption: false,
                                  smallValue: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],

                          // ── Body: Table + Right Panel ─────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── LEFT: Table Card ──────────────────────────
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: colors.divider),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Toolbar
                                      _TableToolbar(
                                        colors: colors,
                                        controller: c,
                                        onSearch: (v) {
                                          c.searchQuery.value = v;
                                          c.currentPage.value = 1;
                                        },
                                      ),
                                      Divider(height: 1, color: colors.divider),

                                      // States the export scope in words.
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          0,
                                          16,
                                          4,
                                        ),
                                        child: ListScopeBar(
                                          chips: [
                                            if (c.searchQuery.value.isNotEmpty)
                                              ListScopeChip(
                                                'Search: "'
                                                '${c.searchQuery.value}"',
                                                () {
                                                  c.searchCtrl.clear();
                                                  c.searchQuery.value = '';
                                                },
                                              ),
                                            if (c.supplierFilter.value !=
                                                'Supplier: All')
                                              ListScopeChip(
                                                c.supplierFilter.value,
                                                () => c.supplierFilter.value =
                                                    'Supplier: All',
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Column Headers
                                      _ColumnHeader(colors: colors),
                                      Divider(height: 1, color: colors.divider),

                                      // Data rows
                                      if (c.isLoading.value)
                                        const AppLoadingIndicator(
                                          label: 'Loading purchase orders...',
                                        )
                                      else if (pageItems.isEmpty)
                                        _EmptyState(colors: colors)
                                      else
                                        ...pageItems.asMap().entries.map((e) {
                                          final globalIdx = startIdx + e.key;
                                          return _PurchaseRow(
                                            order: e.value,
                                            index: globalIdx,
                                            colors: colors,
                                            isLast:
                                                e.key == pageItems.length - 1,
                                            onDelete: () => confirmDelete(
                                              context,
                                              itemName: e.value.poNumber,
                                              itemLabel: 'Purchase Order',
                                              onConfirm: () =>
                                                  c.deleteOrder(e.value.id),
                                            ),
                                          );
                                        }),

                                      // Footer
                                      Divider(height: 1, color: colors.divider),
                                      AppTableFooter(
                                        summaryText:
                                            'Showing ${filtered.isEmpty ? 0 : startIdx + 1}–$endIdx of ${filtered.length}',
                                        currentPage: currentPage,
                                        totalPages: totalPages,
                                        rowsPerPage: rowsPerPage,
                                        colors: colors,
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
                              ),

                              // ── RIGHT: Panel ──────────────────────────────
                              // Both cards are figures about the orders. With
                              // no purchase on record they could only read
                              // zero and list nobody, so the rail stays away
                              // entirely and the table takes the full width.
                              // Gated on the whole list, not the filtered one,
                              // so a search that matches nothing does not make
                              // the page jump about.
                              if (canSeeSummary('Purchase') &&
                                  c.orders.isNotEmpty) ...[
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 272,
                                  child: Column(
                                    children: [
                                      _PurchaseSummaryCard(
                                        colors: colors,
                                        c: c,
                                      ),
                                      const SizedBox(height: 14),
                                      _TopSuppliersCard(colors: colors, c: c),
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

// Table Toolbar
// ─────────────────────────────────────────────────────────────────────────────
class _TableToolbar extends StatefulWidget {
  final AppThemeColors colors;
  final PurchaseController controller;
  final ValueChanged<String> onSearch;
  const _TableToolbar({
    required this.colors,
    required this.controller,
    required this.onSearch,
  });

  @override
  State<_TableToolbar> createState() => _TableToolbarState();
}

class _TableToolbarState extends State<_TableToolbar> {
  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final c = widget.controller;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: FilterBar(
        pillsVisible: () => c.orders.isNotEmpty,
        search: FilterSearchField(
          controller: c.searchCtrl,
          hint: 'Search by Item or PO...',
          width: 260,
          onChanged: widget.onSearch,
        ),
        pills: [
          SingleSelectFilterPill(
            value: c.supplierFilter.value,
            items: c.supplierNames,
            onChanged: (v) {
              c.supplierFilter.value = v;
              c.currentPage.value = 1;
            },
          ),
        ],
        clearAll: Obx(() {
          if (!c.hasActiveFilters) return const SizedBox.shrink();
          return ClearAllButton(onTap: c.resetFilters);
        }),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExportMenuButton(source: purchaseExportConfig(c)),
            const SizedBox(width: 8),

            // View toggle icon
            Container(
              width: 36,
              height: 36,
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
// Column Headers
// ─────────────────────────────────────────────────────────────────────────────
class _ColumnHeader extends StatelessWidget {
  final AppThemeColors colors;
  const _ColumnHeader({required this.colors});

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
          SizedBox(
            width: _kIdxW,
            child: Text('#', style: _s),
          ),
          const SizedBox(width: _kGap),
          Expanded(
            flex: _kPoFlex,
            child: Text('PO Number', style: _s),
          ),
          Expanded(
            flex: _kSupFlex,
            child: Text('Supplier', style: _s),
          ),
          Expanded(
            flex: _kDateFlex,
            child: Text('Date', style: _s),
          ),
          Expanded(
            flex: _kExpFlex,
            child: Text('Expected Delivery', style: _s),
          ),
          Expanded(
            flex: _kItemFlex,
            child: Center(child: Text('Items', style: _s)),
          ),
          Expanded(
            flex: _kAmtFlex,
            child: Text('Amount', style: _s),
          ),
          Expanded(
            flex: _kStsFlex,
            child: Center(child: Text('Status', style: _s)),
          ),
          Expanded(
            flex: _kModFlex,
            child: Text('Modified By', style: _s),
          ),
          Expanded(
            flex: _kActFlex,
            child: Center(child: Text('Actions', style: _s)),
          ),
        ],
      ),
    );
  }
}

// Status Badge
class _StatusBadge extends StatelessWidget {
  final PurchaseStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case PurchaseStatus.received:
        bg = AppColors.success.withValues(alpha: 0.1);
        fg = AppColors.success;
        break;
      case PurchaseStatus.partial:
        bg = AppColors.warning.withValues(alpha: 0.1);
        fg = AppColors.warning;
        break;
      case PurchaseStatus.pending:
        bg = context.appColors.accent.withValues(alpha: 0.1);
        fg = context.appColors.accent;
        break;
      case PurchaseStatus.cancelled:
        bg = AppColors.danger.withValues(alpha: 0.1);
        fg = AppColors.danger;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
          fontFamily: brandFontFamily,
        ),
      ),
    );
  }
}

// Empty State
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
            Icon(Icons.receipt_long_outlined, size: 40, color: colors.textHint),
            const SizedBox(height: 10),
            Text(
              'No purchases found',
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

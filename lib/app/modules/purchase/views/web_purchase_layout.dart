import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:shc_stock/app/modules/purchase/controllers/purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/models/purchase_model.dart';
import 'package:shc_stock/app/modules/purchase/views/purchase_actions.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
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

// ── Table column constants (header + row MUST match) ──────────────────────
const double _kIdxW = 32.0; // # badge
const double _kGap = 16.0; // column gap after # badge
const int _kPoFlex = 16; // PO Number
const int _kSupFlex = 24; // Supplier
const int _kDateFlex = 14; // Date
const int _kItemFlex = 8; // Items
const int _kAmtFlex = 14; // Amount
const int _kStsFlex = 12; // Status
const int _kModFlex = 18; // Modified By
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
                    final all = c.orders;
                    final searchQuery = c.searchQuery.value;
                    final supplierFilter = c.supplierFilter.value;
                    final rowsPerPage = c.rowsPerPage.value;
                    final currentPage = c.currentPage.value;

                    var filtered = all.toList();

                    // Search filter
                    if (searchQuery.isNotEmpty) {
                      filtered = filtered
                          .where(
                            (o) =>
                                o.supplier.toLowerCase().contains(
                                  searchQuery.toLowerCase(),
                                ) ||
                                o.poNumber.toLowerCase().contains(
                                  searchQuery.toLowerCase(),
                                ),
                          )
                          .toList();
                    }

                    // Supplier filter
                    if (supplierFilter != 'Supplier: All') {
                      filtered = filtered
                          .where((o) => o.supplier == supplierFilter)
                          .toList();
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
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Manage all purchase orders and track your inventory purchases.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.textSecondary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    Get.toNamed(AppRoutes.addPurchase),
                                icon: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  'New Purchase',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
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
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── 4 Stat Cards ─────────────────────────────────
                          AppStatCardRow(
                            cards: [
                              AppStatCard(
                                label: 'Orders',
                                value: '${c.stats.value.intOf('totalOrders')}',
                                icon: Icons.receipt_long_outlined,
                                iconColor: context.appColors.accent,
                                trend: c.stats.value.trendLabel('totalOrders'),
                                showCaption: false,
                              ),
                              AppStatCard(
                                label: 'Purchase (MTD)',
                                value: formatRupees(
                                  c.stats.value.doubleOf('purchaseMTD'),
                                ),
                                icon: Icons.shopping_cart_outlined,
                                iconColor: AppColors.primaryOrange,
                                trend: c.stats.value.trendLabel('purchaseMTD'),
                                showCaption: false,
                                smallValue: true,
                              ),
                              AppStatCard(
                                label: 'Amount Paid',
                                value: formatRupees(
                                  c.stats.value.doubleOf('amountPaid'),
                                ),
                                icon: Icons.check_circle_outline_rounded,
                                iconColor: const Color(0xFF22C55E),
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
                                iconColor: const Color(0xFFF59E0B),
                                trend: c.stats.value.trendLabel('amountDue'),
                                trendUp: false,
                                showCaption: false,
                                smallValue: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

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

                              const SizedBox(width: 16),

                              // ── RIGHT: Panel ──────────────────────────────
                              SizedBox(
                                width: 272,
                                child: Column(
                                  children: [
                                    _PurchaseSummaryCard(colors: colors, c: c),
                                    const SizedBox(height: 14),
                                    _TopSuppliersCard(colors: colors, c: c),
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
            // Export
            OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(
                Icons.upload_outlined,
                size: 15,
                color: colors.textSecondary,
              ),
              label: Text(
                'Export',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  color: colors.textSecondary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                side: BorderSide(color: colors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
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
    fontFamily: 'Poppins',
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

// ─────────────────────────────────────────────────────────────────────────────
// Purchase Row
// ─────────────────────────────────────────────────────────────────────────────
class _PurchaseRow extends StatefulWidget {
  final PurchaseOrder order;
  final int index;
  final AppThemeColors colors;
  final bool isLast;
  final VoidCallback onDelete;

  const _PurchaseRow({
    required this.order,
    required this.index,
    required this.colors,
    required this.isLast,
    required this.onDelete,
  });

  @override
  State<_PurchaseRow> createState() => _PurchaseRowState();
}

class _PurchaseRowState extends State<_PurchaseRow> {
  final _hovered = false.obs;

  @override
  void dispose() {
    _hovered.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final colors = widget.colors;
    final dateStr =
        '${o.date.day.toString().padLeft(2, '0')} ${_month(o.date.month)} ${o.date.year}';

    // Resolve modified by
    final mod = resolveModifiedBy(
      storedName: o.modifiedBy,
      storedDate: o.modifiedAt,
    );

    return MouseRegion(
      onEnter: (_) => _hovered.value = true,
      onExit: (_) => _hovered.value = false,
      child: Obx(
        () => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _hovered.value ? colors.rowEven : colors.surface,
            border: widget.isLast
                ? null
                : Border(bottom: BorderSide(color: colors.divider, width: 0.8)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // # badge
                Container(
                  width: _kIdxW,
                  height: _kIdxW,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOrange,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: _kGap),

                // PO Number
                Expanded(
                  flex: _kPoFlex,
                  child: Text(
                    o.poNumber,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.accent,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Supplier
                Expanded(
                  flex: _kSupFlex,
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: context.appColors.accent.withValues(
                            alpha: 0.09,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.business_outlined,
                          color: context.appColors.accent,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          o.supplier,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
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
                    dateStr,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

                // Items
                Expanded(
                  flex: _kItemFlex,
                  child: Center(
                    // Units, not lines — a single 5-unit line used to read "1"
                    // here while the form showed 5. The line count is still a
                    // hover away.
                    child: Tooltip(
                      message: o.itemCount == 1
                          ? '1 line item'
                          : '${o.itemCount} line items',
                      child: Text(
                        o.totalQtyLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
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
                    _formatAmount(o.amount),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

                // Status badge — tap to change just the status, without
                // opening the whole record for editing.
                Expanded(
                  flex: _kStsFlex,
                  child: Center(
                    child: Tooltip(
                      message: 'Update status',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Get.dialog(
                          UpdatePurchaseStatusDialog(order: widget.order),
                        ),
                        child: _StatusBadge(status: o.status),
                      ),
                    ),
                  ),
                ),

                // Modified By
                Expanded(
                  flex: _kModFlex,
                  child: mod == null
                      ? ModifiedByEmpty(textHint: colors.textHint)
                      : ModifiedByCell(
                          name: mod.name,
                          date: mod.date,
                          textPrimary: colors.textPrimary,
                          textHint: colors.textHint,
                        ),
                ),

                // Actions: View, Edit, Delete
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
                        onTap: () =>
                            PurchaseActions.view(context, widget.order),
                      ),
                      const SizedBox(width: 5),
                      RowActionButton(
                        icon: Icons.edit_outlined,
                        color: AppColors.primaryOrange,
                        bg: AppColors.primaryOrange.withValues(alpha: 0.10),
                        tooltip: 'Edit',
                        onTap: () => PurchaseActions.edit(widget.order),
                      ),
                      const SizedBox(width: 5),
                      RowActionButton(
                        icon: Icons.copy_outlined,
                        color: const Color(0xFF3B82F6),
                        bg: const Color(0xFF3B82F6).withValues(alpha: 0.10),
                        tooltip: 'Duplicate',
                        onTap: () => PurchaseActions.duplicate(widget.order),
                      ),
                      const SizedBox(width: 5),
                      RowActionButton(
                        icon: Icons.delete_outline_rounded,
                        iconSize: 18,
                        color: context.appColors.error,
                        // Neutral, not red-tinted — only the icon carries
                        // the warning color.
                        bg: context.appColors.tagBg,
                        tooltip: 'Delete',
                        onTap: widget.onDelete,
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

  String _formatAmount(double v) {
    if (v >= 100000) {
      final lakh = v ~/ 100000;
      final thousands = (v % 100000) ~/ 1000;
      final rem = (v % 1000).toInt();
      if (thousands > 0) {
        return '₹$lakh,${thousands.toString().padLeft(2, '0')},${rem.toString().padLeft(3, '0')}';
      }
      return '₹$lakh,${rem.toString().padLeft(5, '0')}';
    }
    final s = v.toInt();
    if (s >= 1000) {
      final str = s.toString();
      return '₹${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return '₹$s';
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
        bg = const Color(0xFF22C55E).withValues(alpha: 0.1);
        fg = const Color(0xFF22C55E);
        break;
      case PurchaseStatus.partial:
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.1);
        fg = const Color(0xFFF59E0B);
        break;
      case PurchaseStatus.pending:
        bg = context.appColors.accent.withValues(alpha: 0.1);
        fg = context.appColors.accent;
        break;
      case PurchaseStatus.cancelled:
        bg = const Color(0xFFEF4444).withValues(alpha: 0.1);
        fg = const Color(0xFFEF4444);
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
          fontFamily: 'Poppins',
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
// Right Panel — Purchase Summary Card
// ─────────────────────────────────────────────────────────────────────────────
class _PurchaseSummaryCard extends StatelessWidget {
  final AppThemeColors colors;
  final PurchaseController c;
  const _PurchaseSummaryCard({required this.colors, required this.c});

  String _fmt(double v) {
    if (v >= 100000) {
      final lakh = v ~/ 100000;
      final thousands = (v % 100000) ~/ 1000;
      final rem = (v % 1000).toInt();
      if (thousands > 0) {
        return '₹$lakh,${thousands.toString().padLeft(2, '0')},${rem.toString().padLeft(3, '0')}';
      }
      return '₹$lakh,${rem.toString().padLeft(5, '0')}';
    }
    final s = v.toInt();
    if (s >= 1000) {
      final str = s.toString();
      return '₹${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return '₹$s';
  }

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
                  fontFamily: 'Poppins',
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
              valueColor: const Color(0xFF22C55E),
            ),
            _SumRow(
              label: 'Total Due',
              value: _fmt(c.totalAmountDue),
              colors: colors,
              valueColor: const Color(0xFFEF4444),
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
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? colors.textPrimary,
              fontFamily: 'Poppins',
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

  String _fmt(double v) {
    if (v >= 100000) {
      final lakh = v ~/ 100000;
      final thousands = (v % 100000) ~/ 1000;
      final rem = (v % 1000).toInt();
      if (thousands > 0) {
        return '₹$lakh,${thousands.toString().padLeft(2, '0')},${rem.toString().padLeft(3, '0')}';
      }
      return '₹$lakh,${rem.toString().padLeft(5, '0')}';
    }
    final s = v.toInt();
    if (s >= 1000) {
      final str = s.toString();
      return '₹${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return '₹$s';
  }

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
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  Text(
                    'View All',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                      fontFamily: 'Poppins',
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
                          Text(
                            supplier,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: colors.textPrimary,
                              fontFamily: 'Poppins',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$orderCount Orders',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textHint,
                              fontFamily: 'Poppins',
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
                        fontFamily: 'Poppins',
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:shc_stock/app/modules/transactions/controllers/transactions_controller.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/modules/transactions/models/transaction_model.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/transactions/views/transaction_form_dialog.dart';
import 'package:shc_stock/app/modules/transactions/views/transaction_actions.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/modified_by_cell.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/table_footer.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/shared/widgets/row_action_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main Widget — Transactions: colored summary cards + searchable/filterable table
// ─────────────────────────────────────────────────────────────────────────────
class WebTransactionsLayout extends GetView<TransactionsController> {
  const WebTransactionsLayout({super.key});

  static const _kTypes = ['Inbound', 'Outbound'];
  static const _kStatuses = ['Received', 'Shipped', 'Pending', 'Delivered'];

  @override
  Widget build(BuildContext context) {
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
                    final c = controller;
                    final all = c.transactions.toList();
                    final search = c.search.value;
                    final typeFilters = c.typeFilters;
                    final statusFilters = c.statusFilters;
                    final sortOption = c.sortOption.value;
                    final rowsPerPage = c.rowsPerPage.value;
                    final currentPage = c.currentPage.value;
                    final filtered = all.where((t) {
                      final q = search.toLowerCase();
                      if (q.isNotEmpty &&
                          !t.item.toLowerCase().contains(q) &&
                          !t.poNumber.toLowerCase().contains(q)) {
                        return false;
                      }
                      if (typeFilters.isNotEmpty &&
                          !typeFilters.contains(t.typeLabel)) {
                        return false;
                      }
                      if (statusFilters.isNotEmpty &&
                          !statusFilters.contains(t.statusLabel)) {
                        return false;
                      }
                      return true;
                    }).toList();

                    switch (sortOption) {
                      case 'Item Name (A-Z)':
                        filtered.sort((a, b) => a.item.compareTo(b.item));
                      case 'Item Name (Z-A)':
                        filtered.sort((a, b) => b.item.compareTo(a.item));
                      case 'Date: Newest First':
                        filtered.sort((a, b) => b.date.compareTo(a.date));
                      case 'Date: Oldest First':
                        filtered.sort((a, b) => a.date.compareTo(b.date));
                    }

                    final hasActiveFilters =
                        search.isNotEmpty ||
                        typeFilters.isNotEmpty ||
                        statusFilters.isNotEmpty ||
                        sortOption != 'Default';
                    final typeOptions = _kTypes.toList();
                    final statusOptions = _kStatuses.toList();

                    final totalPages = filtered.isEmpty
                        ? 1
                        : (filtered.length / rowsPerPage).ceil();
                    final startIdx = (currentPage - 1) * rowsPerPage;
                    final endIdx = math.min(
                      startIdx + rowsPerPage,
                      filtered.length,
                    );
                    final pageItems = filtered.isEmpty
                        ? <TransactionModel>[]
                        : filtered.sublist(startIdx, endIdx);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Page Header ──────────────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Transactions',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Inbound and outbound stock movement log.',
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
                                    Get.dialog(const TransactionFormDialog()),
                                icon: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  'New Transaction',
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

                          // ── Summary Stat Cards ───────────────────────────────────
                          AppStatCardRow(
                            cards: [
                              AppStatCard(
                                label: 'Total Transactions (This Month)',
                                value: '${c.totalThisMonth}',
                                icon: Icons.swap_horiz_rounded,
                                iconColor: const Color(0xFF3B6FC9),
                              ),
                              AppStatCard(
                                label: 'Inbound',
                                value: '${c.inboundCount}',
                                icon: Icons.call_received_rounded,
                                iconColor: const Color(0xFF2E9E5B),
                              ),
                              AppStatCard(
                                label: 'Outbound',
                                value: '${c.outboundCount}',
                                icon: Icons.call_made_rounded,
                                iconColor: const Color(0xFFC9822F),
                              ),
                              AppStatCard(
                                label: 'Pending',
                                value: '${c.pendingCount}',
                                icon: Icons.schedule_rounded,
                                iconColor: const Color(0xFFD1494C),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Toolbar: search + filters ─────────────────────────────
                          FilterBar(
                            search: FilterSearchField(
                              controller: c.searchCtrl,
                              hint: 'Search by item or PO #...',
                              width: 320,
                              onChanged: (v) {
                                c.search.value = v;
                                c.currentPage.value = 1;
                              },
                            ),
                            pills: [
                              MultiSelectFilterPill(
                                label: 'Type',
                                items: typeOptions,
                                selected: c.typeFilters,
                                onToggle: (v) {
                                  if (c.typeFilters.contains(v)) {
                                    c.typeFilters.remove(v);
                                  } else {
                                    c.typeFilters.add(v);
                                  }
                                  c.currentPage.value = 1;
                                },
                              ),
                              MultiSelectFilterPill(
                                label: 'Status',
                                items: statusOptions,
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
                              SingleSelectFilterPill.sort(
                                value: c.sortOption.value,
                                items: TransactionsController.sortOptions
                                    .where((o) => o != 'Default')
                                    .toList(),
                                onChanged: (v) => c.sortOption.value = v,
                              ),
                            ],
                            clearAll: hasActiveFilters
                                ? ClearAllButton(
                                    onTap: () {
                                      c.search.value = '';
                                      c.searchCtrl.clear();
                                      c.typeFilters.clear();
                                      c.statusFilters.clear();
                                      c.sortOption.value = 'Default';
                                      c.currentPage.value = 1;
                                    },
                                  )
                                : null,
                            trailing: Text(
                              '${filtered.length} transactions',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colors.textSecondary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Table Card ─────────────────────────────────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.divider),
                            ),
                            child: Column(
                              children: [
                                _ColHeader(colors: colors),
                                Divider(height: 1, color: colors.divider),

                                if (c.isLoading.value)
                                  const AppLoadingIndicator(
                                    label: 'Loading transactions...',
                                    padding: 40,
                                  )
                                else if (pageItems.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(48),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.receipt_long_outlined,
                                            size: 40,
                                            color: colors.textHint,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'No transactions found',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: colors.textHint,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ...pageItems.asMap().entries.map(
                                    (e) => _TransactionRow(
                                      txn: e.value,
                                      colors: colors,
                                      isLast: e.key == pageItems.length - 1,
                                    ),
                                  ),

                                Divider(height: 1, color: colors.divider),
                                AppTableFooter(
                                  currentPage: currentPage,
                                  totalPages: totalPages,
                                  rowsPerPage: rowsPerPage,
                                  colors: colors,
                                  onPageChanged: (p) => c.currentPage.value = p,
                                  onRowsChanged: (r) {
                                    c.rowsPerPage.value = r;
                                    c.currentPage.value = 1;
                                  },
                                ),
                              ],
                            ),
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
// Column Header
// ─────────────────────────────────────────────────────────────────────────────
class _ColHeader extends StatelessWidget {
  final AppThemeColors colors;
  const _ColHeader({required this.colors});
  TextStyle get _s => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: colors.textSecondary,
    fontFamily: 'Poppins',
    letterSpacing: 0.1,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text('Item', style: _s)),
          Expanded(flex: 3, child: Text('Type', style: _s)),
          Expanded(flex: 4, child: Text('Party', style: _s)),
          Expanded(flex: 3, child: Text('PO #', style: _s)),
          Expanded(flex: 3, child: Text('Date', style: _s)),
          Expanded(flex: 3, child: Text('Status', style: _s)),
          Expanded(flex: 4, child: Text('Modified By', style: _s)),
          Expanded(
            flex: 5,
            child: Center(child: Text('Actions', style: _s)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Row
// ─────────────────────────────────────────────────────────────────────────────
class _TransactionRow extends StatefulWidget {
  final TransactionModel txn;
  final AppThemeColors colors;
  final bool isLast;
  const _TransactionRow({
    required this.txn,
    required this.colors,
    required this.isLast,
  });
  @override
  State<_TransactionRow> createState() => _TransactionRowState();
}

class _TransactionRowState extends State<_TransactionRow> {
  // Local, widget-scoped hover flag — kept as an Rx on the persistent State
  // object (not setState) so only the row's background repaints on hover.
  final _hovered = false.obs;

  @override
  void dispose() {
    _hovered.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txn = widget.txn;
    final c = widget.colors;
    final dateFmt = DateFormat('MMM d, yyyy');

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
                // Item
                Expanded(
                  flex: 5,
                  child: Text(
                    txn.item,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Type (pill)
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: txn.typeColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        txn.typeLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: txn.typeColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ),

                // Party
                Expanded(
                  flex: 4,
                  child: Text(
                    txn.party,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: c.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // PO #
                Expanded(
                  flex: 3,
                  child: Text(
                    txn.poNumber,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

                // Date
                Expanded(
                  flex: 3,
                  child: Text(
                    dateFmt.format(txn.date),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: c.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

                // Status (colored text)
                Expanded(
                  flex: 3,
                  child: Text(
                    txn.statusLabel,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: txn.statusColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

                // Modified By
                Expanded(
                  flex: 4,
                  child: Builder(
                    builder: (_) {
                      final mod = resolveModifiedBy(
                        storedName: txn.modifiedBy,
                        storedDate: txn.modifiedAt,
                      );
                      if (mod == null) {
                        return ModifiedByEmpty(textHint: c.textHint);
                      }
                      return ModifiedByCell(
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
                  flex: 5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RowActionButton(
                        icon: Icons.remove_red_eye_outlined,
                        color: context.appColors.success,
                        bg: context.appColors.success.withValues(alpha: 0.10),
                        tooltip: 'View',
                        onTap: () => TransactionActions.view(txn),
                      ),
                      const SizedBox(width: 6),
                      RowActionButton(
                        icon: Icons.edit_outlined,
                        color: AppColors.primaryOrange,
                        bg: AppColors.primaryOrange.withValues(alpha: 0.10),
                        tooltip: 'Edit',
                        onTap: () => TransactionActions.edit(txn),
                      ),
                      const SizedBox(width: 6),
                      RowActionButton(
                        icon: Icons.copy_outlined,
                        color: const Color(0xFF3B82F6),
                        bg: const Color(0xFF3B82F6).withValues(alpha: 0.10),
                        tooltip: 'Duplicate',
                        onTap: () => TransactionActions.duplicate(txn),
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
                        onTap: () => TransactionActions.delete(context, txn),
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

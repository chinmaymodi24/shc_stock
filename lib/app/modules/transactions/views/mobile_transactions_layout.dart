import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/app_drawer.dart';
import 'package:shc_stock/app/modules/transactions/controllers/transactions_controller.dart';
import 'package:shc_stock/app/modules/transactions/models/transaction_model.dart';
import 'package:shc_stock/app/modules/transactions/views/transaction_form_dialog.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/shared/widgets/mobile_filter_sheet.dart';

/// Mobile counterpart of WebTransactionsLayout — same data/actions (Add,
/// Edit via TransactionFormDialog, Delete via confirmDelete), card list
/// instead of a table.
class MobileTransactionsLayout extends StatelessWidget {
  const MobileTransactionsLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TransactionsController>();
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      drawer: const AppDrawer(activeRoute: AppRoutes.transactions),
      appBar: _buildAppBar(context, c),
      body: Column(
        children: [
          _buildSearchBar(context, c),
          Expanded(child: _buildList(context, c)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.dialog(const TransactionFormDialog()),
        backgroundColor: AppColors.primaryOrange,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    TransactionsController c,
  ) {
    final colors = context.appColors;
    return AppBar(
      backgroundColor: colors.topBarBg,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.menu_rounded, color: colors.textPrimary, size: 24),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Text(
        'Transactions',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
          fontFamily: 'Poppins',
        ),
      ),
      actions: [
        MobileFilterButton(
          filters: _buildFilters(c),
          onClear: () {
            c.search.value = '';
            c.searchCtrl.clear();
            c.typeFilters.clear();
            c.statusFilters.clear();
            c.sortOption.value = 'Default';
            c.currentPage.value = 1;
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: colors.divider),
      ),
    );
  }

  // Same FilterSearchField the web filter row uses, and the same searchCtrl
  // so a Clear-all tap in the filter sheet also clears the visible text.
  Widget _buildSearchBar(BuildContext context, TransactionsController c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: FilterSearchField(
        controller: c.searchCtrl,
        hint: 'Search by item or PO #...',
        width: double.infinity,
        onChanged: (v) {
          c.search.value = v;
          c.currentPage.value = 1;
        },
      ),
    );
  }

  // Same data/controller bindings as WebTransactionsLayout's FilterBar —
  // Type, Status, Sort — shown as flat chip groups instead of dropdown
  // pills (see mobile_filter_sheet.dart for why).
  List<Widget> _buildFilters(TransactionsController c) {
    return [
      MobileFilterChipGroup(
        label: 'Type',
        items: const ['Inbound', 'Outbound'],
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
      MobileFilterChipGroup(
        label: 'Status',
        items: const ['Received', 'Shipped', 'Pending', 'Delivered'],
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
      Obx(
        () => MobileFilterChoiceGroup(
          label: 'Sort by',
          value: c.sortOption.value,
          items: TransactionsController.sortOptions
              .where((o) => o != 'Default')
              .toList(),
          onChanged: (v) => c.sortOption.value = v,
        ),
      ),
    ];
  }

  Widget _buildList(BuildContext context, TransactionsController c) {
    final colors = context.appColors;
    return Obx(() {
      if (c.isLoading.value && c.transactions.isEmpty) {
        return const AppLoadingIndicator(label: 'Loading transactions...');
      }
      // Same filter + sort logic as WebTransactionsLayout — search, type,
      // status, then the chosen sort order.
      final q = c.search.value.toLowerCase();
      final typeFilters = c.typeFilters;
      final statusFilters = c.statusFilters;
      final filtered = c.transactions.where((t) {
        if (q.isNotEmpty &&
            !t.item.toLowerCase().contains(q) &&
            !t.poNumber.toLowerCase().contains(q)) {
          return false;
        }
        if (typeFilters.isNotEmpty && !typeFilters.contains(t.typeLabel)) {
          return false;
        }
        if (statusFilters.isNotEmpty &&
            !statusFilters.contains(t.statusLabel)) {
          return false;
        }
        return true;
      }).toList();

      switch (c.sortOption.value) {
        case 'Item Name (A-Z)':
          filtered.sort((a, b) => a.item.compareTo(b.item));
        case 'Item Name (Z-A)':
          filtered.sort((a, b) => b.item.compareTo(a.item));
        case 'Date: Newest First':
          filtered.sort((a, b) => b.date.compareTo(a.date));
        case 'Date: Oldest First':
          filtered.sort((a, b) => a.date.compareTo(b.date));
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        children: [
          // IntrinsicHeight, not a fixed SizedBox — a fixed height clipped
          // AppStatCard whenever its 2-line label ("This Month") plus value
          // ran taller than the guessed number, so the strip now sizes to
          // whatever the tallest card actually needs.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _MobileStatCard(
                    label: 'This Month',
                    value: '${c.totalThisMonth}',
                    icon: Icons.swap_horiz_rounded,
                    color: const Color(0xFF3B6FC9),
                  ),
                  const SizedBox(width: 10),
                  _MobileStatCard(
                    label: 'Inbound',
                    value: '${c.inboundCount}',
                    icon: Icons.call_received_rounded,
                    color: const Color(0xFF2E9E5B),
                  ),
                  const SizedBox(width: 10),
                  _MobileStatCard(
                    label: 'Outbound',
                    value: '${c.outboundCount}',
                    icon: Icons.call_made_rounded,
                    color: const Color(0xFFC9822F),
                  ),
                  const SizedBox(width: 10),
                  _MobileStatCard(
                    label: 'Pending',
                    value: '${c.pendingCount}',
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFFD1494C),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Showing ${filtered.length} transactions',
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 44,
                      color: colors.textHint,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No transactions found',
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
            ...filtered.map((t) => _MobileTxnCard(txn: t)),
        ],
      );
    });
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
    return SizedBox(
      width: 140,
      child: AppStatCard(
        label: label,
        value: value,
        icon: icon,
        iconColor: color,
        smallValue: true,
        showCaption: false,
      ),
    );
  }
}

class _MobileTxnCard extends StatelessWidget {
  final TransactionModel txn;
  const _MobileTxnCard({required this.txn});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dateFmt = DateFormat('MMM d, yyyy');

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Get.dialog(TransactionFormDialog(existing: txn)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    txn.item,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: txn.typeColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${txn.party} · PO ${txn.poNumber}',
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                fontFamily: 'Poppins',
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: colors.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  dateFmt.format(txn.date),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const Spacer(),
                Text(
                  txn.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: txn.statusColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: colors.divider),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActBtn(
                  icon: Icons.edit_outlined,
                  color: AppColors.primaryOrange,
                  tooltip: 'Edit',
                  onTap: () => Get.dialog(TransactionFormDialog(existing: txn)),
                ),
                const SizedBox(width: 6),
                _ActBtn(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFEF4444),
                  tooltip: 'Delete',
                  onTap: () => confirmDelete(
                    context,
                    itemName: txn.item,
                    itemLabel: 'Transaction',
                    onConfirm: () => Get.find<TransactionsController>()
                        .deleteTransaction(txn.id),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
      ),
    );
  }
}

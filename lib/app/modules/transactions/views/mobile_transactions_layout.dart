import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/app_drawer.dart';
import 'package:shc_stock/app/modules/transactions/controllers/transactions_controller.dart';
import 'package:shc_stock/app/modules/transactions/models/transaction_model.dart';
import 'package:shc_stock/app/modules/transactions/views/transaction_form_dialog.dart';
import 'package:shc_stock/app/modules/transactions/views/transaction_actions.dart';
import 'package:shc_stock/app/shared/widgets/mobile_row_actions.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';
import 'package:shc_stock/app/shared/widgets/mobile_list_scaffold.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/shared/widgets/mobile_filter_sheet.dart';
import 'package:shc_stock/app/shared/widgets/mobile_appbar_avatar.dart';

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
      body: _buildList(context, c),
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
      centerTitle: true,
      actions: [
        Obx(
          () => MobileFilterButton(
            filters: _buildFilters(c),
            onClear: () {
              c.search.value = '';
              c.searchCtrl.clear();
              c.typeFilters.clear();
              c.statusFilters.clear();
              c.sortOption.value = 'Default';
              c.currentPage.value = 1;
            },
            activeCount:
                c.typeFilters.length +
                c.statusFilters.length +
                (c.sortOption.value == 'Default' ? 0 : 1),
          ),
        ),
        const MobileAppBarAvatar(),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: colors.divider),
      ),
    );
  }

  // Same FilterSearchField the web filter row uses, and the same searchCtrl
  // so a Clear-all tap in the filter sheet also clears the visible text.
  Widget _searchField(TransactionsController c) => FilterSearchField(
    controller: c.searchCtrl,
    hint: 'Search by item or PO #...',
    width: double.infinity,
    onChanged: (v) {
      c.search.value = v;
      c.currentPage.value = 1;
    },
  );

  List<MobileStatCardData> _statCards(TransactionsController c) {
    return [
      MobileStatCardData(
        label: 'This Month',
        value: '${c.totalThisMonth}',
        icon: Icons.swap_horiz_rounded,
        color: const Color(0xFF3B6FC9),
        onTap: () {
          c.typeFilters.clear();
          c.statusFilters.clear();
        },
      ),
      MobileStatCardData(
        label: 'Inbound',
        value: '${c.inboundCount}',
        icon: Icons.call_received_rounded,
        color: const Color(0xFF2E9E5B),
        selected: c.typeFilters.contains('Inbound'),
        onTap: () => c.typeFilters.contains('Inbound')
            ? c.typeFilters.remove('Inbound')
            : c.typeFilters.add('Inbound'),
      ),
      MobileStatCardData(
        label: 'Outbound',
        value: '${c.outboundCount}',
        icon: Icons.call_made_rounded,
        color: const Color(0xFFC9822F),
        selected: c.typeFilters.contains('Outbound'),
        onTap: () => c.typeFilters.contains('Outbound')
            ? c.typeFilters.remove('Outbound')
            : c.typeFilters.add('Outbound'),
      ),
      MobileStatCardData(
        label: 'Pending',
        value: '${c.pendingCount}',
        icon: Icons.schedule_rounded,
        color: const Color(0xFFD1494C),
        selected: c.statusFilters.contains('Pending'),
        onTap: () => c.statusFilters.contains('Pending')
            ? c.statusFilters.remove('Pending')
            : c.statusFilters.add('Pending'),
      ),
    ];
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
    return Obx(() {
      final loading = c.isLoading.value && c.transactions.isEmpty;
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

      return MobileListScaffold(
        statCards: _statCards(c),
        search: _searchField(c),
        countLabel:
            loading ? null : 'Showing ${filtered.length} transactions',
        sliver: loading
            ? const SliverFillRemaining(
                hasScrollBody: false,
                child: AppLoadingIndicator(label: 'Loading transactions...'),
              )
            : filtered.isEmpty
            ? const MobileListEmpty(
                icon: Icons.receipt_long_outlined,
                label: 'No transactions found',
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                sliver: SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _MobileTxnCard(txn: filtered[i]),
                ),
              ),
      );
    });
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
            // Same four actions the web table offers.
            MobileActionRow(
              actions: [
                MobileActionButton.view(
                  context: context,
                  onTap: () => TransactionActions.view(txn),
                ),
                MobileActionButton.edit(
                  context: context,
                  onTap: () => TransactionActions.edit(txn),
                ),
                MobileActionButton.duplicate(
                  onTap: () => TransactionActions.duplicate(txn),
                ),
                MobileActionButton.delete(
                  onTap: () => TransactionActions.delete(context, txn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../controllers/transactions_controller.dart';
import '../models/transaction_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/widgets/web_sidebar.dart';
import '../../dashboard/widgets/web_top_bar.dart';
import '../../dashboard/widgets/modified_by_cell.dart';

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
                          !typeFilters.contains(t.typeLabel))
                        return false;
                      if (statusFilters.isNotEmpty &&
                          !statusFilters.contains(t.statusLabel))
                        return false;
                      return true;
                    }).toList();

                    final hasActiveFilters =
                        search.isNotEmpty ||
                        typeFilters.isNotEmpty ||
                        statusFilters.isNotEmpty;
                    final typeOptions = _kTypes
                        .map(
                          (s) => _FilterOption(
                            s,
                            all.where((t) => t.typeLabel == s).length,
                          ),
                        )
                        .toList();
                    final statusOptions = _kStatuses
                        .map(
                          (s) => _FilterOption(
                            s,
                            all.where((t) => t.statusLabel == s).length,
                          ),
                        )
                        .toList();

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
                          Text(
                            'Transactions',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Summary Stat Cards ───────────────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'Total Transactions (This Month)',
                                  value: '${c.totalThisMonth}',
                                  bg: const Color(0xFFE3EDFB),
                                  labelColor: const Color(0xFF3B6FC9),
                                  valueColor: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  label: 'Inbound',
                                  value: '${c.inboundCount}',
                                  bg: const Color(0xFFE1F5E9),
                                  labelColor: const Color(0xFF2E9E5B),
                                  valueColor: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  label: 'Outbound',
                                  value: '${c.outboundCount}',
                                  bg: const Color(0xFFFBEBD9),
                                  labelColor: const Color(0xFFC9822F),
                                  valueColor: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatCard(
                                  label: 'Pending',
                                  value: '${c.pendingCount}',
                                  bg: const Color(0xFFFBE2E2),
                                  labelColor: const Color(0xFFD1494C),
                                  valueColor: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Toolbar: search + filters ─────────────────────────────
                          Row(
                            children: [
                              SizedBox(
                                width: 320,
                                height: 40,
                                child: TextField(
                                  controller: c.searchCtrl,
                                  onChanged: (v) {
                                    c.search.value = v;
                                    c.currentPage.value = 1;
                                  },
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textPrimary,
                                    fontFamily: 'Poppins',
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search by item or PO #...',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: colors.textHint,
                                      fontFamily: 'Poppins',
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search_rounded,
                                      color: colors.textHint,
                                      size: 17,
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    filled: true,
                                    fillColor: colors.inputFill,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: colors.border,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: colors.border,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: AppColors.primaryOrange,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _MultiSelectFilterPill(
                                icon: Icons.swap_horiz_rounded,
                                label: 'Type',
                                options: typeOptions,
                                selected: typeFilters,
                                onChanged: (v) {
                                  c.typeFilters.assignAll(v);
                                  c.currentPage.value = 1;
                                },
                                colors: colors,
                              ),
                              const SizedBox(width: 10),
                              _MultiSelectFilterPill(
                                icon: Icons.tune_rounded,
                                label: 'Status',
                                options: statusOptions,
                                selected: statusFilters,
                                onChanged: (v) {
                                  c.statusFilters.assignAll(v);
                                  c.currentPage.value = 1;
                                },
                                colors: colors,
                              ),
                              const Spacer(),
                              Text(
                                '${filtered.length} transactions',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: colors.textSecondary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              if (hasActiveFilters) ...[
                                const SizedBox(width: 12),
                                _ClearAllBtn(
                                  colors: colors,
                                  onTap: () {
                                    c.search.value = '';
                                    c.searchCtrl.clear();
                                    c.typeFilters.clear();
                                    c.statusFilters.clear();
                                    c.currentPage.value = 1;
                                  },
                                ),
                              ],
                            ],
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

                                if (pageItems.isEmpty)
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
                                _Footer(
                                  currentPage: currentPage,
                                  totalPages: totalPages,
                                  rowsPerPage: rowsPerPage,
                                  colors: colors,
                                  onPage: (p) => c.currentPage.value = p,
                                  onRows: (r) {
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
// Colored summary stat card (full-tinted background, per design reference)
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final Color bg, labelColor, valueColor;
  const _StatCard({
    required this.label,
    required this.value,
    required this.bg,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: labelColor,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Multi-select filter pill — checkbox dropdown, badge shows selection count
// ─────────────────────────────────────────────────────────────────────────────
class _FilterOption {
  final String label;
  final int? count;
  const _FilterOption(this.label, [this.count]);
}

class _MultiSelectFilterPill extends StatefulWidget {
  final IconData icon;
  final String label;
  final List<_FilterOption> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final AppThemeColors colors;

  const _MultiSelectFilterPill({
    required this.icon,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.colors,
  });

  @override
  State<_MultiSelectFilterPill> createState() => _MultiSelectFilterPillState();
}

class _MultiSelectFilterPillState extends State<_MultiSelectFilterPill> {
  final _overlayController = OverlayPortalController();
  final _link = LayerLink();

  void _toggle(String v) {
    final next = Set<String>.from(widget.selected);
    if (!next.remove(v)) next.add(v);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final count = widget.selected.length;
    final pillBg = colors.background.computeLuminance() > 0.5
        ? const Color(0xFFF1F2F4)
        : colors.inputFill;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) => Positioned(
          width: 230,
          child: CompositedTransformFollower(
            link: _link,
            offset: const Offset(0, 46),
            child: TapRegion(
              onTapOutside: (_) => _overlayController.hide(),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.options.map((o) {
                      final checked = widget.selected.contains(o.label);
                      return InkWell(
                        onTap: () => _toggle(o.label),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                checked
                                    ? Icons.check_box_rounded
                                    : Icons.check_box_outline_blank_rounded,
                                size: 18,
                                color: checked
                                    ? AppColors.primaryOrange
                                    : colors.textHint,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  o.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Poppins',
                                    color: colors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (o.count != null)
                                Text(
                                  '( ${o.count} )',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                    color: colors.textHint,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
        child: InkWell(
          onTap: _overlayController.toggle,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 15, color: colors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Clear all filters button
// ─────────────────────────────────────────────────────────────────────────────
class _ClearAllBtn extends StatelessWidget {
  final AppThemeColors colors;
  final VoidCallback onTap;
  const _ClearAllBtn({required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close_rounded, size: 15, color: colors.textSecondary),
            const SizedBox(width: 4),
            Text(
              'Clear all',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
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
                        seedId: txn.id,
                        storedName: txn.modifiedBy,
                        storedDate: txn.modifiedAt,
                      );
                      return ModifiedByCell(
                        name: mod.name,
                        date: mod.date,
                        textPrimary: c.textPrimary,
                        textHint: c.textHint,
                      );
                    },
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

// ─────────────────────────────────────────────────────────────────────────────
// Footer Pagination
// ─────────────────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final int currentPage, totalPages, rowsPerPage;
  final AppThemeColors colors;
  final ValueChanged<int> onPage, onRows;
  const _Footer({
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
    required this.colors,
    required this.onPage,
    required this.onRows,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Text(
            'Rows per page:',
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(6),
              color: colors.surface,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: rowsPerPage,
                isDense: true,
                style: TextStyle(
                  fontSize: 12.5,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
                dropdownColor: colors.surface,
                items: [5, 10, 20, 50]
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onRows(v);
                },
              ),
            ),
          ),
          const Spacer(),
          _PBtn(
            icon: Icons.first_page_rounded,
            enabled: currentPage > 1,
            colors: colors,
            onTap: () => onPage(1),
          ),
          const SizedBox(width: 4),
          _PBtn(
            icon: Icons.chevron_left_rounded,
            enabled: currentPage > 1,
            colors: colors,
            onTap: () => onPage(currentPage - 1),
          ),
          const SizedBox(width: 6),
          ..._buildPages(),
          const SizedBox(width: 6),
          _PBtn(
            icon: Icons.chevron_right_rounded,
            enabled: currentPage < totalPages,
            colors: colors,
            onTap: () => onPage(currentPage + 1),
          ),
          const SizedBox(width: 4),
          _PBtn(
            icon: Icons.last_page_rounded,
            enabled: currentPage < totalPages,
            colors: colors,
            onTap: () => onPage(totalPages),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPages() {
    final result = <Widget>[];
    final pages = <int>[];
    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        pages.add(i);
      }
    } else {
      pages.addAll([1, 2, 3]);
      if (currentPage > 4) pages.add(-1);
      if (currentPage > 3 && currentPage < totalPages - 1)
        pages.add(currentPage);
      pages.add(totalPages);
    }
    for (int i = 0; i < pages.length; i++) {
      if (i > 0) result.add(const SizedBox(width: 4));
      final p = pages[i];
      if (p == -1) {
        result.add(
          Text(
            '...',
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        );
      } else {
        final isA = p == currentPage;
        result.add(
          InkWell(
            onTap: () => onPage(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isA ? AppColors.primaryOrange : colors.surface,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isA ? AppColors.primaryOrange : colors.border,
                ),
              ),
              child: Center(
                child: Text(
                  '$p',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isA ? Colors.white : colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return result;
  }
}

class _PBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final AppThemeColors colors;
  final VoidCallback onTap;
  const _PBtn({
    required this.icon,
    required this.enabled,
    required this.colors,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(6),
          color: colors.surface,
        ),
        child: Icon(
          icon,
          size: 17,
          color: enabled ? colors.textPrimary : colors.textHint,
        ),
      ),
    );
  }
}

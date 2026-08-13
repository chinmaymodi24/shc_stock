import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'package:shc_stock/app/modules/stock/controllers/stock_controller.dart';
import 'package:shc_stock/app/shared/widgets/app_loading_indicator.dart';
import 'package:shc_stock/app/modules/stock/models/stock_item_model.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/modified_by_cell.dart';
import 'package:shc_stock/app/shared/widgets/table_footer.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main Widget — Inventory table with summary cards (no side panel).
// Every card value and trend comes from GET /api/stats/inventory.
// ─────────────────────────────────────────────────────────────────────────────
class WebStockLayout extends GetView<StockController> {
  const WebStockLayout({super.key});

  static const _kStatuses = [
    'In Stock',
    'Low Stock',
    'Out of Stock',
    'Inactive',
  ];

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
                    final all = c.items.toList();
                    final search = c.search.value;
                    final catFilters = c.catFilters;
                    final statFilters = c.statFilters;
                    final sortOption = c.sortOption.value;
                    final rowsPerPage = c.rowsPerPage.value;
                    final currentPage = c.currentPage.value;
                    final filtered = all.where((item) {
                      final q = search.toLowerCase();
                      if (q.isNotEmpty &&
                          !item.name.toLowerCase().contains(q) &&
                          !item.sku.toLowerCase().contains(q)) {
                        return false;
                      }
                      if (catFilters.isNotEmpty &&
                          !catFilters.contains(item.category)) {
                        return false;
                      }
                      if (statFilters.isNotEmpty &&
                          !statFilters.contains(item.statusLabel)) {
                        return false;
                      }
                      return true;
                    }).toList();

                    switch (sortOption) {
                      case 'Item Name (A-Z)':
                        filtered.sort((a, b) => a.name.compareTo(b.name));
                      case 'Item Name (Z-A)':
                        filtered.sort((a, b) => b.name.compareTo(a.name));
                      case 'Qty: Low to High':
                        filtered.sort(
                          (a, b) => a.stockInHand.compareTo(b.stockInHand),
                        );
                      case 'Qty: High to Low':
                        filtered.sort(
                          (a, b) => b.stockInHand.compareTo(a.stockInHand),
                        );
                      case 'Value: Low to High':
                        filtered.sort(
                          (a, b) => a.stockValue.compareTo(b.stockValue),
                        );
                      case 'Value: High to Low':
                        filtered.sort(
                          (a, b) => b.stockValue.compareTo(a.stockValue),
                        );
                    }

                    final hasActiveFilters =
                        search.isNotEmpty ||
                        catFilters.isNotEmpty ||
                        statFilters.isNotEmpty ||
                        sortOption != 'Default';
                    final categoryOptions =
                        all.map((i) => i.category).toSet().toList()..sort();
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
                        ? <StockItemModel>[]
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
                                    'Inventory',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${filtered.length} items',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.textSecondary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Add Item',
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

                          // ── Summary cards — all from GET /api/stats/inventory ─────
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: AppStatCard(
                                    label: 'Total Items',
                                    value:
                                        '${c.stats.value.intOf('totalItems')}',
                                    icon: Icons.inventory_2_outlined,
                                    iconColor: AppColors.primaryOrange,
                                    trend: c.stats.value.trendLabel(
                                      'totalItems',
                                    ),
                                    trendUp: c.stats.value.trendUp(
                                      'totalItems',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppStatCard(
                                    label: 'Low Stock',
                                    value: '${c.stats.value.intOf('lowStock')}',
                                    icon: Icons.warning_amber_rounded,
                                    iconColor: const Color(0xFFF59E0B),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppStatCard(
                                    label: 'Out of Stock',
                                    value:
                                        '${c.stats.value.intOf('outOfStock')}',
                                    icon: Icons.block_rounded,
                                    iconColor: const Color(0xFFEF4444),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppStatCard(
                                    label: 'Stock Value',
                                    value: formatRupees(
                                      c.stats.value.doubleOf('totalValue'),
                                    ),
                                    smallValue: true,
                                    icon: Icons.currency_rupee_rounded,
                                    iconColor: const Color(0xFF22C55E),
                                    // Stock movement volume this month vs last.
                                    trend: c.stats.value.trendLabel('movement'),
                                    trendUp: c.stats.value.trendUp('movement'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Toolbar: search + filters ─────────────────────────────
                          FilterBar(
                            search: FilterSearchField(
                              controller: c.searchCtrl,
                              hint: 'Search by name or SKU...',
                              width: 320,
                              onChanged: (v) {
                                c.search.value = v;
                                c.currentPage.value = 1;
                              },
                            ),
                            pills: [
                              MultiSelectFilterPill(
                                label: 'Category',
                                items: categoryOptions,
                                selected: c.catFilters,
                                onToggle: (v) {
                                  if (c.catFilters.contains(v)) {
                                    c.catFilters.remove(v);
                                  } else {
                                    c.catFilters.add(v);
                                  }
                                  c.currentPage.value = 1;
                                },
                              ),
                              MultiSelectFilterPill(
                                label: 'Status',
                                items: statusOptions,
                                selected: c.statFilters,
                                onToggle: (v) {
                                  if (c.statFilters.contains(v)) {
                                    c.statFilters.remove(v);
                                  } else {
                                    c.statFilters.add(v);
                                  }
                                  c.currentPage.value = 1;
                                },
                              ),
                              SingleSelectFilterPill.sort(
                                value: c.sortOption.value,
                                items: StockController.sortOptions
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
                                      c.catFilters.clear();
                                      c.statFilters.clear();
                                      c.sortOption.value = 'Default';
                                      c.currentPage.value = 1;
                                    },
                                  )
                                : null,
                            trailing: Text(
                              '${c.totalItems} items',
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
                                    label: 'Loading inventory...',
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
                                            Icons.inventory_2_outlined,
                                            size: 40,
                                            color: colors.textHint,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'No items found',
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
                                    (e) => _StockRow(
                                      item: e.value,
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
  Widget _sortIcon() =>
      Icon(Icons.unfold_more_rounded, size: 13, color: colors.textHint);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Text('Item', style: _s),
                const SizedBox(width: 4),
                _sortIcon(),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text('SKU', style: _s)),
          Expanded(flex: 4, child: Text('Category', style: _s)),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text('Qty', style: _s),
                const SizedBox(width: 4),
                _sortIcon(),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text('Status', style: _s)),
          Expanded(flex: 4, child: Text('Modified By', style: _s)),
          SizedBox(
            width: 96,
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
class _StockRow extends StatefulWidget {
  final StockItemModel item;
  final AppThemeColors colors;
  final bool isLast;
  const _StockRow({
    required this.item,
    required this.colors,
    required this.isLast,
  });
  @override
  State<_StockRow> createState() => _StockRowState();
}

class _StockRowState extends State<_StockRow> {
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
    final item = widget.item;
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
                // Item Name
                Expanded(
                  flex: 5,
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // SKU
                Expanded(
                  flex: 3,
                  child: Text(
                    item.sku,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: c.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

                // Category
                Expanded(
                  flex: 4,
                  child: Text(
                    item.category,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: c.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Qty
                Expanded(
                  flex: 2,
                  child: Text(
                    '${item.stockInHand}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A3AFF),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),

                // Status
                Expanded(
                  flex: 3,
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: item.statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.statusLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: item.statusColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ),

                // Modified By
                Expanded(
                  flex: 4,
                  child: Builder(
                    builder: (_) {
                      final mod = resolveModifiedBy(
                        storedName: item.modifiedBy,
                        storedDate: item.modifiedAt,
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
                SizedBox(
                  width: 96,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActBtn(
                        icon: Icons.edit_outlined,
                        color: const Color(0xFF4A3AFF),
                        tooltip: 'Edit',
                      ),
                      const SizedBox(width: 4),
                      _ActBtn(
                        icon: Icons.copy_outlined,
                        color: c.textSecondary,
                        tooltip: 'Duplicate',
                      ),
                      const SizedBox(width: 4),
                      _ActBtn(
                        icon: Icons.delete_outline_rounded,
                        color: const Color(0xFFEF4444),
                        tooltip: 'Delete',
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

class _ActBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  const _ActBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
  });
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(7),
        child: SizedBox(
          width: 26,
          height: 26,
          child: Icon(icon, color: color, size: 15),
        ),
      ),
    );
  }
}

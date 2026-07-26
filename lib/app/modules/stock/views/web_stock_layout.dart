import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controllers/stock_controller.dart';
import '../models/stock_item_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/widgets/web_sidebar.dart';
import '../../dashboard/widgets/web_top_bar.dart';
import '../../dashboard/widgets/modified_by_cell.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main Widget — simple Inventory table (no stat cards, no side panel)
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

                    final hasActiveFilters =
                        search.isNotEmpty ||
                        catFilters.isNotEmpty ||
                        statFilters.isNotEmpty;
                    final categoryOptions =
                        (all.map((i) => i.category).toSet().toList()..sort())
                            .map((cat) => _FilterOption(cat))
                            .toList();
                    final statusOptions = _kStatuses
                        .map(
                          (s) => _FilterOption(
                            s,
                            all.where((i) => i.statusLabel == s).length,
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
                                    hintText: 'Search by name or SKU...',
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
                                icon: Icons.tune_rounded,
                                label: 'Category',
                                options: categoryOptions,
                                selected: catFilters,
                                onChanged: (v) {
                                  c.catFilters.assignAll(v);
                                  c.currentPage.value = 1;
                                },
                                colors: colors,
                              ),
                              const SizedBox(width: 10),
                              _MultiSelectFilterPill(
                                icon: Icons.tune_rounded,
                                label: 'Status',
                                options: statusOptions,
                                selected: statFilters,
                                onChanged: (v) {
                                  c.statFilters.assignAll(v);
                                  c.currentPage.value = 1;
                                },
                                colors: colors,
                              ),
                              const Spacer(),
                              Text(
                                '${c.totalItems} items',
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
                                    c.catFilters.clear();
                                    c.statFilters.clear();
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
                        seedId: item.id,
                        storedName: item.modifiedBy,
                        storedDate: item.modifiedAt,
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

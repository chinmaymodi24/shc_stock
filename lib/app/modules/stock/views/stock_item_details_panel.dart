import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/modified_by_cell.dart';
import 'package:shc_stock/app/modules/purchase/controllers/purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/models/purchase_model.dart';
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/modules/stock/controllers/stock_controller.dart';
import 'package:shc_stock/app/modules/stock/models/stock_item_model.dart';

PurchaseController _purchaseController() {
  if (Get.isRegistered<PurchaseController>()) {
    return Get.find<PurchaseController>();
  }
  return Get.put(PurchaseController(), permanent: true);
}

SalesController _salesController() {
  if (Get.isRegistered<SalesController>()) {
    return Get.find<SalesController>();
  }
  return Get.put(SalesController(), permanent: true);
}

String _fmtQty(double q) =>
    q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toStringAsFixed(2);

/// One resolved row of the item's history ledger — a `stock_movements` row
/// enriched with the purchase/sale order it came from (supplier/client name,
/// PO/SO number, line amount). [refType] ('purchase' | 'sale' | 'manual')
/// decides which section of the panel it renders in — purchases and sales
/// and manual adjustments are shown separately, never merged into one list.
class _HistoryEntry {
  final bool isIn;
  final String refType;
  final String title;
  final String subtitle;
  final double? amount;
  final DateTime? date;
  const _HistoryEntry({
    required this.isIn,
    required this.refType,
    required this.title,
    required this.subtitle,
    this.amount,
    this.date,
  });
}

List<_HistoryEntry> _buildEntries(
  StockItemModel item,
  List<StockMovement> movements,
  List<PurchaseOrder> purchaseOrders,
  List<SalesOrder> salesOrders,
) {
  final entries = <_HistoryEntry>[];
  for (final m in movements) {
    if (m.refType == 'purchase') {
      final po = purchaseOrders.firstWhereOrNull(
        (o) => o.id == (m.refId?.toString() ?? ''),
      );
      final lines = po?.items.where((i) => i.productId == item.productId);
      final amount = (lines == null || lines.isEmpty)
          ? null
          : lines.fold<double>(0, (s, i) => s + i.amount);
      entries.add(
        _HistoryEntry(
          isIn: true,
          refType: 'purchase',
          title: (po != null && po.supplier.isNotEmpty)
              ? po.supplier
              : 'Purchase',
          subtitle:
              'Qty: ${_fmtQty(m.qty)} · ${m.reference.isEmpty ? '—' : m.reference}',
          amount: amount,
          date: po?.date ?? m.createdAt,
        ),
      );
    } else if (m.refType == 'sale') {
      final so = salesOrders.firstWhereOrNull(
        (o) => o.id == (m.refId?.toString() ?? ''),
      );
      final lines = so?.items.where((i) => i.productId == item.productId);
      final amount = (lines == null || lines.isEmpty)
          ? null
          : lines.fold<double>(0, (s, i) => s + i.amount);
      entries.add(
        _HistoryEntry(
          isIn: false,
          refType: 'sale',
          title: (so != null && so.client.isNotEmpty) ? so.client : 'Sale',
          subtitle:
              'Qty: ${_fmtQty(m.qty)} · ${m.reference.isEmpty ? '—' : m.reference}',
          amount: amount,
          date: so?.date ?? m.createdAt,
        ),
      );
    } else {
      entries.add(
        _HistoryEntry(
          isIn: m.isIn,
          refType: 'manual',
          title: m.isIn ? 'Stock Added' : 'Stock Removed',
          subtitle: m.note.isEmpty
              ? 'Qty: ${_fmtQty(m.qty)}'
              : 'Qty: ${_fmtQty(m.qty)} · ${m.note}',
          // Only set when the adjustment was booked with a price — most
          // manual corrections have none, and stay '—' in the row.
          amount: m.amount,
          date: m.createdAt,
        ),
      );
    }
  }
  entries.sort(
    (a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)),
  );
  return entries;
}

/// Read-only "Item Details" side panel opened from the Inventory list's View
/// icon (and from the Stock Adjustment dialog's "Show Full History"). Top
/// half is the product snapshot (dynamic, straight off the loaded
/// [StockItemModel]); the bottom half is that product's full `stock_movements`
/// ledger — "Purchased From", "Sold To", and "Stock Adjustment" history, kept
/// as three separate lists (never merged) so a purchase, a sale, and a manual
/// correction are never mistaken for one another. This is the whole point of
/// the panel: every unit this item ever had, and where it came from or went.
class StockItemDetailsPanel extends StatefulWidget {
  final StockItemModel item;

  /// Wired by the caller (same pattern as [ClientDetailsDialog]) so this
  /// panel doesn't need to know how a product delete is confirmed/executed.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const StockItemDetailsPanel({
    super.key,
    required this.item,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<StockItemDetailsPanel> createState() => _StockItemDetailsPanelState();
}

class _StockItemDetailsPanelState extends State<StockItemDetailsPanel> {
  final RxBool _loading = true.obs;
  final RxList<StockMovement> _movements = <StockMovement>[].obs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await Get.find<StockController>().fetchMovements(
      productId: widget.item.productId,
    );
    _movements.assignAll(data);
    _loading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final item = widget.item;
    final purchase = _purchaseController();
    final sales = _salesController();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      alignment: Alignment.centerRight,
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          // Full-width on phones — a fixed 400px side panel would overflow
          // (and mostly clip off-screen) on anything narrower than that.
          width: MediaQuery.of(context).size.width < 480
              ? MediaQuery.of(context).size.width
              : 400,
          height: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 24,
                offset: const Offset(-6, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Item Details',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: Get.back,
                      borderRadius: BorderRadius.circular(8),
                      child: Icon(
                        Icons.close_rounded,
                        color: colors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.divider),

              // ── Body ──────────────────────────────────────────────
              Expanded(
                child: Obx(() {
                  final loading = _loading.value;
                  final entries = _buildEntries(
                    item,
                    _movements,
                    purchase.orders,
                    sales.orders,
                  );
                  final purchaseEntries = entries
                      .where((e) => e.refType == 'purchase')
                      .toList();
                  // Entries are already sorted newest-first, so the top of
                  // this list is the most recent restock.
                  final latestPurchase = purchaseEntries.isEmpty
                      ? null
                      : purchaseEntries.first;
                  final salesEntries = entries
                      .where((e) => e.refType == 'sale')
                      .toList();
                  final adjustmentEntries = entries
                      .where((e) => e.refType == 'manual')
                      .toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Item Name', colors),
                        const SizedBox(height: 4),
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SKU: ${item.sku}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 18),
                        _pairField(
                          'Quantity on Hand',
                          '${item.stockInHand} ${item.unit}',
                          'Reorder Point',
                          '${item.minimumStock} ${item.unit}',
                          colors,
                        ),
                        const SizedBox(height: 14),
                        _sectionLabel('Status', colors),
                        const SizedBox(height: 5),
                        Container(
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
                        const SizedBox(height: 14),
                        _pairField(
                          'Category',
                          item.category.isEmpty ? '—' : item.category,
                          'Unit Price',
                          formatRupees(item.sellingPrice),
                          colors,
                        ),
                        const SizedBox(height: 14),
                        _pairField(
                          'Supplier',
                          latestPurchase?.title ?? '—',
                          'Last Restocked',
                          latestPurchase?.date == null
                              ? '—'
                              : DateFormat(
                                  'MMM d, yyyy',
                                ).format(latestPurchase!.date!),
                          colors,
                        ),
                        const SizedBox(height: 18),
                        Divider(height: 1, color: colors.divider),
                        const SizedBox(height: 14),

                        // ── Purchased From (Purchase History) — every
                        // purchase order that added this item's stock.
                        _sectionLabel('Purchased From (Purchase History)', colors),
                        const SizedBox(height: 10),
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        else if (purchaseEntries.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'No purchases recorded for this item yet.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colors.textHint,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          )
                        else
                          ...purchaseEntries.map(
                            (e) => _historyRow(e, colors, showIcon: false),
                          ),

                        const SizedBox(height: 8),
                        Divider(height: 1, color: colors.divider),
                        const SizedBox(height: 14),

                        // ── Sold To (Sales History) — kept separate from
                        // manual adjustments below; never merged into one
                        // list, so the two are never mistaken for each other.
                        _sectionLabel('Sold To (Sales History)', colors),
                        const SizedBox(height: 10),
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        else if (salesEntries.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'No sales recorded for this item yet.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colors.textHint,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          )
                        else
                          ...salesEntries.map(
                            (e) => _historyRow(e, colors, showIcon: false),
                          ),

                        const SizedBox(height: 8),
                        Divider(height: 1, color: colors.divider),
                        const SizedBox(height: 14),

                        // ── Stock Adjustment History — manual IN/OUT
                        // corrections only (Set Reorder Point Only never
                        // books a movement, so it never appears here).
                        _sectionLabel('Stock Adjustment History', colors),
                        const SizedBox(height: 10),
                        if (loading)
                          const SizedBox.shrink()
                        else if (adjustmentEntries.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'No manual adjustments recorded.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colors.textHint,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          )
                        else
                          ...adjustmentEntries.map(
                            (e) => _historyRow(e, colors),
                          ),

                        const SizedBox(height: 8),
                        Divider(height: 1, color: colors.divider),
                        const SizedBox(height: 14),
                        _sectionLabel('Modified By', colors),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (_) {
                            final mod = resolveModifiedBy(
                              storedName: item.modifiedBy,
                              storedDate: item.modifiedAt,
                            );
                            if (mod == null) {
                              return ModifiedByEmpty(textHint: colors.textHint);
                            }
                            return ModifiedByCell(
                              name: mod.name,
                              date: mod.date,
                              textPrimary: colors.textPrimary,
                              textHint: colors.textHint,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ),

              // ── Footer: Edit / Delete ──────────────────────────────
              Divider(height: 1, color: colors.divider),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onEdit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.inputFill,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, AppThemeColors colors) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: colors.textHint,
      fontFamily: 'Poppins',
      letterSpacing: 0.5,
    ),
  );

  Widget _field(String label, String value, AppThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(label, colors),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '—' : value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _pairField(
    String label1,
    String value1,
    String label2,
    String value2,
    AppThemeColors colors,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _field(label1, value1, colors)),
        Expanded(child: _field(label2, value2, colors)),
      ],
    );
  }

  /// [showIcon] is off for Sales History — every row there is a sale (always
  /// stock-out), so the in/out icon would just repeat what the section
  /// heading already says. Adjustment History mixes both directions, so it
  /// keeps the icon.
  Widget _historyRow(
    _HistoryEntry e,
    AppThemeColors colors, {
    bool showIcon = true,
  }) {
    final color = e.isIn ? colors.success : colors.warning;
    final dateFmt = DateFormat('MMM d, yyyy');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showIcon) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                e.isIn ? Icons.call_received_rounded : Icons.call_made_rounded,
                size: 15,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  e.subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                e.amount == null ? '—' : formatRupees(e.amount!),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                e.date == null ? '—' : dateFmt.format(e.date!),
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textHint,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

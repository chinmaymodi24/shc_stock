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

/// One resolved row of the "Stock History" ledger — a `stock_movements` row
/// enriched with the purchase/sale order it came from (supplier/client name,
/// PO/SO number, line amount), so a purchase and a sale render with the same
/// rich entry instead of a bare qty/date line.
class _HistoryEntry {
  final bool isIn;
  final String title;
  final String subtitle;
  final double? amount;
  final DateTime? date;
  const _HistoryEntry({
    required this.isIn,
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
          title: 'Manual Adjustment',
          subtitle: m.note.isEmpty
              ? 'Qty: ${_fmtQty(m.qty)}'
              : 'Qty: ${_fmtQty(m.qty)} · ${m.note}',
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
/// icon. Top half is the product snapshot (dynamic, straight off the loaded
/// [StockItemModel]); the bottom half is a unified ledger built from that
/// product's `stock_movements` rows — every purchase that added stock and
/// every sale that took it back out, in one dated list. This is what answers
/// "I had this much stock, where did it all go".
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
          width: 400,
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
                  final latestPurchase = entries.firstWhereOrNull(
                    (e) => e.isIn,
                  );

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

                        // ── Stock History — every purchase (stock in) and
                        // sale (stock out) recorded against this product,
                        // newest first. Answers "where did this stock go".
                        _sectionLabel('Stock History', colors),
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
                        else if (entries.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'No purchases or sales recorded for this item yet.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colors.textHint,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          )
                        else
                          ...entries.map((e) => _historyRow(e, colors)),

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
                              return ModifiedByEmpty(
                                textHint: colors.textHint,
                              );
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

  Widget _historyRow(_HistoryEntry e, AppThemeColors colors) {
    final color = e.isIn ? colors.success : colors.warning;
    final dateFmt = DateFormat('MMM d, yyyy');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

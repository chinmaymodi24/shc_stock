import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/utils/stock_sync.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/purchase/models/purchase_model.dart';

class PurchaseController extends GetxController {
  /// Summary cards for this page — values *and* month-over-month trends come
  /// from GET /api/stats/purchase, so nothing on the cards is computed here or
  /// hardcoded.
  final stats = StatsSnapshot.empty.obs;

  Future<void> fetchStats() async {
    try {
      stats.value = await StatsSnapshot.fetch('purchase');
    } catch (e) {
      // Cards fall back to zeros; the list fetch already reported any outage.
    }
  }

  final _api = ApiClient.instance;

  // ── Observable list ──────────────────────────────────────────
  final RxList<PurchaseOrder> orders = <PurchaseOrder>[].obs;
  final RxBool isLoading = false.obs;
  final searchCtrl = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString supplierFilter = 'Supplier: All'.obs;
  final RxInt rowsPerPage = 10.obs;
  final RxInt currentPage = 1.obs;

  bool get hasActiveFilters =>
      searchQuery.value.isNotEmpty || supplierFilter.value != 'Supplier: All';

  void resetFilters() {
    searchCtrl.clear();
    searchQuery.value = '';
    supplierFilter.value = 'Supplier: All';
    currentPage.value = 1;
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }

  // ── Stats ────────────────────────────────────────────────────
  int get totalOrders => orders.length;
  double get totalPurchaseMTD => orders.fold(0, (s, o) => s + o.amount);
  double get totalAmountPaid => orders
      .where((o) => o.status == PurchaseStatus.received)
      .fold(0, (s, o) => s + o.amount);
  double get totalAmountDue => orders
      .where(
        (o) =>
            o.status == PurchaseStatus.pending ||
            o.status == PurchaseStatus.partial,
      )
      .fold(0, (s, o) => s + o.amount);
  double get averageOrderValue =>
      orders.isEmpty ? 0 : totalPurchaseMTD / orders.length;

  // ── Top Suppliers (by total amount) ─────────────────────────
  List<MapEntry<String, double>> get topSuppliers {
    final map = <String, double>{};
    for (final o in orders) {
      map[o.supplier] = (map[o.supplier] ?? 0) + o.amount;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(4).toList();
  }

  // ── Unique suppliers for filter ──────────────────────────────
  List<String> get supplierNames {
    final names = orders.map((o) => o.supplier).toSet().toList();
    names.sort();
    return names;
  }

  // ── Seed data (matching screenshot style) ───────────────────
  // The old 28-order seed list is archived in static_data.txt at the
  // project root. Orders now load dynamically via fetchOrders() below.

  void _showError(String message) {
    showAppToast(
      'Error',
      message,
      backgroundColor: const Color(0xFFEF4444),
      colorText: Colors.white,
    );
  }

  // ── Fetch ────────────────────────────────────────────────────
  Future<void> fetchOrders() async {
    isLoading.value = true;
    try {
      final data = await _api.get('/purchase-orders') as List<dynamic>;
      orders.assignAll(
        data.map((e) => PurchaseOrder.fromJson(e as Map<String, dynamic>)),
      );
    } catch (e) {
      _showError('Failed to load purchase orders. Is the backend running?');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchStats();
    fetchOrders();
  }

  // ── CRUD ─────────────────────────────────────────────────────

  /// Creates a purchase order via the backend `/purchase-orders` API.
  /// Returns true on success (the real, server-assigned order is inserted
  /// into [orders]); false on failure (error toast already shown).
  ///
  /// Unlike `SalesController.addOrder`, this has no per-product "insufficient
  /// stock" message to unpack: a purchase only ever adds stock
  /// (`applyStock(direction: +1)` server-side), so the 409/InsufficientStock
  /// path in `stockService.js` can never trigger here — only sales, which
  /// remove stock, can go negative.
  Future<bool> addOrder(PurchaseOrder order) async {
    try {
      final json = await _api.post('/purchase-orders', order.toCreateJson());
      orders.insert(0, PurchaseOrder.fromJson(json as Map<String, dynamic>));
      // Receiving goods raised stock server-side — pull the inventory and
      // product caches back in line.
      await refreshStockViews();
      return true;
    } catch (e) {
      _showError('Failed to save purchase order.');
      return false;
    }
  }

  /// Replaces an existing order — the whole record, not just its status.
  /// The server reverses the old stock movements and applies the new lines in
  /// one transaction, so the inventory caches are pulled back in line here
  /// exactly as they are after a create.
  Future<bool> updateOrder(PurchaseOrder order) async {
    try {
      final json = await _api.put(
        '/purchase-orders/${order.id}',
        order.toCreateJson(),
      );
      final saved = PurchaseOrder.fromJson(json as Map<String, dynamic>);
      // Last modified first: the edited order goes back to the top.
      final idx = orders.indexWhere((o) => o.id == order.id);
      if (idx != -1) orders.removeAt(idx);
      orders.insert(0, saved);
      await refreshStockViews();
      await fetchStats();
      return true;
    } catch (e) {
      _showError('Failed to update purchase order.');
      return false;
    }
  }

  Future<void> deleteOrder(String id) async {
    try {
      await _api.delete('/purchase-orders/$id');
      orders.removeWhere((o) => o.id == id);
      // Deleting the order reversed its stock movements server-side.
      await refreshStockViews();
    } catch (e) {
      _showError('Failed to delete purchase order.');
    }
  }

  Future<void> updateStatus(String id, PurchaseStatus status) async {
    final idx = orders.indexWhere((o) => o.id == id);
    if (idx == -1) return;
    try {
      final json = await _api.patch('/purchase-orders/$id/status', {
        'status': status.label,
      });
      orders.removeAt(idx);
      orders.insert(0, PurchaseOrder.fromJson(json as Map<String, dynamic>));
    } catch (e) {
      _showError('Failed to update status.');
    }
  }
}

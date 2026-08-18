import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/utils/stock_sync.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';

class SalesController extends GetxController {
  /// Summary cards for this page — values *and* month-over-month trends come
  /// from GET /api/stats/sales, so nothing on the cards is computed here or
  /// hardcoded.
  final stats = StatsSnapshot.empty.obs;

  Future<void> fetchStats() async {
    try {
      stats.value = await StatsSnapshot.fetch('sales');
    } catch (e) {
      // Cards fall back to zeros; the list fetch already reported any outage.
    }
  }

  final _api = ApiClient.instance;

  // ── Observable list ──────────────────────────────────────────
  final RxList<SalesOrder> orders = <SalesOrder>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt mobileTabIndex = 0.obs; // 0 = All, 1 = Confirmed, 2 = Delivered
  final RxString searchQuery = ''.obs;
  final RxSet<String> statusFilters = <String>{}.obs;
  final RxSet<String> paymentFilters = <String>{}.obs;

  /// Client names ticked in the toolbar's "Client" filter — the design's
  /// sales list filters by client rather than by status/payment.
  final RxSet<String> clientFilters = <String>{}.obs;
  final RxString sortOption = 'Default'.obs;
  final RxInt rowsPerPage = 10.obs;
  final RxInt currentPage = 1.obs;

  static const statusOptions = [
    'Confirmed',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];
  static const paymentOptions = ['Paid', 'Partial', 'Pending', 'Refunded'];
  static const sortOptions = [
    'Default',
    'Date: Newest First',
    'Date: Oldest First',
    'Amount: Low to High',
    'Amount: High to Low',
  ];

  void resetFilters() {
    searchQuery.value = '';
    statusFilters.clear();
    paymentFilters.clear();
    clientFilters.clear();
    sortOption.value = 'Default';
    currentPage.value = 1;
  }

  // ── Client color map & seed data ─────────────────────────────
  // The old client badge→color map, 15-order seed list, and 141-order
  // generator are archived in static_data.txt at the project root. Order
  // colors now come through SalesOrder.fromJson; orders load dynamically
  // via fetchOrders() below.

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
      final data = await _api.get('/sales-orders') as List<dynamic>;
      orders.assignAll(
        data.map((e) => SalesOrder.fromJson(e as Map<String, dynamic>)),
      );
    } catch (e) {
      _showError('Failed to load sales orders. Is the backend running?');
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

  // ── Computed stats ────────────────────────────────────────────
  int get totalOrders => orders.length;
  double get totalSalesMTD => orders.fold(0, (s, o) => s + o.amount);
  double get totalDue => orders
      .where(
        (o) =>
            o.paymentStatus == PaymentStatus.partial ||
            o.paymentStatus == PaymentStatus.pending,
      )
      .fold(
        0,
        (s, o) => s + o.amount * 0.13,
      ); // ~13% outstanding on those orders
  double get totalReceived => totalSalesMTD - totalDue;
  double get avgOrderValue => totalOrders > 0 ? totalSalesMTD / totalOrders : 0;

  // ── Top Clients — computed from real orders (like PurchaseController's
  // topSuppliers), not a hardcoded list ────────────────────────
  List<TopClient> get topClients {
    final byClient = <String, TopClient>{};
    for (final o in orders) {
      final existing = byClient[o.client];
      byClient[o.client] = TopClient(
        badge: o.clientBadge,
        color: o.clientColor,
        name: o.client,
        orderCount: (existing?.orderCount ?? 0) + 1,
        totalAmount: (existing?.totalAmount ?? 0) + o.amount,
      );
    }
    final sorted = byClient.values.toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return sorted.take(5).toList();
  }

  // ── CRUD ─────────────────────────────────────────────────────

  /// Creates a sales order via the backend `/sales-orders` API. Returns
  /// true on success (the real, server-assigned order is inserted into
  /// [orders]); false on failure (error toast already shown).
  Future<bool> addOrder(SalesOrder order) async {
    try {
      final json = await _api.post('/sales-orders', order.toCreateJson());
      orders.insert(0, SalesOrder.fromJson(json as Map<String, dynamic>));
      // Selling lowered stock server-side — pull the inventory and
      // product caches back in line.
      await refreshStockViews();
      return true;
    } catch (e) {
      _showError(_stockAwareMessage(e, 'Failed to save sales order.'));
      return false;
    }
  }

  /// Turns a 409 insufficient-stock response (`{error, details: [{product,
  /// requested, available}, ...]}`) into a readable per-item message; falls
  /// back to [fallback] for any other failure.
  String _stockAwareMessage(Object e, String fallback) {
    if (e is! ApiException || e.statusCode != 409) return fallback;
    final details = e.details;
    if (details is! List || details.isEmpty) return e.message;
    final lines = details.map((d) {
      final product = d['product'] ?? 'Item';
      final requested = d['requested'];
      final available = d['available'];
      return '$product: only $available in stock, requested $requested';
    });
    return 'Not enough stock —\n${lines.join('\n')}';
  }

  /// Replaces an existing order — the whole record, not just its status.
  /// The server puts the old lines' stock back and takes the new lines out in
  /// one transaction, so an edit can fail on insufficient stock exactly like
  /// a create can, and gets the same per-item message.
  Future<bool> updateOrder(SalesOrder order) async {
    try {
      final json = await _api.put(
        '/sales-orders/${order.id}',
        order.toCreateJson(),
      );
      final saved = SalesOrder.fromJson(json as Map<String, dynamic>);
      // Last modified first: the edited order goes back to the top.
      final idx = orders.indexWhere((o) => o.id == order.id);
      if (idx != -1) orders.removeAt(idx);
      orders.insert(0, saved);
      await refreshStockViews();
      await fetchStats();
      return true;
    } catch (e) {
      _showError(_stockAwareMessage(e, 'Failed to update sales order.'));
      return false;
    }
  }

  Future<void> deleteOrder(String id) async {
    try {
      await _api.delete('/sales-orders/$id');
      orders.removeWhere((o) => o.id == id);
      // Deleting the order put the sold stock back server-side.
      await refreshStockViews();
    } catch (e) {
      _showError('Failed to delete sales order.');
    }
  }

  /// Updates order status and/or payment status via
  /// `PATCH /sales-orders/:id/status`.
  Future<void> updateStatus(
    String id, {
    SalesStatus? status,
    PaymentStatus? paymentStatus,
  }) async {
    final idx = orders.indexWhere((o) => o.id == id);
    if (idx == -1) return;
    try {
      final json = await _api.patch('/sales-orders/$id/status', {
        if (status != null) 'status': status.label,
        if (paymentStatus != null) 'paymentStatus': paymentStatus.label,
      });
      orders.removeAt(idx);
      orders.insert(0, SalesOrder.fromJson(json as Map<String, dynamic>));
    } catch (e) {
      _showError('Failed to update status.');
    }
  }
}

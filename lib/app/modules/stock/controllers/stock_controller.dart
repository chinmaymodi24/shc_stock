import 'package:shc_stock/app/core/session/app_modules.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/stock/models/stock_item_model.dart';

class StockController extends GetxController {
  /// Summary cards for this page — values *and* month-over-month trends come
  /// from GET /api/stats/inventory, so nothing on the cards is computed here or
  /// hardcoded.
  final stats = StatsSnapshot.empty.obs;

  Future<void> fetchStats() async {
    try {
      stats.value = await StatsSnapshot.fetch('inventory');
    } catch (e) {
      // Cards fall back to zeros; the list fetch already reported any outage.
    }
  }

  final _api = ApiClient.instance;

  final RxList<StockItemModel> items = <StockItemModel>[].obs;
  final RxBool isLoading = false.obs;
  final searchCtrl = TextEditingController();
  final RxString search = ''.obs;
  final RxSet<String> catFilters = <String>{}.obs;
  final RxSet<String> statFilters = <String>{}.obs;
  final RxString sortOption = 'Default'.obs;
  final RxInt rowsPerPage = 10.obs;
  final RxInt currentPage = 1.obs;

  static const List<String> sortOptions = [
    'Default',
    'Item Name (A-Z)',
    'Item Name (Z-A)',
    'Qty: Low to High',
    'Qty: High to Low',
    'Value: Low to High',
    'Value: High to Low',
  ];

  // ── RETIRED static seed ────────────────────────────────────────────────
  // The old 8-item seed list is archived in static_data.txt at the project
  // root. Inventory now comes from GET /api/inventory, derived from the
  // products table + the stock_movements ledger.
  // ───────────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    fetchStats();
    // Fetch-once: registered permanent, so re-entering the Inventory route
    // reuses the loaded list. Purchases/sales refresh it via refreshStockViews.
    fetchItems();
  }

  void _showError(String message) {
    showAppToast(
      'Error',
      message,
      backgroundColor: const Color(0xFFEF4444),
      colorText: Colors.white,
    );
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────
  Future<void> fetchItems() async {
    isLoading.value = true;
    try {
      final data = await _api.get('/inventory') as List<dynamic>;
      items.assignAll(
        data.map((e) => StockItemModel.fromJson(e as Map<String, dynamic>)),
      );
    } catch (e) {
      _showError('Failed to load inventory. Is the backend running?');
    } finally {
      isLoading.value = false;
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// The manual "insert" for inventory: books a stock IN/OUT movement against
  /// a product. Returns true on success.
  Future<bool> adjustStock({
    required int productId,
    required String type, // 'IN' | 'OUT'
    required double qty,
    String note = '',
    double? rate,
  }) async {
    if (!requireWrite('Inventory')) return false;
    try {
      final json = await _api.post('/inventory/adjust', {
        'productId': productId,
        'type': type,
        'qty': qty,
        'note': note,
        if (rate != null) 'rate': rate,
      });
      _replaceItem(
        StockItemModel.fromJson(
          (json as Map<String, dynamic>)['item'] as Map<String, dynamic>,
        ),
      );
      return true;
    } catch (e) {
      _showError(
        e is ApiException
            ? shortfallMessage(e) ?? e.message
            : 'Failed to adjust stock.',
      );
      return false;
    }
  }

  /// Updates a row's reorder settings (minimum stock / location / active).
  Future<bool> updateItem(
    int productId, {
    int? minimumStock,
    String? stockLocation,
    bool? isActive,
  }) async {
    if (!requireWrite('Inventory')) return false;
    try {
      final json = await _api.put('/inventory/$productId', {
        if (minimumStock != null) 'minimumStock': minimumStock,
        if (stockLocation != null) 'stockLocation': stockLocation,
        if (isActive != null) 'isActive': isActive,
        // No modifiedBy: the server credits the signed-in account from the
        // request's own token. Sending a name here was the only place the app
        // tried to write its own audit trail, and the server ignores it.
      });
      _replaceItem(StockItemModel.fromJson(json as Map<String, dynamic>));
      return true;
    } catch (e) {
      _showError(e is ApiException ? e.message : 'Failed to update item.');
      return false;
    }
  }

  /// Deletes (undoes) a manual stock adjustment. Purchase/sale movements are
  /// owned by their order — delete the order to reverse those.
  Future<bool> deleteAdjustment(int movementId) async {
    if (!requireWrite('Inventory')) return false;
    try {
      final json = await _api.deleteJson('/inventory/movements/$movementId');
      _replaceItem(StockItemModel.fromJson(json as Map<String, dynamic>));
      return true;
    } catch (e) {
      _showError(
        e is ApiException ? e.message : 'Failed to delete adjustment.',
      );
      return false;
    }
  }

  /// Recent stock movements, newest first — the audit trail behind a row.
  Future<List<StockMovement>> fetchMovements({int? productId}) async {
    // The ledger is Inventory data. Someone opening a product from the
    // Products page without Inventory access simply sees no adjustments.
    if (!canReadModule('Inventory')) return [];
    try {
      final q = productId == null ? '' : '?productId=$productId';
      final data = await _api.get('/inventory/movements$q') as List<dynamic>;
      return data
          .map((e) => StockMovement.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _showError('Failed to load stock movements.');
      return [];
    }
  }

  void _replaceItem(StockItemModel item) {
    final idx = items.indexWhere((i) => i.productId == item.productId);
    if (idx == -1) {
      items.add(item);
    } else {
      items[idx] = item;
    }
  }

  // ── The list query ────────────────────────────────────────────────────────
  /// Inventory exactly as the page shows it — search, category and status
  /// filters, then the chosen sort. The table, the "Showing N of M" line and
  /// every export read this one getter, so a file can never contain rows the
  /// screen was hiding.
  List<StockItemModel> get filteredItems {
    final q = search.value.toLowerCase();
    // Read every filter up front: an Obx only tracks what the build actually
    // touches, and a predicate never runs when the list is empty.
    final cats = catFilters.toSet();
    final stats = statFilters.toSet();
    final sort = sortOption.value;
    final result = items.where((item) {
      if (q.isNotEmpty &&
          !item.name.toLowerCase().contains(q) &&
          !item.sku.toLowerCase().contains(q)) {
        return false;
      }
      if (cats.isNotEmpty && !cats.contains(item.category)) {
        return false;
      }
      if (stats.isNotEmpty && !stats.contains(item.statusLabel)) {
        return false;
      }
      return true;
    }).toList();

    switch (sort) {
      // Default = last added / modified first. Sorted here too (not just by
      // the API) so a row edited in place jumps to the top without a refetch.
      case 'Default':
        result.sort(
          (a, b) => b.effectiveModifiedAt.compareTo(a.effectiveModifiedAt),
        );
      case 'Item Name (A-Z)':
        result.sort((a, b) => a.name.compareTo(b.name));
      case 'Item Name (Z-A)':
        result.sort((a, b) => b.name.compareTo(a.name));
      case 'Qty: Low to High':
        result.sort((a, b) => a.stockInHand.compareTo(b.stockInHand));
      case 'Qty: High to Low':
        result.sort((a, b) => b.stockInHand.compareTo(a.stockInHand));
      case 'Value: Low to High':
        result.sort((a, b) => a.stockValue.compareTo(b.stockValue));
      case 'Value: High to Low':
        result.sort((a, b) => b.stockValue.compareTo(a.stockValue));
    }
    return result;
  }

  bool get hasActiveFilters =>
      search.value.isNotEmpty ||
      catFilters.isNotEmpty ||
      statFilters.isNotEmpty ||
      sortOption.value != 'Default';

  int get totalItems => items.length;
  int get inStockCount =>
      items.where((i) => i.status == StockStatus.inStock).length;
  int get lowStockCount =>
      items.where((i) => i.status == StockStatus.lowStock).length;
  int get outOfStockCount =>
      items.where((i) => i.status == StockStatus.outOfStock).length;
  int get inactiveCount =>
      items.where((i) => i.status == StockStatus.inactive).length;
  int get totalQty => items.fold(0, (s, i) => s + i.stockInHand);
  double get totalValue => items.fold(0.0, (s, i) => s + i.stockValue);

  List<String> get categories => [
    'All Categories',
    ...items.map((i) => i.category).toSet().toList()..sort(),
  ];
  List<String> get units => [
    'All Units',
    ...items.map((i) => i.unit).toSet().toList()..sort(),
  ];

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }
}

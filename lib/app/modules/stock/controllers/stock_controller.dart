import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
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
    try {
      final json = await _api.post('/inventory/adjust', {
        'productId': productId,
        'type': type,
        'qty': qty,
        'note': note,
        'createdBy': currentActorName,
        if (rate != null) 'rate': rate,
      });
      _replaceItem(
        StockItemModel.fromJson(
          (json as Map<String, dynamic>)['item'] as Map<String, dynamic>,
        ),
      );
      return true;
    } catch (e) {
      _showError(e is ApiException ? e.message : 'Failed to adjust stock.');
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
    try {
      final json = await _api.put('/inventory/$productId', {
        if (minimumStock != null) 'minimumStock': minimumStock,
        if (stockLocation != null) 'stockLocation': stockLocation,
        if (isActive != null) 'isActive': isActive,
        'modifiedBy': currentActorName,
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/transactions/models/transaction_model.dart';

class TransactionsController extends GetxController {
  final _api = ApiClient.instance;

  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxBool isLoading = false.obs;

  /// Summary cards — values and trends from GET /api/stats/transactions.
  final stats = StatsSnapshot.empty.obs;
  final searchCtrl = TextEditingController();
  final RxString search = ''.obs;
  final RxSet<String> typeFilters = <String>{}.obs;
  final RxSet<String> statusFilters = <String>{}.obs;
  final RxString sortOption = 'Default'.obs;
  final RxInt rowsPerPage = 10.obs;
  final RxInt currentPage = 1.obs;

  static const List<String> sortOptions = [
    'Default',
    'Item Name (A-Z)',
    'Item Name (Z-A)',
    'Date: Newest First',
    'Date: Oldest First',
  ];

  // ── RETIRED static seed ────────────────────────────────────────────────
  // The old 6-transaction seed list is archived in static_data.txt at the
  // project root. Transactions now come from GET /api/transactions.
  // ───────────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    // Fetch-once: registered permanent, so re-entering the route reuses the
    // loaded list instead of refetching.
    fetchTransactions();
    fetchStats();
  }

  // Monthly summary totals (independent of the seed rows shown in the table).
  // Summary cards — served by GET /api/stats/transactions. These used to
  // return the literals 312 / 178 / 134 / 9.
  int get totalThisMonth => stats.value.intOf('totalTransactions');
  int get inboundCount => stats.value.intOf('inbound');
  int get outboundCount => stats.value.intOf('outbound');
  int get pendingCount => stats.value.intOf('pending');

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
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
  Future<void> fetchTransactions() async {
    isLoading.value = true;
    try {
      final data = await _api.get('/transactions') as List<dynamic>;
      transactions.assignAll(
        data.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)),
      );
      _clampPage();
    } catch (e) {
      _showError('Failed to load transactions. Is the backend running?');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStats() async {
    try {
      stats.value = await StatsSnapshot.fetch('transactions');
    } catch (e) {
      // Cards fall back to zeros; the list fetch already reported any outage.
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<TransactionModel?> addTransaction(Map<String, dynamic> body) async {
    try {
      final json = await _api.post('/transactions', body);
      final created = TransactionModel.fromJson(json as Map<String, dynamic>);
      transactions.insert(0, created);
      await fetchStats();
      return created;
    } catch (e) {
      _showError(e is ApiException ? e.message : 'Failed to add transaction.');
      return null;
    }
  }

  Future<TransactionModel?> updateTransaction(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final json = await _api.put('/transactions/$id', body);
      final updated = TransactionModel.fromJson(json as Map<String, dynamic>);
      final idx = transactions.indexWhere((t) => t.id == id);
      if (idx != -1) transactions[idx] = updated;
      await fetchStats();
      return updated;
    } catch (e) {
      _showError(
        e is ApiException ? e.message : 'Failed to update transaction.',
      );
      return null;
    }
  }

  Future<void> setStatus(String id, TransactionStatus status) async {
    try {
      final labels = {
        TransactionStatus.received: 'Received',
        TransactionStatus.shipped: 'Shipped',
        TransactionStatus.pending: 'Pending',
        TransactionStatus.delivered: 'Delivered',
      };
      final json = await _api.patch('/transactions/$id/status', {
        'status': labels[status],
      });
      final updated = TransactionModel.fromJson(json as Map<String, dynamic>);
      final idx = transactions.indexWhere((t) => t.id == id);
      if (idx != -1) transactions[idx] = updated;
      await fetchStats();
    } catch (e) {
      _showError(e is ApiException ? e.message : 'Failed to update status.');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _api.delete('/transactions/$id');
      transactions.removeWhere((t) => t.id == id);
      _clampPage();
      await fetchStats();
    } catch (e) {
      _showError(
        e is ApiException ? e.message : 'Failed to delete transaction.',
      );
    }
  }

  void _clampPage() {
    final pages = transactions.isEmpty
        ? 1
        : (transactions.length / rowsPerPage.value).ceil();
    if (currentPage.value > pages) currentPage.value = pages;
  }
}

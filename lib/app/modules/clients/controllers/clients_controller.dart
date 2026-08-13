import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
// Static list retired (see static_data.txt at the project root) — clients
// now come from GET /api/clients. The same 1037 rows are seeded via
// backend/prisma/seedClients.js.

class ClientsController extends GetxController {
  final _api = ApiClient.instance;

  final RxList<ClientModel> clients = <ClientModel>[].obs;
  final RxBool isLoading = false.obs;

  /// Summary cards + right-panel data, all from GET /api/stats/clients.
  final stats = StatsSnapshot.empty.obs;
  final RxList<TopStateEntry> topStates = <TopStateEntry>[].obs;
  final RxList<NewClientEntry> newThisMonth = <NewClientEntry>[].obs;
  final RxDouble avgOrderValue = 0.0.obs;
  final RxInt repeatClientsPct = 0.obs;
  final searchCtrl = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxSet<String> stateFilters = <String>{}.obs;
  final RxSet<String> cityFilters = <String>{}.obs;
  final RxInt rowsPerPage = 10.obs;
  final RxInt currentPage = 1.obs;

  bool get hasActiveFilters =>
      searchQuery.value.isNotEmpty ||
      stateFilters.isNotEmpty ||
      cityFilters.isNotEmpty;

  void resetFilters() {
    searchCtrl.clear();
    searchQuery.value = '';
    stateFilters.clear();
    cityFilters.clear();
    currentPage.value = 1;
  }

  @override
  void onInit() {
    super.onInit();
    // Fetch-once: this controller is registered permanent, so re-entering the
    // Clients route reuses the already-loaded list instead of refetching.
    fetchClients();
    fetchStats();
  }

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
  Future<void> fetchClients() async {
    isLoading.value = true;
    try {
      final data = await _api.get('/clients') as List<dynamic>;
      clients.assignAll(
        data.map((e) => ClientModel.fromJson(e as Map<String, dynamic>)),
      );
      _clampPage();
    } catch (e) {
      _showError('Failed to load clients. Is the backend running?');
    } finally {
      isLoading.value = false;
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Creates a client and prepends it locally so the list reflects it without
  /// a full refetch. Returns the saved client, or null when the call failed.
  Future<ClientModel?> addClient(Map<String, dynamic> body) async {
    try {
      final json = await _api.post('/clients', body);
      final created = ClientModel.fromJson(json as Map<String, dynamic>);
      clients.insert(0, created);
      await fetchStats();
      return created;
    } catch (e) {
      _showError(e is ApiException ? e.message : 'Failed to add client.');
      return null;
    }
  }

  Future<ClientModel?> updateClient(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final json = await _api.put('/clients/$id', body);
      final updated = ClientModel.fromJson(json as Map<String, dynamic>);
      final idx = clients.indexWhere((c) => c.id == id);
      if (idx != -1) clients[idx] = updated;
      await fetchStats();
      return updated;
    } catch (e) {
      _showError(e is ApiException ? e.message : 'Failed to update client.');
      return null;
    }
  }

  Future<void> deleteClient(String id) async {
    try {
      await _api.delete('/clients/$id');
      clients.removeWhere((c) => c.id == id);
      _clampPage();
      await fetchStats();
    } catch (e) {
      _showError('Failed to delete client.');
    }
  }

  /// Keeps the pager on a page that still exists after the list size changes.
  void _clampPage() {
    final pages = clients.isEmpty
        ? 1
        : (clients.length / rowsPerPage.value).ceil();
    if (currentPage.value > pages) currentPage.value = pages;
  }

  // ── Summary cards — all served by GET /api/stats/clients ──────────────────
  Future<void> fetchStats() async {
    try {
      final json = await _api.get('/stats/clients') as Map<String, dynamic>;
      stats.value = StatsSnapshot.fromJson(json);
      topStates.assignAll(
        ((json['topStates'] as List?) ?? []).map(
          (e) => TopStateEntry.fromJson(e as Map<String, dynamic>),
        ),
      );
      newThisMonth.assignAll(
        ((json['newThisMonth'] as List?) ?? []).map(
          (e) => NewClientEntry.fromJson(e as Map<String, dynamic>),
        ),
      );
      final quick = (json['quickStats'] as Map?)?.cast<String, dynamic>() ?? {};
      avgOrderValue.value = (quick['avgOrderValue'] as num?)?.toDouble() ?? 0;
      repeatClientsPct.value =
          (quick['repeatClientsPct'] as num?)?.toInt() ?? 0;
    } catch (e) {
      // Cards fall back to zeros; the list itself already reported any outage.
    }
  }

  int get totalClients => stats.value.intOf('totalClients');
  int get registeredClients => stats.value.intOf('gstRegistered');
  int get unregisteredClients => stats.value.intOf('unregistered');
  int get statesCovered => stats.value.intOf('statesCovered');

  /// Every state present in the list, alphabetical — options for the State
  /// filter pill.
  List<String> get stateOptions =>
      (clients.map((c) => c.state).where((s) => s.isNotEmpty).toSet().toList()
        ..sort());

  /// City options for the City filter pill — scoped to the selected states
  /// (if any), else every city across all clients. Matches the approved
  /// design's cascading State → City behaviour.
  List<String> get cityOptions {
    final source = stateFilters.isEmpty
        ? clients
        : clients.where((c) => stateFilters.contains(c.state));
    return (source
        .map((c) => c.city)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort());
  }
}

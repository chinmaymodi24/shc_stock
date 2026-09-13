import 'package:shc_stock/app/core/session/app_modules.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Clients, searched and paged by the server.
//
// This list outgrew the fetch-once pattern the other modules use. Loading all
// 1049 rows so they could be filtered in memory cost about a megabyte of JSON
// on every start, and that number only grows. So [clients] now holds one page,
// and the search box, the filter pills and the pager each send their state to
// GET /api/clients.
//
// Two other screens still need more than a page, and they are served narrowly
// rather than by keeping the fat list around:
//
//   [directory]  three columns per client, for the "type to search" field on
//                Add Sale — 62 KB instead of 983 KB.
//   [findByName] the one full record the invoice header needs.
// ─────────────────────────────────────────────────────────────────────────────

/// Just enough of a client to offer it in an autocomplete: the name to match
/// on, and the state and GSTIN that dropdown prints beneath it.
class ClientRef {
  final String id;
  final String code;
  final String name;
  final String state;
  final String gstin;

  const ClientRef({
    required this.id,
    required this.code,
    required this.name,
    this.state = '',
    this.gstin = '',
  });

  factory ClientRef.fromJson(Map<String, dynamic> json) => ClientRef(
    id: '${json['id']}',
    code: json['code'] as String? ?? '',
    name: json['name'] as String? ?? '',
    state: json['regState'] as String? ?? '',
    gstin: json['gstin'] as String? ?? '',
  );
}

class ClientsController extends GetxController {
  final _api = ApiClient.instance;

  /// The page the table is showing — not every client.
  final RxList<ClientModel> clients = <ClientModel>[].obs;

  /// Every client, three columns each, for autocompletes.
  final RxList<ClientRef> directory = <ClientRef>[].obs;

  /// How many clients match the current search and filters, across all pages.
  final RxInt totalFiltered = 0.obs;

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

  /// Filter-pill options. They cannot be read off a single page, so the server
  /// reports the distinct values; cities narrow to the selected states.
  final RxList<String> stateOptions = <String>[].obs;
  final RxList<String> cityOptions = <String>[].obs;

  /// Rows an export will write, loaded only when the export menu opens. The
  /// export pipeline reads its rows synchronously, so they have to be here
  /// first — see [loadExportRows]. [exportRows] honours the current search and
  /// filters; [exportAllRows] is the whole table, for the "All clients" scope.
  final RxList<ClientModel> exportRows = <ClientModel>[].obs;
  final RxList<ClientModel> exportAllRows = <ClientModel>[].obs;

  Worker? _searchDebounce;

  /// The rows on screen. The server does the filtering now, so this is simply
  /// the current page; the name is kept because the table and the export scope
  /// line both read it.
  List<ClientModel> get filteredClients => clients;

  bool get hasActiveFilters =>
      searchQuery.value.isNotEmpty ||
      stateFilters.isNotEmpty ||
      cityFilters.isNotEmpty;

  int get totalPages {
    final per = rowsPerPage.value;
    if (per <= 0 || totalFiltered.value == 0) return 1;
    return (totalFiltered.value / per).ceil();
  }

  @override
  void onInit() {
    super.onInit();
    // Typing must not fire a request per keystroke; this waits for a pause.
    _searchDebounce = debounce<String>(
      searchQuery,
      (_) => goToPage(1),
      time: const Duration(milliseconds: 300),
    );
    fetchClients();
    fetchDirectory();
    fetchFilterOptions();
    fetchStats();
  }

  @override
  void onClose() {
    _searchDebounce?.dispose();
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

  /// Search and filters as a query string — shared by the page fetch and the
  /// export fetch, so an export can never widen past what the screen shows.
  String _filterQuery() {
    final parts = <String>[];
    final q = searchQuery.value.trim();
    if (q.isNotEmpty) parts.add('search=${Uri.encodeQueryComponent(q)}');
    if (stateFilters.isNotEmpty) {
      parts.add('state=${Uri.encodeQueryComponent(stateFilters.join(','))}');
    }
    if (cityFilters.isNotEmpty) {
      parts.add('city=${Uri.encodeQueryComponent(cityFilters.join(','))}');
    }
    return parts.join('&');
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchClients() async {
    isLoading.value = true;
    try {
      final filters = _filterQuery();
      final path =
          '/clients?page=${currentPage.value}&limit=${rowsPerPage.value}'
          '${filters.isEmpty ? '' : '&$filters'}';
      // instant: the user is waiting on this keystroke by keystroke.
      final json = await _api.get(path, instant: true) as Map<String, dynamic>;
      final items = (json['items'] as List?) ?? const [];
      clients.assignAll(
        items.map((e) => ClientModel.fromJson(e as Map<String, dynamic>)),
      );
      totalFiltered.value = (json['total'] as num?)?.toInt() ?? items.length;

      // A delete, or a filter that narrowed, can strand the pager past the end.
      if (clients.isEmpty && currentPage.value > totalPages) {
        currentPage.value = totalPages;
        isLoading.value = false;
        return fetchClients();
      }
    } catch (e) {
      _showError('Failed to load clients. Is the backend running?');
    } finally {
      isLoading.value = false;
    }
  }

  /// The names behind every client autocomplete. Fetched once.
  Future<void> fetchDirectory() async {
    try {
      final data = await _api.get('/clients/directory') as List<dynamic>;
      directory.assignAll(
        data.map((e) => ClientRef.fromJson(e as Map<String, dynamic>)),
      );
    } catch (e) {
      // The list itself already reported any outage.
    }
  }

  /// Values for the State and City pills; cities narrow to the chosen states.
  Future<void> fetchFilterOptions() async {
    try {
      final scope = stateFilters.isEmpty
          ? ''
          : '?state=${Uri.encodeQueryComponent(stateFilters.join(','))}';
      final json =
          await _api.get('/clients/options$scope', instant: true)
              as Map<String, dynamic>;
      stateOptions.assignAll(
        ((json['states'] as List?) ?? const []).cast<String>(),
      );
      cityOptions.assignAll(
        ((json['cities'] as List?) ?? const []).cast<String>(),
      );
      // A city that is no longer on offer must not keep filtering the list.
      cityFilters.removeWhere((c) => !cityOptions.contains(c));
    } catch (e) {
      // Pills keep whatever they were showing.
    }
  }

  /// Every client matching [filters], walked a page at a time.
  Future<List<ClientModel>> _fetchAll(String filters) async {
    final all = <ClientModel>[];
    var page = 1;
    // 500 is the server's ceiling for a single request (see pagination.js).
    while (true) {
      final path =
          '/clients?page=$page&limit=500${filters.isEmpty ? '' : '&$filters'}';
      final json = await _api.get(path, instant: true) as Map<String, dynamic>;
      final items = (json['items'] as List?) ?? const [];
      all.addAll(
        items.map((e) => ClientModel.fromJson(e as Map<String, dynamic>)),
      );
      if (json['hasMore'] != true) break;
      page++;
    }
    return all;
  }

  /// Pulls the rows an export may need, so it covers more than the page on
  /// screen. Await this before opening the export UI.
  Future<void> loadExportRows() async {
    try {
      final filters = _filterQuery();
      final matching = await _fetchAll(filters);
      exportRows.assignAll(matching);
      // With nothing filtered the two scopes are the same set, so only fetch
      // the whole table when the screen is actually showing a subset.
      exportAllRows.assignAll(
        filters.isEmpty ? matching : await _fetchAll(''),
      );
    } catch (e) {
      // Better to export the page on screen than nothing at all.
      exportRows.assignAll(clients);
      exportAllRows.assignAll(clients);
    }
  }

  /// The full record for a client named on a sale — the invoice header needs
  /// the shipping address and contact the sale itself does not carry. Checks
  /// the loaded page first, so the common case costs no request.
  Future<ClientModel?> findByName(String name) async {
    final wanted = name.trim().toLowerCase();
    if (wanted.isEmpty) return null;
    for (final c in clients) {
      if (c.name.trim().toLowerCase() == wanted) return c;
    }
    try {
      final path =
          '/clients?limit=5&search=${Uri.encodeQueryComponent(name.trim())}';
      final json = await _api.get(path, instant: true) as Map<String, dynamic>;
      for (final e in (json['items'] as List?) ?? const []) {
        final c = ClientModel.fromJson(e as Map<String, dynamic>);
        if (c.name.trim().toLowerCase() == wanted) return c;
      }
    } catch (e) {
      // No client to show; the invoice falls back to the sale's own fields.
    }
    return null;
  }

  // ── What the page drives ──────────────────────────────────────────────────

  void goToPage(int page) {
    currentPage.value = page < 1 ? 1 : page;
    fetchClients();
  }

  /// True while there are rows beyond the ones already shown.
  bool get hasMore => clients.length < totalFiltered.value;

  /// Set while [loadMore] is fetching, so the phone list can show it is busy
  /// without the whole page falling back to its loading state.
  final RxBool isLoadingMore = false.obs;

  /// Appends the next page instead of replacing the current one - what the
  /// phone list does, since it scrolls rather than paging. The desktop table
  /// keeps using [goToPage].
  Future<void> loadMore() async {
    if (isLoadingMore.value || isLoading.value || !hasMore) return;
    isLoadingMore.value = true;
    try {
      final filters = _filterQuery();
      final next = currentPage.value + 1;
      final path =
          '/clients?page=$next&limit=${rowsPerPage.value}'
          '${filters.isEmpty ? '' : '&$filters'}';
      final json = await _api.get(path, instant: true) as Map<String, dynamic>;
      final items = (json['items'] as List?) ?? const [];
      clients.addAll(
        items.map((e) => ClientModel.fromJson(e as Map<String, dynamic>)),
      );
      currentPage.value = next;
      totalFiltered.value = (json['total'] as num?)?.toInt() ?? clients.length;
    } catch (e) {
      _showError('Failed to load more clients.');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void setRowsPerPage(int rows) {
    rowsPerPage.value = rows;
    goToPage(1);
  }

  /// A State pill changed: the city options depend on it, and a city already
  /// chosen may no longer be on offer.
  Future<void> onStateFiltersChanged() async {
    await fetchFilterOptions();
    goToPage(1);
  }

  void onCityFiltersChanged() => goToPage(1);

  void resetFilters() {
    searchCtrl.clear();
    searchQuery.value = '';
    stateFilters.clear();
    cityFilters.clear();
    fetchFilterOptions();
    goToPage(1);
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Creates a client, then reloads the page so the row lands wherever the
  /// server's ordering puts it — a local insert would be wrong the moment the
  /// list is filtered or the user is not on page one.
  Future<ClientModel?> addClient(Map<String, dynamic> body) async {
    try {
      final json = await _api.post('/clients', body);
      final created = ClientModel.fromJson(json as Map<String, dynamic>);
      await _reloadAfterWrite();
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
      await _reloadAfterWrite();
      return updated;
    } catch (e) {
      _showError(e is ApiException ? e.message : 'Failed to update client.');
      return null;
    }
  }

  Future<void> deleteClient(String id) async {
    try {
      await _api.delete('/clients/$id');
      await _reloadAfterWrite();
    } catch (e) {
      _showError('Failed to delete client.');
    }
  }

  /// A write can change the page, the cards, an autocomplete name and even the
  /// filter pills (a new state or city), so all four are refreshed together.
  Future<void> _reloadAfterWrite() => Future.wait([
    fetchClients(),
    fetchStats(),
    fetchDirectory(),
    fetchFilterOptions(),
  ]);

  // ── Summary cards — all served by GET /api/stats/clients ──────────────────
  Future<void> fetchStats() async {
    // Summary figures are their own permission — skip the call without it.
    if (!canSeeSummary('Clients')) return;
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
}

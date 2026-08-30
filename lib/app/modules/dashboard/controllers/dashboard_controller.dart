import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/dashboard/models/dashboard_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard.
//
// Everything on this page comes from GET /api/dashboard, which derives it from
// the real products / purchase / sales / clients / transactions tables. The
// whole controller used to be a 240-line block of hardcoded tiles, charts,
// deliveries and alerts.
//
// Notes are the one piece of user-authored content here, so they get real CRUD
// against /api/dashboard/notes.
// ─────────────────────────────────────────────────────────────────────────────
class DashboardController extends GetxController {
  final _api = ApiClient.instance;

  final RxInt selectedNavIndex = 0.obs;
  final RxString selectedSalesFilter = 'This Month'.obs;
  final RxBool chartsExpanded = false.obs;
  final List<String> salesFilters = ['This Month', 'Last Month', 'This Year'];

  final RxBool isLoading = false.obs;

  /// First name of whoever is signed in — used by the greeting.
  String get greetingName {
    final name = Get.isRegistered<SessionController>()
        ? (Get.find<SessionController>().user.value?.name ?? '')
        : '';
    return name.trim().isEmpty
        ? 'there'
        : name.trim().split(RegExp(r'\s+')).first;
  }

  // ── Fetched data ─────────────────────────────────────────────────────────
  final RxList<StatCardData> webStatCards = <StatCardData>[].obs;
  final RxList<DashboardStatData> dashboardStats = <DashboardStatData>[].obs;

  final RxList<ChartPoint> purchasesData = <ChartPoint>[].obs;
  final RxList<ChartPoint> salesData = <ChartPoint>[].obs;
  final RxList<ChartPoint> newClientsData = <ChartPoint>[].obs;
  final RxString purchasesChange = ''.obs;
  final RxString salesChange = ''.obs;
  final RxString newClientsChange = ''.obs;

  final RxList<CategorySlice> categorySlices = <CategorySlice>[].obs;
  final RxList<TransactionRow> recentTransactions = <TransactionRow>[].obs;
  final RxList<DeliveryItem> incomingDeliveries = <DeliveryItem>[].obs;
  final RxList<LowStockAlertItem> lowStockAlerts = <LowStockAlertItem>[].obs;
  final RxList<NoteItem> notes = <NoteItem>[].obs;

  static List<Color> get _sliceColors => [
    // Was AppColors.primaryPurple — CategoryBreakdown reuses this color as
    // the row's TEXT color on hover, and the fixed dark shade was nearly
    // invisible against the dark theme's surface. Theme-aware purple fixes
    // that the same way `accent` below already does.
    appColors.purple,
    AppColors.primaryOrange,
    appColors.accent,
    const Color(0xFF0EA5E9),
    const Color(0xFF22C55E),
  ];

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
    fetchNotes();
  }

  void _showError(String message) {
    showAppToast(
      'Error',
      message,
      backgroundColor: const Color(0xFFEF4444),
      colorText: Colors.white,
    );
  }

  /// `↑ 12.0% vs last month`, or '' when the API had no baseline — the widget
  /// then shows nothing instead of a made-up delta.
  String _changeLabel(num? pct, {String suffix = 'vs last month'}) {
    if (pct == null) return '';
    final arrow = pct >= 0 ? '↑' : '↓';
    return '$arrow ${pct.abs().toStringAsFixed(1)}% $suffix';
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────
  Future<void> fetchDashboard() async {
    isLoading.value = true;
    try {
      final json = await _api.get('/dashboard') as Map<String, dynamic>;
      _applySummary(json['summary'] as Map<String, dynamic>? ?? {});
      _applyCharts(json['charts'] as Map<String, dynamic>? ?? {});
      _applySlices(json['categorySlices'] as List<dynamic>? ?? []);
      _applyTransactions(json['recentTransactions'] as List<dynamic>? ?? []);
      _applyDeliveries(json['incomingDeliveries'] as List<dynamic>? ?? []);
      _applyLowStock(json['lowStockAlerts'] as List<dynamic>? ?? []);
    } catch (e) {
      _showError('Failed to load the dashboard. Is the backend running?');
    } finally {
      isLoading.value = false;
    }
  }

  void _applySummary(Map<String, dynamic> s) {
    int i(String k) => (s[k] as num?)?.toInt() ?? 0;
    double d(String k) => (s[k] as num?)?.toDouble() ?? 0;
    final fmt = NumberFormat.decimalPattern('en_IN');

    webStatCards.assignAll([
      StatCardData(
        title: 'Total Stock Items',
        value: fmt.format(i('totalStockItems')),
        icon: StatCardIcon.box,
      ),
      StatCardData(
        title: 'Low Stock Items',
        value: '${i('lowStock')}',
        icon: StatCardIcon.warning,
      ),
      StatCardData(
        title: "Today's Sales",
        value: formatRupees(d('todaysSales')),
        icon: StatCardIcon.cart,
      ),
      StatCardData(
        title: 'Total Sales (This Month)',
        value: formatRupees(d('monthSales')),
        icon: StatCardIcon.chart,
      ),
    ]);

    dashboardStats.assignAll([
      DashboardStatData(
        title: 'Total Stock Items',
        value: fmt.format(i('totalStockItems')),
        icon: Icons.inventory_2_rounded,
        iconColor: const Color(0xFF3B6FE0),
      ),
      DashboardStatData(
        title: 'Out of Stock Items',
        value: '${i('outOfStock')}',
        icon: Icons.block_rounded,
        iconColor: const Color(0xFFE0473B),
      ),
      DashboardStatData(
        title: 'Low Stock Items',
        value: '${i('lowStock')}',
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFDB9A1E),
      ),
      DashboardStatData(
        title: 'Dues from Clients',
        value: formatRupees(d('duesFromClients')),
        icon: Icons.description_outlined,
        iconColor: const Color(0xFF2FA85C),
        smallValue: true,
      ),
      DashboardStatData(
        title: 'Top Selling Product',
        value: (s['topSellingProduct'] as String?) ?? '—',
        icon: Icons.emoji_events_rounded,
        smallValue: true,
        // accentPurple, not primaryPurple — the tile's tint and label are
        // drawn from this color, and #2B1888 is too dark to read against the
        // dark theme's background.
        iconColor: appColors.accent,
      ),
    ]);
  }

  void _applyCharts(Map<String, dynamic> charts) {
    List<ChartPoint> series(String key) {
      final block = charts[key] as Map<String, dynamic>?;
      final raw = (block?['series'] as List<dynamic>?) ?? [];
      return raw
          .map(
            (e) => ChartPoint(
              label: (e as Map<String, dynamic>)['label'] as String? ?? '',
              value: (e['value'] as num?)?.toDouble() ?? 0,
            ),
          )
          .toList();
    }

    num? change(String key) =>
        (charts[key] as Map<String, dynamic>?)?['changePct'] as num?;

    purchasesData.assignAll(series('purchases'));
    salesData.assignAll(series('sales'));
    newClientsData.assignAll(series('newClients'));

    purchasesChange.value = _changeLabel(change('purchases'));
    salesChange.value = _changeLabel(change('sales'));
    final newest = newClientsData.isEmpty ? 0 : newClientsData.last.value;
    newClientsChange.value = newest > 0
        ? '↑ ${newest.toStringAsFixed(0)} new this month'
        : '';
  }

  void _applySlices(List<dynamic> raw) {
    categorySlices.assignAll(
      raw.asMap().entries.map((e) {
        final m = e.value as Map<String, dynamic>;
        return CategorySlice(
          label: m['label'] as String? ?? '',
          percent: (m['percent'] as num?)?.toDouble() ?? 0,
          color: _sliceColors[e.key % _sliceColors.length],
          // Stock value behind the slice — read out by the hover tooltips on
          // the donut and the Category breakdown bars.
          value: (m['value'] as num?)?.toDouble(),
        );
      }),
    );
  }

  void _applyTransactions(List<dynamic> raw) {
    final fmt = DateFormat('dd MMM yyyy');
    recentTransactions.assignAll(
      raw.map((e) {
        final m = e as Map<String, dynamic>;
        final date = DateTime.tryParse(m['date'] as String? ?? '');
        return TransactionRow(
          item: m['item'] as String? ?? '',
          type: m['type'] as String? ?? '',
          warehouse: m['party'] as String? ?? '',
          date: date == null ? '—' : fmt.format(date),
          status: m['status'] as String? ?? '',
        );
      }),
    );
  }

  void _applyDeliveries(List<dynamic> raw) {
    incomingDeliveries.assignAll(
      raw.map((e) {
        final m = e as Map<String, dynamic>;
        final due = DateTime.tryParse(m['dueDate'] as String? ?? '');
        return DeliveryItem(
          item: m['item'] as String? ?? '',
          poRef: m['poRef'] as String? ?? '',
          warehouse:
              m['placeOfSupply'] as String? ?? m['supplier'] as String? ?? '',
          eta: _etaLabel(due),
          accentColor: (m['status'] as String?) == 'Partial'
              ? AppColors.primaryOrange
              : AppColors.primaryPurple,
        );
      }),
    );
  }

  /// Relative wording for a delivery due date, or a plain dash when the PO
  /// carries no due date.
  String _etaLabel(DateTime? due) {
    if (due == null) return 'No due date';
    final today = DateTime.now();
    final days = DateTime(
      due.year,
      due.month,
      due.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    if (days < 0) return 'Overdue by ${-days}d';
    if (days == 0) return 'Arriving today';
    if (days == 1) return 'Arriving tomorrow';
    return 'Arriving in ${days}d';
  }

  void _applyLowStock(List<dynamic> raw) {
    lowStockAlerts.assignAll(
      raw.map((e) {
        final m = e as Map<String, dynamic>;
        final min = (m['minimum'] as num?)?.toInt() ?? 0;
        return LowStockAlertItem(
          product: m['product'] as String? ?? '',
          current: (m['current'] as num?)?.toInt() ?? 0,
          // The bar needs a ceiling; the reorder level is the meaningful one.
          max: min > 0 ? min : 1,
        );
      }),
    );
  }

  void toggleDeliveryDone(int index) {
    final item = incomingDeliveries[index];
    incomingDeliveries[index] = item.copyWith(done: !item.done);
  }

  // ── Notes CRUD ────────────────────────────────────────────────────────────
  int? get _userId => Get.isRegistered<SessionController>()
      ? Get.find<SessionController>().user.value?.id
      : null;

  Future<void> fetchNotes() async {
    try {
      final uid = _userId;
      final data =
          await _api.get('/dashboard/notes${uid == null ? '' : '?userId=$uid'}')
              as List<dynamic>;
      notes.assignAll(
        data.map((e) => NoteItem.fromJson(e as Map<String, dynamic>)),
      );
    } catch (e) {
      // Silent — the dashboard fetch already reported any outage.
    }
  }

  Future<void> addNote(String text) async {
    if (text.trim().isEmpty) return;
    try {
      final json = await _api.post('/dashboard/notes', {
        'text': text.trim(),
        if (_userId != null) 'userId': _userId,
      });
      notes.add(NoteItem.fromJson(json as Map<String, dynamic>));
    } catch (e) {
      _showError(e is ApiException ? e.message : 'Failed to add note.');
    }
  }

  Future<void> toggleNote(int index) async {
    if (index < 0 || index >= notes.length) return;
    final note = notes[index];
    // Flip locally first so the checkbox feels instant, then persist.
    notes[index] = note.copyWith(done: !note.done);
    try {
      await _api.put('/dashboard/notes/${note.id}', {'done': !note.done});
    } catch (e) {
      notes[index] = note; // put it back
      _showError('Failed to update note.');
    }
  }

  Future<void> updateNote(int index, String text) async {
    if (index < 0 || index >= notes.length || text.trim().isEmpty) return;
    final note = notes[index];
    try {
      final json = await _api.put('/dashboard/notes/${note.id}', {
        'text': text.trim(),
      });
      notes[index] = NoteItem.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      _showError(e is ApiException ? e.message : 'Failed to update note.');
    }
  }

  Future<void> deleteNote(int index) async {
    if (index < 0 || index >= notes.length) return;
    final note = notes[index];
    try {
      await _api.delete('/dashboard/notes/${note.id}');
      notes.removeAt(index);
    } catch (e) {
      _showError('Failed to delete note.');
    }
  }

  void onNavTap(int index) => selectedNavIndex.value = index;
  void changeSalesFilter(String filter) => selectedSalesFilter.value = filter;
}

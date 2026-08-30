import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/reports/models/analytics_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reports → Analytics.
//
// One call to GET /api/stats/analytics fills the whole tab: the four KPI
// cards, the sales/purchase trend, the two ranked lists, stock movement,
// inventory health, collection rate, receivables aging, revenue by category,
// the month-over-month block and the health-indicator grid.
//
// Nothing on this page is computed here — the controller only parses and
// formats what the backend measured.
// ─────────────────────────────────────────────────────────────────────────────
class AnalyticsController extends GetxController {
  final _api = ApiClient.instance;

  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;

  // ── KPI cards ──────────────────────────────────────────────────────────────
  final RxDouble totalSales = 0.0.obs;
  final RxDouble totalPurchases = 0.0.obs;
  final RxInt activeClients = 0.obs;
  final RxInt invoicesRaised = 0.obs;
  final Rxn<double> totalSalesTrend = Rxn<double>();
  final Rxn<double> totalPurchasesTrend = Rxn<double>();
  final Rxn<double> activeClientsTrend = Rxn<double>();
  final Rxn<double> invoicesTrend = Rxn<double>();

  // ── Charts ─────────────────────────────────────────────────────────────────
  final RxList<TrendPoint> salesVsPurchases = <TrendPoint>[].obs;
  final RxList<RankedRow> topProducts = <RankedRow>[].obs;
  final RxList<RankedRow> topClients = <RankedRow>[].obs;
  final RxList<FlowPoint> stockMovement = <FlowPoint>[].obs;

  final RxInt inStock = 0.obs;
  final RxInt lowStock = 0.obs;
  final RxInt outOfStock = 0.obs;

  final RxDouble collected = 0.0.obs;
  final RxDouble outstanding = 0.0.obs;
  final RxDouble collectionRate = 0.0.obs;

  final RxList<AgingBucket> agingBuckets = <AgingBucket>[].obs;
  final RxDouble agingTotal = 0.0.obs;

  final RxList<CategoryRevenue> categoryRevenue = <CategoryRevenue>[].obs;
  final RxDouble categoryTotal = 0.0.obs;

  // ── Month-over-month ───────────────────────────────────────────────────────
  final RxDouble salesThisMonth = 0.0.obs;
  final RxDouble salesLastMonth = 0.0.obs;
  final Rxn<double> monthGrowth = Rxn<double>();
  final RxInt ordersThisMonth = 0.obs;
  final RxDouble avgOrderValueThisMonth = 0.0.obs;

  final RxList<HealthIndicator> indicators = <HealthIndicator>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAnalytics();
  }

  double? _num(dynamic v) => (v as num?)?.toDouble();

  Future<void> fetchAnalytics() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final json = await _api.get('/stats/analytics') as Map<String, dynamic>;

      final cards = json['cards'] as Map<String, dynamic>? ?? {};
      final trends = cards['trends'] as Map<String, dynamic>? ?? {};
      totalSales.value = _num(cards['totalSales']) ?? 0;
      totalPurchases.value = _num(cards['totalPurchases']) ?? 0;
      activeClients.value = (cards['activeClients'] as num?)?.toInt() ?? 0;
      invoicesRaised.value = (cards['invoicesRaised'] as num?)?.toInt() ?? 0;
      totalSalesTrend.value = _num(trends['totalSales']);
      totalPurchasesTrend.value = _num(trends['totalPurchases']);
      activeClientsTrend.value = _num(trends['activeClients']);
      invoicesTrend.value = _num(trends['invoicesRaised']);

      salesVsPurchases.assignAll(
        ((json['salesVsPurchases'] as List?) ?? []).map(
          (e) => TrendPoint.fromJson(e as Map<String, dynamic>),
        ),
      );

      topProducts.assignAll(
        ((json['topProducts'] as List?) ?? []).map((e) {
          final m = e as Map<String, dynamic>;
          final qty = _num(m['qty']) ?? 0;
          return RankedRow(
            label: m['product'] as String? ?? '',
            value: qty,
            display:
                '${qty.toStringAsFixed(0)} '
                '${qty == 1 ? 'unit' : 'units'}',
          );
        }),
      );

      topClients.assignAll(
        ((json['topClients'] as List?) ?? []).map((e) {
          final m = e as Map<String, dynamic>;
          final total = _num(m['total']) ?? 0;
          return RankedRow(
            label: m['client'] as String? ?? '',
            value: total,
            display: formatRupeesCompact(total),
          );
        }),
      );

      stockMovement.assignAll(
        ((json['stockMovement'] as List?) ?? []).map(
          (e) => FlowPoint.fromJson(e as Map<String, dynamic>),
        ),
      );

      final health = json['inventoryHealth'] as Map<String, dynamic>? ?? {};
      inStock.value = (health['inStock'] as num?)?.toInt() ?? 0;
      lowStock.value = (health['lowStock'] as num?)?.toInt() ?? 0;
      outOfStock.value = (health['outOfStock'] as num?)?.toInt() ?? 0;

      final payment = json['paymentCollection'] as Map<String, dynamic>? ?? {};
      collected.value = _num(payment['collected']) ?? 0;
      outstanding.value = _num(payment['outstanding']) ?? 0;
      collectionRate.value = _num(payment['ratePct']) ?? 0;

      final aging = json['receivablesAging'] as Map<String, dynamic>? ?? {};
      agingTotal.value = _num(aging['total']) ?? 0;
      agingBuckets.assignAll(
        ((aging['buckets'] as List?) ?? []).map(
          (e) => AgingBucket.fromJson(e as Map<String, dynamic>),
        ),
      );

      final revenue = json['revenueByCategory'] as Map<String, dynamic>? ?? {};
      categoryTotal.value = _num(revenue['total']) ?? 0;
      categoryRevenue.assignAll(
        ((revenue['rows'] as List?) ?? []).map(
          (e) => CategoryRevenue.fromJson(e as Map<String, dynamic>),
        ),
      );

      final month = json['monthComparison'] as Map<String, dynamic>? ?? {};
      salesThisMonth.value = _num(month['thisMonth']) ?? 0;
      salesLastMonth.value = _num(month['lastMonth']) ?? 0;
      monthGrowth.value = _num(month['growthPct']);
      ordersThisMonth.value = (month['ordersThisMonth'] as num?)?.toInt() ?? 0;
      avgOrderValueThisMonth.value = _num(month['avgOrderValue']) ?? 0;

      indicators.assignAll(
        _buildIndicators(
          json['healthIndicators'] as Map<String, dynamic>? ?? {},
        ),
      );
    } catch (e) {
      hasError.value = true;
      showAppToast(
        'Error',
        'Failed to load analytics. Is the backend running?',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Turns the indicator block into the six display cells. A null trend means
  /// the backend had no baseline, and the cell says so instead of showing 0%.
  List<HealthIndicator> _buildIndicators(Map<String, dynamic> h) {
    final margin = _num(h['grossMarginPct']) ?? 0;
    final marginTrend = _num(h['grossMarginTrend']);
    final turnover = _num(h['inventoryTurnover']);
    final aov = _num(h['avgOrderValue']) ?? 0;
    final aovTrend = _num(h['avgOrderValueTrend']);
    final repeat = _num(h['repeatClientPct']) ?? 0;
    final payables = _num(h['payablesDue']) ?? 0;
    final overdue = _num(h['payablesOverdue']) ?? 0;
    final newClients = (h['newClientsMTD'] as num?)?.toInt() ?? 0;
    final newDelta = (h['newClientsDelta'] as num?)?.toInt() ?? 0;

    String pct(double? v) => v == null ? '' : '${v.abs().toStringAsFixed(1)}%';

    return [
      HealthIndicator(
        label: 'Gross Margin',
        value: '${margin.toStringAsFixed(1)}%',
        trend: pct(marginTrend),
        trendUp: (marginTrend ?? 0) >= 0,
        caption: marginTrend == null ? 'no baseline' : 'vs last month',
        neutral: marginTrend == null,
      ),
      HealthIndicator(
        label: 'Inventory Turnover',
        value: turnover == null ? '—' : '${turnover.toStringAsFixed(1)}x',
        caption: 'COGS (12 months) vs stock on hand',
        neutral: true,
      ),
      HealthIndicator(
        label: 'Avg. Order Value',
        value: formatRupees(aov),
        trend: pct(aovTrend),
        trendUp: (aovTrend ?? 0) >= 0,
        caption: aovTrend == null ? 'no baseline' : 'vs last month',
        neutral: aovTrend == null,
      ),
      HealthIndicator(
        label: 'Repeat Client Rate',
        value: '${repeat.toStringAsFixed(0)}%',
        caption: 'clients with more than one order',
        neutral: true,
      ),
      HealthIndicator(
        label: 'Payables Due',
        value: formatRupees(payables),
        caption: overdue > 0
            ? '${formatRupees(overdue)} overdue'
            : 'nothing overdue',
        neutral: overdue == 0,
        trendUp: false,
      ),
      HealthIndicator(
        label: 'New Clients (MTD)',
        value: '$newClients',
        trend: newDelta == 0 ? '' : '${newDelta.abs()}',
        trendUp: newDelta >= 0,
        caption: newDelta == 0 ? 'flat vs last month' : 'vs last month',
        neutral: newDelta == 0,
      ),
    ];
  }
}

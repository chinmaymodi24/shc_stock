import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_ripple_controller.dart';
import 'package:shc_stock/app/modules/reports/controllers/analytics_controller.dart';
import 'package:shc_stock/app/modules/reports/controllers/profit_loss_controller.dart';
import 'package:shc_stock/app/modules/reports/controllers/reports_controller.dart';
import 'package:shc_stock/app/modules/reports/models/analytics_models.dart';
import 'package:shc_stock/app/modules/reports/views/mobile_analytics_tab.dart';
import 'package:shc_stock/app/modules/reports/views/profit_loss_tab.dart';
import 'package:shc_stock/app/modules/reports/views/web_reports_layout.dart';
import 'package:shc_stock/app/modules/reports/widgets/analytics_charts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reports → Analytics / Profit & Loss.
//
// These are dense pages: eleven panels, five of them charts that need a box to
// paint into. flutter_test fails on any RenderFlex overflow or unbounded
// constraint, so pumping the real layouts at a real laptop viewport and a real
// phone viewport is the assertion.
// ─────────────────────────────────────────────────────────────────────────────

class _StubSession extends SessionController {
  @override
  Future<void> restore() async => user.value = const SessionUser(
    id: 1,
    name: 'Chinmay Modi',
    email: 'shc@gmail.com',
    role: 'Admin',
  );
}

/// Reports tab data isn't under test here — only that its controller exists so
/// the shared page shell can build.
class _StubReports extends ReportsController {
  @override
  Future<void> fetchReport() async {}
}

/// The analytics payload as the API actually shapes it, with the awkward cases
/// baked in: a long product name, a zero month, and a bucket with no money in
/// it at all.
class _StubAnalytics extends AnalyticsController {
  @override
  Future<void> fetchAnalytics() async {
    totalSales.value = 2485600;
    totalPurchases.value = 154246;
    activeClients.value = 1037;
    invoicesRaised.value = 86;
    totalSalesTrend.value = 9.6;
    totalPurchasesTrend.value = 4.1;
    activeClientsTrend.value = 1.1;
    invoicesTrend.value = null;

    salesVsPurchases.assignAll([
      for (var i = 0; i < 12; i++)
        TrendPoint(
          label: 'M$i',
          sales: i == 3 ? 0 : 120000.0 * (i + 1),
          purchases: 90000.0 * (i + 1),
        ),
    ]);

    topProducts.assignAll(const [
      RankedRow(
        label: 'Ceramic Fiber Blanket 128 kg/m³ 25mm 1260°C',
        value: 612,
        display: '612 units',
      ),
      RankedRow(
        label: 'Ceramic Fiber Cloth 1mm',
        value: 231,
        display: '231 units',
      ),
      RankedRow(
        label: 'Fire Bricks (Standard)',
        value: 84,
        display: '84 units',
      ),
      RankedRow(
        label: 'Ceramic Fiber Rope 12mm',
        value: 18,
        display: '18 units',
      ),
    ]);
    topClients.assignAll(const [
      RankedRow(
        label: 'Vishal Aluminium Pvt. Ltd.',
        value: 4200000,
        display: '₹42L',
      ),
      RankedRow(
        label: 'Vimal Fire Controls Pvt. Ltd.',
        value: 3100000,
        display: '₹31L',
      ),
      RankedRow(label: 'Vinav Refractories', value: 2400000, display: '₹24L'),
      RankedRow(
        label: 'Vintech Fluxo Pvt. Ltd.',
        value: 1800000,
        display: '₹18L',
      ),
    ]);

    stockMovement.assignAll([
      for (var i = 0; i < 6; i++)
        FlowPoint(
          label: 'M$i',
          inflow: i == 0 ? 0 : 120.0 * i,
          outflow: 90.0 * i,
        ),
    ]);

    inStock.value = 18;
    lowStock.value = 6;
    outOfStock.value = 3;

    collected.value = 1864200;
    outstanding.value = 621400;
    collectionRate.value = 75;

    agingTotal.value = 1064500;
    agingBuckets.assignAll(const [
      AgingBucket(label: '0-30 days', amount: 642000),
      AgingBucket(label: '31-60 days', amount: 284500),
      AgingBucket(label: '61-90 days', amount: 96200),
      AgingBucket(label: '90+ days', amount: 0),
    ]);

    categoryTotal.value = 2485000;
    categoryRevenue.assignAll(const [
      CategoryRevenue(
        category: 'Ceramic Fiber Products',
        amount: 1184000,
        percent: 48,
      ),
      CategoryRevenue(category: 'Refractories', amount: 621000, percent: 25),
      CategoryRevenue(
        category: 'Insulation Bricks',
        amount: 372000,
        percent: 15,
      ),
      CategoryRevenue(
        category: 'Mortars & Castables',
        amount: 209000,
        percent: 8,
      ),
      CategoryRevenue(category: 'Accessories', amount: 100000, percent: 4),
    ]);

    salesThisMonth.value = 2486000;
    salesLastMonth.value = 2132000;
    monthGrowth.value = 16.6;
    ordersThisMonth.value = 128;
    avgOrderValueThisMonth.value = 19400;

    indicators.assignAll(const [
      HealthIndicator(
        label: 'Gross Margin',
        value: '39.2%',
        trend: '1.1%',
        caption: 'vs last month',
      ),
      HealthIndicator(
        label: 'Inventory Turnover',
        value: '6.4x',
        caption: 'COGS (12 months) vs stock on hand',
        neutral: true,
      ),
      HealthIndicator(
        label: 'Avg. Order Value',
        value: '₹18,400',
        trend: '4.2%',
        caption: 'vs last month',
      ),
      HealthIndicator(
        label: 'Repeat Client Rate',
        value: '62%',
        caption: 'clients with more than one order',
        neutral: true,
      ),
      HealthIndicator(
        label: 'Payables Due',
        value: '₹1,54,246',
        caption: '₹22,400 overdue',
        trendUp: false,
      ),
      HealthIndicator(
        label: 'New Clients (MTD)',
        value: '14',
        trend: '3',
        caption: 'vs last month',
      ),
    ]);

    isLoading.value = false;
  }
}

class _StubProfitLoss extends ProfitLossController {
  @override
  Future<void> fetchProfitLoss() async {
    months.assignAll([
      for (var i = 0; i < 12; i++)
        ProfitLossMonth(
          label: 'M$i',
          revenue: 120000.0 * (i + 1),
          cogs: 74000.0 * (i + 1),
          grossProfit: 46000.0 * (i + 1),
          marginPct: 38.3,
          purchases: 90000.0 * (i + 1),
        ),
    ]);
    topProducts.assignAll(const [
      ProfitLossProduct(
        product: 'Ceramic Fiber Blanket 128 kg/m³ 25mm 1260°C',
        revenue: 1184000,
        cogs: 720000,
        grossProfit: 464000,
        marginPct: 39.2,
      ),
      ProfitLossProduct(
        product: 'Fire Bricks (Standard)',
        revenue: 372000,
        cogs: 300000,
        grossProfit: 72000,
        marginPct: 19.4,
      ),
    ]);
    revenue.value = 9360000;
    cogs.value = 5772000;
    grossProfit.value = 3588000;
    purchases.value = 7020000;
    marginPct.value = 38.3;
    isLoading.value = false;
  }
}

void _registerControllers() {
  Get.put(ThemeController(), permanent: true);
  Get.put(ThemeRippleController(), permanent: true);
  Get.put<SessionController>(_StubSession(), permanent: true);
  Get.put<ReportsController>(_StubReports());
  Get.put<AnalyticsController>(_StubAnalytics());
  Get.put<ProfitLossController>(_StubProfitLoss());
}

Widget _app(Widget home) => GetMaterialApp(
  theme: ThemeData(extensions: const [AppThemeColors.light]),
  home: home,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  group('Analytics tab', () {
    testWidgets('lays out on a laptop viewport without overflowing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      _registerControllers();
      Get.find<ReportsController>().tab.value = 1;

      await tester.pumpWidget(_app(const WebReportsLayout()));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Sales vs Purchases (12 months)'), findsOneWidget);
      expect(find.text('Top Selling Products'), findsOneWidget);
      expect(find.text('Business Health Indicators'), findsOneWidget);
    });

    testWidgets('stacks on a phone viewport without overflowing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      _registerControllers();

      await tester.pumpWidget(_app(const Scaffold(body: MobileAnalyticsTab())));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Sales vs Purchases (12 months)'), findsOneWidget);
    });
  });

  group('Profit & Loss tab', () {
    testWidgets('lays out on a laptop viewport', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      _registerControllers();
      Get.find<ReportsController>().tab.value = 2;

      await tester.pumpWidget(_app(const WebReportsLayout()));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Monthly Statement'), findsOneWidget);
      expect(find.text('Gross Profit by Month (12 months)'), findsOneWidget);
    });

    testWidgets('drops the two middle columns on a phone', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      _registerControllers();

      await tester.pumpWidget(
        _app(const Scaffold(body: ProfitLossTab(compact: true))),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      // The header keeps Month / Gross Profit / Margin; Revenue and COGS go.
      expect(find.text('Revenue'), findsNothing);
      expect(find.text('COGS'), findsNothing);
      expect(find.text('Margin'), findsOneWidget);
    });
  });

  group('treemap layout', () {
    test('tiles fill the container and keep their proportions', () {
      const box = Rect.fromLTWH(0, 0, 400, 200);
      final rects = squarify([48, 25, 15, 8, 4], box);

      var covered = 0.0;
      for (final r in rects) {
        expect(box.contains(r.topLeft), isTrue);
        expect(r.right, lessThanOrEqualTo(box.right + 0.001));
        expect(r.bottom, lessThanOrEqualTo(box.bottom + 0.001));
        covered += r.width * r.height;
      }
      expect(covered, closeTo(box.width * box.height, 0.5));

      // Bigger share, bigger tile — the whole point of the chart.
      expect(
        rects[0].width * rects[0].height,
        greaterThan(rects[1].width * rects[1].height),
      );
    });

    test('an empty or zero-total dataset lays out nothing', () {
      expect(squarify(const [], const Rect.fromLTWH(0, 0, 10, 10)), isEmpty);
      final zeros = squarify(const [0, 0], const Rect.fromLTWH(0, 0, 10, 10));
      expect(zeros.every((r) => r == Rect.zero), isTrue);
    });
  });
}

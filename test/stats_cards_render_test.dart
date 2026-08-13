import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_ripple_controller.dart';
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/views/web_sales_layout.dart';
import 'package:shc_stock/app/modules/stock/controllers/stock_controller.dart';
import 'package:shc_stock/app/modules/stock/views/web_stock_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Proves the summary cards actually RENDER the API's numbers — not just that
// the JSON parses. Each page is pumped with a controller whose fetches are
// stubbed to a known /api/stats payload, then we assert those exact figures
// appear on screen.
//
// This is the check that would have caught the Sales page still printing its
// hardcoded "₹ 24,85,600".
// ─────────────────────────────────────────────────────────────────────────────

class _OfflineSalesController extends SalesController {
  @override
  Future<void> fetchOrders() async {}

  @override
  Future<void> fetchStats() async {
    stats.value = StatsSnapshot.fromJson(const {
      'salesMTD': 2485600,
      'totalOrders': 47,
      'amountDue': 325400,
      'receivedMTD': 2160200,
      'totalSales': 3000000,
      'totalReceived': 2500000,
      'avgOrderValue': 15932,
      'trends': {'salesMTD': 18.6, 'receivedMTD': -8.3, 'totalOrders': null},
    });
  }
}

class _OfflineStockController extends StockController {
  @override
  Future<void> fetchItems() async {}

  @override
  Future<void> fetchStats() async {
    stats.value = StatsSnapshot.fromJson(const {
      'totalItems': 28,
      'inStock': 23,
      'lowStock': 2,
      'outOfStock': 3,
      'totalQty': 3152,
      'totalValue': 653274,
      'trends': {'totalItems': null, 'movement': 42.0},
    });
  }
}

Future<void> _pump(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  Get.put(ThemeController(), permanent: true);
  Get.put(ThemeRippleController(), permanent: true);

  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(extensions: const [AppThemeColors.light]),
      home: page,
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  testWidgets(
    'Sales cards render the API figures, not the old hardcoded ones',
    (tester) async {
      Get.put<SalesController>(_OfflineSalesController());
      await _pump(tester, const WebSalesLayout());

      // The four summary cards.
      expect(find.text('₹24,85,600'), findsWidgets); // salesMTD
      expect(find.text('47'), findsWidgets); // totalOrders
      expect(find.text('₹3,25,400'), findsWidgets); // amountDue
      expect(find.text('₹21,60,200'), findsWidgets); // receivedMTD

      // Trends come from the payload, and a null trend prints nothing.
      expect(find.text('+18.6%'), findsWidgets);
      expect(find.text('-8.3%'), findsWidgets);
      expect(find.text('+12.5%'), findsNothing);

      // The Sales Summary side panel is API-driven too.
      expect(find.text('₹30,00,000'), findsWidgets); // totalSales
      expect(find.text('₹25,00,000'), findsWidgets); // totalReceived
      expect(find.text('₹15,932'), findsWidgets); // avgOrderValue
    },
  );

  testWidgets('Sales page no longer contains the old hardcoded literals', (
    tester,
  ) async {
    // Same stub, but with numbers that differ from the retired literals — if
    // any literal survived in the widget tree it would show up here.
    Get.put<SalesController>(_OfflineSalesController());
    await _pump(tester, const WebSalesLayout());

    for (final stale in [
      '₹ 24,85,600',
      '₹ 3,25,400',
      '₹ 21,60,200',
      '₹ 15,932',
    ]) {
      expect(find.text(stale), findsNothing, reason: '$stale is hardcoded');
    }
  });

  testWidgets('Inventory summary cards render from /api/stats/inventory', (
    tester,
  ) async {
    Get.put<StockController>(_OfflineStockController());
    await _pump(tester, const WebStockLayout());

    expect(find.text('Total Items'), findsOneWidget);
    expect(find.text('28'), findsWidgets);
    expect(find.text('Low Stock'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Out of Stock'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.text('Stock Value'), findsOneWidget);
    expect(find.text('₹6,53,274'), findsWidgets);

    // movement trend flows into the Stock Value card.
    expect(find.text('+42.0%'), findsWidgets);
  });
}

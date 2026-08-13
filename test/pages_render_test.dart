import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_ripple_controller.dart';
import 'package:shc_stock/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:shc_stock/app/modules/dashboard/models/dashboard_models.dart';
import 'package:shc_stock/app/modules/dashboard/views/web_dashboard_layout.dart';
import 'package:shc_stock/app/modules/reports/controllers/reports_controller.dart';
import 'package:shc_stock/app/modules/reports/views/reports_view.dart';
import 'package:shc_stock/app/modules/settings/controllers/settings_controller.dart';
import 'package:shc_stock/app/modules/settings/views/mobile_profile_view.dart';
import 'package:shc_stock/app/modules/settings/views/web_settings_layout.dart';
import 'package:shc_stock/app/modules/transactions/controllers/transactions_controller.dart';
import 'package:shc_stock/app/modules/transactions/models/transaction_model.dart';
import 'package:shc_stock/app/modules/transactions/views/web_transactions_layout.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Renders every page that was rewritten but never seen on screen, with stubbed
// API data. Asserts the real values appear, and — because flutter_test fails a
// test on any RenderFlex overflow — that nothing blows out of its box.
// ─────────────────────────────────────────────────────────────────────────────

const _signedIn = SessionUser(
  id: 1,
  name: 'Chinmay Modi',
  email: 'shc@gmail.com',
  role: 'Admin',
);

class _StubSession extends SessionController {
  @override
  Future<void> restore() async => user.value = _signedIn;
}

class _StubDashboard extends DashboardController {
  @override
  Future<void> fetchNotes() async {
    notes.assignAll(const [
      NoteItem(id: 1, text: 'Confirm PO delivery slot', done: true),
      NoteItem(id: 2, text: 'Follow up on restock'),
    ]);
  }

  @override
  Future<void> fetchDashboard() async {
    webStatCards.assignAll(const [
      StatCardData(
        title: 'Total Stock Items',
        value: '3,152',
        icon: StatCardIcon.box,
      ),
    ]);
    dashboardStats.assignAll([
      DashboardStatData(
        title: 'Total Stock Items',
        value: '3,152',
        icon: Icons.inventory_2_rounded,
        iconColor: const Color(0xFF3B6FE0),
      ),
      DashboardStatData(
        title: 'Out of Stock Items',
        value: '3',
        icon: Icons.block_rounded,
        iconColor: const Color(0xFFE0473B),
      ),
      DashboardStatData(
        title: 'Dues from Clients',
        value: '₹1,25,000',
        icon: Icons.description_outlined,
        iconColor: const Color(0xFF2FA85C),
      ),
      DashboardStatData(
        title: 'Top Selling Product',
        value: 'Ceramic Fiber Blanket',
        icon: Icons.emoji_events_rounded,
        iconColor: AppColors.primaryPurple,
      ),
    ]);
    const series = [
      ChartPoint(label: 'Mar', value: 10),
      ChartPoint(label: 'Apr', value: 25),
      ChartPoint(label: 'May', value: 18),
      ChartPoint(label: 'Jun', value: 40),
      ChartPoint(label: 'Jul', value: 32),
      ChartPoint(label: 'Aug', value: 47),
    ];
    purchasesData.assignAll(series);
    salesData.assignAll(series);
    newClientsData.assignAll(series);
    purchasesChange.value = '↑ 12.5% vs last month';
    salesChange.value = '';
    newClientsChange.value = '↑ 47 new this month';

    categorySlices.assignAll(const [
      CategorySlice(
        label: 'Ceramic Fiber Products',
        percent: 55.8,
        color: AppColors.primaryPurple,
      ),
      CategorySlice(
        label: 'Other (3)',
        percent: 44.2,
        color: AppColors.primaryOrange,
      ),
    ]);
    recentTransactions.assignAll(const [
      TransactionRow(
        item: 'Copper Pipe 15mm',
        type: 'Inbound',
        warehouse: 'Ashoka Metals',
        date: '10 Jul 2026',
        status: 'Received',
      ),
    ]);
    incomingDeliveries.assignAll(const [
      DeliveryItem(
        item: 'Brass Valve',
        poRef: 'PO-2024-10001',
        warehouse: 'Gujarat',
        eta: 'Arriving in 3d',
        accentColor: AppColors.primaryPurple,
      ),
    ]);
    lowStockAlerts.assignAll(const [
      LowStockAlertItem(product: 'Fire Bricks', current: 4, max: 10),
    ]);
  }
}

class _StubTransactions extends TransactionsController {
  @override
  Future<void> fetchTransactions() async {
    transactions.assignAll([
      TransactionModel(
        id: '1',
        item: 'Copper Pipe 15mm',
        type: TransactionType.inbound,
        party: 'Ashoka Metals',
        poNumber: '#4421',
        date: DateTime(2026, 7, 10),
        status: TransactionStatus.received,
        // No modifier stored — the cell must degrade to a dash, not a fake name.
        modifiedBy: '',
        modifiedAt: DateTime(2026, 7, 10),
      ),
      TransactionModel(
        id: '2',
        item: 'PEX Fitting Kit',
        type: TransactionType.outbound,
        party: 'Patel Plumbing Co.',
        poNumber: '#4419',
        date: DateTime(2026, 7, 10),
        status: TransactionStatus.shipped,
        modifiedBy: 'Riya Patel',
        modifiedAt: DateTime(2026, 7, 10, 11, 5),
      ),
    ]);
  }

  @override
  Future<void> fetchStats() async {
    stats.value = StatsSnapshot.fromJson(const {
      'totalTransactions': 6,
      'inbound': 3,
      'outbound': 3,
      'pending': 1,
      'trends': {'totalTransactions': null},
    });
  }
}

class _StubReports extends ReportsController {
  @override
  Future<void> fetchReport() async {
    salesLines.assignAll(const [
      ReportLine('Orders', '12'),
      ReportLine('Total Sales', '2485600'),
      ReportLine('Receivable', '325400'),
      ReportLine('Average Order Value', '15932'),
    ]);
    purchaseLines.assignAll(const [
      ReportLine('Orders', '8'),
      ReportLine('Total Purchases', '1200000'),
      ReportLine('Payable', '47200'),
    ]);
    stockLines.assignAll(const [
      ReportLine('Products', '28'),
      ReportLine('Stock Value', '653274'),
      ReportLine('Low Stock', '2'),
      ReportLine('Out of Stock', '3'),
    ]);
    netMovement.value = '1285600';
    topProducts.assignAll(const [
      ReportRank(
        name: 'Ceramic Fiber Blanket',
        detail: 'units sold',
        value: '120',
      ),
    ]);
    topClients.assignAll(const [
      ReportRank(
        name: 'Aavkar Enterprise',
        detail: '4 orders',
        value: '985600',
      ),
    ]);
  }
}

class _StubSettings extends SettingsController {
  @override
  Future<void> fetchSettings() async {
    nameCtrl.text = 'Chinmay Modi';
    emailCtrl.text = 'shc@gmail.com';
    phoneCtrl.text = '+91 98765 00001';
    lowStock.value = true;
    delivery.value = false;
    rowsPerPage.value = 20;
  }
}

Future<void> _pump(WidgetTester tester, Widget page, {Size? size}) async {
  // Realistic laptop viewport — overflows only show up at real sizes.
  tester.view.physicalSize = size ?? const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  Get.put(ThemeController(), permanent: true);
  Get.put(ThemeRippleController(), permanent: true);
  Get.put<SessionController>(_StubSession(), permanent: true);

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

  testWidgets('Dashboard renders API tiles, charts, notes and alerts', (
    tester,
  ) async {
    Get.put<DashboardController>(_StubDashboard());
    await _pump(tester, const WebDashboardLayout());

    // Summary tiles
    expect(find.text('3,152'), findsWidgets);
    expect(find.text('Dues from Clients'), findsWidgets);
    expect(find.text('₹1,25,000'), findsWidgets);
    expect(find.text('Ceramic Fiber Blanket'), findsWidgets);

    // Charts: labels from the API series, and a null change prints nothing.
    expect(find.text('Aug'), findsWidgets);
    expect(find.text('↑ 12.5% vs last month'), findsWidgets);

    // The "Other" bucket that makes the donut total 100%.
    expect(find.text('Other (3)'), findsWidgets);

    // Panels
    expect(find.text('Copper Pipe 15mm'), findsWidgets);
    expect(find.text('Fire Bricks'), findsWidgets);
    expect(find.text('Follow up on restock'), findsWidgets);

    // Greeting uses the signed-in user's first name.
    expect(find.textContaining('Chinmay'), findsWidgets);
  });

  testWidgets('Transactions renders rows, API cards and the new actions', (
    tester,
  ) async {
    Get.put<TransactionsController>(_StubTransactions());
    await _pump(tester, const WebTransactionsLayout());

    // Cards come from /api/stats/transactions — these used to be 312/178/134/9.
    expect(find.text('6'), findsWidgets);
    expect(find.text('312'), findsNothing);
    expect(find.text('178'), findsNothing);

    // Rows
    expect(find.text('Copper Pipe 15mm'), findsWidgets);
    expect(find.text('PEX Fitting Kit'), findsWidgets);

    // The Actions column added for edit/delete.
    expect(find.text('Actions'), findsOneWidget);
    expect(find.byTooltip('Edit'), findsWidgets);
    expect(find.byTooltip('Delete'), findsWidgets);

    // Modified By: real name shows, missing one degrades to a dash.
    expect(find.text('Riya Patel'), findsWidgets);
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('Reports renders every section with formatted money', (
    tester,
  ) async {
    Get.put<ReportsController>(_StubReports());
    await _pump(tester, const ReportsView());

    expect(find.text('Reports'), findsWidgets);
    expect(find.text('Sales'), findsWidgets);
    expect(find.text('Purchases'), findsWidgets);
    expect(find.text('Stock'), findsWidgets);

    // Raw numbers must be rendered as grouped rupees.
    expect(find.text('₹24,85,600'), findsWidgets);
    expect(find.text('₹15,932'), findsWidgets);
    expect(find.text('₹6,53,274'), findsWidgets);
    expect(find.text('₹12,85,600'), findsWidgets); // net movement

    // Non-money lines stay plain.
    expect(find.text('12'), findsWidgets);
    expect(find.text('28'), findsWidgets);

    expect(find.text('Aavkar Enterprise'), findsWidgets);
    expect(find.text('Ceramic Fiber Blanket'), findsWidgets);
    // The disclaimer that this is cash movement, not profit.
    expect(find.textContaining('not accounting profit'), findsWidgets);
  });

  testWidgets('Settings loads the signed-in user and wires its buttons', (
    tester,
  ) async {
    Get.put<SettingsController>(_StubSettings());
    await _pump(tester, const WebSettingsLayout());

    // Profile fields come from the API, not a hardcoded name.
    expect(find.text('Chinmay Modi'), findsWidgets);
    expect(find.text('shc@gmail.com'), findsWidgets);
    // Role is the session's, and the retired literal default is gone.
    expect(find.text('chinmaymodi24@gmail.com'), findsNothing);

    // The buttons that used to be no-ops are present and enabled.
    final save = find.text('Save Changes');
    expect(save, findsWidgets);
    expect(
      tester
          .widget<InkWell>(
            find.ancestor(of: save.first, matching: find.byType(InkWell)).first,
          )
          .onTap,
      isNotNull,
      reason: 'Save Changes must be wired to saveSettings',
    );
  });

  testWidgets('Mobile Profile shows the session user, not a literal', (
    tester,
  ) async {
    Get.put<SettingsController>(_StubSettings());
    await _pump(tester, const MobileProfileView(), size: const Size(430, 1400));

    expect(find.text('CM'), findsWidgets); // session initials
    expect(find.text('Chinmay Modi'), findsWidgets);
    expect(find.text('chinmaymodi24@gmail.com'), findsNothing);
  });
}

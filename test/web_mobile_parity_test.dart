import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/export/export_service.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_ripple_controller.dart';
import 'package:shc_stock/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:shc_stock/app/modules/dashboard/models/dashboard_models.dart';
import 'package:shc_stock/app/modules/dashboard/views/mobile_dashboard_layout.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/notes_todo.dart';
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/modules/sales/views/mobile_sales_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Web ↔ mobile parity, as an executable rule.
//
// The desktop layouts keep a 300px right rail the phone has no room for, and
// the temptation is to drop what was in it. These pin the things that were
// actually missing — the Sale page's three rail cards, and the dashboard's
// recent transactions and notes — so a phone user is not quietly given less.
//
// Row actions are covered elsewhere: web and mobile both route through
// `SalesActions` / `PurchaseActions`, which is what keeps those from drifting.
// ─────────────────────────────────────────────────────────────────────────────

const _phone = Size(390, 844);

const _signedIn = SessionUser(
  id: 1,
  name: 'Chinmay Modi',
  email: 'shc@gmail.com',
  role: 'Super Admin',
  isSuperAdmin: true,
);

class _StubSession extends SessionController {
  @override
  Future<void> restore() async => user.value = _signedIn;
}

class _StubSales extends SalesController {
  @override
  Future<void> fetchStats() async {
    stats.value = StatsSnapshot.fromJson(const {
      'totalOrders': 5,
      'totalSales': 75050,
      'totalReceived': 62950,
      'amountDue': 12100,
      'avgOrderValue': 15010,
      'salesMTD': 2485600,
      'receivedMTD': 2160200,
    });
  }

  @override
  Future<void> fetchOrders() async {
    orders.assignAll([
      SalesOrder(
        id: '156',
        soNumber: 'SO-2024-00156',
        client: 'Suresh Patel Traders',
        clientBadge: 'SP',
        clientColor: AppColors.primaryOrange,
        date: DateTime(2026, 7, 10),
        itemCount: 1,
        amount: 40800,
        status: SalesStatus.delivered,
        paymentStatus: PaymentStatus.paid,
        paidAmount: 40800,
        items: const [
          SaleDetailItem(product: 'Copper Pipe 15mm', qty: 120, rate: 340),
        ],
      ),
    ]);
    isLoading.value = false;
  }
}

class _StubDashboard extends DashboardController {
  @override
  Future<void> fetchNotes() async {}

  @override
  Future<void> fetchDashboard() async {
    dashboardStats.assignAll([
      for (var i = 0; i < 5; i++)
        DashboardStatData(
          title: 'Stat',
          value: '0',
          icon: Icons.insights_rounded,
          iconColor: AppColors.primaryOrange,
        ),
    ]);
    recentTransactions.assignAll(const [
      TransactionRow(
        item: 'Copper Pipe 15mm x 3m',
        type: 'Outbound',
        warehouse: 'Vatva',
        date: '10 Jul 2026',
        status: 'Shipped',
      ),
      TransactionRow(
        item: 'Brass Valve 3/4"',
        type: 'Inbound',
        warehouse: 'Bodakdev',
        date: '09 Jul 2026',
        status: 'Received',
      ),
    ]);
    notes.assignAll([
      NoteItem(id: 1, text: 'Call Suresh about the pending payment'),
    ]);
  }

  // The real one posts to /api/dashboard/notes; here the list is the record.
  @override
  Future<void> addNote(String text) async =>
      notes.add(NoteItem(id: notes.length + 1, text: text));

  @override
  Future<void> toggleNote(int index) async {
    final note = notes[index];
    notes[index] = NoteItem(id: note.id, text: note.text, done: !note.done);
  }

  @override
  Future<void> deleteNote(int index) async => notes.removeAt(index);
}

Future<void> _pump(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  Get.put(ThemeController(), permanent: true);
  Get.put(ThemeRippleController(), permanent: true);
  Get.put<SessionController>(_StubSession(), permanent: true);
  Get.put(ExportService(), permanent: true);

  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(extensions: [AppThemeColors.light]),
      home: page,
    ),
  );
  await tester.pump();
}

/// Drags the page until [target] is on screen — the rail cards live under the
/// list, and the dashboard's new sections under four others.
Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.dragUntilVisible(
    target,
    find.byType(Scrollable).first,
    const Offset(0, -300),
  );
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  group('Sale page · the web rail reaches the phone', () {
    testWidgets('Sales Summary carries the same five figures', (tester) async {
      Get.put<SalesController>(_StubSales());
      await _pump(tester, const MobileSalesLayout());

      await _scrollTo(tester, find.text('Sales Summary'));
      expect(find.text('Total Sales Orders'), findsOneWidget);
      expect(find.text('Total Sales Amount'), findsOneWidget);
      expect(find.text('Total Received'), findsOneWidget);
      expect(find.text('Total Due'), findsOneWidget);
      expect(find.text('Average Order Value'), findsOneWidget);
      // Straight off the same stats the web card reads.
      expect(find.text('₹75,050'), findsOneWidget);
      expect(find.text('₹15,010'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the Billing card and its shortcut are there', (tester) async {
      Get.put<SalesController>(_StubSales());
      await _pump(tester, const MobileSalesLayout());

      await _scrollTo(tester, find.text('Billing'));
      expect(find.text('Bills generated'), findsOneWidget);
      expect(find.text('Pending billing'), findsOneWidget);
      expect(find.text('e-Invoice IRN'), findsOneWidget);
      expect(find.text('Open latest bill'), findsOneWidget);
      expect(find.text('Bill format settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Top Clients is there, with its amounts', (tester) async {
      Get.put<SalesController>(_StubSales());
      await _pump(tester, const MobileSalesLayout());

      await _scrollTo(tester, find.text('Top Clients'));
      expect(find.text('Suresh Patel Traders'), findsWidgets);
      expect(find.text('1 Order'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Dashboard · the web sections reach the phone', () {
    testWidgets('recent transactions are shown, not dropped', (tester) async {
      Get.put<DashboardController>(_StubDashboard());
      await _pump(tester, const MobileDashboardLayout());

      await _scrollTo(tester, find.text('Recent transactions'));
      expect(find.text('Copper Pipe 15mm x 3m'), findsOneWidget);
      expect(find.text('Outbound · Vatva'), findsOneWidget);
      expect(find.text('Shipped'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('notes are shown and can be added from a phone', (
      tester,
    ) async {
      Get.put<DashboardController>(_StubDashboard());
      await _pump(tester, const MobileDashboardLayout());

      await _scrollTo(tester, find.text('Notes & to-dos'));
      expect(
        find.text('Call Suresh about the pending payment'),
        findsOneWidget,
      );

      // The add field is the half that makes the card useful on a phone.
      final field = find.descendant(
        of: find.byType(NotesTodo),
        matching: find.byType(TextField),
      );
      expect(field, findsOneWidget);
      await tester.enterText(field, 'Order more brass valves');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(Get.find<DashboardController>().notes.length, 2);
      expect(tester.takeException(), isNull);
    });
  });
}

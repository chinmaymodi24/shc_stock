import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/session/app_modules.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_ripple_controller.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/app_drawer.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/reports/controllers/reports_controller.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'support/session.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The Analytics nav entry.
//
// The insights dashboard (Reports / Analytics / Profit & Loss) had a route but
// nothing pointing at it, so the page was unreachable - it looked deleted.
// These pin down that the entry exists on both navs, that it opens on the tab
// it is named after, and that it does not light up alongside Reports, whose
// route it sits under.
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _pumpWebChrome(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  Get.put(ThemeController(), permanent: true);
  Get.put(ThemeRippleController(), permanent: true);

  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(extensions: [AppThemeColors.light]),
      home: page,
    ),
  );
  await tester.pump();
}

/// An employee holding exactly the permissions in [permissions].
void _signInWith(Map<String, ModuleAccess> permissions) {
  Get.put(SessionController(), permanent: true).user.value = SessionUser(
    id: 9,
    name: 'Store Staff',
    email: 'staff@example.com',
    role: 'Store Staff',
    token: 'test-token',
    permissions: permissions,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  group('the entry is on both navs', () {
    testWidgets('the web sidebar lists Analytics under Reports', (
      tester,
    ) async {
      signInSuperAdmin();
      await _pumpWebChrome(tester, const Scaffold(body: WebSidebar()));

      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);

      // Under Reports, not above it.
      expect(
        tester.getTopLeft(find.text('Analytics')).dy,
        greaterThan(tester.getTopLeft(find.text('Reports')).dy),
      );
    });

    testWidgets('the mobile drawer lists it too', (tester) async {
      signInSuperAdmin();
      await _pumpWebChrome(
        tester,
        const Scaffold(drawer: AppDrawer(activeRoute: AppRoutes.dashboard)),
      );
      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Analytics'), findsOneWidget);
    });
  });

  group('which entry lights up', () {
    // The whole point of the longest-prefix rule: /reports prefixes
    // /reports/insights, so a plain startsWith highlighted both at once.
    const routes = [
      AppRoutes.dashboard,
      AppRoutes.products,
      AppRoutes.reports,
      AppRoutes.reportsInsights,
      AppRoutes.users,
      AppRoutes.settings,
    ];

    test('the catalog lights Reports alone', () {
      expect(
        WebSidebar.activeNavRoute(AppRoutes.reports, routes),
        AppRoutes.reports,
      );
    });

    test('the insights page lights Analytics, not Reports', () {
      expect(
        WebSidebar.activeNavRoute(AppRoutes.reportsInsights, routes),
        AppRoutes.reportsInsights,
      );
    });

    test('a sub-route still lights its module', () {
      expect(
        WebSidebar.activeNavRoute(AppRoutes.reportDetail, routes),
        AppRoutes.reports,
      );
      expect(
        WebSidebar.activeNavRoute(AppRoutes.addProduct, routes),
        AppRoutes.products,
      );
    });

    test('an unknown route lights nothing', () {
      expect(WebSidebar.activeNavRoute('/login', routes), isNull);
    });
  });

  group('permissions', () {
    test('summary rights on Reports open it', () {
      _signInWith(const {
        'Reports': ModuleAccess(read: true, summary: true),
      });
      expect(canOpenRoute(AppRoutes.reportsInsights), isTrue);
    });

    test('read without summary opens the catalog but not Analytics', () {
      _signInWith(const {'Reports': ModuleAccess(read: true)});
      expect(canOpenRoute(AppRoutes.reports), isTrue);
      expect(canOpenRoute(AppRoutes.reportsInsights), isFalse);
    });

    testWidgets('and the entry is hidden from that employee', (tester) async {
      _signInWith(const {'Reports': ModuleAccess(read: true)});
      await _pumpWebChrome(tester, const Scaffold(body: WebSidebar()));

      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Analytics'), findsNothing);
    });
  });

  test('the page opens on the tab the entry is named after', () {
    // ReportsTabBar: 0 Reports, 1 Analytics, 2 Profit & Loss.
    expect(ReportsController().tab.value, 1);
  });
}

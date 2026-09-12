import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/session/app_modules.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_ripple_controller.dart';
import 'package:shc_stock/app/modules/categories/controllers/categories_controller.dart';
import 'package:shc_stock/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:shc_stock/app/modules/dashboard/views/web_dashboard_layout.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/products/views/mobile_products_layout.dart';
import 'package:shc_stock/app/modules/products/views/web_products_layout.dart';
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/views/web_sales_layout.dart';
import 'package:shc_stock/app/modules/settings/controllers/settings_controller.dart';
import 'package:shc_stock/app/modules/settings/views/web_settings_layout.dart';
import 'package:shc_stock/app/modules/stock/controllers/stock_controller.dart';
import 'package:shc_stock/app/modules/stock/models/stock_item_model.dart';
import 'package:shc_stock/app/modules/stock/views/mobile_stock_layout.dart';
import 'package:shc_stock/app/modules/stock/views/web_stock_layout.dart';
import 'package:shc_stock/app/modules/users/controllers/add_employee_wizard_controller.dart';
import 'package:shc_stock/app/modules/users/controllers/users_controller.dart';
import 'package:shc_stock/app/modules/users/models/permission_editor.dart';
import 'package:shc_stock/app/modules/users/models/role_model.dart';
import 'package:shc_stock/app/modules/users/views/web_users_layout.dart';
import 'package:shc_stock/app/modules/users/views/wizard/custom_role_dialog.dart';
import 'package:shc_stock/app/modules/users/views/wizard/permission_table.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/shared/widgets/stat_cards.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Employee rights, as each kind of employee actually sees the app.
//
// The backend has its own end-to-end suite (backend/e2e_rights_test.js). These
// tests pump the real pages under specific permission maps and check what is
// shown: summary cards, add / edit / delete, the Settings tabs, the dashboard
// blocks — plus the wizard's permission editing and the session plumbing.
// ─────────────────────────────────────────────────────────────────────────────

const _r = ModuleAccess(read: true);
const _rw = ModuleAccess(read: true, write: true);
const _rs = ModuleAccess(read: true, summary: true);

/// The ready-made Store Staff role: stock entry, no business figures.
const _storeStaff = {
  'Dashboard': _r,
  'Categories': _r,
  'Products': _r,
  'Purchase': _r,
  'Inventory': _rw,
  'Settings: Notifications': _rw,
};

/// The ready-made Sales role.
const _sales = {
  'Dashboard': _r,
  'Products': _r,
  'Inventory': _r,
  'Sales': _rw,
  'Clients': _rw,
};

void _signIn(Map<String, ModuleAccess> perms, {bool superAdmin = false}) {
  Get.put(SessionController(), permanent: true).user.value = SessionUser(
    id: 7,
    name: 'Test Employee',
    email: 'employee@example.com',
    role: superAdmin ? 'Super Admin' : 'Custom',
    isSuperAdmin: superAdmin,
    token: 'test-token',
    permissions: perms,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(1440, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  Get.put(ThemeController(), permanent: true);
  Get.put(ThemeRippleController(), permanent: true);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(extensions: [AppThemeColors.light]),
      home: page,
      getPages: [GetPage(name: AppRoutes.login, page: () => const Scaffold())],
    ),
  );
  await tester.pump();
}

// ── Offline controllers ────────────────────────────────────────────────────

class _Stock extends StockController {
  @override
  Future<void> fetchStats() async {}
  @override
  Future<void> fetchItems() async {
    items.assignAll([
      StockItemModel.fromJson(const {
        'id': 1,
        'productId': 1,
        'sku': 'CFB-1260-64',
        'name': 'CF Blanket 1260°C',
        'category': 'Ceramic Fiber Products',
        'stockInHand': 12,
        'status': 'inStock',
      }),
    ]);
  }
}

class _Products extends ProductsController {
  @override
  Future<void> fetchStats() async {}
  @override
  Future<void> fetchProducts() async {
    final rows = [
      ProductModel(
        id: '1',
        name: 'CF Blanket 1260°C',
        sku: 'CFB-1260-64',
        categoryId: '1',
        categoryName: 'Ceramic Fiber Products',
        subCategory: 'Blanket',
        unit: 'Roll',
        sellingPrice: 2800,
        costPrice: 1900,
        currentStock: 12,
        minimumStock: 5,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];
    products.assignAll(rows);
    filteredProducts.assignAll(rows);
  }
}

class _Categories extends CategoriesController {
  @override
  Future<void> fetchCategories() async {}
  @override
  Future<void> fetchStats() async {}
}

class _Sales extends SalesController {
  @override
  Future<void> fetchOrders() async {}
  @override
  Future<void> fetchStats() async {
    stats.value = StatsSnapshot.empty;
  }
}

class _Dashboard extends DashboardController {
  @override
  Future<void> fetchDashboard() async {}
  @override
  Future<void> fetchNotes() async {}
}

class _Settings extends SettingsController {
  @override
  Future<void> fetchSettings() async {}
}

const _storeStaffRole = RoleModel(
  id: 5,
  key: 'store_staff',
  name: 'Store Staff',
  isSystem: true,
  permissions: _storeStaff,
);
const _superAdminRole = RoleModel(
  id: 1,
  key: 'super_admin',
  name: 'Super Admin',
  isSystem: true,
  isSuperAdmin: true,
);

class _Users extends UsersController {
  RoleModel? lastCreated;
  Map<String, dynamic>? lastBody;

  @override
  Future<void> fetchUsers() async {}
  @override
  Future<void> fetchStats() async {}
  @override
  Future<void> fetchRoles() async {
    roles.assignAll([_superAdminRole, _storeStaffRole]);
  }

  @override
  Future<RoleModel?> createRole(Map<String, dynamic> body) async {
    lastBody = body;
    return lastCreated = RoleModel(
      id: 99,
      name: body['name'] as String,
      permissions: const {'Inventory': _rw},
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  group('Store Staff — stock entry without the business figures', () {
    testWidgets(
      'Inventory (web): Adjust Stock yes, cards and product edits no',
      (tester) async {
        _signIn(_storeStaff);
        Get.put<CategoriesController>(_Categories(), permanent: true);
        Get.put<ProductsController>(_Products(), permanent: true);
        Get.put<StockController>(_Stock());
        await _pump(tester, const WebStockLayout());

        expect(find.byType(AppStatCardRow), findsNothing);
        expect(find.text('Adjust Stock'), findsOneWidget);
        expect(find.text('CF Blanket 1260°C'), findsOneWidget);
        expect(find.byTooltip('View'), findsOneWidget);
        // Edit / Duplicate / Delete change the product — Products is read-only.
        expect(find.byTooltip('Edit'), findsNothing);
        expect(find.byTooltip('Duplicate'), findsNothing);
        expect(find.byTooltip('Delete'), findsNothing);
      },
    );

    testWidgets('Inventory (mobile): no KPI grid, Adjust Stock FAB stays', (
      tester,
    ) async {
      _signIn(_storeStaff);
      Get.put<CategoriesController>(_Categories(), permanent: true);
      Get.put<ProductsController>(_Products(), permanent: true);
      Get.put<StockController>(_Stock());
      await _pump(
        tester,
        const MobileStockLayout(),
        size: const Size(390, 844),
      );

      expect(find.byType(MobileStatGrid), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Adjust Stock'), findsOneWidget);
    });

    testWidgets('Products (web): read-only — no Add, no row edits, no cards', (
      tester,
    ) async {
      _signIn(_storeStaff);
      Get.put<CategoriesController>(_Categories(), permanent: true);
      Get.put<ProductsController>(_Products());
      await _pump(tester, WebProductsLayout());

      expect(find.text('CF Blanket 1260°C'), findsWidgets);
      expect(find.text('Add Product'), findsNothing);
      expect(find.byType(AppStatCardRow), findsNothing);
      expect(find.byTooltip('Edit'), findsNothing);
      expect(find.byTooltip('Delete'), findsNothing);
      expect(find.byTooltip('View'), findsWidgets);
    });

    testWidgets('Products (mobile): no Add FAB, no KPI grid', (tester) async {
      _signIn(_storeStaff);
      Get.put<CategoriesController>(_Categories(), permanent: true);
      Get.put<ProductsController>(_Products());
      await _pump(
        tester,
        const MobileProductsLayout(),
        size: const Size(390, 844),
      );

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byType(MobileStatGrid), findsNothing);
    });

    testWidgets(
      'Dashboard (web): no KPIs or charts; allowed lists and notes stay',
      (tester) async {
        _signIn(_storeStaff);
        Get.put<DashboardController>(_Dashboard());
        await _pump(tester, const WebDashboardLayout());

        expect(find.byType(AppStatCardRow), findsNothing);
        expect(find.text('Sales (6 months)'), findsNothing);
        expect(find.text('Category breakdown'), findsNothing);
        // No Transactions access.
        expect(find.text('Recent transactions'), findsNothing);
        // Purchase read and Inventory read.
        expect(find.text('Incoming deliveries'), findsOneWidget);
        expect(find.text('Low stock alerts'), findsOneWidget);
        expect(find.text('Notes & to-dos'), findsOneWidget);
      },
    );

    test('routes: stock yes, add product no, employee no', () {
      _signIn(_storeStaff);
      expect(canOpenRoute(AppRoutes.stock), isTrue);
      expect(canOpenRoute(AppRoutes.products), isTrue);
      expect(canOpenRoute(AppRoutes.addProduct), isFalse);
      expect(canOpenRoute(AppRoutes.users), isFalse);
      expect(canOpenRoute(AppRoutes.reportsInsights), isFalse);
    });

    test('summary cards are never even requested', () async {
      _signIn(_storeStaff);
      // The network is disabled under test, so a real request would throw.
      final snap = await StatsSnapshot.fetch('inventory');
      expect(snap.values, isEmpty);
    });

    test('a write guard refuses and says why', () {
      _signIn(_storeStaff);
      expect(canWriteModule('Inventory'), isTrue);
      expect(canWriteModule('Products'), isFalse);
    });
  });

  group('Sales and Manager — the Sales page', () {
    testWidgets('Sales role: Add Sale, but no cards and no summary rail', (
      tester,
    ) async {
      _signIn(_sales);
      Get.put<SalesController>(_Sales());
      await _pump(tester, const WebSalesLayout());

      expect(find.text('Add Sale'), findsOneWidget);
      expect(find.text('Total Sales (MTD)'), findsNothing);
      expect(find.text('Sales Summary'), findsNothing);
    });

    testWidgets('with Sales summary: cards and rail are back', (tester) async {
      _signIn({'Sales': const ModuleAccess(read: true, summary: true)});
      Get.put<SalesController>(_Sales());
      await _pump(tester, const WebSalesLayout());

      expect(find.text('Total Sales (MTD)'), findsOneWidget);
      expect(find.text('Sales Summary'), findsOneWidget);
      // Read + summary, but no write.
      expect(find.text('Add Sale'), findsNothing);
    });

    test(
      'a Super Admin opens the summary endpoint (so it would be called)',
      () {
        _signIn(const {}, superAdmin: true);
        expect(
          () => StatsSnapshot.fetch('inventory'),
          throwsA(isA<ApiException>()),
        );
      },
    );
  });

  group('Employee page', () {
    testWidgets('read-only: no Add, no Reset, Export stays', (tester) async {
      _signIn({'Employee': _r});
      Get.put<UsersController>(_Users());
      await _pump(tester, const WebUsersLayout());

      expect(find.text('Add New Employee'), findsNothing);
      expect(find.text('Reset Permissions'), findsNothing);
      expect(find.text('Export Employee List'), findsOneWidget);
      expect(find.text('Role Breakdown'), findsNothing);
    });

    testWidgets('write without summary: Add shows, figures do not', (
      tester,
    ) async {
      _signIn({'Employee': _rw});
      Get.put<UsersController>(_Users());
      await _pump(tester, const WebUsersLayout());

      expect(find.text('Add New Employee'), findsWidgets);
      expect(find.text('Role Breakdown'), findsNothing);
      expect(find.byType(AppStatCardRow), findsNothing);
    });

    testWidgets('with summary: role breakdown shows', (tester) async {
      _signIn({'Employee': _rs});
      Get.put<UsersController>(_Users());
      await _pump(tester, const WebUsersLayout());

      expect(find.text('Role Breakdown'), findsOneWidget);
    });
  });

  group('Settings tabs', () {
    testWidgets('only permitted tabs are listed; read-only tab is view only', (
      tester,
    ) async {
      _signIn({'Settings: Notifications': _r});
      final settings = Get.put<SettingsController>(
        _Settings(),
        permanent: true,
      );
      await _pump(tester, const WebSettingsLayout());

      // Always open.
      expect(find.text('Profile'), findsWidgets);
      expect(find.text('Security'), findsWidgets);
      // Granted (read).
      expect(find.text('Notifications'), findsWidgets);
      // Not granted — not even listed.
      expect(find.text('Preferences'), findsNothing);
      expect(find.text('Billing'), findsNothing);
      expect(find.text('Appearance'), findsNothing);

      settings.tab.value = 1; // Notifications
      await tester.pump();
      expect(find.textContaining('View only'), findsOneWidget);
      expect(find.byType(AbsorbPointer), findsWidgets);

      settings.tab.value = 5; // Appearance, reached some other way
      await tester.pump();
      expect(
        find.textContaining("don't have permission to view Appearance"),
        findsOneWidget,
      );
    });

    testWidgets('with write the tab is editable — no view-only notice', (
      tester,
    ) async {
      _signIn({'Settings: Notifications': _rw});
      final settings = Get.put<SettingsController>(
        _Settings(),
        permanent: true,
      );
      settings.tab.value = 1;
      await _pump(tester, const WebSettingsLayout());

      expect(find.textContaining('View only'), findsNothing);
    });
  });

  group('Permission editor rules', () {
    test('write and summary switch read on; read off clears both', () {
      final e = PermissionEditor();
      final inv = e.perms.firstWhere((p) => p.key == 'Inventory');

      e.setWrite(inv, true);
      expect(inv.read, isTrue);
      e.setSummary(inv, true);
      expect(inv.summary, isTrue);
      e.setRead(inv, false);
      expect([inv.read, inv.write, inv.summary], [false, false, false]);
    });

    test('Settings rows carry no summary', () {
      final e = PermissionEditor();
      final billing = e.perms.firstWhere((p) => p.key == 'Settings: Billing');
      e.setSummary(billing, true);
      expect(billing.summary, isFalse);
      expect(billing.toJson().containsKey('summary'), isFalse);
      expect(e.settingsCnt, kSettingsSections.length);
      expect(e.moduleCnt, kGatedModules.length);
    });

    test('select-all toggles on, then off', () {
      final e = PermissionEditor();
      e.toggleAllSummary();
      expect(e.modules.every((p) => p.summary && p.read), isTrue);
      e.toggleAllSummary();
      expect(e.modules.any((p) => p.summary), isFalse);

      e.toggleAllWrite();
      expect(e.perms.every((p) => p.write && p.read), isTrue);
      e.toggleAllRead(); // all read already on → clears everything
      expect(e.perms.every((p) => p.noAccess), isTrue);
    });

    test('loading a role copies it; a Super Admin loads everything', () {
      final e = PermissionEditor();
      e.load(_storeStaff);
      expect(e.writeCnt, 1); // Inventory
      expect(e.summaryCnt, 0);
      expect(e.settingsWriteCnt, 1); // Notifications

      e.load(const {}, everything: true);
      expect(e.noCnt, 0);
      expect(e.summaryCnt, e.moduleCnt);
    });

    testWidgets('table: Show All Summary turns every module on', (
      tester,
    ) async {
      final e = PermissionEditor();
      await _pump(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                PermissionBulkActions(editor: e),
                PermissionTable(editor: e, wide: true),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Summary'), findsWidgets);
      await tester.tap(find.text('Show All Summary'));
      await tester.pump();
      expect(e.summaryCnt, e.moduleCnt);
      expect(find.text('Hide All Summary'), findsOneWidget);
    });
  });

  group('Add Employee wizard', () {
    test('picking a role fills the permissions from it', () {
      _signIn(const {}, superAdmin: true);
      Get.put<UsersController>(_Users());
      final c = Get.put(AddEmployeeWizardController());

      c.selectRole(_storeStaffRole);
      expect(c.roleId.value, 5);
      final inv = c.perms.firstWhere((p) => p.key == 'Inventory');
      expect(inv.write, isTrue);
      expect(inv.summary, isFalse);
      expect(c.editor.toJson()['Sales'], {
        'read': false,
        'write': false,
        'summary': false,
      });

      c.selectRole(_superAdminRole);
      expect(c.editor.noCnt, 0);
    });

    test('a role is required to continue', () {
      _signIn(const {}, superAdmin: true);
      Get.put<UsersController>(_Users());
      final c = Get.put(AddEmployeeWizardController());
      expect(c.v2(), isFalse);
      expect(c.roleErr.value, isTrue);
      c.selectRole(_storeStaffRole);
      expect(c.v2(), isTrue);
    });

    test('only a Super Admin can hand out Super Admin', () {
      _signIn({'Employee': _rw});
      Get.put<UsersController>(_Users());
      final c = Get.put(AddEmployeeWizardController());
      expect(c.assignableRoles.map((r) => r.name), ['Store Staff']);
    });

    testWidgets('Define Custom Role: name required, then saves the table', (
      tester,
    ) async {
      _signIn(const {}, superAdmin: true);
      final users = Get.put<UsersController>(_Users()) as _Users;
      await _pump(tester, const Scaffold(body: SizedBox()));

      final result = showCustomRoleDialog();
      await tester.pumpAndSettle();
      expect(find.text('Define Custom Role'), findsOneWidget);

      await tester.tap(find.text('Save Role'));
      await tester.pump();
      expect(find.text('Role name is required'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Stock Clerk');
      await tester.tap(find.text('Store Staff')); // start from Store Staff
      await tester.pump();
      await tester.tap(find.text('Save Role'));
      await tester.pumpAndSettle();

      expect(users.lastBody!['name'], 'Stock Clerk');
      final perms = users.lastBody!['permissions'] as Map<String, dynamic>;
      expect(perms['Inventory'], {
        'read': true,
        'write': true,
        'summary': false,
      });
      expect(perms['Settings: Notifications'], {'read': true, 'write': true});
      expect((await result)!.name, 'Stock Clerk');
    });
  });

  group('Session', () {
    test('a session saved before tokens existed signs out', () async {
      SharedPreferences.setMockInitialValues({
        'session_user':
            '{"id":1,"name":"Old","email":"old@example.com","role":"Admin"}',
      });
      final s = Get.put(SessionController());
      await s.ready;
      expect(s.isSignedIn, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('session_user'), isNull);
    });

    test('a role named "Admin" is not a Super Admin', () {
      _signIn(const {});
      expect(isSuperAdminSession, isFalse);
      expect(canOpenRoute(AppRoutes.products), isFalse);
    });

    test('saving the profile keeps the token and permissions', () async {
      _signIn(_sales);
      final s = Get.find<SessionController>();
      await s.updateProfile(name: 'Renamed');
      expect(s.user.value!.name, 'Renamed');
      expect(s.user.value!.token, 'test-token');
      expect(s.canWrite('Sales'), isTrue);
    });

    test('every request carries the token', () {
      _signIn(_sales);
      expect(ApiClient.instance.tokenProvider!(), 'test-token');
    });

    testWidgets('a rejected session (401) signs out to the login page', (
      tester,
    ) async {
      _signIn(_sales);
      await _pump(tester, const Scaffold(body: Text('Somewhere')));
      ApiClient.instance.onUnauthorized!();
      await tester.pumpAndSettle();
      expect(Get.find<SessionController>().isSignedIn, isFalse);
      expect(Get.currentRoute, AppRoutes.login);
    });
  });
}

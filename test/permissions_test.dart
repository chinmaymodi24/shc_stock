import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/session/app_modules.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Per-employee module access.
//
// Read / write / summary are ticked per module (read / write per Settings
// tab) in the Add Employee wizard; that map is stored on the user row and read
// back here by the sidebar, the drawer, the route guard, the summary cards and
// the Settings tabs. The rules that matter:
//   • a Super Admin ignores the map entirely,
//   • the Settings page is never gated, nor its Profile and Security tabs —
//     they hold your own profile and password,
//   • a module's sub-routes inherit the module's own permission, and an add
//     screen needs write, not just read,
//   • summary is its own right, separate from read,
//   • signed out fails closed.
// ─────────────────────────────────────────────────────────────────────────────

SessionUser _employee(Map<String, ModuleAccess> perms) => SessionUser(
  id: 2,
  name: 'Deepak',
  email: 'deepak@shc.com',
  role: 'Salesman',
  permissions: perms,
);

void main() {
  tearDown(Get.reset);

  group('SessionUser', () {
    test('a Super Admin can do everything, map or no map', () {
      const admin = SessionUser(
        id: 1,
        name: 'Administrator',
        email: 'admin@admin.com',
        role: 'Super Admin',
        isSuperAdmin: true,
      );
      for (final m in kAppModules) {
        expect(admin.canRead(m.name), isTrue, reason: m.name);
        expect(admin.canWrite(m.name), isTrue, reason: m.name);
        expect(admin.canSummary(m.name), isTrue, reason: m.name);
      }
      for (final s in kSettingsSections) {
        expect(admin.canWrite(s.key), isTrue, reason: s.key);
      }
    });

    test('a role merely named "Admin" is not a Super Admin', () {
      final u = _employee(const {});
      expect(
        SessionUser.fromJson({...u.toJson(), 'role': 'Admin'}).isSuperAdmin,
        isFalse,
      );
    });

    test('summary is separate from read, and implies it', () {
      final u = _employee({
        'Inventory': const ModuleAccess(read: true, write: true),
      });
      expect(u.canRead('Inventory'), isTrue);
      expect(u.canWrite('Inventory'), isTrue);
      expect(u.canSummary('Inventory'), isFalse);

      final back = SessionUser.fromJson({
        ...u.toJson(),
        'permissions': {
          'Sales': {'summary': true},
        },
      });
      expect(back.canSummary('Sales'), isTrue);
      expect(back.canRead('Sales'), isTrue);
    });

    test('an employee gets exactly what the map grants', () {
      final u = _employee({
        'Products': const ModuleAccess(read: true, write: false),
        'Sales': ModuleAccess.full,
      });

      expect(u.isSuperAdmin, isFalse);
      expect(u.canRead('Products'), isTrue);
      expect(u.canWrite('Products'), isFalse);
      expect(u.canRead('Sales'), isTrue);
      expect(u.canWrite('Sales'), isTrue);
      // Never mentioned in the map at all.
      expect(u.canRead('Employee'), isFalse);
      expect(u.canWrite('Employee'), isFalse);
    });

    test('survives a round trip through storage', () {
      final u = _employee({
        'Products': const ModuleAccess(read: true, write: false),
      });
      final back = SessionUser.fromJson(u.toJson());

      expect(back.email, 'deepak@shc.com');
      expect(back.canRead('Products'), isTrue);
      expect(back.canWrite('Products'), isFalse);
      expect(back.canRead('Reports'), isFalse);
    });

    test('a malformed permissions blob reads as no access, never throws', () {
      final u = SessionUser.fromJson(const {
        'id': 3,
        'name': 'X',
        'email': 'x@y.com',
        'role': 'Salesman',
        'permissions': 'not-a-map',
      });
      expect(u.permissions, isEmpty);
      expect(u.canRead('Products'), isFalse);
    });
  });

  group('moduleForRoute', () {
    test('maps each module route to its own name', () {
      expect(moduleForRoute(AppRoutes.products), 'Products');
      expect(moduleForRoute(AppRoutes.users), 'Employee');
      expect(moduleForRoute(AppRoutes.stock), 'Inventory');
    });

    test('a sub-route belongs to its parent module', () {
      expect(moduleForRoute(AppRoutes.addProduct), 'Products');
      expect(moduleForRoute(AppRoutes.addPurchase), 'Purchase');
      expect(moduleForRoute(AppRoutes.addEmployee), 'Employee');
      expect(moduleForRoute(AppRoutes.reportDetail), 'Reports');
    });

    test('login and splash belong to no module', () {
      expect(moduleForRoute(AppRoutes.login), isNull);
      expect(moduleForRoute(AppRoutes.splash), isNull);
    });
  });

  group('canOpenRoute', () {
    void signIn(SessionUser u) {
      final s = Get.put(SessionController(), permanent: true);
      s.user.value = u;
    }

    test('an employee is blocked from a module they were not granted', () {
      signIn(
        _employee({'Products': const ModuleAccess(read: true, write: false)}),
      );

      expect(canOpenRoute(AppRoutes.products), isTrue);
      expect(canOpenRoute(AppRoutes.users), isFalse);
      expect(canOpenRoute(AppRoutes.reports), isFalse);
    });

    test('blocking a module also blocks its add screen', () {
      signIn(_employee({'Sales': ModuleAccess.full}));

      expect(canOpenRoute(AppRoutes.addSale), isTrue);
      // Products was never granted, so its add route is closed too — this is
      // the hole that hiding the nav entry alone would have left open.
      expect(canOpenRoute(AppRoutes.addProduct), isFalse);
    });

    test('an add screen needs write, not just read', () {
      signIn(
        _employee({'Products': const ModuleAccess(read: true, write: false)}),
      );

      expect(canOpenRoute(AppRoutes.products), isTrue);
      expect(canOpenRoute(AppRoutes.addProduct), isFalse);
    });

    test('summary cards and Settings tabs follow their own rights', () {
      signIn(
        _employee({
          'Inventory': const ModuleAccess(read: true, write: true),
          'Sales': ModuleAccess.full,
          settingsKey('Billing'): const ModuleAccess(read: true),
        }),
      );

      expect(canSeeSummary('Inventory'), isFalse);
      expect(canSeeSummary('Sales'), isTrue);
      expect(canOpenSettingsTab('Billing'), isTrue);
      expect(canSaveSettingsTab('Billing'), isFalse);
      expect(canOpenSettingsTab('Appearance'), isFalse);
      // Your own account is always yours.
      expect(canOpenSettingsTab('Profile'), isTrue);
      expect(canSaveSettingsTab('Security'), isTrue);
    });

    test('Settings and Profile stay open to everyone', () {
      signIn(_employee(const {}));

      expect(canOpenRoute(AppRoutes.settings), isTrue);
      expect(canOpenRoute(AppRoutes.settingsDetail), isTrue);
    });

    test('a Super Admin opens everything', () {
      signIn(
        const SessionUser(
          id: 1,
          name: 'Administrator',
          email: 'admin@admin.com',
          role: 'Super Admin',
          isSuperAdmin: true,
        ),
      );

      for (final m in kAppModules) {
        expect(canOpenRoute(m.route), isTrue, reason: m.route);
      }
    });

    test('signed out fails closed on a gated route', () {
      Get.put(SessionController(), permanent: true);
      expect(canOpenRoute(AppRoutes.products), isFalse);
      // …but never on one nothing gates.
      expect(canOpenRoute(AppRoutes.login), isTrue);
    });
  });
}

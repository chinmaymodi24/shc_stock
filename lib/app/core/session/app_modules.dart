import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The one list of gateable modules.
//
// The permissions an admin ticks in the Add Employee wizard are stored by
// MODULE NAME, and the sidebar, the drawer and the route guard all read them
// back by that same name — so the name has to mean the same thing in all four
// places. It didn't: the wizard offered "Sale" while the nav called it
// "Sales", and the wizard had no "Employee" entry at all, so those two could
// never be granted or denied. Everything now derives from this list.
// ─────────────────────────────────────────────────────────────────────────────
class AppModule {
  /// Stored in `users.permissions` and shown in the wizard — never localised.
  final String name;
  final IconData icon;
  final String route;

  const AppModule(this.name, this.icon, this.route);
}

const kAppModules = <AppModule>[
  AppModule('Dashboard', Icons.dashboard_rounded, AppRoutes.dashboard),
  AppModule('Categories', Icons.category_outlined, AppRoutes.categories),
  AppModule('Products', Icons.inventory_2_outlined, AppRoutes.products),
  AppModule('Purchase', Icons.shopping_bag_outlined, AppRoutes.purchase),
  AppModule('Sales', Icons.point_of_sale_outlined, AppRoutes.sales),
  AppModule('Inventory', Icons.warehouse_outlined, AppRoutes.stock),
  AppModule('Clients', Icons.people_outline_rounded, AppRoutes.clients),
  AppModule('Transactions', Icons.swap_horiz_rounded, AppRoutes.transactions),
  AppModule('Employee', Icons.manage_accounts_outlined, AppRoutes.users),
  AppModule('Reports', Icons.bar_chart_rounded, AppRoutes.reports),
  AppModule('Settings', Icons.settings_outlined, AppRoutes.settings),
];

/// The Settings page itself is never gated. It is where a signed-in person
/// changes their own password and reads their own profile, so denying it
/// would lock them out of their own account. Its other tabs are gated one by
/// one instead — see [kSettingsSections].
const kAlwaysAllowedModules = {'Settings'};

/// The modules an employee is granted access to one by one — every module
/// except the always-open Settings page. Each has read, write and summary.
final kGatedModules = kAppModules
    .where((m) => !kAlwaysAllowedModules.contains(m.name))
    .toList();

/// A Settings tab that changes something beyond the signed-in person's own
/// account, and so needs its own permission (read = see the tab, write =
/// save it). Profile and Security are absent on purpose: they are always open.
class SettingsSection {
  final String name;
  final IconData icon;
  const SettingsSection(this.name, this.icon);

  /// Stored in `users.permissions` — mirrored by backend/src/permissions.js.
  String get key => settingsKey(name);
}

String settingsKey(String section) => 'Settings: $section';

const kSettingsSections = <SettingsSection>[
  SettingsSection('Notifications', Icons.notifications_none_rounded),
  SettingsSection('Preferences', Icons.tune_rounded),
  SettingsSection('Billing', Icons.receipt_long_outlined),
  SettingsSection('Appearance', Icons.palette_outlined),
];

/// Settings tabs that are never gated.
const kAlwaysOpenSettingsTabs = {'Profile', 'Security'};

SessionController? get _session => Get.isRegistered<SessionController>()
    ? Get.find<SessionController>()
    : null;

/// Whether the signed-in user may see the summary figures of [module] — the
/// stat cards at the top of its page (the KPIs and charts on the Dashboard).
bool canSeeSummary(String module) => _session?.canSummary(module) ?? false;

/// Whether the signed-in user holds the Super Admin role.
bool get isSuperAdminSession => _session?.isSuperAdmin ?? false;

/// Whether the signed-in user may open [module] at all.
bool canReadModule(String module) => _session?.canRead(module) ?? false;

/// Whether the signed-in user may add, edit or delete in [module].
bool canWriteModule(String module) => _session?.canWrite(module) ?? false;

/// Guard for an action that changes data in [module]. Returns true when the
/// signed-in user may; otherwise says why and returns false.
///
/// The buttons for these actions are hidden from someone without write
/// access. This is the safety net for every other way in — a details dialog,
/// a menu, a keyboard shortcut — so none of them can open an edit form the
/// backend would refuse to save anyway.
bool requireWrite(String module) {
  if (canWriteModule(module)) return true;
  showAppToast(
    'No Permission',
    "You don't have permission to change $module.",
    backgroundColor: const Color(0xFFEF4444),
    colorText: Colors.white,
    icon: Icons.lock_outline_rounded,
  );
  return false;
}

/// Whether the signed-in user may open the Settings tab called [tab].
bool canOpenSettingsTab(String tab) {
  if (kAlwaysOpenSettingsTabs.contains(tab)) return true;
  return _session?.canRead(settingsKey(tab)) ?? false;
}

/// Whether the signed-in user may save changes on the Settings tab [tab].
bool canSaveSettingsTab(String tab) {
  if (kAlwaysOpenSettingsTabs.contains(tab)) return true;
  return _session?.canWrite(settingsKey(tab)) ?? false;
}

/// Routes that only create or change data. Opening one needs write access to
/// its module, not just read — otherwise a read-only employee could still
/// reach Add Product by URL.
const kWriteOnlyRoutes = {
  AppRoutes.addProduct,
  AppRoutes.addPurchase,
  AppRoutes.addSale,
  AppRoutes.addClient,
  AppRoutes.addEmployee,
};

/// The module a route belongs to, or null for the ungated ones (splash,
/// login).
///
/// Matched by path prefix, so a module's sub-routes are covered by the module
/// itself: `/products/add` answers "Products", `/reports/detail` answers
/// "Reports". Denying Products has to deny the Add Product screen too —
/// otherwise the nav entry is hidden while the route behind it stays open.
String? moduleForRoute(String route) {
  // Longest first, so `/reports/detail` can never be claimed by a shorter
  // route that happens to prefix it.
  final byLength = [...kAppModules]
    ..sort((a, b) => b.route.length.compareTo(a.route.length));
  for (final m in byLength) {
    if (route == m.route || route.startsWith('${m.route}/')) return m.name;
  }
  return null;
}

/// Whether the signed-in user may open [route].
///
/// Gating by route rather than by the nav item's label on purpose: the web
/// sidebar calls the settings entry "Settings" and the mobile drawer calls
/// the same route "Profile", so a label-based check would have hidden the
/// drawer's own profile link from every employee.
///
/// An ungated route (no module owns it) is allowed — the login page, the
/// splash and the add/edit sub-routes are reached only from a screen the
/// user already passed this check for.
bool canOpenRoute(String route) {
  final module = moduleForRoute(route);
  if (module == null) return true;
  if (kAlwaysAllowedModules.contains(module)) return true;
  final session = _session;
  if (session == null) return true;
  final path = route.split('?').first;
  if (kWriteOnlyRoutes.contains(path)) return session.canWrite(module);
  // The Insights dashboard is nothing but business figures.
  if (path == AppRoutes.reportsInsights) return session.canSummary(module);
  return session.canRead(module);
}

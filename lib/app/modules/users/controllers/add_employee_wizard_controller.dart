import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/users/models/user_model.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'users_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Static data types shared with the wizard view
// ─────────────────────────────────────────────────────────────────────────────
class RoleOpt {
  final String id, name, desc;
  final IconData icon;
  const RoleOpt(this.id, this.name, this.desc, this.icon);
}

const kRoles = <RoleOpt>[
  RoleOpt(
    'super_admin',
    'Super Admin',
    'Full access to all modules and settings',
    Icons.stars_rounded,
  ),
  RoleOpt(
    'admin',
    'Admin',
    'Manage most modules and system settings',
    Icons.admin_panel_settings_outlined,
  ),
  RoleOpt(
    'manager',
    'Manager',
    'Manage stock, purchases, sales and reports',
    Icons.manage_accounts_outlined,
  ),
  RoleOpt(
    'sales',
    'Sales',
    'Access to sales, customers and invoices',
    Icons.point_of_sale_outlined,
  ),
  RoleOpt(
    'store_staff',
    'Store Staff',
    'Access to stock and warehouse operations',
    Icons.warehouse_outlined,
  ),
  RoleOpt(
    'custom',
    'Custom Role',
    'Custom role with specific permissions',
    Icons.tune_rounded,
  ),
];

/// Maps a wizard role-option id to the backend's [UserRole] enum — the same
/// mapping [AddEmployeeWizardController.submit] uses when saving.
UserRole userRoleForOptId(String id) {
  switch (id) {
    case 'super_admin':
    case 'admin':
      return UserRole.admin;
    case 'manager':
    case 'custom':
      return UserRole.manager;
    case 'sales':
      return UserRole.salesman;
    case 'store_staff':
      return UserRole.stockManager;
    default:
      return UserRole.salesman;
  }
}

/// Live "N users with this role" count, from the real `/api/users` role
/// breakdown — not a hardcoded number. Two wizard options can share one
/// [UserRole] bucket (e.g. Super Admin & Admin both map to `UserRole.admin`)
/// since the backend doesn't track "custom" as its own role.
int roleOptUserCount(String id) {
  if (!Get.isRegistered<UsersController>()) return 0;
  return Get.find<UsersController>().roleBreakdown[userRoleForOptId(id)] ?? 0;
}

class WizMod {
  final String name;
  final IconData icon;
  const WizMod(this.name, this.icon);
}

const kMods = <WizMod>[
  WizMod('Dashboard', Icons.dashboard_rounded),
  WizMod('Categories', Icons.category_outlined),
  WizMod('Products', Icons.inventory_2_outlined),
  WizMod('Inventory', Icons.warehouse_outlined),
  WizMod('Purchase', Icons.shopping_bag_outlined),
  WizMod('Sale', Icons.point_of_sale_outlined),
  WizMod('Clients', Icons.people_outline_rounded),
  WizMod('Transactions', Icons.swap_horiz_rounded),
  WizMod('Reports', Icons.bar_chart_rounded),
  WizMod('Settings', Icons.settings_outlined),
];

const kDepts = <String>[
  'Sales',
  'Marketing',
  'IT',
  'Finance',
  'Operations',
  'HR',
  'Warehouse',
];

const kEmploymentTypes = <String>[
  'Full-time',
  'Part-time',
  'Contract',
  'Intern',
];

class WizPerm {
  final String module;
  final IconData icon;
  bool read;
  bool write;
  WizPerm({
    required this.module,
    required this.icon,
    this.read = true,
    this.write = true,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Controller — all wizard state, no setState in the view.
// ─────────────────────────────────────────────────────────────────────────────
class AddEmployeeWizardController extends GetxController {
  final step = 0.obs;

  // ── Step 1 ────────────────────────────────────────────────────────────
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final altPhoneCtrl = TextEditingController();
  final designationCtrl = TextEditingController();
  final reportingManagerCtrl = TextEditingController();
  final employeeCodeCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confCtrl = TextEditingController();
  final dept = ''.obs;
  final employmentType = 'Full-time'.obs;
  final status = 'Active'.obs;
  final welcome = true.obs;
  final showPass = false.obs;
  final showConf = false.obs;
  final doj = Rx<DateTime?>(null);
  final dob = Rx<DateTime?>(null);
  final eName = RxnString();
  final eEmail = RxnString();
  final eUser = RxnString();
  final ePass = RxnString();
  final eConf = RxnString();

  // ── Step 2 ────────────────────────────────────────────────────────────
  final roleId = RxnString();
  final customTab = false.obs;
  final roleErr = false.obs;
  final roleSearchCtrl = TextEditingController();
  final roleSearchQuery = ''.obs;

  // ── Step 3 ────────────────────────────────────────────────────────────
  late final RxList<WizPerm> perms;

  @override
  void onInit() {
    super.onInit();
    perms = kMods
        .map(
          (m) =>
              WizPerm(module: m.name, icon: m.icon, read: true, write: false),
        )
        .toList()
        .obs;
    roleSearchCtrl.addListener(
      () => roleSearchQuery.value = roleSearchCtrl.text,
    );
  }

  @override
  void onClose() {
    for (final c in [
      nameCtrl,
      emailCtrl,
      phoneCtrl,
      altPhoneCtrl,
      designationCtrl,
      reportingManagerCtrl,
      employeeCodeCtrl,
      userCtrl,
      passCtrl,
      confCtrl,
      roleSearchCtrl,
    ]) {
      c.dispose();
    }
    super.onClose();
  }

  // ── Computed ─────────────────────────────────────────────────────────
  int get readCnt => perms.where((p) => p.read).length;
  int get writeCnt => perms.where((p) => p.write).length;
  int get noCnt => perms.where((p) => !p.read && !p.write).length;

  RoleOpt? get selRole => roleId.value == null
      ? null
      : kRoles.where((r) => r.id == roleId.value).firstOrNull;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _fmtDate(DateTime? d) =>
      d == null ? '-' : '${d.day} ${_months[d.month - 1]} ${d.year}';

  String get fmtDOJ => _fmtDate(doj.value);
  String get fmtDOB => _fmtDate(dob.value);

  // ── Validation ───────────────────────────────────────────────────────
  bool v1() {
    eName.value = nameCtrl.text.trim().isEmpty ? 'Full name is required' : null;
    eEmail.value = emailCtrl.text.trim().isEmpty
        ? 'Email is required'
        : !RegExp(
            r'^[\w\-.]+@[\w\-]+\.[\w\-.]+$',
          ).hasMatch(emailCtrl.text.trim())
        ? 'Enter a valid email'
        : null;
    eUser.value = userCtrl.text.trim().isEmpty ? 'Username is required' : null;
    ePass.value = passCtrl.text.isEmpty
        ? 'Password is required'
        : passCtrl.text.length < 6
        ? 'Minimum 6 characters'
        : null;
    eConf.value = confCtrl.text.isEmpty
        ? 'Confirm your password'
        : confCtrl.text != passCtrl.text
        ? 'Passwords do not match'
        : null;
    return ![
      eName.value,
      eEmail.value,
      eUser.value,
      ePass.value,
      eConf.value,
    ].any((e) => e != null);
  }

  bool v2() {
    if (customTab.value) return true;
    roleErr.value = roleId.value == null;
    return roleId.value != null;
  }

  /// Async so the wizard's finish button can stay busy until the create call
  /// answers — the earlier steps return immediately.
  Future<void> next() async {
    if (step.value == 0 && !v1()) return;
    if (step.value == 1 && !v2()) return;
    if (step.value < 3) {
      step.value++;
    } else {
      await submit();
    }
  }

  void back() {
    if (step.value > 0) {
      step.value--;
    } else {
      Get.back();
    }
  }

  /// True while the create call is in flight — the wizard's finish button
  /// reads this to avoid double submits.
  final isSaving = false.obs;

  Future<void> submit() async {
    final c = Get.find<UsersController>();
    final ur = userRoleForOptId(roleId.value ?? 'sales');

    isSaving.value = true;
    // The backend assigns the USR-#### code, hashes a starter password and
    // returns the saved row — no locally invented ids or codes.
    final created = await c.addUser({
      'name': nameCtrl.text.trim(),
      'email': emailCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
      'role': ur.label,
      'department': dept.value.isEmpty ? 'General' : dept.value,
      'isActive': status.value == 'Active',
    });
    isSaving.value = false;

    // addUser() already surfaced the API error — keep the wizard open so the
    // entered details aren't lost.
    if (created == null) return;

    Get.offNamed(AppRoutes.users);
    showAppToast(
      'Employee Created',
      '${created.name} (${created.code}) has been added successfully.',
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
      icon: Icons.check_circle_outline,
    );
  }
}

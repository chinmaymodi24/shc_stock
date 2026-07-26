import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../../../routes/app_routes.dart';
import 'users_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Static data types shared with the wizard view
// ─────────────────────────────────────────────────────────────────────────────
class RoleOpt {
  final String id, name, desc;
  final IconData icon;
  final int count;
  const RoleOpt(this.id, this.name, this.desc, this.icon, this.count);
}

const kRoles = <RoleOpt>[
  RoleOpt(
    'super_admin',
    'Super Admin',
    'Full access to all modules and settings',
    Icons.stars_rounded,
    1,
  ),
  RoleOpt(
    'admin',
    'Admin',
    'Manage most modules and system settings',
    Icons.admin_panel_settings_outlined,
    3,
  ),
  RoleOpt(
    'manager',
    'Manager',
    'Manage stock, purchases, sales and reports',
    Icons.manage_accounts_outlined,
    5,
  ),
  RoleOpt(
    'sales',
    'Sales',
    'Access to sales, customers and invoices',
    Icons.point_of_sale_outlined,
    8,
  ),
  RoleOpt(
    'store_staff',
    'Store Staff',
    'Access to stock and warehouse operations',
    Icons.warehouse_outlined,
    7,
  ),
  RoleOpt(
    'custom',
    'Custom Role',
    'Custom role with specific permissions',
    Icons.tune_rounded,
    2,
  ),
];

class WizMod {
  final String name;
  final IconData icon;
  const WizMod(this.name, this.icon);
}

const kMods = <WizMod>[
  WizMod('Dashboard', Icons.dashboard_rounded),
  WizMod('Products', Icons.inventory_2_outlined),
  WizMod('Stock', Icons.warehouse_outlined),
  WizMod('Purchase', Icons.shopping_bag_outlined),
  WizMod('Sales', Icons.point_of_sale_outlined),
  WizMod('Clients', Icons.people_outline_rounded),
  WizMod('Reports', Icons.bar_chart_rounded),
  WizMod('Users', Icons.manage_accounts_outlined),
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
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confCtrl = TextEditingController();
  final dept = ''.obs;
  final status = 'Active'.obs;
  final welcome = true.obs;
  final showPass = false.obs;
  final showConf = false.obs;
  final doj = Rx<DateTime?>(null);
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
          (m) => WizPerm(
            module: m.name,
            icon: m.icon,
            read: true,
            write: m.name != 'Reports' && m.name != 'Users',
          ),
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

  String get fmtDOJ {
    final d = doj.value;
    if (d == null) return '-';
    const months = [
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

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

  void next() {
    if (step.value == 0 && !v1()) return;
    if (step.value == 1 && !v2()) return;
    if (step.value < 3) {
      step.value++;
    } else {
      submit();
    }
  }

  void back() {
    if (step.value > 0) {
      step.value--;
    } else {
      Get.back();
    }
  }

  void submit() {
    final c = Get.find<UsersController>();
    final nm = nameCtrl.text.trim();
    final pts = nm.split(' ');
    final ini = pts.length >= 2
        ? '${pts.first[0]}${pts.last[0]}'.toUpperCase()
        : nm.substring(0, nm.length >= 2 ? 2 : 1).toUpperCase();

    UserRole ur = UserRole.salesman;
    switch (roleId.value) {
      case 'super_admin':
      case 'admin':
        ur = UserRole.admin;
        break;
      case 'manager':
        ur = UserRole.manager;
        break;
      case 'sales':
        ur = UserRole.salesman;
        break;
      case 'store_staff':
        ur = UserRole.stockManager;
        break;
      case 'custom':
        ur = UserRole.manager;
        break;
    }

    c.users.add(
      UserModel(
        id: '${c.users.length + 1}',
        code: 'EMP-${(c.users.length + 1).toString().padLeft(4, '0')}',
        name: nm,
        initials: ini,
        badgeColor: ur.color,
        email: emailCtrl.text.trim(),
        phone: phoneCtrl.text.trim().isEmpty ? '-' : phoneCtrl.text.trim(),
        role: ur,
        isActive: status.value == 'Active',
        lastLogin: 'Never',
        createdAt: fmtDOJ == '-'
            ? '${DateTime.now().day} Jul ${DateTime.now().year}'
            : fmtDOJ,
        department: dept.value.isEmpty ? 'General' : dept.value,
      ),
    );

    Get.offNamed(AppRoutes.users);
    Get.snackbar(
      'Employee Created',
      '$nm has been added successfully.',
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    );
  }
}

import 'package:shc_stock/app/core/utils/dispose_later.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/utils/app_date.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/utils/phone_input.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/modules/users/models/permission_editor.dart';
import 'package:shc_stock/app/modules/users/models/role_model.dart';
import 'package:shc_stock/app/modules/users/models/user_model.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'users_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Static data types shared with the wizard view
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps an employee routed into the wizard so it updates that record in
/// place. A bare [UserModel] argument means Duplicate — pre-fill, save as new.
class EditEmployee {
  final UserModel user;
  const EditEmployee(this.user);
}

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
  final passCtrl = TextEditingController();
  final confCtrl = TextEditingController();
  final dept = ''.obs;
  final employmentType = 'Full-time'.obs;
  final status = 'Active'.obs;
  final showPass = false.obs;
  final showConf = false.obs;
  // Review step's own eye toggle — separate from Step 1's so the summary
  // always opens masked, even if the password was left visible while typing.
  final showReviewPass = false.obs;
  final doj = Rx<DateTime?>(null);
  final dob = Rx<DateTime?>(null);
  final eName = RxnString();
  final eEmail = RxnString();
  final ePhone = RxnString();
  final eAltPhone = RxnString();
  final ePass = RxnString();
  final eConf = RxnString();

  // ── Step 2 ────────────────────────────────────────────────────────────
  /// Id of the chosen role (from GET /api/roles).
  final roleId = RxnInt();
  final customTab = false.obs;
  final roleErr = false.obs;
  final roleSearchCtrl = TextEditingController();
  final roleSearchQuery = ''.obs;

  // ── Step 3 ────────────────────────────────────────────────────────────
  /// The Permissions table — rows, counts and toggle rules.
  final editor = PermissionEditor();
  RxList<WizPerm> get perms => editor.perms;

  @override
  void onInit() {
    super.onInit();
    roleSearchCtrl.addListener(
      () => roleSearchQuery.value = roleSearchCtrl.text,
    );

    final arg = Get.arguments;
    if (arg is EditEmployee) {
      editingId.value = arg.user.id;
      loadFrom(arg.user);
    } else if (arg is UserModel) {
      loadFrom(arg);
      // A duplicate needs its own login — the email is the unique key.
      emailCtrl.clear();
    }
  }

  /// Id of the employee being edited, or null for a new/duplicated one.
  /// Drives whether [submit] POSTs or PUTs.
  final editingId = RxnString();
  bool get isEdit => editingId.value != null;

  /// Fills the form from an existing employee — the Edit and Duplicate
  /// entry points, and the one place a stored phone reaches the box.
  void loadFrom(UserModel u) {
    nameCtrl.text = u.name;
    emailCtrl.text = u.email;
    // Normalised on the way in, not just on the way out: a stored value the
    // formatter would rewrite (an old row, an import) makes Ctrl+Z inside the
    // box trip a framework assertion — undo restores the raw text, the
    // formatter cleans it, and Flutter finds the field is not holding what it
    // just put back. Feeding the box clean text keeps that out of the
    // undo stack entirely. See lib/app/core/utils/phone_input.dart.
    phoneCtrl.text = normalisePhone(u.phone);
    dept.value = u.department;
    status.value = u.isActive ? 'Active' : 'Inactive';
    roleId.value = u.role.id;
    // Show the access this employee actually has, so saving an edit doesn't
    // quietly hand back the role's defaults instead.
    // A Super Admin holds everything regardless of the stored map.
    editor.load(u.permissions, everything: u.role.isSuperAdmin);
  }

  /// GetX can route a delete through this controller more than once (a forced
  /// delete on top of the route's own disposal). Disposing a
  /// TextEditingController twice throws, so the second pass is a no-op.
  bool _closed = false;

  @override
  void onClose() {
    if (_closed) {
      super.onClose();
      return;
    }
    _closed = true;
    // Disposed once the page has gone, not while it is still on screen
    // for its exit transition — see dispose_later.dart.
    disposeAfterPageExit([
      nameCtrl,
      emailCtrl,
      phoneCtrl,
      altPhoneCtrl,
      designationCtrl,
      reportingManagerCtrl,
      employeeCodeCtrl,
      passCtrl,
      confCtrl,
      roleSearchCtrl,
    ]);
    super.onClose();
  }

  // ── Computed ─────────────────────────────────────────────────────────
  UsersController get _users => Get.find<UsersController>();

  /// Roles this person may hand out. Only a Super Admin can make another.
  List<RoleModel> get assignableRoles {
    final session = Get.find<SessionController>();
    return _users.roles
        .where((r) => !r.isSuperAdmin || session.isSuperAdmin)
        .toList();
  }

  RoleModel? get selRole => roleId.value == null
      ? null
      : _users.roles.firstWhereOrNull((r) => r.id == roleId.value);

  /// Picks [role] and fills the Permissions step with its access, which can
  /// then be fine-tuned for this one employee.
  void selectRole(RoleModel role) {
    roleId.value = role.id;
    roleErr.value = false;
    editor.load(role.permissions, everything: role.isSuperAdmin);
  }

  String _fmtDate(DateTime? d) => fmtDate(d, empty: '-');

  String get fmtDOJ => _fmtDate(doj.value);
  String get fmtDOB => _fmtDate(dob.value);

  // ── Validation ───────────────────────────────────────────────────────

  /// Both phone fields are optional, but anything typed has to be a real
  /// 10-digit Indian number. The fields themselves only accept digits (and
  /// stop at 10), so the only way to land here is a half-typed number.
  String? _phoneError(String raw, String label) {
    final digits = raw.trim();
    if (digits.isEmpty) return null;
    if (digits.length != 10) return '$label must be 10 digits';
    return null;
  }

  bool v1() {
    eName.value = nameCtrl.text.trim().isEmpty ? 'Full name is required' : null;
    eEmail.value = emailCtrl.text.trim().isEmpty
        ? 'Email is required'
        : !RegExp(
            r'^[\w\-.]+@[\w\-]+\.[\w\-.]+$',
          ).hasMatch(emailCtrl.text.trim())
        ? 'Enter a valid email'
        : null;
    ePhone.value = _phoneError(phoneCtrl.text, 'Phone number');
    eAltPhone.value = _phoneError(altPhoneCtrl.text, 'Alternate phone');
    // On a new employee the password is what they will sign in with, so it is
    // required. On an edit, leaving both fields blank means "keep the current
    // password" — only a typed one is validated and sent.
    final passwordOptional = isEdit && passCtrl.text.isEmpty;
    ePass.value = passwordOptional
        ? null
        : passCtrl.text.isEmpty
        ? 'Password is required'
        : passCtrl.text.length < 6
        ? 'Minimum 6 characters'
        : null;
    eConf.value = passwordOptional && confCtrl.text.isEmpty
        ? null
        : confCtrl.text.isEmpty
        ? 'Confirm your password'
        : confCtrl.text != passCtrl.text
        ? 'Passwords do not match'
        : null;
    return ![
      eName.value,
      eEmail.value,
      ePhone.value,
      eAltPhone.value,
      ePass.value,
      eConf.value,
    ].any((e) => e != null);
  }

  /// A role is required — a custom one has to be defined (and so saved)
  /// before moving on.
  bool v2() {
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
    isSaving.value = true;
    final body = {
      'name': nameCtrl.text.trim(),
      'email': emailCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
      'roleId': roleId.value,
      'department': dept.value.isEmpty ? 'General' : dept.value,
      'isActive': status.value == 'Active',
      // What step 3 ticked, in the shape the API stores and the sidebar
      // reads back: {"Products": {"read", "write", "summary"}, …}.
      'permissions': editor.toJson(),
      // The password the admin typed IS the employee's login password. It
      // used to be dropped here, so the backend fell back to a starter
      // password and nobody could sign in with what the form had shown.
      // On an edit a blank field means "leave the password alone".
      if (passCtrl.text.isNotEmpty) 'password': passCtrl.text,
    };
    // The backend assigns the USR-#### code, hashes the password and returns
    // the saved row — no locally invented ids or codes.
    final created = isEdit
        ? await c.updateUser(editingId.value!, body)
        : await c.addUser(body);
    isSaving.value = false;

    // addUser()/updateUser() already surfaced the API error — keep the wizard
    // open so the entered details aren't lost.
    if (created == null) return;

    Get.offNamed(AppRoutes.users);
    showAppToast(
      isEdit ? 'Employee Updated' : 'Employee Created',
      '${created.name} (${created.code}) has been ${isEdit ? 'updated' : 'added'} successfully.',
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      icon: Icons.check_circle_outline,
    );
  }
}

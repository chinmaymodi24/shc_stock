import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_ripple_controller.dart';
import 'package:shc_stock/app/modules/users/controllers/add_employee_wizard_controller.dart';
import 'package:shc_stock/app/modules/users/controllers/users_controller.dart';
import 'package:shc_stock/app/modules/users/models/user_model.dart';
import 'package:shc_stock/app/modules/users/views/add_employee_wizard.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Editing an existing employee ran the whole wizard under "create" wording —
// the last step still said "Review & Create" and the finish button still said
// "Create Employee", which reads like it is about to add a second account.
//
// Pumped at phone width: the mobile layout shares one footer and one step rail
// with the web one, so the labels are checked for both at once.
// ─────────────────────────────────────────────────────────────────────────────

const _existingRow = {
  'id': 7,
  'code': 'USR-0007',
  'name': 'Deepak Shah',
  'email': 'deepak@gmail.com',
  'role': 'Super Admin',
  'phone': '9714888588',
  'department': 'Operations',
  'isActive': true,
  'permissions': <String, dynamic>{},
};

class _OfflineUsers extends UsersController {
  @override
  Future<void> fetchUsers() async {}
  @override
  Future<void> fetchRoles() async {}
  @override
  Future<void> fetchStats() async {}
}

Future<void> _pumpWizard(
  WidgetTester tester, {
  required bool edit,
  Size size = const Size(390, 1400),
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  Get.put(ThemeController(), permanent: true);
  Get.put(ThemeRippleController(), permanent: true);
  Get.put(SessionController(), permanent: true).user.value = const SessionUser(
    id: 1,
    name: 'Admin',
    email: 'admin@admin.com',
    role: 'Super Admin',
    isSuperAdmin: true,
    token: 'test-token',
    permissions: {},
  );
  Get.put<UsersController>(_OfflineUsers(), permanent: true);

  final c = Get.put(AddEmployeeWizardController());
  if (edit) {
    c.editingId.value = '7';
    c.loadFrom(UserModel.fromJson(_existingRow));
  }
  c.step.value = 3;

  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(extensions: [AppThemeColors.light]),
      home: const AddEmployeeWizard(),
    ),
  );
  await tester.pump();
}

void main() {
  tearDown(Get.reset);

  testWidgets('editing says Save, not Create', (tester) async {
    await _pumpWizard(tester, edit: true);

    // The phone footer uses the short verb — the full wording overflows it.
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Create'), findsNothing);
    expect(find.text('Create Employee'), findsNothing);
    expect(find.text('Edit Employee'), findsOneWidget);
  });

  testWidgets('a new employee keeps the create wording', (tester) async {
    await _pumpWizard(tester, edit: false);

    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
    expect(find.text('Create Employee'), findsOneWidget);
  });

  // The step rail only prints its titles from tablet width up.
  testWidgets('the step rail follows the mode on a wide screen', (
    tester,
  ) async {
    await _pumpWizard(tester, edit: true, size: const Size(900, 1600));

    expect(find.text('Review & Save'), findsWidgets);
    expect(find.text('Review & Create'), findsNothing);
    expect(find.text('Save Changes'), findsOneWidget);
  });
}

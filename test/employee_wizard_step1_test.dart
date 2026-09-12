import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/users/controllers/add_employee_wizard_controller.dart';
import 'package:shc_stock/app/modules/users/views/wizard/step1_employee_details.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 of the Add Employee wizard used to be inert: it's a separate widget,
// so the Obx wrapped around it in add_employee_wizard.dart never saw the
// observables its build() reads — a parent Obx only tracks what's read while
// its OWN builder runs. The show/hide password eyes flipped `showPass` and
// nothing repainted, and every validation message stayed invisible, which made
// a blocked "Continue" look like a dead button.
//
// These tests pin the three things that were wrong: the eyes actually toggle,
// the phone fields refuse anything that isn't up to 10 digits, and a page that
// doesn't validate never advances the step.
// ─────────────────────────────────────────────────────────────────────────────

Widget _host() => GetMaterialApp(
  theme: ThemeData(extensions: [AppThemeColors.light]),
  home: const Scaffold(
    body: SingleChildScrollView(
      child: EmployeeDetailsStep(wide: true, tablet: true),
    ),
  ),
);

/// The obscureText of the field sitting under a given label. wizPwdField
/// builds `Column[ Row[Text(label)], gap, TextField ]`, so the closest Column
/// ancestor of the label owns exactly that one field.
bool _isObscured(WidgetTester tester, String label) {
  final labelColumn = find
      .ancestor(of: find.text(label), matching: find.byType(Column))
      .first;
  final field = tester.widget<TextField>(
    find.descendant(of: labelColumn, matching: find.byType(TextField)),
  );
  return field.obscureText;
}

void main() {
  late AddEmployeeWizardController c;

  setUp(() {
    c = Get.put(AddEmployeeWizardController());
  });
  tearDown(Get.reset);

  group('password visibility toggles', () {
    testWidgets('the Password eye actually flips obscureText', (tester) async {
      tester.view.physicalSize = const Size(1600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host());

      expect(_isObscured(tester, 'Password'), isTrue);

      c.showPass.value = true;
      await tester.pump();

      expect(
        _isObscured(tester, 'Password'),
        isFalse,
        reason: 'flipping showPass must repaint the field — this is the bug',
      );
    });

    testWidgets('Confirm Password has its own independent eye', (tester) async {
      tester.view.physicalSize = const Size(1600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host());

      c.showConf.value = true;
      await tester.pump();

      expect(_isObscured(tester, 'Confirm Password'), isFalse);
      // Toggling one must not reveal the other.
      expect(_isObscured(tester, 'Password'), isTrue);
    });
  });

  group('phone fields', () {
    testWidgets('letters are rejected and input stops at 10 digits', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host());

      await tester.enterText(
        find.widgetWithText(TextField, 'Enter 10-digit phone number').first,
        'asdf98765432109999',
      );
      await tester.pump();

      expect(c.phoneCtrl.text, '9876543210');
      expect(c.phoneCtrl.text.length, 10);
    });
  });

  group('validation gates the step', () {
    test('a half-typed phone number blocks step 1', () async {
      c.nameCtrl.text = 'Deepak';
      c.emailCtrl.text = 'deeps@g.co';
      c.userCtrl.text = 'deepak';
      c.passCtrl.text = 'secret123';
      c.confCtrl.text = 'secret123';
      c.phoneCtrl.text = '98765'; // 5 digits — incomplete

      await c.next();

      expect(c.step.value, 0, reason: 'must not advance while invalid');
      expect(c.ePhone.value, 'Phone number must be 10 digits');
    });

    test('an alternate phone is optional but validated when filled', () async {
      c.nameCtrl.text = 'Deepak';
      c.emailCtrl.text = 'deeps@g.co';
      c.userCtrl.text = 'deepak';
      c.passCtrl.text = 'secret123';
      c.confCtrl.text = 'secret123';

      // Left blank — fine.
      expect(c.v1(), isTrue);
      expect(c.eAltPhone.value, isNull);

      c.altPhoneCtrl.text = '12345';
      expect(c.v1(), isFalse);
      expect(c.eAltPhone.value, 'Alternate phone must be 10 digits');

      c.altPhoneCtrl.text = '9998887776';
      expect(c.v1(), isTrue);
    });

    test('a fully valid step 1 advances to step 2', () async {
      c.nameCtrl.text = 'Deepak';
      c.emailCtrl.text = 'deeps@g.co';
      c.userCtrl.text = 'deepak';
      c.passCtrl.text = 'secret123';
      c.confCtrl.text = 'secret123';
      c.phoneCtrl.text = '9876543210';

      await c.next();

      expect(c.step.value, 1);
    });
  });
}

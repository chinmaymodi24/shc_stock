import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/utils/phone_input.dart';
import 'package:shc_stock/app/modules/users/controllers/add_employee_wizard_controller.dart';
import 'package:shc_stock/app/modules/users/models/role_model.dart';
import 'package:shc_stock/app/modules/users/models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Ctrl+Z inside a phone box.
//
// Flutter's UndoHistory restores a value and then asserts the field is holding
// exactly it — but undo runs the input formatters again on the way back, so a
// value the formatter would rewrite fails that assertion:
//
//   undo_history.dart:178  'widget.value.value == nextValue': is not true
//
// A stored "+91 90000 00001" loaded straight into the box is exactly such a
// value. (The plain digitsOnly + maxLength pair this replaced failed the same
// way, and worse: it undid to 9190000000, a different number.)
//
// The fix is not to catch the assertion but to keep dirty text out of the box:
// every form normalises a phone on the way IN, so nothing the formatter would
// rewrite ever reaches the undo stack.
// ─────────────────────────────────────────────────────────────────────────────

/// Types into a pre-filled box, then presses Ctrl+Z. Returns what the field
/// held afterwards and whatever the framework threw, if anything.
Future<({String text, Object? error})> _typeThenUndo(
  WidgetTester tester,
  String prefill,
) async {
  final ctrl = TextEditingController(text: prefill);
  addTearDown(ctrl.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TextField(
          controller: ctrl,
          inputFormatters: kPhoneInputFormatters,
        ),
      ),
    ),
  );
  await tester.tap(find.byType(TextField));
  await tester.pump(const Duration(milliseconds: 600));

  tester.testTextInput.updateEditingValue(
    const TextEditingValue(
      text: '5',
      selection: TextSelection.collapsed(offset: 1),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));

  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();

  return (text: ctrl.text, error: tester.takeException());
}

UserModel _employee(String phone) => UserModel(
  id: '7',
  code: 'USR-0007',
  name: 'Deepak Shah',
  initials: 'DS',
  badgeColor: Colors.orange,
  email: 'deepak@gmail.com',
  phone: phone,
  role: const RoleBadge(id: 1, label: 'Super Admin', isSuperAdmin: true),
  isActive: true,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  testWidgets('undo on a clean number is quiet', (tester) async {
    final r = await _typeThenUndo(tester, '9000000001');
    expect(r.error, isNull);
    expect(r.text, '9000000001');
  });

  testWidgets('undo on a value the formatter would rewrite throws', (
    tester,
  ) async {
    // Pins the mechanism, so the guard below is protecting against something
    // real rather than a fix nobody can explain later.
    final r = await _typeThenUndo(tester, '+91 90000 00001');
    expect(r.error, isA<AssertionError>());
    expect(r.error.toString(), contains('undo_history.dart'));
  });

  test('the edit form never puts such a value in the box', () {
    final c = Get.put(AddEmployeeWizardController(), tag: 'phone-undo');
    // What an older row, a backup or an import can still hand back.
    c.loadFrom(_employee('+91 90000 00001'));

    expect(c.phoneCtrl.text, '9000000001');
    expect(
      normalisePhone(c.phoneCtrl.text),
      c.phoneCtrl.text,
      reason: 'already clean, so undo re-running the formatter is a no-op',
    );
  });
}

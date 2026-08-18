import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';
import 'package:shc_stock/app/shared/widgets/status_update_dialog_shell.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The app's two shared dialogs, in their in-flight state. This is where the
// stretched spinner lived: a fixed-size box handed straight to a full-width
// Container gets tight constraints and paints as an ellipse.
//
// The page-level equivalent of this check runs for every page inside
// late_data_render_test.dart.
// ─────────────────────────────────────────────────────────────────────────────

void _expectSquareSpinner(WidgetTester tester) {
  final spinners = find.byType(CircularProgressIndicator);
  expect(spinners, findsOneWidget, reason: 'the button should be spinning');
  final size = tester.getSize(spinners);
  expect(
    size.width,
    closeTo(size.height, 0.5),
    reason: 'spinner rendered ${size.width}x${size.height}',
  );
  expect(size.width, lessThan(40), reason: 'must not span the whole button');
}

Future<void> _pumpDialog(WidgetTester tester, Widget dialog) async {
  tester.view.physicalSize = const Size(900, 700);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(extensions: const [AppThemeColors.light]),
      home: Scaffold(body: Builder(builder: (context) => dialog)),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  testWidgets('the status dialog spins on Update without distorting', (
    tester,
  ) async {
    final gate = Completer<void>();
    await _pumpDialog(
      tester,
      StatusUpdateDialogShell(
        title: 'Update Status',
        subtitle: 'PO-2024-10001',
        body: const Text('Received'),
        onSave: () => gate.future,
      ),
    );

    await tester.tap(find.text('Update'));
    await tester.pump();
    _expectSquareSpinner(tester);

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('the delete dialog waits for the API before closing', (
    tester,
  ) async {
    final gate = Completer<void>();
    var deleted = false;
    await _pumpDialog(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => confirmDelete(
            context,
            itemName: 'PO-2024-10001',
            itemLabel: 'Purchase Order',
            onConfirm: () async {
              deleted = true;
              await gate.future;
            },
          ),
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Yes, Delete'), findsOneWidget);

    await tester.tap(find.text('Yes, Delete'));
    await tester.pump();

    expect(deleted, isTrue);
    _expectSquareSpinner(tester);
    // Still open — it used to close first and fire the call into the void.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
  });
}

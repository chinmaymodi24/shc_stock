import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';

// A delete the server refuses (a product with history, a category that still
// has products) shows its reason in a toast. The dialog used to call
// Get.back() afterwards, which closed that toast instead of the dialog: the
// dialog stayed open and the reason was gone before anyone could read it.

Future<void> _pump(WidgetTester tester, Future<void> Function() onConfirm) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(extensions: [AppThemeColors.light]),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => confirmDelete(
                context,
                itemName: 'Brick',
                itemLabel: 'Product',
                onConfirm: onConfirm,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(Get.reset);

  testWidgets('a refused delete closes the dialog and the reason stays readable', (tester) async {
    await _pump(tester, () async {
      showAppToast(
        'Error',
        'This product has history, so it cannot be deleted.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    });
    expect(find.text('Delete Product?'), findsOneWidget);

    await tester.tap(find.text('Yes, Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Delete Product?'), findsNothing, reason: 'the dialog must close');
    expect(
      find.textContaining('has history, so it cannot be deleted'),
      findsOneWidget,
      reason: 'and the toast must not be closed along with it',
    );
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 4));
    }
    await tester.pumpAndSettle();
  });

  testWidgets('a delete that goes through just closes the dialog', (tester) async {
    var deleted = false;
    await _pump(tester, () async => deleted = true);
    await tester.tap(find.text('Yes, Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
    expect(find.text('Delete Product?'), findsNothing);
  });

  testWidgets('Cancel closes without deleting', (tester) async {
    var deleted = false;
    await _pump(tester, () async => deleted = true);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(deleted, isFalse);
    expect(find.text('Delete Product?'), findsNothing);
  });
}

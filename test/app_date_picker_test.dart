import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/shared/widgets/app_date_range_dialog.dart';
import 'package:shc_stock/app/shared/widgets/app_date_picker.dart';

// Flutter's calendar dialog ignores Enter, so a picked day could only be saved
// by clicking OK. showAppDatePicker makes Enter do what OK does.
void main() {
  Future<DateTime?> open(
    WidgetTester tester,
    void Function(DateTime?) done,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => done(
              await showAppDatePicker(
                context: context,
                initialDate: DateTime(2026, 10, 5),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return null;
  }

  testWidgets('Enter saves the highlighted date', (tester) async {
    DateTime? result;
    var closed = false;
    await open(tester, (d) {
      result = d;
      closed = true;
    });
    expect(find.text('OK'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result, DateTime(2026, 10, 5));
    expect(find.text('OK'), findsNothing);
  });

  testWidgets('Enter after tapping another day saves that day', (tester) async {
    DateTime? result;
    await open(tester, (d) => result = d);

    await tester.tap(find.text('12'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(result, DateTime(2026, 10, 12));
  });

  testWidgets('Cancel still returns nothing', (tester) async {
    DateTime? result = DateTime(2000);
    var closed = false;
    await open(tester, (d) {
      result = d;
      closed = true;
    });
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, isNull);
  });

  testWidgets('Esc cancels the single-date picker', (tester) async {
    DateTime? result = DateTime(2000);
    var closed = false;
    await open(tester, (d) {
      result = d;
      closed = true;
    });
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, isNull);
  });

  group('range picker keys', () {
    Future<void> openRange(
      WidgetTester tester,
      void Function(DateTimeRange?) done,
    ) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      addTearDown(Get.reset);
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData(extensions: [AppThemeColors.light]),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => done(
                await showAppDateRangePicker(
                  context,
                  initialRange: DateTimeRange(
                    start: DateTime(2026, 10, 3),
                    end: DateTime(2026, 10, 9),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('Enter applies the range', (tester) async {
      DateTimeRange? result;
      var closed = false;
      await openRange(tester, (r) {
        result = r;
        closed = true;
      });
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(closed, isTrue);
      expect(result?.start, DateTime(2026, 10, 3));
      expect(result?.end, DateTime(2026, 10, 9));
    });

    testWidgets('Esc cancels the range picker', (tester) async {
      DateTimeRange? result = DateTimeRange(
        start: DateTime(2000),
        end: DateTime(2001),
      );
      var closed = false;
      await openRange(tester, (r) {
        result = r;
        closed = true;
      });
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(closed, isTrue);
      expect(result, isNull);
    });
  });
}

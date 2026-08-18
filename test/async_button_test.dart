import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/shared/widgets/async_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Every button that hits the API is an AppAsyncButton, so this is the one
// place the "show a spinner while the call is in flight" behaviour is pinned:
// it must spin, refuse a second tap, and come back.
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _pump(WidgetTester tester, Widget button) => tester.pumpWidget(
  MaterialApp(
    theme: ThemeData(extensions: const [AppThemeColors.light]),
    home: Scaffold(body: Center(child: button)),
  ),
);

void main() {
  testWidgets('spins while the call is running, then shows its label again', (
    tester,
  ) async {
    final gate = Completer<void>();
    await _pump(
      tester,
      AppAsyncButton(label: 'Save Purchase', onPressed: () => gate.future),
    );

    expect(find.text('Save Purchase'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byType(AppAsyncButton));
    await tester.pump();

    // In flight: spinner instead of the label.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Save Purchase'), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Save Purchase'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a second tap while busy cannot fire the call twice', (
    tester,
  ) async {
    final gate = Completer<void>();
    var calls = 0;
    await _pump(
      tester,
      AppAsyncButton(
        label: 'Yes, Delete',
        onPressed: () {
          calls++;
          return gate.future;
        },
      ),
    );

    await tester.tap(find.byType(AppAsyncButton));
    await tester.pump();
    await tester.tap(find.byType(AppAsyncButton), warnIfMissed: false);
    await tester.pump();

    expect(calls, 1, reason: 'double-tapping must not post the record twice');

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('a failed call still returns the button to normal', (
    tester,
  ) async {
    await _pump(
      tester,
      AppAsyncButton(
        label: 'Save',
        onPressed: () async => throw Exception('network down'),
      ),
    );

    await tester.tap(find.byType(AppAsyncButton));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isA<Exception>());

    // Not stuck spinning — the user can correct and retry.
    expect(find.text('Save'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('the spinner stays square in a full-width button', (
    tester,
  ) async {
    // Regression: a fixed-size SizedBox placed straight inside a full-width
    // Container inherits tight constraints and the spinner paints as a wide
    // ellipse across the whole button.
    final gate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppThemeColors.light]),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: AppAsyncButton(
                label: 'Update',
                onPressed: () => gate.future,
                expand: true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AppAsyncButton));
    await tester.pump();

    final spinner = tester.getSize(find.byType(CircularProgressIndicator));
    expect(spinner.width, spinner.height);
    expect(spinner.width, lessThan(40), reason: 'must not span the button');

    gate.complete();
    await tester.pumpAndSettle();
  });
}

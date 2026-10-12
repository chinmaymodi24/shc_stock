import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shc_stock/app/core/utils/dispose_later.dart';

// After Save the form's page is replaced, but it stays on screen for its exit
// transition. Its text controllers must outlive that, or the focused field
// rebuilds with a disposed controller (the red screen seen on the phone).

void main() {
  testWidgets('a page controller outlives the exit transition', (tester) async {
    final ctrl = TextEditingController(text: '88');
    final focus = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(controller: ctrl, focusNode: focus),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    expect(focus.hasFocus, isTrue);

    disposeAfterPageExit([ctrl]);

    // Focus is dropped at once…
    await tester.pump();
    expect(focus.hasFocus, isFalse);
    // …and mid-transition the field can still rebuild and use it.
    await tester.pump(const Duration(milliseconds: 300));
    ctrl.addListener(() {});
    expect(ctrl.text, '88');

    // Once the grace has passed it is disposed.
    await tester.pump(kPageExitGrace);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pumpWidget(const SizedBox());
    expect(() => ctrl.addListener(() {}), throwsFlutterError);
    focus.dispose();
  });
}

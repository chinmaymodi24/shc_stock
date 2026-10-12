import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shc_stock/app/modules/sales/controllers/add_sale_controller.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/shared/widgets/section_card.dart';
import 'package:shc_stock/main.dart' as app;

// ─────────────────────────────────────────────────────────────────────────────
// The whole app, for real: sign in -> add a sale -> see it listed -> open the
// bill. It drives the shipped UI against a running backend, so it catches what
// unit and widget tests cannot — a route that no longer opens, a form that no
// longer saves, a screen that crashes on the data the server really returns.
//
// Run (backend on :4000; the emulator reaches it through `adb reverse`):
//
//   node backend/scripts/e2eFixture.js setup
//   flutter test integration_test/app_flow_test.dart -d emulator-5554
//   node backend/scripts/e2eFixture.js teardown
//
// On the web, the same file runs with `flutter drive` (see integration_test/
// README.md). The layout under test follows the window size: a phone-sized
// device exercises the mobile forms, a desktop browser the web ones.
// ─────────────────────────────────────────────────────────────────────────────

const _email = String.fromEnvironment(
  'E2E_EMAIL',
  defaultValue: 'zz-e2e@example.com',
);
const _password = String.fromEnvironment(
  'E2E_PASSWORD',
  defaultValue: 'E2eTest#1',
);

/// Pumps frames until [finder] matches. `pumpAndSettle` is no use here: the
/// splash screen animates forever and every list shows a loading shimmer.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
  String? reason,
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure(
    'Timed out waiting for ${reason ?? finder.describeMatch(Plurality.one)}',
  );
}

Future<void> settleBriefly(WidgetTester tester, [int ms = 600]) async {
  await tester.pump(Duration(milliseconds: ms));
  await tester.pump(const Duration(milliseconds: 100));
}

Finder _fieldWithHint(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && (w.decoration?.hintText ?? '').startsWith(hint),
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sign in, add a sale, find it in the list, open its bill', (
    tester,
  ) async {
    await app.main();

    // ── Sign in ───────────────────────────────────────────────────────────
    await pumpUntil(tester, find.text('Sign in'), reason: 'the login screen');
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), _email);
    await tester.enterText(fields.at(1), _password);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settleBriefly(tester);
    if (find.text('Sign in').evaluate().isNotEmpty) {
      await tester.tap(find.text('Sign in').last);
    }
    await pumpUntil(
      tester,
      find.textContaining(RegExp(r'Good (morning|afternoon|evening)')),
      reason: 'the dashboard after signing in',
    );

    // ── Add a sale ────────────────────────────────────────────────────────
    Get.toNamed(AppRoutes.addSale);
    await pumpUntil(
      tester,
      find.text('Save Sale'),
      reason: 'the Add Sale form',
    );

    // The server numbers the order: the Invoice No. box is prefilled.
    final numbered = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          RegExp(r'^SO/\d{4}/\d{2}-\d{2}$').hasMatch(w.controller?.text ?? ''),
    );
    await pumpUntil(
      tester,
      numbered,
      reason: 'the server-issued invoice number',
    );
    final soNumber = tester.widget<TextField>(numbered.first).controller!.text;

    // Client — type, then pick the suggestion.
    await tester.enterText(
      _fieldWithHint('Type to search client').first,
      'ZZ-E2E',
    );
    await pumpUntil(
      tester,
      find.text('ZZ-E2E Client'),
      reason: 'the client suggestion',
    );
    await tester.tap(find.text('ZZ-E2E Client').last);
    await settleBriefly(tester);

    // Item — type, pick, give it a quantity.
    await tester.ensureVisible(_fieldWithHint('Type e.g.').first);
    await tester.enterText(_fieldWithHint('Type e.g.').first, 'ZZ-E2E');
    await pumpUntil(
      tester,
      find.text('ZZ-E2E Item'),
      reason: 'the item suggestion',
    );
    await tester.tap(find.text('ZZ-E2E Item').last);
    await settleBriefly(tester);

    // The buyer is in the seller's state (or the seller has no state yet): the
    // totals show CGST + SGST, or IGST — never a flat 9% hardcoded pair.
    expect(
      find.textContaining(RegExp(r'(CGST|IGST)')),
      findsWidgets,
      reason: 'the totals block names the tax that applies',
    );

    // Paid in two goes: ₹50 now, the rest by UPI. The first payment row
    // starts at the grand total (₹118: 1 x ₹100 + 18%).
    final amountBoxes = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'e.g. 5000',
    );
    await tester.ensureVisible(amountBoxes.first);
    expect(tester.widget<TextField>(amountBoxes.first).controller!.text, '118');
    await tester.enterText(amountBoxes.first, '50');
    await settleBriefly(tester);
    final addPills = find.byType(AppAddRowPill);
    await tester.ensureVisible(addPills.last);
    await tester.tap(addPills.last);
    await settleBriefly(tester);
    expect(find.text('Payment 2'), findsOneWidget);
    expect(tester.widget<TextField>(amountBoxes.last).controller!.text, '68');
    final form = Get.find<AddSaleController>();
    form.setPaymentMode(form.payments.last, 'UPI');
    await settleBriefly(tester);

    await tester.ensureVisible(find.text('Save Sale'));
    await tester.tap(find.text('Save Sale'));
    await pumpUntil(
      tester,
      find.text('✅ Sale Saved'),
      reason: 'the saved confirmation',
    );

    // ── It is in the list ─────────────────────────────────────────────────
    await pumpUntil(
      tester,
      find.textContaining('ZZ-E2E Item'),
      reason: 'the new sale in the list',
    );
    expect(find.textContaining('ZZ-E2E Client'), findsWidgets);

    // ── Both payments are in Transactions, under the SO number ────────────
    Get.toNamed(AppRoutes.transactions);
    await pumpUntil(
      tester,
      find.text(soNumber),
      reason: 'the payments in Transactions',
    );
    expect(
      find.text(soNumber),
      findsNWidgets(2),
      reason: 'one row per payment',
    );
    expect(find.textContaining('₹50'), findsWidgets);
    expect(find.textContaining('₹68'), findsWidgets);
    expect(find.textContaining('UPI'), findsWidgets);
    // Back to Sales by route — Get.back() would only close the "Saved" toast.
    Get.offNamed(AppRoutes.sales);
    await pumpUntil(
      tester,
      find.byType(PopupMenuButton<VoidCallback>),
      reason: 'the Sales list again',
    );

    // ── Open its bill ─────────────────────────────────────────────────────
    final more = find.byType(PopupMenuButton<VoidCallback>);
    if (more.evaluate().isNotEmpty) {
      await tester.tap(more.first);
      await settleBriefly(tester);
      await tester.tap(find.text('Bill').last);
    } else {
      await tester.tap(find.byTooltip('Bill').first);
    }
    await pumpUntil(
      tester,
      find.textContaining(RegExp(r'Generate Bill|Tax Invoice|Invoice')),
      reason: 'the bill screen',
    );

    // Let the "Saved" toast run out: a toast still animating when the test
    // ends fails the teardown, not the app.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  });
}

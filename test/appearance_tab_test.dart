import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/app_theme.dart';
import 'package:shc_stock/app/core/theme/brand_controller.dart';
import 'package:shc_stock/app/core/theme/brand_theme.dart';
import 'package:shc_stock/app/modules/settings/views/appearance/appearance_tab.dart';
import 'package:shc_stock/app/modules/settings/views/appearance/appearance_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Settings › Appearance, driven the way a buyer drives it.
//
// The screen's contract is narrow but load-bearing: picking a preset must
// change the draft and nothing else, the preview must say whether what you're
// looking at is live yet, and Apply must be the only thing that commits.
// ─────────────────────────────────────────────────────────────────────────────

Future<BrandController> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final bc = Get.put(BrandController(), permanent: true);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: AppTheme.lightTheme,
      home: const Scaffold(body: SingleChildScrollView(child: AppearanceTab())),
    ),
  );
  await tester.pump();
  return bc;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  testWidgets('renders the three editor cards and the preview', (tester) async {
    await _pump(tester);

    expect(find.text('Brand identity'), findsOneWidget);
    expect(find.text('Color palette'), findsOneWidget);
    expect(find.text('Typography & shape'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Apply theme'), findsOneWidget);
    expect(find.text('Discard changes'), findsOneWidget);
    expect(find.text('Restore Secure Heat Care default'), findsOneWidget);
  });

  testWidgets('all eight presets are offered with their industry', (
    tester,
  ) async {
    await _pump(tester);

    for (final preset in kBrandPresets) {
      expect(find.text(preset.name), findsWidgets, reason: preset.name);
    }
    expect(find.text('Steel & metals'), findsOneWidget);
    expect(find.text('Pharma & labs'), findsOneWidget);
  });

  testWidgets('picking a preset changes the draft but not the live app', (
    tester,
  ) async {
    final bc = await _pump(tester);
    expect(bc.isDirty, isFalse);
    expect(find.text('Applied'), findsOneWidget);

    await tester.tap(find.text('Steel Blue'));
    await tester.pump();

    expect(bc.draft.value.primary, const Color(0xFF1F6FEB));
    expect(bc.applied.value.primary, BrandTheme.defaults.primary);
    expect(
      AppColors.primaryOrange,
      BrandTheme.defaults.primary,
      reason: 'the app behind the settings page must not change yet',
    );
    // The preview says so out loud.
    expect(find.text('Not applied yet'), findsOneWidget);
  });

  testWidgets('Apply commits the draft and the preview flips to Applied', (
    tester,
  ) async {
    final bc = await _pump(tester);

    await tester.tap(find.text('Chemical Teal'));
    await tester.pump();
    await tester.tap(find.text('Apply theme'));
    await tester.pump();
    // Ride out the 3s success toast; a snackbar still animating when the tree
    // is torn down leaks its ticker into the next test.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(bc.applied.value.primary, const Color(0xFF0F766E));
    expect(AppColors.primaryOrange, const Color(0xFF0F766E));
    expect(bc.isDirty, isFalse);
    expect(find.text('Applied'), findsOneWidget);
  });

  testWidgets('Discard puts the draft back without touching the app', (
    tester,
  ) async {
    final bc = await _pump(tester);

    await tester.tap(find.text('Power Amber'));
    await tester.pump();
    expect(bc.isDirty, isTrue);

    await tester.tap(find.text('Discard changes'));
    await tester.pump();

    expect(bc.isDirty, isFalse);
    expect(bc.draft.value.primary, BrandTheme.defaults.primary);
  });

  testWidgets('Restore default returns the draft to the shipped brand', (
    tester,
  ) async {
    final bc = await _pump(tester);
    bc.draft.value = bc.draft.value.copyWith(
      companyName: 'Someone Else Ltd',
      radius: 16,
    );
    await tester.pump();

    await tester.tap(find.text('Restore Secure Heat Care default'));
    await tester.pump();

    expect(bc.draft.value.companyName, 'Secure Heat Care');
    expect(bc.draft.value.radius, BrandTheme.defaults.radius);
  });

  testWidgets('the corner-radius cards drive the draft', (tester) async {
    final bc = await _pump(tester);
    expect(bc.draft.value.radius, 10);

    await tester.tap(find.text('Sharp'));
    await tester.pump();
    expect(bc.draft.value.radius, 4);

    await tester.tap(find.text('Soft'));
    await tester.pump();
    expect(bc.draft.value.radius, 16);
  });

  testWidgets('the typography specimen renders in the chosen font', (
    tester,
  ) async {
    final bc = await _pump(tester);
    bc.draft.value = bc.draft.value.copyWith(font: 'IBM Plex Sans');
    await tester.pump();

    final specimen = tester.widget<Text>(find.text('₹1,42,00,000'));
    expect(specimen.style?.fontFamily, 'IBM Plex Sans');
  });

  testWidgets('the preview exercises every status colour', (tester) async {
    await _pump(tester);

    // The mini table's three pills and the two buttons — if a colour has no
    // home in the preview, a buyer can change it and see nothing happen.
    expect(find.text('Received'), findsOneWidget);
    expect(find.text('Partial'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Add Purchase'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
  });

  testWidgets('switching to Custom hex lists the colours with their usage', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Custom hex'));
    await tester.pump();

    expect(find.text('BRAND'), findsOneWidget);
    expect(find.text('STATUS'), findsOneWidget);
    expect(find.text('SURFACES'), findsOneWidget);
    expect(find.text('TEXT'), findsOneWidget);
    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Text tertiary'), findsOneWidget);
    // The usage hint is what tells a buyer what they are about to change.
    expect(find.text('Left navigation panel'), findsOneWidget);
  });

  testWidgets('typing a hex updates that colour and drops the preset', (
    tester,
  ) async {
    final bc = await _pump(tester);
    expect(bc.draft.value.presetName, 'Secure Heat Care');

    await tester.tap(find.text('Custom hex'));
    await tester.pump();

    final primaryHex = find.descendant(
      of: find.byType(HexField).first,
      matching: find.byType(TextField),
    );
    await tester.enterText(primaryHex, '#1F6FEB');
    await tester.pump();

    expect(bc.draft.value.primary, const Color(0xFF1F6FEB));
    expect(
      bc.draft.value.presetName,
      isNull,
      reason: 'a hand-edited palette is no longer that preset',
    );
  });

  testWidgets('an invalid hex is rejected without losing the field', (
    tester,
  ) async {
    final bc = await _pump(tester);
    await tester.tap(find.text('Custom hex'));
    await tester.pump();

    final field = find.descendant(
      of: find.byType(HexField).first,
      matching: find.byType(TextField),
    );

    // Non-hex characters never make it into the field at all — the input
    // formatter drops them, so "#ZZZZZZ" arrives as a bare "#".
    await tester.enterText(field, '#ZZZZZZ');
    await tester.pump();
    expect(tester.widget<TextField>(field).controller?.text, '#');
    expect(
      bc.draft.value.primary,
      BrandTheme.defaults.primary,
      reason: 'an unparseable value must not be committed',
    );

    // A half-typed hex stays on screen on the way to a full one, and is not
    // committed until it is complete — otherwise "#1f6" would expand to
    // "#11FF66" under the caret.
    await tester.enterText(field, '#1F6');
    await tester.pump();
    expect(find.text('#1F6'), findsOneWidget);
    expect(bc.draft.value.primary, BrandTheme.defaults.primary);

    await tester.enterText(field, '#1F6FEB');
    await tester.pump();
    expect(bc.draft.value.primary, const Color(0xFF1F6FEB));
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/app_theme.dart';
import 'package:shc_stock/app/core/theme/brand_controller.dart';
import 'package:shc_stock/app/core/theme/brand_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The white-label theme.
//
// The point of the whole exercise: a buyer sets their colours once and every
// screen follows, with no rebuild and no hardcoded hex left behind. These
// tests hold the three things that make that true — AppColors reads through
// to the live brand, tints are derived rather than stored, and the draft the
// Appearance screen edits never leaks into the app before Apply.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  group('hex round trip', () {
    test('parses #RRGGBB, #RGB and bare hex', () {
      expect(colorFromHex('#F5820A'), const Color(0xFFF5820A));
      expect(colorFromHex('f5820a'), const Color(0xFFF5820A));
      expect(colorFromHex('#FFF'), const Color(0xFFFFFFFF));
    });

    test('rejects junk instead of throwing', () {
      expect(colorFromHex('nope'), isNull);
      expect(colorFromHex('#12'), isNull);
      expect(colorFromHex('#GGGGGG'), isNull);
    });

    test('hexOf is the inverse', () {
      expect(hexOf(const Color(0xFF2D1B8C)), '#2D1B8C');
      expect(hexOf(colorFromHex('#1e8449')!), '#1E8449');
    });
  });

  group('derived values', () {
    test('tints are mixed from their base, never stored', () {
      const b = BrandTheme.defaults;
      expect(b.tintPrimary, tint(b.primary, 0.88));
      expect(b.tintDanger, tint(b.danger, 0.90));

      // Change the base and the tint follows — this is the whole reason
      // tints aren't configurable.
      final blue = b.copyWith(primary: const Color(0xFF1F6FEB));
      expect(blue.tintPrimary, tint(const Color(0xFF1F6FEB), 0.88));
      expect(blue.tintPrimary, isNot(b.tintPrimary));
    });

    test('radiusSm tracks radius and never drops below 3', () {
      expect(BrandTheme.defaults.copyWith(radius: 10).radiusSm, 7);
      expect(BrandTheme.defaults.copyWith(radius: 16).radiusSm, 11);
      expect(BrandTheme.defaults.copyWith(radius: 4).radiusSm, 3);
    });

    test('toJson stores no tint — they are computed on read', () {
      final json = BrandTheme.defaults.toJson();
      expect(json.keys.where((k) => k.startsWith('tint')), isEmpty);
      expect(json.containsKey('radiusSm'), isFalse);
    });
  });

  group('storage', () {
    test('survives a round trip', () {
      final custom = BrandTheme.defaults.copyWith(
        companyName: 'Steel Works Ltd',
        shortCode: 'SWL',
        primary: const Color(0xFF1F6FEB),
        font: 'DM Sans',
        radius: 16,
      );
      final back = BrandTheme.fromJson(
        jsonDecode(jsonEncode(custom.toJson())) as Map<String, dynamic>,
      );

      expect(back.companyName, 'Steel Works Ltd');
      expect(back.shortCode, 'SWL');
      expect(back.primary, const Color(0xFF1F6FEB));
      expect(back.font, 'DM Sans');
      expect(back.radius, 16);
    });

    test('a half-written blob degrades to defaults, never throws', () {
      final back = BrandTheme.fromJson(const {
        'companyName': 'Half Co',
        'primary': 'not-a-colour',
        'font': 'Comic Sans',
        'radius': 999,
      });

      expect(back.companyName, 'Half Co');
      expect(back.primary, BrandTheme.defaults.primary);
      expect(back.font, BrandTheme.defaults.font, reason: 'unknown font');
      expect(
        back.radius,
        BrandTheme.defaults.radius,
        reason: 'radius not one of the three',
      );
    });
  });

  group('presets', () {
    test('all eight ship, starting with the default brand', () {
      expect(kBrandPresets.length, 8);
      expect(kBrandPresets.first.name, 'Secure Heat Care');
      expect(kBrandPresets.first.primary, BrandTheme.defaults.primary);
    });

    test('applying one sets warning = primary and keeps surfaces', () {
      final steel = kBrandPresets.firstWhere((p) => p.name == 'Steel Blue');
      final themed = steel.applyTo(BrandTheme.defaults);

      expect(themed.primary, const Color(0xFF1F6FEB));
      expect(themed.warning, themed.primary, reason: 'spec: warning = primary');
      expect(themed.presetName, 'Steel Blue');
      // A preset is a palette, not a whole new set of greys.
      expect(themed.bg, BrandTheme.defaults.bg);
      expect(themed.textPrimary, BrandTheme.defaults.textPrimary);
    });
  });

  group('AppColors reads through to the live brand', () {
    test('changing primary changes what every call site resolves to', () async {
      final c = Get.put(BrandController(), permanent: true);
      expect(AppColors.primaryOrange, BrandTheme.defaults.primary);

      c.draft.value = c.draft.value.copyWith(primary: const Color(0xFF1F6FEB));
      await c.apply();

      // The 350-odd `AppColors.primaryOrange` call sites now resolve here.
      expect(AppColors.primaryOrange, const Color(0xFF1F6FEB));
      expect(
        AppThemeColors.light.tintPrimary,
        tint(const Color(0xFF1F6FEB), 0.88),
      );
    });

    test('falls back to defaults when no controller is registered', () {
      expect(Get.isRegistered<BrandController>(), isFalse);
      expect(AppColors.primaryOrange, BrandTheme.defaults.primary);
    });

    test('ThemeData carries the brand font and radius', () async {
      final c = Get.put(BrandController(), permanent: true);
      c.draft.value = c.draft.value.copyWith(font: 'IBM Plex Sans', radius: 16);
      await c.apply();

      final theme = AppTheme.lightTheme;
      // google_fonts registers its own family name ("IBMPlexSans_regular"),
      // so the assertion is that ThemeData carries the SAME family every
      // hand-written TextStyle gets — not the raw menu label.
      // ThemeData must carry the SAME family every hand-written TextStyle
      // gets from brandFontFamily — that equality is the whole contract.
      // (Under test that is the plain name; see flutter_test_config.dart.)
      expect(theme.textTheme.bodyLarge?.fontFamily, brandFontFamily);
      expect(
        theme.textTheme.bodyLarge?.fontFamily,
        fontFamilyFor('IBM Plex Sans'),
      );
      expect(theme.extension<AppThemeColors>()?.radius, 16);
      expect(theme.extension<AppThemeColors>()?.radiusSm, 11);
    });

    test('dark mode keeps the brand hue and swaps only the surfaces', () async {
      final c = Get.put(BrandController(), permanent: true);
      c.draft.value = c.draft.value.copyWith(primary: const Color(0xFF1F6FEB));
      await c.apply();

      final light = AppThemeColors.light;
      final dark = AppThemeColors.dark;

      expect(dark.background, isNot(light.background));
      expect(dark.textPrimary, isNot(light.textPrimary));
      // The buyer's blue survives the switch rather than reverting to orange.
      expect(dark.accent, isNot(BrandTheme.defaults.accent));
      expect(AppColors.primaryOrange, const Color(0xFF1F6FEB));
    });
  });

  group('the sweep', _sweepTests);

  group('draft vs applied', () {
    test('editing the draft leaves the live app alone until Apply', () async {
      final c = Get.put(BrandController(), permanent: true);

      c.draft.value = c.draft.value.copyWith(primary: const Color(0xFF0F766E));
      expect(c.isDirty, isTrue);
      expect(
        AppColors.primaryOrange,
        BrandTheme.defaults.primary,
        reason:
            'a half-picked palette must not leak onto the app behind the dialog',
      );

      await c.apply();
      expect(c.isDirty, isFalse);
      expect(AppColors.primaryOrange, const Color(0xFF0F766E));
    });

    test('discard throws the draft away', () async {
      final c = Get.put(BrandController(), permanent: true);
      c.draft.value = c.draft.value.copyWith(companyName: 'Typed by mistake');
      c.discard();

      expect(c.draft.value.companyName, BrandTheme.defaults.companyName);
      expect(c.isDirty, isFalse);
    });

    test('editing one colour clears the selected preset', () {
      final c = Get.put(BrandController(), permanent: true);
      c.selectPreset(kBrandPresets.firstWhere((p) => p.name == 'Steel Blue'));
      expect(c.draft.value.presetName, 'Steel Blue');

      c.editColor((b) => b.copyWith(success: const Color(0xFF123456)));
      expect(
        c.draft.value.presetName,
        isNull,
        reason: 'the palette is custom now',
      );
    });

    test('restore default returns exactly the shipped brand', () async {
      final c = Get.put(BrandController(), permanent: true);
      c.selectPreset(kBrandPresets.last);
      c.updateDraft((b) => b.copyWith(companyName: 'Someone Else', radius: 4));
      await c.apply();

      c.restoreDefaults();
      await c.apply();

      expect(c.applied.value.toJson(), BrandTheme.defaults.toJson());
    });

    test('apply reports that the server did not take it', () async {
      // Tests run with the network off, so this is the offline path: the
      // theme still applies locally, but apply() must say it did not reach
      // anyone else rather than letting the UI claim success.
      final c = Get.put(BrandController(), permanent: true);
      c.draft.value = c.draft.value.copyWith(companyName: 'Offline Co');

      final saved = await c.apply();

      expect(saved, isFalse, reason: 'the PUT could not go out');
      expect(c.applied.value.companyName, 'Offline Co');
      expect(c.isDirty, isFalse, reason: 'locally it IS applied');
    });

    test('a server that is down leaves the cached brand standing', () async {
      final first = Get.put(BrandController(), permanent: true);
      first.draft.value = first.draft.value.copyWith(companyName: 'Cached Co');
      await first.apply();
      Get.reset();

      final next = Get.put(BrandController(), permanent: true);
      await next.load(); // disk hit, then a sync that cannot reach anything

      expect(next.applied.value.companyName, 'Cached Co');
    });

    test('an applied brand is read back before the first frame', () async {
      final first = Get.put(BrandController(), permanent: true);
      first.draft.value = first.draft.value.copyWith(
        companyName: 'Blue Buyer',
        primary: const Color(0xFF1F6FEB),
      );
      await first.apply();
      Get.reset();

      // A fresh launch: load() is what main() awaits before runApp, so the
      // login screen never flashes the shipped orange.
      final next = Get.put(BrandController(), permanent: true);
      await next.load();

      expect(next.applied.value.companyName, 'Blue Buyer');
      expect(AppColors.primaryOrange, const Color(0xFF1F6FEB));
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// The sweep, as an executable rule.
//
// The theme model is only worth anything if the app actually reads it. These
// walk the source: a stray `fontFamily: 'Poppins'`, a `BorderRadius.circular(10)`
// or a brand hex compiled into a screen would each be a control in Appearance
// that silently does nothing.
// ─────────────────────────────────────────────────────────────────────────────
void _sweepTests() {
  final lib = Directory('lib');

  // The paper palette is the one deliberate exception to the sweep. A printed
  // tax invoice is black on white in both themes and on the printer — if it
  // read the brand's surfaces, a dark theme would leak onto the page. See the
  // note at the top of invoice_paper.dart.
  const exempt = ['/core/theme/', '/billing/widgets/invoice_paper.dart'];

  List<String> offenders(bool Function(String content) hasIssue) => lib
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !exempt.any(f.path.replaceAll(r'\', '/').contains))
      .where((f) => hasIssue(f.readAsStringSync()))
      .map((f) => f.path)
      .toList();

  test('no screen hardcodes a font family', () {
    expect(
      offenders((s) => s.contains("fontFamily: 'Poppins'")),
      isEmpty,
      reason: 'use brandFontFamily so the Appearance font picker reaches it',
    );
  });

  test('no screen hardcodes the default corner radius', () {
    expect(
      offenders((s) => s.contains('BorderRadius.circular(10)')),
      isEmpty,
      reason: 'use appColors.radius so Sharp/Rounded/Soft reaches it',
    );
  });

  test('no screen hardcodes a brand colour', () {
    const brandHexes = [
      'F5820A',
      '2D1B8C',
      '1E8449',
      'C0392B',
      'FAF9F7',
      'ECECEC',
      'F5F4F0',
      '2563EB',
      '6B5CBF',
    ];
    for (final hex in brandHexes) {
      expect(
        offenders(
          (s) =>
              s.contains('0xFF$hex') || s.contains('0xff${hex.toLowerCase()}'),
        ),
        isEmpty,
        reason: '#$hex belongs to the brand, not to a screen',
      );
    }
  });
}

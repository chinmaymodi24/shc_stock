import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/export/writers/pdf_logo.dart';
import 'package:shc_stock/app/core/theme/brand_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Owns the live brand and the unsaved draft behind the Appearance screen.
//
// Two copies on purpose: [applied] is what the whole app renders from, and
// [draft] is what the editors and the live preview mutate. Nothing the buyer
// touches reaches the app until Apply, so a half-picked palette never leaks
// onto the screens behind the settings page.
//
// [load] runs before `runApp`, so the first frame is already the buyer's
// brand — no flash of the shipped orange for a buyer whose brand is blue.
// ─────────────────────────────────────────────────────────────────────────────
class BrandController extends GetxController {
  static const _key = 'brand_theme';

  final applied = BrandTheme.defaults.obs;
  final draft = BrandTheme.defaults.obs;

  /// True while the draft differs from what's live — drives the preview's
  /// "Not applied yet" note and whether Discard does anything.
  bool get isDirty => jsonEncode(draft.value.toJson()) != _appliedJson;
  String _appliedJson = jsonEncode(BrandTheme.defaults.toJson());

  /// Reads the stored brand. Awaited by `main()` before the first frame.
  ///
  /// Disk first, then the server. The local copy is only a cache so the very
  /// first frame is already branded — the SERVER is the source of truth,
  /// because an admin sets the brand for the whole portal and every employee
  /// on every device has to get it. A device that has never synced still
  /// paints correctly on its second launch.
  ///
  /// Neither step may throw: a bad blob, or a backend that is down, must
  /// never be the reason the app won't start.
  Future<void> load() async {
    await _loadFromDisk();
    await syncFromServer();
  }

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      await _adopt(
        BrandTheme.fromJson(jsonDecode(raw) as Map<String, dynamic>),
      );
    } catch (_) {
      // Keep the defaults already in place.
    }
  }

  /// Pulls the portal's brand. Called on startup and safe to call again —
  /// an employee signing in on a new device picks up the admin's brand here.
  Future<void> syncFromServer() async {
    try {
      final json = await ApiClient.instance.get('/settings/brand');
      if (json is! Map || json.isEmpty) return;
      final theme = BrandTheme.fromJson(Map<String, dynamic>.from(json));
      if (jsonEncode(theme.toJson()) == _appliedJson) return;
      await _adopt(theme);
      await _cacheToDisk();
    } catch (_) {
      // Offline, or the backend is down: the cached brand stands.
    }
  }

  Future<void> _adopt(BrandTheme theme) async {
    applied.value = theme;
    draft.value = theme;
    _appliedJson = jsonEncode(theme.toJson());
    // Decode the logo now, so the first export already has it — the PDF
    // writers are synchronous and cannot wait for it.
    await warmPdfLogoCache(theme.logoBase64);
  }

  /// Commits the draft. The app re-themes in place — every screen reads
  /// through [applied], so there is nothing to reload.
  ///
  /// Returns false when the theme applied locally but could not be saved for
  /// everyone else, so the UI can say so rather than implying it shipped.
  Future<bool> apply() async {
    await _adopt(draft.value);
    await _cacheToDisk();
    try {
      await ApiClient.instance.put('/settings/brand', applied.value.toJson());
      return true;
    } catch (e) {
      // The caller only needs the yes/no, but swallowing the reason outright
      // made a rejected save indistinguishable from an offline one — a 413 on
      // an oversized logo looked exactly like a dead backend.
      debugPrint('Brand save failed: $e');
      return false;
    }
  }

  Future<void> _cacheToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, _appliedJson);
    } catch (_) {
      // The theme is applied in memory either way; a failed write only means
      // it won't survive a restart, which is not worth blocking the UI for.
    }
  }

  /// Throws the draft away and starts again from what is live.
  void discard() => draft.value = applied.value;

  /// Back to the brand the app ships with — draft only, so it still takes an
  /// Apply to commit.
  void restoreDefaults() => draft.value = BrandTheme.defaults;

  // ── Draft editing ───────────────────────────────────────────────────────

  void updateDraft(BrandTheme Function(BrandTheme) change) =>
      draft.value = change(draft.value);

  /// Editing any single colour makes the palette custom — the preset card it
  /// came from is no longer an honest description of it.
  void editColor(BrandTheme Function(BrandTheme) change) =>
      draft.value = change(draft.value).copyWith(clearPreset: true);

  void selectPreset(BrandPreset preset) =>
      draft.value = preset.applyTo(draft.value);
}

/// The live brand, readable from anywhere — including inside `Obx` and static
/// contexts where there is no `BuildContext`.
///
/// Falls back to the shipped defaults when the controller isn't registered,
/// which is what keeps widget tests and `AppColors` working without every
/// test having to stand one up.
BrandTheme get brand => Get.isRegistered<BrandController>()
    ? Get.find<BrandController>().applied.value
    : BrandTheme.defaults;

import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/utils/phone_input.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/session/app_modules.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/utils/app_date.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';

/// SharedPreferences keys mirroring the `autoNumberPurchase` / `autoNumberSales`
/// user settings, so the Add Purchase / Add Sale forms can read them without
/// depending on SettingsController being registered.
const kAutoNumberPurchasePrefKey = 'pref_auto_number_purchase';
const kAutoNumberSalesPrefKey = 'pref_auto_number_sales';

Future<bool> _prefOrTrue(String key) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? true;
  } catch (_) {
    return true;
  }
}

/// Whether Add Purchase should prefill "Invoice No." with the next number in
/// the series. Defaults to true (opt-out).
Future<bool> autoNumberPurchaseEnabled() =>
    _prefOrTrue(kAutoNumberPurchasePrefKey);

/// Same for Add Sale — switched separately.
Future<bool> autoNumberSalesEnabled() => _prefOrTrue(kAutoNumberSalesPrefKey);

// ─────────────────────────────────────────────────────────────────────────────
// Settings for the signed-in user, loaded from and saved to /api/settings.
//
// This used to hold a hardcoded name/email/password and toggles that lived
// only in memory — nothing survived a restart.
// ─────────────────────────────────────────────────────────────────────────────
class SettingsController extends GetxController {
  final _api = ApiClient.instance;

  final RxInt tab = 0.obs;
  final RxInt mobileTab =
      0.obs; // 0 = Preferences, 1 = Security, 2 = Notifications

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isChangingPassword = false.obs;

  // Profile
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  // Security
  final curPwdCtrl = TextEditingController();
  final newPwdCtrl = TextEditingController();
  final confirmPwdCtrl = TextEditingController();

  // Notifications
  final lowStock = true.obs;
  final delivery = true.obs;
  final payment = false.obs;
  final weekly = true.obs;
  final twoFactor = false.obs;

  // Preferences
  final rowsPerPage = 10.obs;
  final dateFormat = kDefaultDateFormatLabel.obs;
  final autoNumberPurchase = true.obs;
  final autoNumberSales = true.obs;

  /// Business-wide (not per-user): flag a product "Low Stock" once its stock
  /// falls to this level or below, for products with no per-item minimum set.
  /// 0 = off. Loaded from / saved to /api/settings/app.
  final lowStockThreshold = 0.obs;

  Future<void> _cacheAutoNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kAutoNumberPurchasePrefKey, autoNumberPurchase.value);
      await prefs.setBool(kAutoNumberSalesPrefKey, autoNumberSales.value);
    } catch (_) {}
  }

  int? get _userId => Get.isRegistered<SessionController>()
      ? Get.find<SessionController>().user.value?.id
      : null;

  @override
  void onInit() {
    super.onInit();
    fetchSettings();
  }

  void _error(String message) => showAppToast(
    'Error',
    message,
    backgroundColor: AppColors.danger,
    colorText: Colors.white,
  );

  void _ok(String title, String message) => showAppToast(
    title,
    message,
    backgroundColor: AppColors.success,
    colorText: Colors.white,
  );

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> fetchSettings() async {
    final uid = _userId;
    if (uid == null) return; // signed out — nothing to load
    isLoading.value = true;
    try {
      final json =
          await _api.get('/settings?userId=$uid') as Map<String, dynamic>;
      nameCtrl.text = json['name'] as String? ?? '';
      emailCtrl.text = json['email'] as String? ?? '';
      phoneCtrl.text = normalisePhone(json['phone'] as String? ?? '');
      lowStock.value = json['notifyLowStock'] as bool? ?? true;
      delivery.value = json['notifyDelivery'] as bool? ?? true;
      payment.value = json['notifyPayment'] as bool? ?? false;
      weekly.value = json['notifyWeekly'] as bool? ?? true;
      twoFactor.value = json['twoFactor'] as bool? ?? false;
      rowsPerPage.value = (json['rowsPerPage'] as num?)?.toInt() ?? 10;
      final fmt = json['dateFormat'] as String?;
      dateFormat.value = kDateFormatLabels.contains(fmt)
          ? fmt!
          : kDefaultDateFormatLabel;
      await AppDates.apply(dateFormat.value);
      // An older server only knows the single switch: it covers both.
      final legacy = json['autoNumberDocs'] as bool? ?? true;
      autoNumberPurchase.value = json['autoNumberPurchase'] as bool? ?? legacy;
      autoNumberSales.value = json['autoNumberSales'] as bool? ?? legacy;
      await _cacheAutoNumber();

      final app = await _api.get('/settings/app') as Map<String, dynamic>;
      lowStockThreshold.value =
          (app['lowStockThreshold'] as num?)?.toInt() ?? 0;
    } catch (e) {
      _error('Failed to load settings. Is the backend running?');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> saveSettings() async {
    final uid = _userId;
    if (uid == null) return _error('You are signed out.');
    isSaving.value = true;
    try {
      final json = await _api.put('/settings', {
        'userId': uid,
        'name': nameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'notifyLowStock': lowStock.value,
        'notifyDelivery': delivery.value,
        'notifyPayment': payment.value,
        'notifyWeekly': weekly.value,
        'twoFactor': twoFactor.value,
        'rowsPerPage': rowsPerPage.value,
        'dateFormat': dateFormat.value,
        'autoNumberPurchase': autoNumberPurchase.value,
        'autoNumberSales': autoNumberSales.value,
      });
      await _cacheAutoNumber();
      // Every date on every screen follows the new format straight away.
      final formatChanged =
          AppDates.styleFor(dateFormat.value) != AppDates.style.value;
      await AppDates.apply(dateFormat.value);
      if (formatChanged) Get.forceAppUpdate();

      // Business-wide low-stock threshold — its own endpoint, not per-user,
      // and only for someone allowed to change Preferences.
      if (canSaveSettingsTab('Preferences')) {
        await _api.put('/settings/app', {
          'lowStockThreshold': lowStockThreshold.value,
        });
      }

      // Name/email may have changed — keep the top bar in step. Updating the
      // profile in place keeps the session's token and permissions; signing
      // in again with this partial map used to wipe both.
      final map = json as Map<String, dynamic>;
      await Get.find<SessionController>().updateProfile(
        name: map['name'] as String?,
        email: map['email'] as String?,
        phone: map['phone'] as String?,
      );
      _ok('Settings Saved', 'Your changes have been saved.');
    } catch (e) {
      _error(e is ApiException ? e.message : 'Failed to save settings.');
    } finally {
      isSaving.value = false;
    }
  }

  /// Persists a single toggle immediately — the switches save as you flip them.
  Future<void> toggle(RxBool flag, bool value) async {
    final previous = flag.value;
    flag.value = value;
    final uid = _userId;
    if (uid == null) return;
    try {
      await _api.put('/settings', {
        'userId': uid,
        'notifyLowStock': lowStock.value,
        'notifyDelivery': delivery.value,
        'notifyPayment': payment.value,
        'notifyWeekly': weekly.value,
        'twoFactor': twoFactor.value,
      });
    } catch (e) {
      flag.value = previous; // put it back
      _error('Failed to save that preference.');
    }
  }

  // ── Password ──────────────────────────────────────────────────────────────
  Future<void> changePassword() async {
    final uid = _userId;
    if (uid == null) return _error('You are signed out.');

    if (curPwdCtrl.text.isEmpty) {
      return _error('Enter your current password.');
    }
    if (newPwdCtrl.text.length < 6) {
      return _error('New password must be at least 6 characters.');
    }
    if (newPwdCtrl.text != confirmPwdCtrl.text) {
      return _error('New password and confirmation do not match.');
    }

    isChangingPassword.value = true;
    try {
      final json = await _api.post('/settings/password', {
        'userId': uid,
        'currentPassword': curPwdCtrl.text,
        'newPassword': newPwdCtrl.text,
      });
      // The old session token stopped working with the old password; carry on
      // with the fresh one.
      final fresh = json is Map ? json['token'] : null;
      if (fresh is String && Get.isRegistered<SessionController>()) {
        await Get.find<SessionController>().markPasswordChanged(token: fresh);
      }
      curPwdCtrl.clear();
      newPwdCtrl.clear();
      confirmPwdCtrl.clear();
      _ok('Password Changed', 'Use your new password next time you sign in.');
    } catch (e) {
      _error(e is ApiException ? e.message : 'Failed to change password.');
    } finally {
      isChangingPassword.value = false;
    }
  }

  @override
  void onClose() {
    for (final c in [
      nameCtrl,
      emailCtrl,
      phoneCtrl,
      curPwdCtrl,
      newPwdCtrl,
      confirmPwdCtrl,
    ]) {
      c.dispose();
    }
    super.onClose();
  }
}

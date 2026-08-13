import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';

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
  final dateFormat = 'MMM D, YYYY (Jul 18, 2026)'.obs;

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
    backgroundColor: const Color(0xFFEF4444),
    colorText: Colors.white,
  );

  void _ok(String title, String message) => showAppToast(
    title,
    message,
    backgroundColor: const Color(0xFF22C55E),
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
      phoneCtrl.text = json['phone'] as String? ?? '';
      lowStock.value = json['notifyLowStock'] as bool? ?? true;
      delivery.value = json['notifyDelivery'] as bool? ?? true;
      payment.value = json['notifyPayment'] as bool? ?? false;
      weekly.value = json['notifyWeekly'] as bool? ?? true;
      twoFactor.value = json['twoFactor'] as bool? ?? false;
      rowsPerPage.value = (json['rowsPerPage'] as num?)?.toInt() ?? 10;
      dateFormat.value =
          json['dateFormat'] as String? ?? 'MMM D, YYYY (Jul 18, 2026)';
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
      });
      // Name/email may have changed — keep the top bar in step.
      final map = json as Map<String, dynamic>;
      await Get.find<SessionController>().signIn({
        'id': map['id'],
        'name': map['name'],
        'email': map['email'],
        'role': map['role'],
      });
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
      await _api.post('/settings/password', {
        'userId': uid,
        'currentPassword': curPwdCtrl.text,
        'newPassword': newPwdCtrl.text,
      });
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

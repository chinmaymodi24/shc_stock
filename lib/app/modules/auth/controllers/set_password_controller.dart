import 'package:shc_stock/app/core/utils/dispose_later.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/routes/app_routes.dart';

/// What to tell someone choosing their own password, or null when it is fine.
///
/// Mirrors the server (min 6 characters, different from the old one) so the
/// obvious mistakes are caught before a round trip.
String? checkNewPassword({
  required String current,
  required String next,
  required String confirm,
}) {
  if (current.isEmpty) return 'Enter the password you were given.';
  if (next.length < 6) return 'New password must be at least 6 characters.';
  if (next == current) {
    return 'Choose a password different from the current one.';
  }
  if (next != confirm) return 'New password and confirmation do not match.';
  return null;
}

/// The fresh session token in a `/settings/password` response, if any.
String? _tokenOf(dynamic json) {
  final t = json is Map ? json['token'] : null;
  return t is String && t.isNotEmpty ? t : null;
}

/// Drives the "set your own password" screen.
///
/// An employee whose password was chosen by somebody else (a new account, or
/// a reset by an admin) lands here after signing in; the server refuses every
/// other call until it is done.
class SetPasswordController extends GetxController {
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  final showCurrent = false.obs;
  final showNew = false.obs;
  final isSaving = false.obs;
  final error = RxnString();

  Future<void> save() async {
    final problem = checkNewPassword(
      current: currentCtrl.text,
      next: newCtrl.text,
      confirm: confirmCtrl.text,
    );
    if (problem != null) {
      error.value = problem;
      return;
    }
    final session = Get.find<SessionController>();
    final id = session.user.value?.id;
    if (id == null) return;

    error.value = null;
    isSaving.value = true;
    try {
      final json = await ApiClient.instance.post('/settings/password', {
        'userId': id,
        'currentPassword': currentCtrl.text,
        'newPassword': newCtrl.text,
      });
      await session.markPasswordChanged(token: _tokenOf(json));
      showAppToast(
        'Password set',
        'Use your new password the next time you sign in.',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
      Get.offAllNamed(session.homeRoute);
    } catch (e) {
      error.value = e is ApiException && e.statusCode != -1
          ? e.message
          : 'Could not set the password. Check your connection and try again.';
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> signOut() async {
    await Get.find<SessionController>().signOut();
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void onClose() {
    // Disposed once the page has gone, not while it is still on screen
    // for its exit transition — see dispose_later.dart.
    disposeAfterPageExit([currentCtrl, newCtrl, confirmCtrl]);
    super.onClose();
  }
}

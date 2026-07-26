import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  final RxInt tab = 0.obs;
  final RxInt mobileTab =
      0.obs; // 0 = Preferences, 1 = Security, 2 = Notifications

  // Profile
  final nameCtrl = TextEditingController(text: 'Chinmay Modi');
  final emailCtrl = TextEditingController(text: 'chinmaymodi24@gmail.com');

  // Security
  final curPwdCtrl = TextEditingController(text: 'password');
  final newPwdCtrl = TextEditingController();
  final confirmPwdCtrl = TextEditingController();

  // Notifications toggles
  final lowStock = true.obs;
  final delivery = true.obs;
  final payment = false.obs;
  final weekly = true.obs;
  final twoFactor = false.obs;

  // Preferences
  final rowsPerPage = 10.obs;
  final dateFormat = 'MMM D, YYYY (Jul 18, 2026)'.obs;

  @override
  void onClose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    curPwdCtrl.dispose();
    newPwdCtrl.dispose();
    confirmPwdCtrl.dispose();
    super.onClose();
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final RxBool isPasswordVisible = false.obs;
  final RxBool rememberMe = false.obs;
  final RxBool isLoading = false.obs;
  final RxString selectedLanguage = 'English'.obs;

  final List<String> languages = ['English', 'Hindi', 'Gujarati'];

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.toggle();
  }

  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
  }

  void changeLanguage(String language) {
    selectedLanguage.value = language;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      // TODO: Implement actual authentication
      await Future.delayed(const Duration(seconds: 2));
      Get.offNamed(AppRoutes.dashboard);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Sign in failed. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF47B20),
        colorText: const Color(0xFFFFFFFF),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void signInWithAnotherAccount() {
    // TODO: Implement alternate sign-in
    Get.snackbar(
      'Info',
      'Alternative sign-in coming soon.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void forgotPassword() {
    // TODO: Navigate to forgot password screen
    Get.snackbar(
      'Info',
      'Password reset coming soon.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

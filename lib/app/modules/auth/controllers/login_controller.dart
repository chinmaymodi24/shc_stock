import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../routes/app_routes.dart';

class LoginController extends GetxController {
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  final formKey            = GlobalKey<FormState>();

  final RxBool isPasswordVisible = false.obs;
  final RxBool rememberMe        = false.obs;
  final RxBool isLoading         = false.obs;
  final RxString selectedLanguage = 'English'.obs;

  final List<String> languages = ['English', 'Hindi', 'Gujarati'];

  // ── SharedPreferences keys ─────────────────────────────────
  static const _keyRemember  = 'remember_me';
  static const _keyEmail     = 'saved_email';
  static const _keyPassword  = 'saved_password'; // legacy key, only used to purge old plaintext values

  // ── Lifecycle ─────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _loadRememberedCredentials();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // ── Load saved credentials on app start ─────────────────────
  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    // Purge any password persisted in plaintext by older versions of this app.
    if (prefs.containsKey(_keyPassword)) await prefs.remove(_keyPassword);

    final isRemembered = prefs.getBool(_keyRemember) ?? false;
    if (isRemembered) {
      rememberMe.value     = true;
      emailController.text = prefs.getString(_keyEmail) ?? '';
    }
  }

  // ── Save or clear credentials ──────────────────────────────
  // Only the email is persisted. Passwords are never written to disk in
  // plaintext; the user must always re-enter their password to sign in.
  Future<void> _saveRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe.value) {
      await prefs.setBool(_keyRemember, true);
      await prefs.setString(_keyEmail,  emailController.text.trim());
    } else {
      await prefs.remove(_keyRemember);
      await prefs.remove(_keyEmail);
    }
  }

  // ── Toggle ────────────────────────────────────────────────────
  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
  }

  // ── Other ─────────────────────────────────────────────────────
  void togglePasswordVisibility() => isPasswordVisible.toggle();

  void changeLanguage(String language) => selectedLanguage.value = language;

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email address.';
    if (!GetUtils.isEmail(value))       return 'Please enter a valid email address.';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password.';
    if (value.length < 6)               return 'Password must be at least 6 characters.';
    return null;
  }

  // ── Sign In ───────────────────────────────────────────────────
  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      // TODO: Replace with real Firebase Authentication
      await Future.delayed(const Duration(milliseconds: 600));

      // Save remember-me silently — never block navigation
      try { await _saveRememberMe(); } catch (_) {}

      Get.offNamed(AppRoutes.dashboard);
    } catch (e) {
      _showTopRightToast(
        'Sign In Failed',
        'Something went wrong. Please try again.',
        backgroundColor: const Color(0xFFEF4444),
        colorText: const Color(0xFFFFFFFF),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void signInWithAnotherAccount() {
    _showTopRightToast(
      'Coming Soon',
      'Single Sign-On (SSO) will be available in a future release.',
    );
  }

  void forgotPassword() {
    _showTopRightToast(
      'Coming Soon',
      'Password reset via email will be available soon.',
    );
  }

  // ── Shared top-right toast ─────────────────────────────────────
  void _showTopRightToast(
    String title,
    String message, {
    Color? backgroundColor,
    Color? colorText,
  }) {
    const toastWidth = 380.0;
    final screenWidth = Get.width;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor,
      colorText: colorText,
      margin: EdgeInsets.only(
        top: 16,
        right: 16,
        left: (screenWidth - toastWidth - 16).clamp(16, screenWidth - 32),
      ),
      borderRadius: 12,
    );
  }
}


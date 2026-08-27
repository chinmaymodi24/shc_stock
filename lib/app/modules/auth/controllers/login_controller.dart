import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';

class LoginController extends GetxController {
  final _api = ApiClient.instance;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final RxBool isPasswordVisible = false.obs;
  final RxBool rememberMe = false.obs;
  final RxBool isLoading = false.obs;
  final RxString selectedLanguage = 'English'.obs;

  final List<String> languages = ['English', 'Hindi', 'Gujarati'];

  // ── SharedPreferences keys ─────────────────────────────────
  static const _keyRemember = 'remember_me';
  static const _keyEmail = 'saved_email';
  static const _keyPassword =
      'saved_password'; // legacy key, only used to purge old plaintext values

  // ── Secure storage (password only) ──────────────────────────
  static const _secureKeyPassword = 'saved_password';
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

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
      rememberMe.value = true;
      emailController.text = prefs.getString(_keyEmail) ?? '';
      try {
        passwordController.text =
            await _secureStorage.read(key: _secureKeyPassword) ?? '';
      } catch (_) {}
    }
  }

  // ── Save or clear credentials ──────────────────────────────
  // The email is kept in SharedPreferences; the password is kept only in
  // the platform-encrypted secure storage (Keychain / Keystore / DPAPI).
  Future<void> _saveRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe.value) {
      await prefs.setBool(_keyRemember, true);
      await prefs.setString(_keyEmail, emailController.text.trim());
      await _secureStorage.write(
        key: _secureKeyPassword,
        value: passwordController.text,
      );
    } else {
      await prefs.remove(_keyRemember);
      await prefs.remove(_keyEmail);
      await _secureStorage.delete(key: _secureKeyPassword);
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
    if (value == null || value.isEmpty) {
      return 'Please enter your email address.';
    }
    if (!GetUtils.isEmail(value)) return 'Please enter a valid email address.';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password.';
    if (value.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  // ── Sign In ───────────────────────────────────────────────────
  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      final res = await _api.post('/auth/login', {
        'email': emailController.text.trim(),
        'password': passwordController.text,
      });
      // Remember who signed in — drives the top bar and audit stamps.
      await Get.find<SessionController>().signIn(res as Map<String, dynamic>);

      // Save remember-me silently — never block navigation
      try {
        await _saveRememberMe();
      } catch (_) {}

      Get.offNamed(AppRoutes.dashboard);
    } on ApiException catch (e) {
      showAppToast(
        'Sign In Failed',
        e.statusCode == 401
            ? 'Invalid email or password.'
            : 'Something went wrong. Please try again.',
        backgroundColor: const Color(0xFFEF4444),
        colorText: const Color(0xFFFFFFFF),
      );
    } catch (e) {
      showAppToast(
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
    showAppToast(
      'Coming Soon',
      'Single Sign-On (SSO) will be available in a future release.',
    );
  }

  void forgotPassword() {
    showAppToast(
      'Coming Soon',
      'Password reset via email will be available soon.',
    );
  }
}

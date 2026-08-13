import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared toast used everywhere instead of Get.snackbar's default full-width
/// bar — renders as a compact card pinned to the top-right corner.
void showAppToast(
  String title,
  String message, {
  Color? backgroundColor,
  Color? colorText,
  Duration duration = const Duration(seconds: 3),
  IconData? icon,
}) {
  const toastWidth = 380.0;
  final screenWidth = Get.width;
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.TOP,
    backgroundColor: backgroundColor,
    colorText: colorText,
    duration: duration,
    icon: icon == null ? null : Icon(icon, color: colorText ?? Colors.white),
    margin: EdgeInsets.only(
      top: 16,
      right: 16,
      left: (screenWidth - toastWidth - 16).clamp(16, screenWidth - 32),
    ),
    borderRadius: 12,
  );
}

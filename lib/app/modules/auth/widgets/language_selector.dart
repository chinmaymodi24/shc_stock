import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/auth/controllers/login_controller.dart';

class LanguageSelector extends GetView<LoginController> {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.inputBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: PopupMenuButton<String>(
          onSelected: controller.changeLanguage,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          offset: const Offset(0, 40),
          itemBuilder: (context) => controller.languages
              .map(
                (lang) => PopupMenuItem(
                  value: lang,
                  child: Text(
                    lang,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              )
              .toList(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language_rounded,
                size: 16,
                color: AppColors.textMedium,
              ),
              const SizedBox(width: 6),
              Text(
                controller.selectedLanguage.value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppColors.textMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/auth/controllers/login_controller.dart';
import 'mobile_login_layout.dart';
import 'tablet_login_layout.dart';
import 'web_login_layout.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(LoginController());
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        if (w >= 1100) return const WebLoginLayout(); // Desktop
        if (w >= 600) return const TabletLoginLayout(); // Tablet
        return const MobileLoginLayout(); // Mobile
      },
    );
  }
}

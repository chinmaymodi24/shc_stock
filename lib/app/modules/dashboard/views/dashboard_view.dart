import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'mobile_dashboard_layout.dart';
import 'web_dashboard_layout.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // permanent + guarded: this runs inside build(), so an unguarded Get.put
    // would rebuild the controller — and refetch the whole dashboard — on
    // every layout pass.
    if (!Get.isRegistered<DashboardController>()) {
      Get.put(DashboardController(), permanent: true);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) {
          return const WebDashboardLayout();
        }
        return const MobileDashboardLayout();
      },
    );
  }
}

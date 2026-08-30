import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/reports/controllers/reports_controller.dart';

/// The Reports / Analytics / Profit & Loss strip that sits directly under the
/// top bar. Selection lives on [ReportsController], so the web and mobile
/// layouts stay on the same tab as the window is resized across the breakpoint.
class ReportsTabBar extends GetView<ReportsController> {
  const ReportsTabBar({super.key});

  static const List<String> titles = ['Reports', 'Analytics', 'Profit & Loss'];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.topBarBg,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Obx(
          () => Row(
            children: [
              for (var i = 0; i < titles.length; i++)
                _tab(context, i, controller.tab.value == i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int index, bool active) {
    final colors = context.appColors;
    return InkWell(
      onTap: () => controller.tab.value = index,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.primaryOrange : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          titles[index],
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? colors.textPrimary : colors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}

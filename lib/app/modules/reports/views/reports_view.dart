import 'package:flutter/material.dart';
import 'web_reports_layout.dart';
import 'mobile_reports_layout.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) return const WebReportsLayout();
        return const MobileReportsLayout();
      },
    );
  }
}

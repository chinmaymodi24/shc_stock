import 'package:flutter/material.dart';
import 'mobile_settings_view.dart';
import 'web_settings_layout.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) return const WebSettingsLayout();
        return const MobileSettingsView();
      },
    );
  }
}

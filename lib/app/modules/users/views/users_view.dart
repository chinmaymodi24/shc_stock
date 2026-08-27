import 'package:flutter/material.dart';
import 'web_users_layout.dart';
import 'mobile_users_layout.dart';

class UsersView extends StatelessWidget {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) return const WebUsersLayout();
        return const MobileUsersLayout();
      },
    );
  }
}

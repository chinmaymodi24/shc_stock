import 'package:flutter/material.dart';
import 'web_add_client_layout.dart';
import 'mobile_add_client_layout.dart';

class AddClientView extends StatelessWidget {
  const AddClientView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) return const WebAddClientLayout();
        return const MobileAddClientLayout();
      },
    );
  }
}

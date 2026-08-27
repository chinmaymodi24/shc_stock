import 'package:flutter/material.dart';
import 'web_clients_layout.dart';
import 'mobile_clients_layout.dart';

class ClientsView extends StatelessWidget {
  const ClientsView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) return const WebClientsLayout();
        return const MobileClientsLayout();
      },
    );
  }
}

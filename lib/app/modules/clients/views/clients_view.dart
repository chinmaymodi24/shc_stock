import 'package:flutter/material.dart';
import 'web_clients_layout.dart';

class ClientsView extends StatelessWidget {
  const ClientsView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use web layout for wide screens
        if (constraints.maxWidth >= 700) return const WebClientsLayout();
        return const WebClientsLayout(); // mobile layout can be added later
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'mobile_add_product_layout.dart';
import 'web_add_product_layout.dart';

class AddProductView extends StatelessWidget {
  const AddProductView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) return const WebAddProductLayout();
        return const MobileAddProductLayout();
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'mobile_products_layout.dart';
import 'web_products_layout.dart';

class ProductsView extends StatelessWidget {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) return WebProductsLayout();
        return const MobileProductsLayout();
      },
    );
  }
}

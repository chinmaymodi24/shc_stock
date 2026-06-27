import 'package:flutter/material.dart';
import 'web_sales_layout.dart';
import 'mobile_sales_layout.dart';

class SalesView extends StatelessWidget {
  const SalesView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) {
          return const WebSalesLayout();
        }
        return const MobileSalesLayout();
      },
    );
  }
}

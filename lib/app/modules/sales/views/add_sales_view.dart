import 'package:flutter/material.dart';
import 'web_new_sales_layout.dart';
import 'mobile_add_sales_layout.dart';

class AddSalesView extends StatelessWidget {
  const AddSalesView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) return const WebNewSalesLayout();
        return const MobileAddSalesLayout();
      },
    );
  }
}

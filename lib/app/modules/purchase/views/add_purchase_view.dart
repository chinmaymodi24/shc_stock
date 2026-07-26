import 'package:flutter/material.dart';
import 'web_new_purchase_layout.dart';
import 'mobile_add_purchase_layout.dart';

class AddPurchaseView extends StatelessWidget {
  const AddPurchaseView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) return const WebNewPurchaseLayout();
        return const MobileAddPurchaseLayout();
      },
    );
  }
}

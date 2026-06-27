import 'package:flutter/material.dart';
import 'web_purchase_layout.dart';
import 'mobile_purchase_layout.dart';

class PurchaseView extends StatelessWidget {
  const PurchaseView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) return const WebPurchaseLayout();
        return const MobilePurchaseLayout();
      },
    );
  }
}

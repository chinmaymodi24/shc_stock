import 'package:flutter/material.dart';
import 'web_transactions_layout.dart';
import 'mobile_transactions_layout.dart';

class TransactionsView extends StatelessWidget {
  const TransactionsView({super.key});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) return const WebTransactionsLayout();
        return const MobileTransactionsLayout();
      },
    );
  }
}

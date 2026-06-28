import 'package:flutter/material.dart';
import 'web_stock_layout.dart';

class StockView extends StatelessWidget {
  const StockView({super.key});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 700) return const WebStockLayout();
      return const WebStockLayout();
    });
  }
}

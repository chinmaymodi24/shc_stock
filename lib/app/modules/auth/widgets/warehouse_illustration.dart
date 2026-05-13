import 'package:flutter/material.dart';

/// Warehouse background image — fills its container completely.
/// Used in the top hero section of the mobile login layout.
class WarehouseIllustration extends StatelessWidget {
  final double width;
  final double height;

  const WarehouseIllustration({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/background.png',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.fitWidth,
      alignment: Alignment.center,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';

/// A stylized warehouse illustration using CustomPainter
/// Replace with actual asset image: Image.asset('assets/images/warehouse.png')
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
      "assets/background.png",
      width: context.width * 0.8,
      height: context.height * 0.5,
      fit: BoxFit.fitWidth,
    );
  }
}
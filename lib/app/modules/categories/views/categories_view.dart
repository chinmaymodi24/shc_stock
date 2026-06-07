import 'package:flutter/material.dart';
import 'mobile_categories_layout.dart';
import 'web_categories_layout.dart';

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) return const WebCategoriesLayout();
        return const MobileCategoriesLayout();
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/products/views/add_product_dialog.dart';
import 'package:shc_stock/app/modules/products/views/products_view.dart';

/// `/products/add` — reached from the top-bar search ("Add Product").
///
/// This used to be a separate full-page form whose Save button only showed a
/// "saved successfully" toast and never called the API, so nothing was created.
/// Products are added through [AddProductDialog] (the one that talks to the
/// server), so this route simply shows the Products page with that dialog open.
class AddProductView extends StatefulWidget {
  const AddProductView({super.key});

  @override
  State<AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<AddProductView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Get.dialog(const AddProductDialog());
    });
  }

  @override
  Widget build(BuildContext context) => const ProductsView();
}

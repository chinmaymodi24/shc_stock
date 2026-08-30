import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/products/views/add_product_dialog.dart';
import 'package:shc_stock/app/modules/stock/models/stock_item_model.dart';
import 'package:shc_stock/app/modules/stock/views/stock_item_details_panel.dart';
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';

/// The four row actions a product supports, defined once so the web table and
/// the mobile card can't drift apart on what a button does.
class ProductActions {
  const ProductActions._();

  /// Opens the same details panel the Inventory page uses — a product and its
  /// inventory row are the same record seen from two pages.
  static void view(ProductModel product) {
    Get.dialog(
      StockItemDetailsPanel(
        item: StockItemModel.fromProduct(product),
        onEdit: () {
          Get.back();
          edit(product);
        },
        onDelete: () {
          Get.back();
          delete(Get.context!, product);
        },
      ),
    );
  }

  static void edit(ProductModel product) =>
      Get.dialog(AddProductDialog(product: product));

  /// Pre-fills Add Product from this one but saves as a new record — the
  /// product duplicated from is never touched.
  static void duplicate(ProductModel product) =>
      Get.dialog(AddProductDialog(product: product, duplicate: true));

  static void delete(BuildContext context, ProductModel product) =>
      confirmDelete(
        context,
        itemName: product.name,
        itemLabel: 'Product',
        onConfirm: () =>
            Get.find<ProductsController>().deleteProduct(product.id),
      );
}

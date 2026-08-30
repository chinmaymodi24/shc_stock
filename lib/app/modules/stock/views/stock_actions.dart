import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/core/utils/stock_sync.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/products/views/add_product_dialog.dart';
import 'package:shc_stock/app/modules/stock/models/stock_item_model.dart';
import 'package:shc_stock/app/modules/stock/views/stock_item_details_panel.dart';
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';

/// The row actions an inventory item supports, defined once so the web table
/// and the mobile card can't drift apart on what a button does.
///
/// An inventory row IS a product — Edit/Duplicate/Delete all go through
/// ProductsController and then [refreshStockViews] so the inventory list and
/// its KPI cards pick up the change.
class StockActions {
  const StockActions._();

  static ProductsController _products() {
    if (!Get.isRegistered<ProductsController>()) {
      Get.put(ProductsController(), permanent: true);
    }
    return Get.find<ProductsController>();
  }

  /// The product behind this inventory row, or null if the products list
  /// hasn't been loaded far enough to hold it yet.
  static ProductModel? productFor(StockItemModel item) => _products()
      .products
      .firstWhereOrNull((p) => p.id == item.productId.toString());

  static void _needsProduct() => showAppToast(
    'Product Not Loaded',
    'Open the Products page once so this item can be edited.',
    backgroundColor: const Color(0xFFEF4444),
    colorText: Colors.white,
  );

  static void view(BuildContext context, StockItemModel item) {
    Get.dialog(
      StockItemDetailsPanel(
        item: item,
        onEdit: () {
          Get.back();
          edit(item);
        },
        onDelete: () {
          Get.back();
          delete(context, item);
        },
      ),
    );
  }

  static void edit(StockItemModel item) {
    final product = productFor(item);
    if (product == null) return _needsProduct();
    Get.dialog(AddProductDialog(product: product));
  }

  static void duplicate(StockItemModel item) {
    final product = productFor(item);
    if (product == null) return _needsProduct();
    Get.dialog(AddProductDialog(product: product, duplicate: true));
  }

  static void delete(BuildContext context, StockItemModel item) =>
      confirmDelete(
        context,
        itemName: item.name,
        itemLabel: 'Product',
        onConfirm: () async {
          await _products().deleteProduct(item.productId.toString());
          await refreshStockViews();
        },
      );
}

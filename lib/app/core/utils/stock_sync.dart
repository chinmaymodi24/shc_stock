import 'package:get/get.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/stock/controllers/stock_controller.dart';

/// Purchases add stock and sales remove it, server-side. The Inventory and
/// Products lists are fetch-once caches, so after any order write they'd still
/// be showing the pre-move quantities — this pulls them back in line.
///
/// Only refreshes controllers that are actually registered, so calling it from
/// Purchase/Sales never forces those modules to load.
Future<void> refreshStockViews() async {
  final futures = <Future<void>>[];
  if (Get.isRegistered<StockController>()) {
    futures.add(Get.find<StockController>().fetchItems());
  }
  if (Get.isRegistered<ProductsController>()) {
    futures.add(Get.find<ProductsController>().fetchProducts());
  }
  await Future.wait(futures);
}

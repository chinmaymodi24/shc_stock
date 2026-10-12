import 'package:get/get.dart';
import 'package:shc_stock/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/stock/controllers/stock_controller.dart';
import 'package:shc_stock/app/modules/transactions/controllers/transactions_controller.dart';

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
  // A fully-paid purchase and every payment on a sale leave rows in
  // Transactions, and a new or
  // changed purchase moves what Incoming deliveries and the dashboard cards
  // show — all fetch-once caches too.
  if (Get.isRegistered<TransactionsController>()) {
    final t = Get.find<TransactionsController>();
    futures.add(t.fetchTransactions());
    futures.add(t.fetchStats());
  }
  if (Get.isRegistered<DashboardController>()) {
    futures.add(Get.find<DashboardController>().fetchDashboard());
  }
  await Future.wait(futures);
}

import 'package:get/get.dart';
import 'package:shc_stock/app/modules/stock/controllers/stock_controller.dart';

class StockBinding extends Bindings {
  @override
  void dependencies() {
    // permanent: true — fetched once from /api/inventory and kept alive for
    // the whole app session. Purchases and sales refresh it through
    // refreshStockViews() rather than it refetching on every route entry.
    if (!Get.isRegistered<StockController>()) {
      Get.put(StockController(), permanent: true);
    }
  }
}

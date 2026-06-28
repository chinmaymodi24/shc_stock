import 'package:get/get.dart';
import '../modules/stock/controllers/stock_controller.dart';

class StockBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StockController>(() => StockController(), fenix: true);
  }
}

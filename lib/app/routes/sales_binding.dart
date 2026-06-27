import 'package:get/get.dart';
import '../modules/sales/controllers/sales_controller.dart';

class SalesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SalesController>(() => SalesController(), fenix: true);
  }
}

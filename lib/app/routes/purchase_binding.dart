import 'package:get/get.dart';
import '../modules/purchase/controllers/purchase_controller.dart';

class PurchaseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PurchaseController>(() => PurchaseController(), fenix: true);
  }
}

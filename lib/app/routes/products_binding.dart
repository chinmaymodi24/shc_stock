import 'package:get/get.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';

class ProductsBinding extends Bindings {
  @override
  void dependencies() {
    // permanent: true — fetched once from the API and kept alive for the
    // whole app session so navigating away and back doesn't clear the list
    // and re-trigger a fetch. Only inserts/updates/deletes touch the list
    // after that (see ProductsController.addProduct/updateProduct/deleteProduct).
    if (!Get.isRegistered<ProductsController>()) {
      Get.put(ProductsController(), permanent: true);
    }
  }
}

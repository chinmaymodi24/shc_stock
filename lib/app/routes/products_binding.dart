import 'package:get/get.dart';
import '../modules/products/controllers/products_controller.dart';
import '../modules/products/controllers/add_product_form_controller.dart';

class ProductsBinding extends Bindings {
  @override
  void dependencies() {
    // fenix: true — recreates if deleted, prevents "not found" on back-navigation
    Get.lazyPut<ProductsController>(() => ProductsController(), fenix: true);
    // Fresh per visit — not fenix, so it's disposed when the Add Item page closes.
    Get.lazyPut<AddProductFormController>(() => AddProductFormController());
  }
}

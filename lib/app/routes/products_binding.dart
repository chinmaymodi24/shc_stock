import 'package:get/get.dart';
import '../modules/products/controllers/products_controller.dart';

class ProductsBinding extends Bindings {
  @override
  void dependencies() {
    // fenix: true — recreates if deleted, prevents "not found" on back-navigation
    Get.lazyPut<ProductsController>(
      () => ProductsController(),
      fenix: true,
    );
  }
}

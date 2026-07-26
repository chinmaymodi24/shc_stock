import 'package:get/get.dart';
import '../modules/categories/controllers/categories_controller.dart';

class CategoriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoriesController>(
      () => CategoriesController(),
      fenix: true,
    );
  }
}

import 'package:get/get.dart';
import 'package:shc_stock/app/modules/categories/controllers/categories_controller.dart';

class CategoriesBinding extends Bindings {
  @override
  void dependencies() {
    // permanent: true — fetched once from the API and kept alive for the
    // whole app session so navigating away and back doesn't clear the list
    // and re-trigger a fetch. Only inserts/updates/deletes touch the list
    // after that (see CategoriesController's CRUD methods).
    if (!Get.isRegistered<CategoriesController>()) {
      Get.put(CategoriesController(), permanent: true);
    }
  }
}

import 'package:get/get.dart';
import '../modules/purchase/controllers/purchase_controller.dart';
import '../modules/purchase/controllers/add_purchase_controller.dart';
import '../modules/purchase/controllers/mobile_add_purchase_controller.dart';
import '../modules/products/controllers/products_controller.dart';
import '../modules/clients/controllers/clients_controller.dart';

class PurchaseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PurchaseController>(() => PurchaseController(), fenix: true);
    // The Add Purchase form's item autocomplete needs this for HSN/grade/
    // density/UoM/cost-price lookup, independent of whether the Products
    // module was visited first.
    Get.lazyPut<ProductsController>(() => ProductsController(), fenix: true);
    // The Add Purchase form's client autocomplete needs the universal client
    // list, independent of whether the Clients module was visited first.
    Get.lazyPut<ClientsController>(() => ClientsController(), fenix: true);
    // Fresh per visit — not fenix, so it's disposed when the Add Purchase page closes.
    Get.lazyPut<AddPurchaseController>(() => AddPurchaseController());
    Get.lazyPut<MobileAddPurchaseController>(
      () => MobileAddPurchaseController(),
    );
  }
}

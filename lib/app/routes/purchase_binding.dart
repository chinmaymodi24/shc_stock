import 'package:get/get.dart';
import 'package:shc_stock/app/modules/purchase/controllers/purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/controllers/add_purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/controllers/mobile_add_purchase_controller.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';

class PurchaseBinding extends Bindings {
  @override
  void dependencies() {
    // permanent: true — fetched once from the API and kept alive for the
    // whole app session (see ProductsBinding's comment for why).
    if (!Get.isRegistered<PurchaseController>()) {
      Get.put(PurchaseController(), permanent: true);
    }
    // The Add Purchase form's item autocomplete needs this for HSN/grade/
    // density/UoM/cost-price lookup, independent of whether the Products
    // module was visited first. permanent: true — same shared, fetch-once
    // instance as ProductsBinding (see its comment for why).
    if (!Get.isRegistered<ProductsController>()) {
      Get.put(ProductsController(), permanent: true);
    }
    // The Add Purchase form's client autocomplete needs the universal client
    // list, independent of whether the Clients module was visited first.
    // permanent: true — same shared, fetch-once instance as ClientsBinding.
    if (!Get.isRegistered<ClientsController>()) {
      Get.put(ClientsController(), permanent: true);
    }
    // Fresh per visit — not fenix, so it's disposed when the Add Purchase page closes.
    Get.lazyPut<AddPurchaseController>(() => AddPurchaseController());
    Get.lazyPut<MobileAddPurchaseController>(
      () => MobileAddPurchaseController(),
    );
  }
}

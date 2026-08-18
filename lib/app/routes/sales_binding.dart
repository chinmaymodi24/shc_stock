import 'package:get/get.dart';
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/controllers/add_sale_controller.dart';
import 'package:shc_stock/app/modules/sales/controllers/mobile_add_sale_controller.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';

class SalesBinding extends Bindings {
  @override
  void dependencies() {
    // permanent: true — fetched once from the API and kept alive for the
    // whole app session (see ProductsBinding's comment for why).
    if (!Get.isRegistered<SalesController>()) {
      Get.put(SalesController(), permanent: true);
    }
    // The Add Sell form needs these for the client dropdown and the
    // product autocomplete (HSN/SAC + rate lookup), independent of
    // whether the Clients/Products modules were visited first.
    // permanent: true — same shared, fetch-once instance as ClientsBinding.
    if (!Get.isRegistered<ClientsController>()) {
      Get.put(ClientsController(), permanent: true);
    }
    // permanent: true — same shared, fetch-once instance as ProductsBinding
    // (see its comment for why).
    if (!Get.isRegistered<ProductsController>()) {
      Get.put(ProductsController(), permanent: true);
    }
    // Fresh per visit — not fenix, so it's disposed when the Add Sell page closes.
    // Any leftover instance is dropped first: the same form is used for
    // "New Sale" and for editing an existing order (opened with the order as
    // the route argument), so a survivor from a previous visit would carry
    // the last order's values — and its `editing` flag — into the next one.
    if (Get.isRegistered<AddSaleController>()) {
      Get.delete<AddSaleController>(force: true);
    }
    Get.lazyPut<AddSaleController>(() => AddSaleController());
    Get.lazyPut<MobileAddSaleController>(() => MobileAddSaleController());
  }
}

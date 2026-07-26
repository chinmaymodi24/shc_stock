import 'package:get/get.dart';
import '../modules/sales/controllers/sales_controller.dart';
import '../modules/sales/controllers/add_sale_controller.dart';
import '../modules/sales/controllers/mobile_add_sale_controller.dart';
import '../modules/clients/controllers/clients_controller.dart';
import '../modules/products/controllers/products_controller.dart';

class SalesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SalesController>(() => SalesController(), fenix: true);
    // The Add Sell form needs these for the client dropdown and the
    // product autocomplete (HSN/SAC + rate lookup), independent of
    // whether the Clients/Products modules were visited first.
    Get.lazyPut<ClientsController>(() => ClientsController(), fenix: true);
    Get.lazyPut<ProductsController>(() => ProductsController(), fenix: true);
    // Fresh per visit — not fenix, so it's disposed when the Add Sell page closes.
    Get.lazyPut<AddSaleController>(() => AddSaleController());
    Get.lazyPut<MobileAddSaleController>(() => MobileAddSaleController());
  }
}

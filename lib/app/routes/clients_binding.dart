import 'package:get/get.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'package:shc_stock/app/modules/clients/controllers/add_client_controller.dart';

class ClientsBinding extends Bindings {
  @override
  void dependencies() {
    // permanent: true — fetched once from the API and kept alive for the
    // whole app session, so re-entering the Clients route (or opening it from
    // Purchase/Sales) reuses the loaded list instead of refetching. Refresh
    // only happens after an insert/update/delete.
    if (!Get.isRegistered<ClientsController>()) {
      Get.put(ClientsController(), permanent: true);
    }
    // Fresh per visit — not fenix, so it's disposed when the Add Client page closes.
    Get.lazyPut<AddClientController>(() => AddClientController());
  }
}

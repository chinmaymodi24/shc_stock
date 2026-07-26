import 'package:get/get.dart';
import '../modules/clients/controllers/clients_controller.dart';
import '../modules/clients/controllers/add_client_controller.dart';

class ClientsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClientsController>(() => ClientsController(), fenix: true);
    // Fresh per visit — not fenix, so it's disposed when the Add Client page closes.
    Get.lazyPut<AddClientController>(() => AddClientController());
  }
}

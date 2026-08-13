import 'package:get/get.dart';
import 'package:shc_stock/app/modules/users/controllers/users_controller.dart';
import 'package:shc_stock/app/modules/users/controllers/add_employee_wizard_controller.dart';

class UsersBinding extends Bindings {
  @override
  void dependencies() {
    // permanent: true — fetched once from /api/users and kept alive for the
    // whole app session; refreshed only after an insert/update/delete.
    if (!Get.isRegistered<UsersController>()) {
      Get.put(UsersController(), permanent: true);
    }
    // Fresh per visit — not fenix, so it's disposed when the wizard closes.
    Get.lazyPut<AddEmployeeWizardController>(
      () => AddEmployeeWizardController(),
    );
  }
}

import 'package:get/get.dart';
import '../modules/users/controllers/users_controller.dart';
import '../modules/users/controllers/add_employee_wizard_controller.dart';

class UsersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UsersController>(() => UsersController(), fenix: true);
    // Fresh per visit — not fenix, so it's disposed when the wizard closes.
    Get.lazyPut<AddEmployeeWizardController>(
      () => AddEmployeeWizardController(),
    );
  }
}

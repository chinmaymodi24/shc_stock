import 'package:get/get.dart';
import 'package:shc_stock/app/modules/users/controllers/users_controller.dart';
import 'package:shc_stock/app/modules/users/controllers/add_employee_wizard_controller.dart';

/// permanent: true — fetched once from /api/users and kept alive for the
/// whole app session; refreshed only after an insert/update/delete.
void _ensureUsersController() {
  if (!Get.isRegistered<UsersController>()) {
    Get.put(UsersController(), permanent: true);
  }
}

/// Employee list route.
class UsersBinding extends Bindings {
  @override
  void dependencies() => _ensureUsersController();
}

/// Add / Edit / Duplicate employee wizard route.
///
/// Deliberately separate from [UsersBinding], and deliberately not a
/// `lazyPut`:
///
///  * Sharing one binding with the list route meant every visit to the list
///    touched the wizard's registration while the wizard could still be on
///    screen (the sidebar leaves the wizard with `Get.offNamed`).
///  * A `lazyPut` only replaces an existing registration when GetX has
///    already marked it dirty. Coming back to the wizard a second time could
///    therefore hand back the *previous* visit's controller after GetX had
///    closed it — every TextEditingController in step 1 was already disposed,
///    so the fields rendered as red "A TextEditingController was used after
///    being disposed" boxes.
///
/// So the wizard gets a guaranteed fresh instance on every entry, which is
/// also what the form needs: it loads from `Get.arguments` in `onInit`.
class AddEmployeeBinding extends Bindings {
  @override
  void dependencies() {
    _ensureUsersController();
    if (Get.isRegistered<AddEmployeeWizardController>() ||
        Get.isPrepared<AddEmployeeWizardController>()) {
      Get.delete<AddEmployeeWizardController>(force: true);
    }
    Get.put(AddEmployeeWizardController());
  }
}

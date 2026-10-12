import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/users/controllers/add_employee_wizard_controller.dart';
import 'package:shc_stock/app/modules/users/controllers/users_controller.dart';
import 'package:shc_stock/app/routes/users_binding.dart';

// The wizard route used to share UsersBinding's lazyPut. Re-entering the
// wizard (Employee → Edit, then back, then Edit again) could hand back the
// previous visit's controller after GetX had closed it, and every field in
// step 1 rendered as a red "A TextEditingController was used after being
// disposed" box.
class _OfflineUsersController extends UsersController {
  @override
  Future<void> fetchUsers() async {}
  @override
  Future<void> fetchRoles() async {}
  @override
  Future<void> fetchStats() async {}
}

void main() {
  setUp(() {
    Get.reset();
    Get.put<UsersController>(_OfflineUsersController(), permanent: true);
  });

  tearDown(Get.reset);

  test('each visit to the wizard route gets a live controller', () {
    final binding = AddEmployeeBinding();

    binding.dependencies();
    final first = Get.find<AddEmployeeWizardController>();
    first.nameCtrl.text = 'Ravi Sharma';

    // The route closing: GetX disposes what the binding put.
    Get.delete<AddEmployeeWizardController>();

    binding.dependencies();
    final second = Get.find<AddEmployeeWizardController>();

    expect(identical(first, second), isFalse);
    // Would throw "used after being disposed" if the stale instance came back.
    second.nameCtrl.text = 'Priya Patel';
    expect(second.nameCtrl.text, 'Priya Patel');
  });

  test('re-entering without the route having been disposed still works', () {
    final binding = AddEmployeeBinding();

    binding.dependencies();
    final first = Get.find<AddEmployeeWizardController>();

    binding.dependencies();
    final second = Get.find<AddEmployeeWizardController>();

    expect(identical(first, second), isFalse);
    second.emailCtrl.text = 'priya@shc.com';
    expect(second.emailCtrl.text, 'priya@shc.com');
  });

  test('closing the controller twice is a no-op', () {
    final c = Get.put(AddEmployeeWizardController());
    c.onClose();
    expect(c.onClose, returnsNormally);
  });

  test('the list route leaves the wizard registration alone', () {
    AddEmployeeBinding().dependencies();
    final wizard = Get.find<AddEmployeeWizardController>();

    UsersBinding().dependencies();

    expect(identical(Get.find<AddEmployeeWizardController>(), wizard), isTrue);
    wizard.nameCtrl.text = 'still alive';
    expect(wizard.nameCtrl.text, 'still alive');
  });
}

import 'package:get/get.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';

/// Signs in a Super Admin for a widget test.
///
/// Every permission check fails closed when nobody is signed in, so a page
/// pumped without a session hides its summary cards and its add / edit /
/// delete actions. Tests that assert on those render as the one role that
/// holds everything.
void signInSuperAdmin() {
  Get.put(SessionController(), permanent: true).user.value = const SessionUser(
    id: 1,
    name: 'Administrator',
    email: 'admin@admin.com',
    role: 'Super Admin',
    isSuperAdmin: true,
    token: 'test-token',
  );
}

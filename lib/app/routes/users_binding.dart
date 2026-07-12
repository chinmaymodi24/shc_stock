import 'package:get/get.dart';
import '../modules/users/controllers/users_controller.dart';

class UsersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UsersController>(() => UsersController(), fenix: true);
  }
}

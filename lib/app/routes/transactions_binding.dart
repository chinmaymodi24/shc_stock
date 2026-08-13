import 'package:get/get.dart';
import 'package:shc_stock/app/modules/transactions/controllers/transactions_controller.dart';

class TransactionsBinding extends Bindings {
  @override
  void dependencies() {
    // permanent: true — fetched once from /api/transactions and kept alive for
    // the whole app session; refreshed only after an insert/update/delete.
    if (!Get.isRegistered<TransactionsController>()) {
      Get.put(TransactionsController(), permanent: true);
    }
  }
}

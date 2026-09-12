import 'package:get/get.dart';
import 'package:shc_stock/app/modules/billing/controllers/bill_controller.dart';

/// Binds one bill screen. The sale arrives as the route argument — the whole
/// [SalesOrder] when navigating from the list, or its id when arriving by URL.
///
/// Not permanent: a bill screen is opened for one sale at a time, and the next
/// one must not inherit the last one's document.
class BillingBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(BillController(Get.arguments));
  }
}

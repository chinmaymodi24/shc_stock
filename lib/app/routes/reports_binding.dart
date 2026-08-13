import 'package:get/get.dart';
import 'package:shc_stock/app/modules/reports/controllers/reports_controller.dart';

class ReportsBinding extends Bindings {
  @override
  void dependencies() {
    // Not permanent — a report is a point-in-time snapshot, so it should
    // re-run whenever the page is opened.
    Get.lazyPut<ReportsController>(() => ReportsController());
  }
}

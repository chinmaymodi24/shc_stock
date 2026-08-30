import 'package:get/get.dart';
import 'package:shc_stock/app/modules/reports/controllers/analytics_controller.dart';
import 'package:shc_stock/app/modules/reports/controllers/profit_loss_controller.dart';
import 'package:shc_stock/app/modules/reports/controllers/reports_controller.dart';

class ReportsBinding extends Bindings {
  @override
  void dependencies() {
    // Not permanent — a report is a point-in-time snapshot, so it should
    // re-run whenever the page is opened.
    Get.lazyPut<ReportsController>(() => ReportsController());
    // Lazy on purpose: opening Reports shouldn't cost three round trips. Each
    // controller fetches the first time its tab is actually built.
    Get.lazyPut<AnalyticsController>(() => AnalyticsController());
    Get.lazyPut<ProfitLossController>(() => ProfitLossController());
  }
}

import 'package:get/get.dart';
import 'package:shc_stock/app/modules/reports/controllers/analytics_controller.dart';
import 'package:shc_stock/app/modules/reports/controllers/profit_loss_controller.dart';
import 'package:shc_stock/app/modules/reports/controllers/reports_controller.dart';
import 'package:shc_stock/app/modules/reports/controllers/report_screen_controller.dart';
import 'package:shc_stock/app/modules/reports/models/report_catalog.dart';

/// Binds one report screen. The report key arrives as the route argument, so
/// the controller knows which statement to build before its first frame.
class ReportScreenBinding extends Bindings {
  @override
  void dependencies() {
    final key = Get.arguments as String? ?? 'profit-loss';
    final definition = reportByKey(key) ?? kReportCatalog.first;
    // Not permanent: a report is a point-in-time snapshot, so re-opening it
    // re-runs the query rather than showing yesterday's figures.
    Get.put(ReportScreenController(definition));
  }
}

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

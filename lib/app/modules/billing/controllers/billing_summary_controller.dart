import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/modules/billing/models/bill_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The Sale page's Billing card: how many sales are billed, how many are not,
// and how many invoices carry an IRN.
//
// Fetch-once and permanent, like every other list-page summary — it refetches
// when a bill is generated, not on every visit to the Sale page.
// ─────────────────────────────────────────────────────────────────────────────
class BillingSummaryController extends GetxController {
  static BillingSummaryController get to =>
      Get.find<BillingSummaryController>();

  final _api = ApiClient.instance;

  final Rx<BillingSummary> summary = BillingSummary.empty.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    isLoading.value = true;
    try {
      final json = await _api.get('/bills/summary');
      if (json is Map<String, dynamic>) {
        summary.value = BillingSummary.fromJson(json);
      }
    } catch (e) {
      // The card falls back to zeros; the Sale list has already reported any
      // backend outage of its own.
    } finally {
      isLoading.value = false;
    }
  }

  /// Refreshes the card if it is registered — called after a bill is issued.
  static void refreshIfLoaded() {
    if (Get.isRegistered<BillingSummaryController>()) to.fetch();
  }
}

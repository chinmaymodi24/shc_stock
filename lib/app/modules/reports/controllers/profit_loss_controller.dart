import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/reports/models/analytics_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reports → Profit & Loss.
//
// GET /api/stats/profit-loss returns a 12-month gross-profit statement built
// off the sale lines: revenue is qty × rate, COGS is qty × the product's cost
// price. Operating expenses aren't modelled anywhere in the system, so the
// statement stops at gross profit rather than inventing a net line.
// ─────────────────────────────────────────────────────────────────────────────
class ProfitLossController extends GetxController {
  final _api = ApiClient.instance;

  final RxBool isLoading = true.obs;

  final RxList<ProfitLossMonth> months = <ProfitLossMonth>[].obs;
  final RxList<ProfitLossProduct> topProducts = <ProfitLossProduct>[].obs;

  final RxDouble revenue = 0.0.obs;
  final RxDouble cogs = 0.0.obs;
  final RxDouble grossProfit = 0.0.obs;
  final RxDouble purchases = 0.0.obs;
  final RxDouble marginPct = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfitLoss();
  }

  double _num(dynamic v) => (v as num?)?.toDouble() ?? 0;

  Future<void> fetchProfitLoss() async {
    isLoading.value = true;
    try {
      final json = await _api.get('/stats/profit-loss') as Map<String, dynamic>;

      months.assignAll(
        ((json['months'] as List?) ?? []).map(
          (e) => ProfitLossMonth.fromJson(e as Map<String, dynamic>),
        ),
      );
      topProducts.assignAll(
        ((json['topProducts'] as List?) ?? []).map(
          (e) => ProfitLossProduct.fromJson(e as Map<String, dynamic>),
        ),
      );

      final totals = json['totals'] as Map<String, dynamic>? ?? {};
      revenue.value = _num(totals['revenue']);
      cogs.value = _num(totals['cogs']);
      grossProfit.value = _num(totals['grossProfit']);
      purchases.value = _num(totals['purchases']);
      marginPct.value = _num(totals['marginPct']);
    } catch (e) {
      showAppToast(
        'Error',
        'Failed to load the profit & loss statement. Is the backend running?',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}

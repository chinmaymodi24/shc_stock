import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';

/// A single line of a report section.
class ReportLine {
  final String label;
  final String value;
  const ReportLine(this.label, this.value);
}

/// A ranked row (top products / top clients).
class ReportRank {
  final String name;
  final String detail;
  final String value;
  const ReportRank({
    required this.name,
    required this.detail,
    required this.value,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Reports.
//
// Backed by GET /api/stats/reports, which consolidates sales, purchase, stock
// and client figures over an optional date range. The sidebar had a Reports
// link but no page registered behind it, so the route was dead.
// ─────────────────────────────────────────────────────────────────────────────
class ReportsController extends GetxController {
  final _api = ApiClient.instance;

  final RxBool isLoading = false.obs;
  final Rx<DateTime?> from = Rx<DateTime?>(null);
  final Rx<DateTime?> to = Rx<DateTime?>(null);

  final RxList<ReportLine> salesLines = <ReportLine>[].obs;
  final RxList<ReportLine> purchaseLines = <ReportLine>[].obs;
  final RxList<ReportLine> stockLines = <ReportLine>[].obs;
  final RxList<ReportRank> topProducts = <ReportRank>[].obs;
  final RxList<ReportRank> topClients = <ReportRank>[].obs;
  final RxString netMovement = '—'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchReport();
  }

  String _money(num? v) {
    // Local import-free rupee formatting is handled by the view; keep the raw
    // number here so the view can format it consistently with everything else.
    return (v ?? 0).toStringAsFixed(2);
  }

  Future<void> fetchReport() async {
    isLoading.value = true;
    try {
      final params = <String>[];
      if (from.value != null) {
        params.add('from=${from.value!.toIso8601String()}');
      }
      if (to.value != null) params.add('to=${to.value!.toIso8601String()}');
      final query = params.isEmpty ? '' : '?${params.join('&')}';

      final json =
          await _api.get('/stats/reports$query') as Map<String, dynamic>;

      final sales = json['sales'] as Map<String, dynamic>? ?? {};
      final purchase = json['purchase'] as Map<String, dynamic>? ?? {};
      final stock = json['stock'] as Map<String, dynamic>? ?? {};

      salesLines.assignAll([
        ReportLine('Orders', '${sales['orders'] ?? 0}'),
        ReportLine('Total Sales', _money(sales['total'] as num?)),
        ReportLine('Receivable', _money(sales['receivable'] as num?)),
        ReportLine(
          'Average Order Value',
          _money(sales['averageOrderValue'] as num?),
        ),
      ]);
      purchaseLines.assignAll([
        ReportLine('Orders', '${purchase['orders'] ?? 0}'),
        ReportLine('Total Purchases', _money(purchase['total'] as num?)),
        ReportLine('Payable', _money(purchase['payable'] as num?)),
      ]);
      stockLines.assignAll([
        ReportLine('Products', '${stock['products'] ?? 0}'),
        ReportLine('Stock Value', _money(stock['totalValue'] as num?)),
        ReportLine('Low Stock', '${stock['lowStock'] ?? 0}'),
        ReportLine('Out of Stock', '${stock['outOfStock'] ?? 0}'),
      ]);
      netMovement.value = _money(json['netMovement'] as num?);

      topProducts.assignAll(
        ((json['topProducts'] as List?) ?? []).map((e) {
          final m = e as Map<String, dynamic>;
          return ReportRank(
            name: m['product'] as String? ?? '',
            detail: 'units sold',
            value: (m['qty'] as num?)?.toStringAsFixed(0) ?? '0',
          );
        }),
      );
      topClients.assignAll(
        ((json['topClients'] as List?) ?? []).map((e) {
          final m = e as Map<String, dynamic>;
          return ReportRank(
            name: m['client'] as String? ?? '',
            detail: '${m['orders'] ?? 0} orders',
            value: _money(m['total'] as num?),
          );
        }),
      );
    } catch (e) {
      showAppToast(
        'Error',
        'Failed to load the report. Is the backend running?',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: from.value != null && to.value != null
          ? DateTimeRange(start: from.value!, end: to.value!)
          : null,
    );
    if (picked == null) return;
    from.value = picked.start;
    to.value = picked.end;
    await fetchReport();
  }

  Future<void> clearRange() async {
    from.value = null;
    to.value = null;
    await fetchReport();
  }
}

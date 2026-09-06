import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/export/statement.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/reports/models/report_catalog.dart';
import 'package:shc_stock/app/modules/reports/models/report_period.dart';

// ─────────────────────────────────────────────────────────────────────────────
// One controller behind the report shell.
//
// It knows which report is open, which period is selected, and how to turn the
// backend's numbers into a [StatementDoc] — the single model the on-screen
// sheet and the exported PDF both render.
// ─────────────────────────────────────────────────────────────────────────────
class ReportScreenController extends GetxController {
  final ReportDefinition definition;

  ReportScreenController(this.definition);

  final _api = ApiClient.instance;

  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  late final Rx<ReportPeriod> period = ReportPeriod.currentFinancialYear().obs;
  final Rx<StatementDoc> statement = StatementDoc.empty.obs;

  bool get isAsOnDate => definition.basis == ReportBasis.asOnDate;

  /// What the toolbar's selector button shows.
  String get periodButtonLabel =>
      isAsOnDate ? period.value.asOnLabel : period.value.label;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> setPeriod(ReportPeriod next) async {
    period.value = next;
    await load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      statement.value = switch (definition.key) {
        'profit-loss' => await _fetchProfitAndLoss(),
        'balance-sheet' => await _fetchBalanceSheet(),
        _ => StatementDoc.empty,
      };
    } catch (e) {
      error.value = 'Could not load this report. Is the backend running?';
      statement.value = StatementDoc.empty;
      showAppToast(
        'Error',
        error.value,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  double _num(dynamic v) => (v as num?)?.toDouble() ?? 0;

  String _query() {
    final p = period.value;
    if (isAsOnDate) return '?asOn=${p.to.toIso8601String()}';
    return '?from=${p.from.toIso8601String()}&to=${p.to.toIso8601String()}';
  }

  // ── Profit & Loss ─────────────────────────────────────────────────────────
  Future<StatementDoc> _fetchProfitAndLoss() async {
    final json =
        await _api.get('/statements/profit-and-loss${_query()}')
            as Map<String, dynamic>;

    final income = json['income'] as Map<String, dynamic>? ?? {};
    final cogs = json['cogs'] as Map<String, dynamic>? ?? {};
    final expenses = json['operatingExpenses'] as Map<String, dynamic>? ?? {};

    final salesRevenue = _num(income['salesRevenue']);
    final totalIncome = _num(income['total']);
    final openingStock = _num(cogs['openingStock']);
    final purchases = _num(cogs['purchases']);
    final closingStock = _num(cogs['closingStock']);
    final totalCogs = _num(cogs['total']);
    final grossProfit = _num(json['grossProfit']);
    final netProfit = _num(json['netProfit']);
    final expensesModelled = expenses['modelled'] == true;

    return StatementDoc(
      companyName: kCompanyName,
      title: 'Profit & Loss Statement',
      periodLine: period.value.statementLine,
      kpis: [
        StatementKpi('Total Income', formatRupeesCompact(totalIncome)),
        StatementKpi('Total COGS', formatRupeesCompact(totalCogs)),
        StatementKpi(
          'Operating Expenses',
          expensesModelled ? formatRupeesCompact(_num(expenses['total'])) : '—',
        ),
        StatementKpi(
          'Net Profit',
          formatRupeesCompact(netProfit),
          positive: true,
        ),
      ],
      rows: [
        const StatementRow.section('Income'),
        StatementRow.item('Sales Revenue', salesRevenue, drillKey: 'sales'),
        if (income['otherIncomeModelled'] != true)
          const StatementRow.note(
            'Other income is not recorded in this system, so no figure is '
            'shown for it.',
          ),
        StatementRow.subtotal('Total Income', totalIncome),
        const StatementRow.spacer(),

        const StatementRow.section('Cost of Goods Sold'),
        StatementRow.item('Opening Stock', openingStock, drillKey: 'inventory'),
        StatementRow.item('Purchases', purchases, drillKey: 'purchase'),
        StatementRow.item(
          'Less: Closing Stock',
          closingStock,
          negative: true,
          drillKey: 'inventory',
        ),
        StatementRow.subtotal('Total COGS', totalCogs),
        const StatementRow.spacer(),

        StatementRow.derived('Gross Profit', grossProfit),
        const StatementRow.spacer(),

        const StatementRow.section('Operating Expenses'),
        if (!expensesModelled)
          const StatementRow.note(
            'Salaries, freight, rent and other operating expenses are not '
            'recorded anywhere in this system yet, so net profit below equals '
            'gross profit.',
          ),
        StatementRow.result('Net Profit', netProfit),
      ],
    );
  }

  // ── Balance Sheet ─────────────────────────────────────────────────────────
  Future<StatementDoc> _fetchBalanceSheet() async {
    final json =
        await _api.get('/statements/balance-sheet${_query()}')
            as Map<String, dynamic>;

    final assets = json['assets'] as Map<String, dynamic>? ?? {};
    final liabilities = json['liabilities'] as Map<String, dynamic>? ?? {};

    final closingStock = _num(assets['closingStock']);
    final receivables = _num(assets['tradeReceivables']);
    final cash = _num(assets['cashMovement']);
    final totalAssets = _num(assets['total']);
    final payables = _num(liabilities['tradePayables']);
    final ownersFunds = _num(liabilities['ownersFunds']);
    final totalLiabilities = _num(liabilities['total']);
    final balanced = json['balanced'] == true;

    return StatementDoc(
      companyName: kCompanyName,
      title: 'Balance Sheet',
      periodLine: period.value.asOnLine,
      kpis: [
        StatementKpi('Total Assets', formatRupeesCompact(totalAssets)),
        StatementKpi('Trade Receivables', formatRupeesCompact(receivables)),
        StatementKpi('Trade Payables', formatRupeesCompact(payables)),
        StatementKpi(
          "Owner's Funds",
          formatRupeesCompact(ownersFunds),
          positive: true,
        ),
      ],
      rows: [
        const StatementRow.section('Equity & Liabilities'),
        StatementRow.item("Owner's Funds (net worth)", ownersFunds),
        StatementRow.item(
          'Trade Payables (Suppliers)',
          payables,
          drillKey: 'purchase',
        ),
        StatementRow.subtotal('Total Equity & Liabilities', totalLiabilities),
        const StatementRow.spacer(),

        const StatementRow.section('Assets'),
        StatementRow.item('Closing Stock', closingStock, drillKey: 'inventory'),
        StatementRow.item(
          'Trade Receivables (Clients)',
          receivables,
          drillKey: 'sales',
        ),
        StatementRow.item('Cash Movement (collected − paid)', cash),
        StatementRow.subtotal('Total Assets', totalAssets),
        const StatementRow.spacer(),

        if (json['fixedAssetsModelled'] != true)
          const StatementRow.note(
            "Owner's funds is derived as assets less outside liabilities. "
            'Fixed assets, loans and share capital have no source in this '
            'system, and cash is the net of what has been collected and paid '
            'rather than a bank balance.',
          ),
        StatementRow.result(
          balanced ? 'Balanced' : 'Out of balance — check the data',
          totalAssets,
        ),
      ],
    );
  }
}

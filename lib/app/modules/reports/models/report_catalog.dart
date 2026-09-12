import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/brand_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

/// The business this app runs for. Printed at the top of every statement.
/// The company the reports are FOR — the buyer's, not ours. Reads through to
/// the applied brand so exported PDFs and the catalog header carry whoever the
/// app was rebranded to.
String get kCompanyName => brand.companyName;

/// Whether a report covers a stretch of time or a single moment.
enum ReportBasis {
  /// "For the period 01 Apr 2025 to 31 Mar 2026" — P&L, registers.
  period,

  /// "As on 31 Mar 2026" — Balance Sheet, Stock Valuation.
  asOnDate,
}

/// The domains the catalog groups reports under.
enum ReportGroup { financial, inventory, salesPurchase }

extension ReportGroupX on ReportGroup {
  String get label => switch (this) {
    ReportGroup.financial => 'FINANCIAL',
    ReportGroup.inventory => 'INVENTORY',
    ReportGroup.salesPurchase => 'SALES & PURCHASE',
  };
}

/// One card in the Reports catalog, and the identity of the report behind it.
class ReportDefinition {
  /// Route argument and filename stem — "profit-loss".
  final String key;
  final String name;
  final String description;
  final IconData icon;

  /// Tint for the card's icon square. Kept per-report so the catalog reads as
  /// a set of distinct things rather than a wall of orange.
  final Color tint;
  final ReportGroup group;
  final ReportBasis basis;

  /// False while a report has no data source behind it yet. The catalog dims
  /// the card and says so, rather than opening an empty statement.
  final bool available;

  ReportDefinition({
    required this.key,
    required this.name,
    required this.description,
    required this.icon,
    required this.tint,
    required this.group,
    this.basis = ReportBasis.period,
    this.available = false,
  });
}

// Card tints — one per domain-ish role, taken from the brand so a rebrand
// recolours the catalog with everything else. Getters, not consts: the brand
// is a runtime value.
Color get _blue => appColors.info;
Color get _purple => appColors.accent;
Color get _green => appColors.success;
Color get _amber => appColors.warning;
Color get _red => appColors.error;

/// Every report the catalog offers.
///
/// Profit & Loss and Balance Sheet are the two built against the
/// `/api/statements` endpoints; the rest are declared here so the catalog is
/// complete and each one only needs its data source to go live.
List<ReportDefinition> kReportCatalog = [
  // ── Financial ─────────────────────────────────────────────────────────────
  ReportDefinition(
    key: 'profit-loss',
    name: 'Profit & Loss',
    description: 'Income, COGS, expenses and net profit',
    icon: Icons.receipt_long_outlined,
    tint: _amber,
    group: ReportGroup.financial,
    available: true,
  ),
  ReportDefinition(
    key: 'balance-sheet',
    name: 'Balance Sheet',
    description: 'Assets, liabilities and equity as on a date',
    icon: Icons.account_balance_outlined,
    tint: _blue,
    group: ReportGroup.financial,
    basis: ReportBasis.asOnDate,
    available: true,
  ),
  ReportDefinition(
    key: 'outstanding-dues',
    name: 'Outstanding Dues',
    description: 'Client-wise receivables with ageing',
    icon: Icons.payments_outlined,
    tint: _green,
    group: ReportGroup.financial,
    basis: ReportBasis.asOnDate,
  ),
  ReportDefinition(
    key: 'tax-summary',
    name: 'Tax Summary',
    description: 'Output and input GST for the period',
    icon: Icons.percent_rounded,
    tint: _purple,
    group: ReportGroup.financial,
  ),

  // ── Inventory ─────────────────────────────────────────────────────────────
  ReportDefinition(
    key: 'stock-valuation',
    name: 'Stock Valuation',
    description: 'Closing stock quantity and value by category',
    icon: Icons.inventory_2_outlined,
    tint: _blue,
    group: ReportGroup.inventory,
    basis: ReportBasis.asOnDate,
  ),
  ReportDefinition(
    key: 'low-stock',
    name: 'Low Stock',
    description: 'Items at or below reorder level',
    icon: Icons.warning_amber_rounded,
    tint: _red,
    group: ReportGroup.inventory,
    basis: ReportBasis.asOnDate,
  ),
  ReportDefinition(
    key: 'stock-movement',
    name: 'Stock Movement',
    description: 'Inward vs outward quantity per period',
    icon: Icons.swap_horiz_rounded,
    tint: _amber,
    group: ReportGroup.inventory,
  ),

  // ── Sales & Purchase ──────────────────────────────────────────────────────
  ReportDefinition(
    key: 'sales-register',
    name: 'Sales Register',
    description: 'Invoice-wise sales with taxable value and GST',
    icon: Icons.trending_up_rounded,
    tint: _green,
    group: ReportGroup.salesPurchase,
  ),
  ReportDefinition(
    key: 'purchase-register',
    name: 'Purchase Register',
    description: 'Supplier-wise purchase entries with tax breakup',
    icon: Icons.shopping_cart_outlined,
    tint: _amber,
    group: ReportGroup.salesPurchase,
  ),
  ReportDefinition(
    key: 'client-ledger',
    name: 'Client Ledger',
    description: 'Per-client transaction and payment history',
    icon: Icons.people_outline_rounded,
    tint: _purple,
    group: ReportGroup.salesPurchase,
  ),
];

ReportDefinition? reportByKey(String key) {
  for (final report in kReportCatalog) {
    if (report.key == key) return report;
  }
  return null;
}

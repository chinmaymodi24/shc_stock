// ─────────────────────────────────────────────────────────────────────────────
// Shapes behind the Reports → Analytics and Profit & Loss tabs.
//
// Everything here is a plain parse of GET /api/stats/analytics and
// GET /api/stats/profit-loss — no value is computed in the app, so a card can
// never drift from what the backend actually measured.
// ─────────────────────────────────────────────────────────────────────────────

/// One month on the "Sales vs Purchases" line chart.
class TrendPoint {
  final String label;
  final double sales;
  final double purchases;

  const TrendPoint({
    required this.label,
    required this.sales,
    required this.purchases,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) => TrendPoint(
    label: json['label'] as String? ?? '',
    sales: (json['sales'] as num?)?.toDouble() ?? 0,
    purchases: (json['purchases'] as num?)?.toDouble() ?? 0,
  );
}

/// One month on the "Stock Movement (Inflow vs Outflow)" bar chart.
class FlowPoint {
  final String label;
  final double inflow;
  final double outflow;

  const FlowPoint({
    required this.label,
    required this.inflow,
    required this.outflow,
  });

  factory FlowPoint.fromJson(Map<String, dynamic> json) => FlowPoint(
    label: json['label'] as String? ?? '',
    inflow: (json['inflow'] as num?)?.toDouble() ?? 0,
    outflow: (json['outflow'] as num?)?.toDouble() ?? 0,
  );
}

/// A row in "Top Selling Products" / "Top Clients by Revenue" — the label, the
/// raw number that sizes its bar, and the already-formatted readout.
class RankedRow {
  final String label;
  final double value;
  final String display;

  const RankedRow({
    required this.label,
    required this.value,
    required this.display,
  });
}

/// One age bucket of the receivables bar.
class AgingBucket {
  final String label;
  final double amount;

  const AgingBucket({required this.label, required this.amount});

  factory AgingBucket.fromJson(Map<String, dynamic> json) => AgingBucket(
    label: json['label'] as String? ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
  );
}

/// One tile of the "Revenue by Category" treemap.
class CategoryRevenue {
  final String category;
  final double amount;
  final double percent;

  const CategoryRevenue({
    required this.category,
    required this.amount,
    required this.percent,
  });

  factory CategoryRevenue.fromJson(Map<String, dynamic> json) =>
      CategoryRevenue(
        category: json['category'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        percent: (json['percent'] as num?)?.toDouble() ?? 0,
      );
}

/// One cell of the "Business Health Indicators" grid. [trend] is null when the
/// backend had no baseline to compare against — the cell then shows [caption]
/// on its own rather than a fabricated percentage.
class HealthIndicator {
  final String label;
  final String value;
  final String trend;
  final String caption;
  final bool trendUp;
  final bool neutral;

  const HealthIndicator({
    required this.label,
    required this.value,
    this.trend = '',
    this.caption = '',
    this.trendUp = true,
    this.neutral = false,
  });
}

/// One month of the gross-profit statement.
class ProfitLossMonth {
  final String label;
  final double revenue;
  final double cogs;
  final double grossProfit;
  final double marginPct;
  final double purchases;

  const ProfitLossMonth({
    required this.label,
    required this.revenue,
    required this.cogs,
    required this.grossProfit,
    required this.marginPct,
    required this.purchases,
  });

  factory ProfitLossMonth.fromJson(Map<String, dynamic> json) =>
      ProfitLossMonth(
        label: json['label'] as String? ?? '',
        revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
        cogs: (json['cogs'] as num?)?.toDouble() ?? 0,
        grossProfit: (json['grossProfit'] as num?)?.toDouble() ?? 0,
        marginPct: (json['marginPct'] as num?)?.toDouble() ?? 0,
        purchases: (json['purchases'] as num?)?.toDouble() ?? 0,
      );
}

/// A product's contribution to gross profit.
class ProfitLossProduct {
  final String product;
  final double revenue;
  final double cogs;
  final double grossProfit;
  final double marginPct;

  const ProfitLossProduct({
    required this.product,
    required this.revenue,
    required this.cogs,
    required this.grossProfit,
    required this.marginPct,
  });

  factory ProfitLossProduct.fromJson(Map<String, dynamic> json) =>
      ProfitLossProduct(
        product: json['product'] as String? ?? '',
        revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
        cogs: (json['cogs'] as num?)?.toDouble() ?? 0,
        grossProfit: (json['grossProfit'] as num?)?.toDouble() ?? 0,
        marginPct: (json['marginPct'] as num?)?.toDouble() ?? 0,
      );
}

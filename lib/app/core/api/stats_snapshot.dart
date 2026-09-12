import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/session/app_modules.dart';

/// The summary-card payload from `/api/stats/<module>`.
///
/// Every list page's cards read their number *and* their month-over-month
/// trend from here, so nothing on those cards is computed in the app or
/// hardcoded. A trend of null means the backend had no baseline to compare
/// against (e.g. nothing existed last month) — the card then shows no
/// percentage at all rather than inventing one.
class StatsSnapshot {
  final Map<String, dynamic> values;
  final Map<String, dynamic> trends;

  const StatsSnapshot({this.values = const {}, this.trends = const {}});

  static const empty = StatsSnapshot();

  factory StatsSnapshot.fromJson(Map<String, dynamic> json) => StatsSnapshot(
    values: Map<String, dynamic>.from(json)..remove('trends'),
    trends: Map<String, dynamic>.from(
      (json['trends'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
  );

  /// `/stats/<name>` → the module whose Summary permission guards it.
  static const _moduleOf = {
    'categories': 'Categories',
    'products': 'Products',
    'purchase': 'Purchase',
    'sales': 'Sales',
    'inventory': 'Inventory',
    'clients': 'Clients',
    'transactions': 'Transactions',
    'users': 'Employee',
  };

  /// Fetches and parses `/stats/<module>`; returns [empty] on failure so the
  /// cards render zeros instead of throwing. Someone without the module's
  /// Summary permission gets [empty] without asking — the cards are hidden
  /// for them and the backend would refuse anyway.
  static Future<StatsSnapshot> fetch(String module) async {
    final gate = _moduleOf[module];
    if (gate != null && !canSeeSummary(gate)) return empty;
    final json = await ApiClient.instance.get('/stats/$module');
    return StatsSnapshot.fromJson(json as Map<String, dynamic>);
  }

  int intOf(String key) => (values[key] as num?)?.toInt() ?? 0;

  double doubleOf(String key) => (values[key] as num?)?.toDouble() ?? 0;

  /// Raw trend percentage, or null when there's no baseline.
  double? trendOf(String key) => (trends[key] as num?)?.toDouble();

  /// `+18.6%` / `-8.3%`, or '' when there's no baseline — [AppStatCard] hides
  /// the whole trend row on an empty string.
  String trendLabel(String key) {
    final t = trendOf(key);
    if (t == null) return '';
    final sign = t >= 0 ? '+' : '';
    return '$sign${t.toStringAsFixed(1)}%';
  }

  bool trendUp(String key) => (trendOf(key) ?? 0) >= 0;
}

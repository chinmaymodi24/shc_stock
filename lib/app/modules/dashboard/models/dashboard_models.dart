import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';

// ── Shared with mobile_dashboard_layout.dart / stat_card.dart — keep stable ──
class StatCardData {
  final String title;
  final String value;
  final String? change;
  final bool? isPositive;
  final StatCardIcon icon;

  const StatCardData({
    required this.title,
    required this.value,
    this.change,
    this.isPositive,
    required this.icon,
  });
}

enum StatCardIcon { box, warning, cart, chart }

// ── Dashboard-only models (web_dashboard_layout.dart) ────────────────────────

/// One of the 5 pastel-tinted summary tiles at the top of the dashboard.
class DashboardStatData {
  final String title;
  final String value;
  final String? change;
  final bool isPositive;
  final IconData icon;
  final Color iconColor;

  /// Drops the value to the smaller type size — for the tiles whose value is
  /// a rupee total or a product name rather than a short count, same as the
  /// list pages do for their "Total Value" card.
  final bool smallValue;

  const DashboardStatData({
    required this.title,
    required this.value,
    this.change,
    this.isPositive = true,
    required this.icon,
    required this.iconColor,
    this.smallValue = false,
  });
}

/// A single point on a bar or line chart (Purchases, Sales, New Clients).
class ChartPoint {
  final String label;
  final double value;

  const ChartPoint({required this.label, required this.value});
}

/// A colored slice — used by the "Sales by category" donut and the
/// Category Breakdown bar list, so both stay in sync from one dataset.
class CategorySlice {
  final String label;
  final double percent;
  final Color color;

  /// Stock value behind the slice, in rupees. Null when the source didn't
  /// send one — the hover tooltip then falls back to the percentage alone.
  final double? value;

  /// Overrides the legend's default "label — 25%" text. Inventory Health reads
  /// out counts ("In Stock  18"), not shares.
  final String? legendText;

  /// Overrides the hover tooltip's value line.
  final String? tooltipText;

  const CategorySlice({
    required this.label,
    required this.percent,
    required this.color,
    this.value,
    this.legendText,
    this.tooltipText,
  });

  /// What the hover tooltip reads out: the rupee value plus its share.
  String get tooltipValue {
    if (tooltipText != null) return tooltipText!;
    // Whole numbers, matching the legend and the breakdown rows — only a
    // sliver under 1% gets a decimal, so it doesn't read as "0%".
    final share = '${percent.toStringAsFixed(percent < 1 ? 1 : 0)}%';
    return value == null ? share : '${formatRupees(value!)} · $share';
  }
}

class TransactionRow {
  final String item;
  final String type; // Inbound / Outbound
  final String warehouse;
  final String date;
  final String status; // Received / Shipped / Pending / Delivered

  const TransactionRow({
    required this.item,
    required this.type,
    required this.warehouse,
    required this.date,
    required this.status,
  });
}

/// How a not-yet-done delivery is emphasized in the timeline — the next one
/// due stands out from everything further out.
enum DeliveryEmphasis { next, upcoming }

class DeliveryItem {
  final String item;
  final String poRef;
  final String warehouse;
  final String eta;
  final Color accentColor;
  final DeliveryEmphasis emphasis;

  /// Whether this delivery has been ticked off as arrived — shown checked
  /// off with a strike-through label. Toggleable by tapping its marker.
  final bool done;

  const DeliveryItem({
    required this.item,
    required this.poRef,
    required this.warehouse,
    required this.eta,
    required this.accentColor,
    this.emphasis = DeliveryEmphasis.upcoming,
    this.done = false,
  });

  DeliveryItem copyWith({bool? done}) => DeliveryItem(
    item: item,
    poRef: poRef,
    warehouse: warehouse,
    eta: eta,
    accentColor: accentColor,
    emphasis: emphasis,
    done: done ?? this.done,
  );
}

class LowStockAlertItem {
  final String product;
  final int current;
  final int max;

  const LowStockAlertItem({
    required this.product,
    required this.current,
    required this.max,
  });
}

/// A dashboard note / to-do, backed by GET /api/dashboard/notes.
class NoteItem {
  final int id;
  final String text;
  final bool done;

  const NoteItem({required this.id, required this.text, this.done = false});

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
    id: (json['id'] as num).toInt(),
    text: json['text'] as String? ?? '',
    done: json['done'] as bool? ?? false,
  );

  NoteItem copyWith({String? text, bool? done}) =>
      NoteItem(id: id, text: text ?? this.text, done: done ?? this.done);
}

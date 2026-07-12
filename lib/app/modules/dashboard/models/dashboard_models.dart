import 'package:flutter/material.dart';

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
  final Color bgColor;
  final Color iconColor;

  const DashboardStatData({
    required this.title,
    required this.value,
    this.change,
    this.isPositive = true,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
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

  const CategorySlice({required this.label, required this.percent, required this.color});
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

class DeliveryItem {
  final String item;
  final String poRef;
  final String warehouse;
  final String eta;
  final Color accentColor;

  const DeliveryItem({
    required this.item,
    required this.poRef,
    required this.warehouse,
    required this.eta,
    required this.accentColor,
  });
}

class LowStockAlertItem {
  final String product;
  final int current;
  final int max;

  const LowStockAlertItem({required this.product, required this.current, required this.max});
}

class NoteItem {
  final String text;
  bool done;

  NoteItem({required this.text, this.done = false});
}

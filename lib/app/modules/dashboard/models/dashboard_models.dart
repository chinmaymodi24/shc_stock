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

class TransactionData {
  final String type;
  final String invoiceNo;
  final String amount;
  final String date;

  const TransactionData({
    required this.type,
    required this.invoiceNo,
    required this.amount,
    required this.date,
  });
}

class LowStockItem {
  final String product;
  final int currentStock;
  final int minimumStock;

  const LowStockItem({
    required this.product,
    required this.currentStock,
    required this.minimumStock,
  });
}

class SalesChartPoint {
  final String label;
  final double value;

  const SalesChartPoint({required this.label, required this.value});
}

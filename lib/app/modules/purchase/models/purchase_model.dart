// Purchase Order model
class PurchaseOrder {
  final String id;
  final String poNumber;
  final String supplier;
  final String supplierIcon;
  final DateTime date;
  final int itemCount;
  final double amount;
  final PurchaseStatus status;
  final String modifiedBy;
  final DateTime? modifiedAt;

  const PurchaseOrder({
    required this.id,
    required this.poNumber,
    required this.supplier,
    required this.supplierIcon,
    required this.date,
    required this.itemCount,
    required this.amount,
    required this.status,
    this.modifiedBy = 'Admin',
    this.modifiedAt,
  });
}

enum PurchaseStatus { received, partial, pending, cancelled }

extension PurchaseStatusX on PurchaseStatus {
  String get label {
    switch (this) {
      case PurchaseStatus.received:
        return 'Received';
      case PurchaseStatus.partial:
        return 'Partial';
      case PurchaseStatus.pending:
        return 'Pending';
      case PurchaseStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// Purchase Item (for New Purchase Order form)
class PurchaseItem {
  String product;
  String description;
  String hsnSac;
  double qty;
  String unit;
  double rate;
  double gstPercent;

  PurchaseItem({
    this.product = '',
    this.description = '',
    this.hsnSac = '—',
    this.qty = 1,
    this.unit = '',
    this.rate = 0,
    this.gstPercent = 18,
  });

  double get amount => qty * rate;
  double get gstAmount => amount * gstPercent / 100;
  double get total => amount + gstAmount;
}

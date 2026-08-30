import 'package:shc_stock/app/shared/models/order_payment.dart';

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

  // ── Full invoice detail — populated when created via the "Add Purchase"
  // form; blank/empty on older/seed orders that predate this. The "View"
  // details panel falls back to "—" for anything missing.
  final String supplierAddress;
  final String buyerGst;
  final String pan;
  final String invoiceNo;
  final DateTime? invoiceDate;
  final String despatchThrough;
  final String lrNo;
  final DateTime? lrDate;
  final String vehicleNo;
  final double freight;
  final String placeOfSupply;
  final DateTime? dueDate;

  /// Optional. When set, the backend flips the order to Received on that date
  /// — which is what books the stock IN. Null leaves the status alone.
  final DateTime? expectedDelivery;

  /// How much of this order has been paid to the supplier.
  final OrderPaymentType paymentType;
  final double paidAmount;
  final List<PurchaseDetailItem> items;

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
    this.supplierAddress = '',
    this.buyerGst = '',
    this.pan = '',
    this.invoiceNo = '',
    this.invoiceDate,
    this.despatchThrough = '',
    this.lrNo = '',
    this.lrDate,
    this.vehicleNo = '',
    this.freight = 0,
    this.placeOfSupply = '',
    this.dueDate,
    this.expectedDelivery,
    this.paymentType = OrderPaymentType.none,
    this.paidAmount = 0,
    this.items = const [],
  });

  double get subTotal => items.fold(0.0, (s, i) => s + i.amount);
  double get sgst => subTotal * 0.09;
  double get cgst => subTotal * 0.09;

  /// Builds a [PurchaseOrder] from the backend `/purchase-orders` JSON shape.
  /// Units on the order — every line's quantity added up. The list's "Items"
  /// column reads this, so a single 5-unit line shows 5 there and 5 in the
  /// form; [itemCount] is the number of lines behind that number.
  double get totalQty => items.fold(0.0, (s, i) => s + i.qty);

  /// [totalQty] without a trailing `.0`, falling back to the line count for
  /// older records that were saved without their lines.
  String get totalQtyLabel {
    if (items.isEmpty) return '$itemCount';
    final q = totalQty;
    return q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toStringAsFixed(2);
  }

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.parse(v as String);
    return PurchaseOrder(
      id: (json['id'] as int).toString(),
      poNumber: json['poNumber'] as String? ?? '',
      supplier: json['supplier'] as String? ?? '',
      supplierIcon: json['supplierIcon'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      itemCount: (json['items'] as List<dynamic>? ?? []).length,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: PurchaseStatus.values.firstWhere(
        (s) => s.label == json['status'],
        orElse: () => PurchaseStatus.pending,
      ),
      modifiedBy: json['modifiedBy'] as String? ?? 'Admin',
      modifiedAt: parseDate(json['modifiedAt']),
      supplierAddress: json['supplierAddress'] as String? ?? '',
      buyerGst: json['buyerGst'] as String? ?? '',
      pan: json['pan'] as String? ?? '',
      invoiceNo: json['invoiceNo'] as String? ?? '',
      invoiceDate: parseDate(json['invoiceDate']),
      despatchThrough: json['despatchThrough'] as String? ?? '',
      lrNo: json['lrNo'] as String? ?? '',
      lrDate: parseDate(json['lrDate']),
      vehicleNo: json['vehicleNo'] as String? ?? '',
      freight: (json['freight'] as num?)?.toDouble() ?? 0,
      placeOfSupply: json['placeOfSupply'] as String? ?? '',
      dueDate: parseDate(json['dueDate']),
      expectedDelivery: parseDate(json['expectedDelivery']),
      paymentType: orderPaymentTypeFrom(json['paymentType'] as String?),
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => PurchaseDetailItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Body for `POST /purchase-orders`.
  Map<String, dynamic> toCreateJson() => {
    'poNumber': poNumber,
    'supplier': supplier,
    'supplierIcon': supplierIcon,
    'date': date.toIso8601String(),
    'amount': amount,
    'status': status.label,
    'modifiedBy': modifiedBy,
    'supplierAddress': supplierAddress,
    'buyerGst': buyerGst,
    'pan': pan,
    'invoiceNo': invoiceNo,
    if (invoiceDate != null) 'invoiceDate': invoiceDate!.toIso8601String(),
    'despatchThrough': despatchThrough,
    'lrNo': lrNo,
    if (lrDate != null) 'lrDate': lrDate!.toIso8601String(),
    'vehicleNo': vehicleNo,
    'freight': freight,
    'placeOfSupply': placeOfSupply,
    if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
    if (expectedDelivery != null)
      'expectedDelivery': expectedDelivery!.toIso8601String(),
    'paymentType': paymentType.label,
    'paidAmount': paidAmount,
    'items': items.map((i) => i.toJson()).toList(),
  };
}

/// A single line item as shown on the Purchase Details view.
class PurchaseDetailItem {
  /// Backend product id when the line was picked from the product
  /// autocomplete — this is what lets the server move that product's stock.
  /// Null for free-typed lines, which are recorded but move no stock.
  final int? productId;
  final String product;
  final String hsn;
  final String grade;
  final String density;
  final double qty;
  final String unit;
  final double rate;

  const PurchaseDetailItem({
    this.productId,
    required this.product,
    this.hsn = '',
    this.grade = '',
    this.density = '',
    required this.qty,
    this.unit = '',
    required this.rate,
  });

  double get amount => qty * rate;

  factory PurchaseDetailItem.fromJson(Map<String, dynamic> json) {
    return PurchaseDetailItem(
      productId: (json['productId'] as num?)?.toInt(),
      product: json['product'] as String? ?? '',
      hsn: json['hsn'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      density: json['density'] as String? ?? '',
      qty: (json['qty'] as num).toDouble(),
      unit: json['unit'] as String? ?? '',
      rate: (json['rate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (productId != null) 'productId': productId,
    'product': product,
    'hsn': hsn,
    'grade': grade,
    'density': density,
    'qty': qty,
    'unit': unit,
    'rate': rate,
  };
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

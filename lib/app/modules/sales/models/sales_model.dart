import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/utils/gst.dart';
import 'package:shc_stock/app/shared/models/order_qty.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/shared/models/order_payment.dart';
import 'package:shc_stock/app/modules/sales/models/sale_payment.dart';

// ── Enums ────────────────────────────────────────────────────────────────────

enum SalesStatus { delivered, shipped, confirmed, cancelled, processing }

extension SalesStatusX on SalesStatus {
  String get label {
    switch (this) {
      case SalesStatus.delivered:
        return 'Delivered';
      case SalesStatus.shipped:
        return 'Shipped';
      case SalesStatus.confirmed:
        return 'Confirmed';
      case SalesStatus.cancelled:
        return 'Cancelled';
      case SalesStatus.processing:
        return 'Processing';
    }
  }

  Color get color {
    switch (this) {
      case SalesStatus.delivered:
        return AppColors.success;
      case SalesStatus.shipped:
        return appColors.accent;
      case SalesStatus.confirmed:
        return AppColors.info;
      case SalesStatus.cancelled:
        return AppColors.danger;
      case SalesStatus.processing:
        return AppColors.warning;
    }
  }
}

enum PaymentStatus { paid, partial, refunded, pending }

extension PaymentStatusX on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.partial:
        return 'Partial';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.pending:
        return 'Pending';
    }
  }

  Color get color {
    switch (this) {
      case PaymentStatus.paid:
        return AppColors.success;
      case PaymentStatus.partial:
        return AppColors.warning;
      case PaymentStatus.refunded:
        return const Color(0xFF8B5CF6);
      case PaymentStatus.pending:
        return appColors.accent;
    }
  }
}

// ── Models ───────────────────────────────────────────────────────────────────

class SalesOrder {
  final String id;
  final String soNumber;
  final String client;
  final String clientBadge; // 2-3 letter abbreviation
  final Color clientColor;
  final DateTime date;
  final int itemCount;
  final double amount;
  final SalesStatus status;
  final PaymentStatus paymentStatus;
  final String modifiedBy;
  final DateTime? modifiedAt;

  // ── Full invoice detail — populated when created via the "Add Sale"
  // form; blank/empty on older/seed orders that predate this. The "View"
  // details panel falls back to "—" for anything missing.
  final String clientAddress;
  final String buyerGstin;
  final String pan;
  final String invoiceNo;
  final DateTime? invoiceDate;
  final String despatchedThrough;
  final String destination;

  /// Optional. When set, the backend flips the order to Delivered on that date
  /// — which is what books the stock OUT. Null leaves the status alone.
  final DateTime? expectedDelivery;

  /// When the order was marked Delivered; null while it is not.
  final DateTime? deliveredAt;

  /// How much of this order the client has actually paid.
  final OrderPaymentType paymentType;
  final double paidAmount;
  final List<SaleDetailItem> items;

  /// The payments received, oldest first. Each is a row of the Transactions
  /// list; [paidAmount] is their sum once the sale is saved with them.
  final List<SalePayment> payments;

  /// Buyer in another state: IGST instead of CGST + SGST.
  final bool interState;

  SalesOrder({
    required this.id,
    required this.soNumber,
    required this.client,
    required this.clientBadge,
    required this.clientColor,
    required this.date,
    required this.itemCount,
    required this.amount,
    required this.status,
    required this.paymentStatus,
    this.modifiedBy = 'Admin',
    this.modifiedAt,
    this.clientAddress = '',
    this.buyerGstin = '',
    this.pan = '',
    this.invoiceNo = '',
    this.invoiceDate,
    this.despatchedThrough = '',
    this.destination = '',
    this.expectedDelivery,
    this.deliveredAt,
    this.paymentType = OrderPaymentType.none,
    this.paidAmount = 0,
    this.items = const [],
    this.payments = const [],
    this.interState = false,
  });

  /// Units on the order — every line's quantity added up. The list's "Items"
  /// column reads this, so a single 5-unit line shows 5 there and 5 in the
  /// form; [itemCount] is the number of lines behind that number.
  double get totalQty => items.fold(0.0, (s, i) => s + i.qty);

  /// [totalQty] without a trailing `.0`, falling back to the line count for
  /// older records that were saved without their lines.
  /// "300 pcs" when every line shares a unit, "2 items" when they don't
  /// (100 pcs + 200 kg is not 300 of anything). See order_qty.dart.
  String get totalQtyLabel => orderQtyLabel([
    for (final i in items) (i.qty, i.unit),
  ], fallbackCount: itemCount);

  /// "100 pcs + 200 kg" — the full breakdown, for the row's tooltip.
  String get qtyBreakdown =>
      orderQtyBreakdown([for (final i in items) (i.qty, i.unit)]);

  double get taxableValue => items.fold(0.0, (s, i) => s + i.amount);

  /// The tax on this order: each line at its own rate, IGST when the buyer
  /// is in another state (see gst.dart).
  GstBreakup get gst => computeGst([
    for (final i in items) GstLine(i.amount, i.taxPercent),
  ], interState: interState);
  double get cgst => gst.cgst;
  double get sgst => gst.sgst;
  double get igst => gst.igst;

  static Color _colorForBadge(String badge) {
    final colors = {
      'AE': Color(0xFFF47B20),
      'SRT': AppColors.info,
      'JMD': Color(0xFF7C3AED),
      'GH': Color(0xFF64748B),
      'NIC': Color(0xFF0D9488),
      'TMC': Color(0xFFDC2626),
      'BS': Color(0xFF16A34A),
      'OST': Color(0xFF1D4ED8),
      'SE': Color(0xFF9333EA),
      'LI': Color(0xFF4F46E5),
      'RS': Color(0xFF0891B2),
      'PS': Color(0xFFB45309),
      'BT': Color(0xFF059669),
      'VE': Color(0xFF6D28D9),
      'SI': Color(0xFF0369A1),
    };
    return colors[badge] ?? appColors.accent;
  }

  /// Builds a [SalesOrder] from the backend `/sales-orders` JSON shape.
  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.parse(v as String).toLocal();
    final badge = json['clientBadge'] as String? ?? '';
    return SalesOrder(
      id: (json['id'] as int).toString(),
      soNumber: json['soNumber'] as String? ?? '',
      client: json['client'] as String? ?? '',
      clientBadge: badge,
      clientColor: _colorForBadge(badge),
      date: DateTime.parse(json['date'] as String).toLocal(),
      itemCount: (json['items'] as List<dynamic>? ?? []).length,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: SalesStatus.values.firstWhere(
        (s) => s.label == json['status'],
        orElse: () => SalesStatus.confirmed,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (p) => p.label == json['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      modifiedBy: json['modifiedBy'] as String? ?? 'Admin',
      modifiedAt: parseDate(json['modifiedAt']),
      clientAddress: json['clientAddress'] as String? ?? '',
      buyerGstin: json['buyerGstin'] as String? ?? '',
      pan: json['pan'] as String? ?? '',
      invoiceNo: json['invoiceNo'] as String? ?? '',
      invoiceDate: parseDate(json['invoiceDate']),
      despatchedThrough: json['despatchedThrough'] as String? ?? '',
      destination: json['destination'] as String? ?? '',
      expectedDelivery: parseDate(json['expectedDelivery']),
      deliveredAt: parseDate(json['deliveredAt']),
      paymentType: orderPaymentTypeFrom(json['paymentType'] as String?),
      interState: json['interState'] == true,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => SaleDetailItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((e) => SalePayment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Body for `POST /sales-orders`.
  Map<String, dynamic> toCreateJson() => {
    'soNumber': soNumber,
    'client': client,
    'clientBadge': clientBadge,
    'date': date.toIso8601String(),
    'amount': amount,
    'status': status.label,
    'paymentStatus': paymentStatus.label,
    'modifiedBy': modifiedBy,
    'clientAddress': clientAddress,
    'buyerGstin': buyerGstin,
    'pan': pan,
    'invoiceNo': invoiceNo,
    if (invoiceDate != null) 'invoiceDate': invoiceDate!.toIso8601String(),
    'despatchedThrough': despatchedThrough,
    'destination': destination,
    if (expectedDelivery != null)
      'expectedDelivery': expectedDelivery!.toIso8601String(),
    'paymentType': paymentType.label,
    'interState': interState,
    'paidAmount': paidAmount,
    'items': items.map((i) => i.toJson()).toList(),
    // The server derives paidAmount, paymentType and paymentStatus from these.
    'payments': payments.map((p) => p.toJson()).toList(),
  };
}

/// A single line item as shown on the Sale Details view.
class SaleDetailItem {
  /// Backend product id when the line was picked from the product
  /// autocomplete — this is what lets the server take that product's stock
  /// out. Null for free-typed lines, which move no stock.
  final int? productId;
  final String product;
  final String hsn;
  final double qty;
  final String unit;
  final double rate;

  /// GST rate (percent) on this line — the product's own rate.
  final double taxPercent;

  const SaleDetailItem({
    this.productId,
    required this.product,
    this.hsn = '',
    required this.qty,
    this.unit = '',
    required this.rate,
    this.taxPercent = kDefaultGstRate,
  });

  double get amount => qty * rate;

  factory SaleDetailItem.fromJson(Map<String, dynamic> json) {
    return SaleDetailItem(
      productId: (json['productId'] as num?)?.toInt(),
      product: json['product'] as String? ?? '',
      hsn: json['hsn'] as String? ?? '',
      qty: (json['qty'] as num).toDouble(),
      unit: json['unit'] as String? ?? '',
      rate: (json['rate'] as num).toDouble(),
      taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? kDefaultGstRate,
    );
  }

  Map<String, dynamic> toJson() => {
    if (productId != null) 'productId': productId,
    'product': product,
    'hsn': hsn,
    'qty': qty,
    'unit': unit,
    'rate': rate,
    'taxPercent': taxPercent,
  };
}

class TopClient {
  final String badge;
  final Color color;
  final String name;
  final int orderCount;
  final double totalAmount;

  const TopClient({
    required this.badge,
    required this.color,
    required this.name,
    required this.orderCount,
    required this.totalAmount,
  });
}

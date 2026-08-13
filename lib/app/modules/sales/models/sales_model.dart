import 'package:flutter/material.dart';

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
        return const Color(0xFF22C55E);
      case SalesStatus.shipped:
        return const Color(0xFF4A3AFF);
      case SalesStatus.confirmed:
        return const Color(0xFF3B82F6);
      case SalesStatus.cancelled:
        return const Color(0xFFEF4444);
      case SalesStatus.processing:
        return const Color(0xFFF59E0B);
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
        return const Color(0xFF22C55E);
      case PaymentStatus.partial:
        return const Color(0xFFF59E0B);
      case PaymentStatus.refunded:
        return const Color(0xFF8B5CF6);
      case PaymentStatus.pending:
        return const Color(0xFF4A3AFF);
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
  final List<SaleDetailItem> items;

  const SalesOrder({
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
    this.items = const [],
  });

  double get taxableValue => items.fold(0.0, (s, i) => s + i.amount);
  double get cgst => taxableValue * 0.09;
  double get sgst => taxableValue * 0.09;

  static Color _colorForBadge(String badge) {
    const colors = {
      'AE': Color(0xFFF47B20),
      'SRT': Color(0xFF3B82F6),
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
    return colors[badge] ?? const Color(0xFF4A3AFF);
  }

  /// Builds a [SalesOrder] from the backend `/sales-orders` JSON shape.
  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.parse(v as String);
    final badge = json['clientBadge'] as String? ?? '';
    return SalesOrder(
      id: (json['id'] as int).toString(),
      soNumber: json['soNumber'] as String? ?? '',
      client: json['client'] as String? ?? '',
      clientBadge: badge,
      clientColor: _colorForBadge(badge),
      date: DateTime.parse(json['date'] as String),
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
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => SaleDetailItem.fromJson(e as Map<String, dynamic>))
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
    'items': items.map((i) => i.toJson()).toList(),
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

  const SaleDetailItem({
    this.productId,
    required this.product,
    this.hsn = '',
    required this.qty,
    this.unit = '',
    required this.rate,
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
    );
  }

  Map<String, dynamic> toJson() => {
    if (productId != null) 'productId': productId,
    'product': product,
    'hsn': hsn,
    'qty': qty,
    'unit': unit,
    'rate': rate,
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

import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum TransactionType { inbound, outbound }

enum TransactionStatus { received, shipped, pending, delivered }

class TransactionModel {
  final String id;
  final String item;
  final TransactionType type;
  final String party;
  final String poNumber;
  final DateTime date;
  final TransactionStatus status;
  final String modifiedBy;
  final DateTime modifiedAt;

  final String notes;

  /// Money moved by this row — a payment on a sale, or a paid purchase. 0 for
  /// a row that records goods only.
  final double amount;

  /// Cash | UPI | Bank Transfer | Cheque | Card | Other, or ''.
  final String mode;

  /// 'sale' or 'purchase' when the row was generated from that order (its
  /// number is [poNumber]); null for a hand-entered row.
  final String? refType;

  const TransactionModel({
    required this.id,
    required this.item,
    required this.type,
    required this.party,
    required this.poNumber,
    required this.date,
    required this.status,
    required this.modifiedBy,
    required this.modifiedAt,
    this.notes = '',
    this.amount = 0,
    this.mode = '',
    this.refType,
  });

  /// Generated from an order: it is changed from that order, not here.
  bool get isLinked => refType != null && refType!.isNotEmpty;

  /// "Sale" / "Purchase" for a generated row.
  String get sourceLabel => refType == 'sale' ? 'Sale' : 'Purchase';

  /// Maps a row from GET /api/transactions. Unknown type/status labels fall
  /// back rather than throwing, so a value added server-side can't blank the
  /// whole list.
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    const types = {
      'Inbound': TransactionType.inbound,
      'Outbound': TransactionType.outbound,
    };
    const statuses = {
      'Received': TransactionStatus.received,
      'Shipped': TransactionStatus.shipped,
      'Pending': TransactionStatus.pending,
      'Delivered': TransactionStatus.delivered,
    };
    DateTime date(String key) =>
        DateTime.tryParse(json[key] as String? ?? '')?.toLocal() ??
        DateTime.now();

    return TransactionModel(
      id: json['id'].toString(),
      item: json['item'] as String? ?? '',
      type: types[json['type']] ?? TransactionType.inbound,
      party: json['party'] as String? ?? '',
      poNumber: json['poNumber'] as String? ?? '',
      date: date('date'),
      status: statuses[json['status']] ?? TransactionStatus.pending,
      notes: json['notes'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      mode: json['mode'] as String? ?? '',
      refType: json['refType'] as String?,
      modifiedBy: json['modifiedBy'] as String? ?? 'Admin',
      modifiedAt: date('modifiedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
    'item': item,
    'type': typeLabel,
    'party': party,
    'poNumber': poNumber,
    'date': date.toIso8601String(),
    'status': statusLabel,
    'notes': notes,
    'amount': amount,
    'mode': mode,
    'modifiedBy': modifiedBy,
  };

  String get typeLabel {
    switch (type) {
      case TransactionType.inbound:
        return 'Inbound';
      case TransactionType.outbound:
        return 'Outbound';
    }
  }

  Color get typeColor {
    switch (type) {
      case TransactionType.inbound:
        return AppColors.success;
      case TransactionType.outbound:
        return AppColors.warning;
    }
  }

  String get statusLabel {
    switch (status) {
      case TransactionStatus.received:
        return 'Received';
      case TransactionStatus.shipped:
        return 'Shipped';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.delivered:
        return 'Delivered';
    }
  }

  Color get statusColor {
    switch (status) {
      case TransactionStatus.received:
        return AppColors.success;
      case TransactionStatus.shipped:
        return AppColors.info;
      case TransactionStatus.pending:
        return AppColors.warning;
      case TransactionStatus.delivered:
        return AppColors.success;
    }
  }
}

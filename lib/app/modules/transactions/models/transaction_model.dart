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
  });

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
        return const Color(0xFF22C55E);
      case TransactionType.outbound:
        return const Color(0xFFF59E0B);
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
        return const Color(0xFF22C55E);
      case TransactionStatus.shipped:
        return const Color(0xFF3B82F6);
      case TransactionStatus.pending:
        return const Color(0xFFF59E0B);
      case TransactionStatus.delivered:
        return const Color(0xFF22C55E);
    }
  }
}

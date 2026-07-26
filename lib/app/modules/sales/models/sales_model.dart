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
  });
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

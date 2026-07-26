import 'package:flutter/material.dart';

enum StockStatus { inStock, lowStock, outOfStock, inactive }

class StockItemModel {
  final String id;
  final String code;
  final String sku;
  final String name;
  final String category;
  final String unit;
  final int stockInHand;
  final int availableStock;
  final double stockValue;
  final StockStatus status;
  final String modifiedBy;
  final DateTime? modifiedAt;

  const StockItemModel({
    required this.id,
    required this.code,
    required this.sku,
    required this.name,
    required this.category,
    required this.unit,
    required this.stockInHand,
    required this.availableStock,
    required this.stockValue,
    required this.status,
    this.modifiedBy = 'Admin',
    this.modifiedAt,
  });

  DateTime get effectiveModifiedAt => modifiedAt ?? DateTime(2024, 5, 1);

  Color get statusColor {
    switch (status) {
      case StockStatus.inStock:
        return const Color(0xFF22C55E);
      case StockStatus.lowStock:
        return const Color(0xFFF59E0B);
      case StockStatus.outOfStock:
        return const Color(0xFFEF4444);
      case StockStatus.inactive:
        return const Color(0xFF94A3B8);
    }
  }

  String get statusLabel {
    switch (status) {
      case StockStatus.inStock:
        return 'In Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.outOfStock:
        return 'Out of Stock';
      case StockStatus.inactive:
        return 'Inactive';
    }
  }
}

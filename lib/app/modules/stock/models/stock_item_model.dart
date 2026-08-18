import 'package:flutter/material.dart';

enum StockStatus { inStock, lowStock, outOfStock, inactive }

class StockItemModel {
  final String id;

  /// Backend product id — inventory rows are products viewed through stock.
  final int productId;
  final String code;
  final String sku;
  final String name;
  final String category;
  final String unit;
  final int stockInHand;
  final int availableStock;
  final int minimumStock;
  final double costPrice;
  final double sellingPrice;
  final double stockValue;
  final String stockLocation;
  final bool isActive;
  final StockStatus status;
  final String modifiedBy;
  final DateTime? modifiedAt;

  const StockItemModel({
    required this.id,
    this.productId = 0,
    required this.code,
    required this.sku,
    required this.name,
    required this.category,
    required this.unit,
    required this.stockInHand,
    required this.availableStock,
    this.minimumStock = 0,
    this.costPrice = 0,
    this.sellingPrice = 0,
    required this.stockValue,
    this.stockLocation = 'Main Warehouse',
    this.isActive = true,
    required this.status,
    this.modifiedBy = 'Admin',
    this.modifiedAt,
  });

  /// Maps a row from GET /api/inventory. `status` arrives already derived by
  /// the backend (stockService.stockStatus) so the app and the API can't
  /// disagree about what counts as low stock.
  factory StockItemModel.fromJson(Map<String, dynamic> json) {
    const statuses = {
      'inStock': StockStatus.inStock,
      'lowStock': StockStatus.lowStock,
      'outOfStock': StockStatus.outOfStock,
      'inactive': StockStatus.inactive,
    };
    return StockItemModel(
      id: json['id'].toString(),
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      code: json['code'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      stockInHand: (json['stockInHand'] as num?)?.toInt() ?? 0,
      availableStock: (json['availableStock'] as num?)?.toInt() ?? 0,
      minimumStock: (json['minimumStock'] as num?)?.toInt() ?? 0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
      stockValue: (json['stockValue'] as num?)?.toDouble() ?? 0,
      stockLocation: json['stockLocation'] as String? ?? 'Main Warehouse',
      isActive: json['isActive'] as bool? ?? true,
      status: statuses[json['status']] ?? StockStatus.inStock,
      modifiedBy: json['modifiedBy'] as String? ?? 'Admin',
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.tryParse(json['modifiedAt'] as String),
    );
  }

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

/// One row of the stock ledger (`stock_movements`) — the audit trail behind a
/// product's current quantity. `refType` is purchase | sale | manual.
class StockMovement {
  final int id;
  final int productId;
  final String productName;
  final String unit;

  /// IN | OUT
  final String type;
  final double qty;
  final String refType;
  final int? refId;
  final String reference;
  final String note;
  final String createdBy;
  final DateTime? createdAt;

  const StockMovement({
    required this.id,
    required this.productId,
    this.productName = '',
    this.unit = '',
    required this.type,
    required this.qty,
    this.refType = 'manual',
    this.refId,
    this.reference = '',
    this.note = '',
    this.createdBy = 'Admin',
    this.createdAt,
  });

  bool get isIn => type == 'IN';

  /// Only manual adjustments can be deleted directly; purchase/sale rows are
  /// reversed by deleting the order that created them.
  bool get isDeletable => refType == 'manual';

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return StockMovement(
      id: (json['id'] as num).toInt(),
      productId: (json['productId'] as num).toInt(),
      productName: product?['name'] as String? ?? '',
      unit: product?['unit'] as String? ?? '',
      type: json['type'] as String? ?? 'IN',
      qty: (json['qty'] as num?)?.toDouble() ?? 0,
      refType: json['refType'] as String? ?? 'manual',
      refId: (json['refId'] as num?)?.toInt(),
      reference: json['reference'] as String? ?? '',
      note: json['note'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? 'Admin',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
    );
  }
}

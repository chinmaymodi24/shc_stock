import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';

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

  /// Decimal: a product measured in kg / m can hold 12.5 of it.
  final double stockInHand;
  final double availableStock;
  final double minimumStock;
  final double costPrice;
  final double sellingPrice;
  final double stockValue;
  final String stockLocation;

  /// Relative `/uploads/...` photo path of the product, if it has one.
  final String? imageUrl;
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
    this.imageUrl,
    this.isActive = true,
    required this.status,
    this.modifiedBy = 'Admin',
    this.modifiedAt,
  });

  /// Builds the inventory view of a product straight from the products list,
  /// so the Products page can open the same [StockItemDetailsPanel] the
  /// Inventory page uses instead of needing a second details screen.
  factory StockItemModel.fromProduct(ProductModel p) {
    const statuses = {
      'inStock': StockStatus.inStock,
      'lowStock': StockStatus.lowStock,
      'outOfStock': StockStatus.outOfStock,
      'inactive': StockStatus.inactive,
    };
    return StockItemModel(
      id: p.id,
      productId: int.tryParse(p.id) ?? 0,
      code: p.sku,
      sku: p.sku,
      name: p.name,
      category: p.categoryName,
      unit: p.unit,
      stockInHand: p.currentStock,
      availableStock: p.currentStock,
      minimumStock: p.minimumStock,
      costPrice: p.costPrice,
      sellingPrice: p.sellingPrice,
      stockValue: p.currentStock * p.costPrice,
      stockLocation: p.stockLocation,
      imageUrl: p.imageUrl,
      isActive: p.isActive,
      status:
          statuses[p.serverStockStatus] ??
          (p.currentStock == 0
              ? StockStatus.outOfStock
              : p.currentStock <= p.minimumStock
              ? StockStatus.lowStock
              : StockStatus.inStock),
      modifiedBy: p.modifiedBy,
      modifiedAt: p.effectiveModifiedAt,
    );
  }

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
      stockInHand: (json['stockInHand'] as num?)?.toDouble() ?? 0,
      availableStock: (json['availableStock'] as num?)?.toDouble() ?? 0,
      minimumStock: (json['minimumStock'] as num?)?.toDouble() ?? 0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
      stockValue: (json['stockValue'] as num?)?.toDouble() ?? 0,
      stockLocation: json['stockLocation'] as String? ?? 'Main Warehouse',
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      status: statuses[json['status']] ?? StockStatus.inStock,
      modifiedBy: json['modifiedBy'] as String? ?? 'Admin',
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.tryParse(json['modifiedAt'] as String)?.toLocal(),
    );
  }

  DateTime get effectiveModifiedAt => modifiedAt ?? DateTime(2024, 5, 1);

  Color get statusColor {
    switch (status) {
      case StockStatus.inStock:
        return AppColors.success;
      case StockStatus.lowStock:
        return AppColors.warning;
      case StockStatus.outOfStock:
        return AppColors.danger;
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

  /// Per-unit price, only ever set on a manual adjustment where one was
  /// recorded (e.g. an opening-balance entry). Null for purchase/sale rows —
  /// their price lives on the order's line items instead.
  final double? rate;
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
    this.rate,
    this.refType = 'manual',
    this.refId,
    this.reference = '',
    this.note = '',
    this.createdBy = 'Admin',
    this.createdAt,
  });

  /// `qty * rate` when a price was recorded, else null.
  double? get amount => rate == null ? null : qty * rate!;

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
      rate: (json['rate'] as num?)?.toDouble(),
      refType: json['refType'] as String? ?? 'manual',
      refId: (json['refId'] as num?)?.toInt(),
      reference: json['reference'] as String? ?? '',
      note: json['note'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? 'Admin',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String)?.toLocal(),
    );
  }
}

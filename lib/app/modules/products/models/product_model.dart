import 'dart:typed_data';

class ProductModel {
  final String id;
  final String name;
  final String sku;
  final String categoryId;
  final String categoryName;
  final String subCategory;
  final String unit;
  final double sellingPrice;
  final double costPrice;
  final int currentStock;
  final int minimumStock;
  final bool isActive;
  final String? brand;
  final String? hsnCode;
  final String? description;
  final double taxPercent;
  final String stockLocation;
  final DateTime createdAt;

  // Variant toggles
  final List<String> densityVariants;
  final List<String> boardVariants;
  final List<String> thicknessVariants;
  final List<String> reinforcementTypes;
  final String? otherSpecs;

  const ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.categoryId,
    required this.categoryName,
    required this.subCategory,
    required this.unit,
    required this.sellingPrice,
    required this.costPrice,
    required this.currentStock,
    required this.minimumStock,
    this.isActive = true,
    this.brand,
    this.hsnCode,
    this.description,
    this.taxPercent = 18.0,
    this.stockLocation = 'Main Warehouse',
    required this.createdAt,
    this.densityVariants = const [],
    this.boardVariants = const [],
    this.thicknessVariants = const [],
    this.reinforcementTypes = const [],
    this.otherSpecs,
  });

  String get stockStatus {
    if (currentStock == 0) return 'Out of Stock';
    if (currentStock <= minimumStock) return 'Low Stock';
    return 'In Stock';
  }

  ProductModel copyWith({
    String? name,
    String? sku,
    String? categoryId,
    String? categoryName,
    String? subCategory,
    String? unit,
    double? sellingPrice,
    double? costPrice,
    int? currentStock,
    int? minimumStock,
    bool? isActive,
    String? brand,
    String? hsnCode,
    String? description,
    double? taxPercent,
    String? stockLocation,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      subCategory: subCategory ?? this.subCategory,
      unit: unit ?? this.unit,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      isActive: isActive ?? this.isActive,
      brand: brand ?? this.brand,
      hsnCode: hsnCode ?? this.hsnCode,
      description: description ?? this.description,
      taxPercent: taxPercent ?? this.taxPercent,
      stockLocation: stockLocation ?? this.stockLocation,
      createdAt: createdAt,
    );
  }
}

// ── Category model ──────────────────────────────────────────────
class ProductCategory {
  final String id;
  final String name;
  final List<String> subProducts;
  final String description;
  /// Parallel to [subProducts] — each index holds the description for that sub-category.
  final List<String> subDescriptions;
  /// User-picked image bytes (null = use initials placeholder).
  final Uint8List? imageBytes;

  ProductCategory({
    required this.id,
    required this.name,
    required this.subProducts,
    this.description = '',
    this.subDescriptions = const [],
    this.imageBytes,
  });
}

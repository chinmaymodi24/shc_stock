import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/stock_item_model.dart';

class StockController extends GetxController {
  final RxList<StockItemModel> items = <StockItemModel>[].obs;
  final searchCtrl = TextEditingController();
  final RxString search = ''.obs;
  final RxSet<String> catFilters = <String>{}.obs;
  final RxSet<String> statFilters = <String>{}.obs;
  final RxInt rowsPerPage = 10.obs;
  final RxInt currentPage = 1.obs;

  static final _seed = [
    StockItemModel(
      id: '1',
      code: 'CFB-1042',
      sku: 'CFB-1042',
      name: 'Ceramic Fiber Blanket 128 kg/m³',
      category: 'Ceramic Fiber Products',
      unit: 'Roll',
      stockInHand: 612,
      availableStock: 612,
      stockValue: 208080,
      status: StockStatus.inStock,
      modifiedBy: 'Chinmay Modi',
      modifiedAt: DateTime(2026, 7, 10, 14, 40),
    ),
    StockItemModel(
      id: '2',
      code: 'CFL-2201',
      sku: 'CFL-2201',
      name: 'Ceramic Fiber Bulk (Loose Fiber)',
      category: 'Ceramic Fiber Products',
      unit: 'Kg',
      stockInHand: 4,
      availableStock: 4,
      stockValue: 880,
      status: StockStatus.lowStock,
      modifiedBy: 'Riya Patel',
      modifiedAt: DateTime(2026, 6, 22, 11, 15),
    ),
    StockItemModel(
      id: '3',
      code: 'CFR-3312',
      sku: 'CFR-3312',
      name: 'Ceramic Fiber Rope 12mm',
      category: 'Ceramic Fiber Textile',
      unit: 'Meter',
      stockInHand: 15,
      availableStock: 15,
      stockValue: 3150,
      status: StockStatus.lowStock,
      modifiedBy: 'Chinmay Modi',
      modifiedAt: DateTime(2026, 6, 30, 9, 2),
    ),
    StockItemModel(
      id: '4',
      code: 'FB-1187',
      sku: 'FB-1187',
      name: 'Fire Bricks (Standard)',
      category: 'Refractories',
      unit: 'Piece',
      stockInHand: 18,
      availableStock: 18,
      stockValue: 26100,
      status: StockStatus.lowStock,
      modifiedBy: 'Riya Patel',
      modifiedAt: DateTime(2026, 7, 5, 16, 20),
    ),
    StockItemModel(
      id: '5',
      code: 'RMO-5502',
      sku: 'RMO-5502',
      name: 'Refractory Mortar (ORTEX) 25kg',
      category: 'Mortars & Castables',
      unit: 'Bag',
      stockInHand: 84,
      availableStock: 84,
      stockValue: 47040,
      status: StockStatus.inStock,
      modifiedBy: 'Chinmay Modi',
      modifiedAt: DateTime(2026, 7, 9, 10, 47),
    ),
    StockItemModel(
      id: '6',
      code: 'FBL-0087',
      sku: 'FBL-0087',
      name: 'Fire Blanket 1.2m x 1.2m',
      category: 'Fire & Welding Protection',
      unit: 'Piece',
      stockInHand: 9,
      availableStock: 9,
      stockValue: 16200,
      status: StockStatus.lowStock,
      modifiedBy: 'Riya Patel',
      modifiedAt: DateTime(2026, 6, 18, 15, 8),
    ),
    StockItemModel(
      id: '7',
      code: 'SWA-7710',
      sku: 'SWA-7710',
      name: 'Stud & Washer Anchor',
      category: 'Accessories & Services',
      unit: 'Piece',
      stockInHand: 0,
      availableStock: 0,
      stockValue: 0,
      status: StockStatus.outOfStock,
      modifiedBy: 'Chinmay Modi',
      modifiedAt: DateTime(2026, 5, 28, 17, 33),
    ),
    StockItemModel(
      id: '8',
      code: 'HFC-1204',
      sku: 'HFC-1204',
      name: 'HF/CF Insulation Bricks',
      category: 'Insulation Bricks',
      unit: 'Piece',
      stockInHand: 231,
      availableStock: 231,
      stockValue: 15015,
      status: StockStatus.inStock,
      modifiedBy: 'Riya Patel',
      modifiedAt: DateTime(2026, 7, 8, 13, 19),
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    items.addAll(_seed);
  }

  int get totalItems => items.length;
  int get inStockCount =>
      items.where((i) => i.status == StockStatus.inStock).length;
  int get lowStockCount =>
      items.where((i) => i.status == StockStatus.lowStock).length;
  int get outOfStockCount =>
      items.where((i) => i.status == StockStatus.outOfStock).length;
  int get inactiveCount =>
      items.where((i) => i.status == StockStatus.inactive).length;
  int get totalQty => items.fold(0, (s, i) => s + i.stockInHand);
  double get totalValue => items.fold(0.0, (s, i) => s + i.stockValue);

  List<String> get categories => [
    'All Categories',
    ...items.map((i) => i.category).toSet().toList()..sort(),
  ];
  List<String> get units => [
    'All Units',
    ...items.map((i) => i.unit).toSet().toList()..sort(),
  ];

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }
}

import 'package:cross_file/cross_file.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/categories/controllers/categories_controller.dart';
import 'package:shc_stock/app/modules/categories/models/category_model.dart';
import 'package:flutter/material.dart';

class ProductsController extends GetxController {
  /// Summary cards for this page — values *and* month-over-month trends come
  /// from GET /api/stats/products, so nothing on the cards is computed here or
  /// hardcoded.
  final stats = StatsSnapshot.empty.obs;

  Future<void> fetchStats() async {
    try {
      stats.value = await StatsSnapshot.fetch('products');
    } catch (e) {
      // Cards fall back to zeros; the list fetch already reported any outage.
    }
  }

  final _api = ApiClient.instance;

  // ── Observables ──────────────────────────────────────────────
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<ProductModel> filteredProducts = <ProductModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'All Categories'.obs;
  final RxSet<String> selectedCategories = <String>{}.obs;
  final RxSet<String> selectedSubCategories = <String>{}.obs;
  final RxString selectedStatus = 'All Status'.obs;
  final RxString selectedStockStatus = 'All'.obs;
  final RxString sortOption = 'Default'.obs;
  final RxInt currentPage = 1.obs;
  final RxInt rowsPerPage = 10.obs;

  static const List<String> sortOptions = [
    'Default',
    'Product Name (A-Z)',
    'Product Name (Z-A)',
    'Price: Low to High',
    'Price: High to Low',
    'Stock: Low to High',
    'Stock: High to Low',
  ];

  // ── Add Product Form ─────────────────────────────────────────
  final RxString formCategory = ''.obs;
  final RxString formSubCategory = ''.obs;
  final RxBool densityVariantsEnabled = false.obs;
  final RxBool boardVariantsEnabled = false.obs;
  final RxBool thicknessVariantsEnabled = false.obs;
  final RxBool reinforcementEnabled = false.obs;
  final RxBool lowStockAlertEnabled = true.obs;
  final RxSet<String> selectedDensities = <String>{}.obs;
  final RxSet<String> selectedBoardTypes = <String>{}.obs;
  final RxSet<String> selectedThicknesses = <String>{}.obs;
  final RxSet<String> selectedReinforcements = <String>{}.obs;
  final RxString formUnit = 'Kilogram (kg)'.obs;
  final RxString formTax = '18% GST'.obs;
  final RxString formStockLocation = 'Main Warehouse'.obs;
  final RxString formStatus = 'Active'.obs;
  final RxList<XFile> formImages = <XFile>[].obs;

  // ── Categories & Sub-products ────────────────────────────────
  // The old hardcoded taxonomy (7 categories) is archived in static_data.txt
  // at the project root. Category/sub-category pickers now read live from
  // CategoriesController (see `realCategories` below and
  // `categoryNames`/`subProductsForCategory`, which use it).

  /// Live categories from the real, API-backed Categories module — shared,
  /// permanent instance. Registration happens once in [onInit], not here:
  /// a getter that can silently `Get.put` a new global singleton the first
  /// time it's read is a surprise for whoever calls it next.
  List<CategoryModel> get realCategories =>
      Get.find<CategoriesController>().categories;

  static const List<String> units = [
    'Kilogram (kg)',
    'Meter (m)',
    'Piece (pcs)',
    'Roll',
    'Bag',
    'Box',
    'Square Meter (sqm)',
    'Cubic Meter (m³)',
    'Set',
  ];

  static const List<String> taxOptions = [
    '0% (Exempt)',
    '5% GST',
    '12% GST',
    '18% GST',
    '28% GST',
  ];

  static const List<String> stockLocations = [
    'Main Warehouse',
    'Godown A',
    'Godown B',
  ];

  static const List<String> densityOptions = [
    '64 kg/m³',
    '96 kg/m³',
    '128 kg/m³',
    '160 kg/m³',
    '192 kg/m³',
  ];

  static const List<String> boardVariantOptions = [
    'Normal Board',
    'Vacuum Formed Board',
    'High Strength Board',
  ];

  static const List<String> thicknessOptions = [
    '1 mm',
    '2 mm',
    '3 mm',
    '5 mm',
    '6 mm',
    '10 mm',
  ];

  static const List<String> reinforcementOptions = [
    'Fiberglass reinforced',
    'SS wire reinforced',
  ];

  // ── Seed data — Static SHC Products ─────────────────────────
  // The old 26-product seed list is archived in static_data.txt at the
  // project root. Products now load dynamically via fetchProducts() below.

  void _showError(String message) {
    showAppToast(
      'Error',
      message,
      backgroundColor: const Color(0xFFEF4444),
      colorText: Colors.white,
    );
  }

  // ── Fetch ────────────────────────────────────────────────────
  Future<void> fetchProducts() async {
    isLoading.value = true;
    try {
      final data = await _api.get('/products') as List<dynamic>;
      products.assignAll(
        data.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)),
      );
      _applyFilters();
    } catch (e) {
      _showError('Failed to load products. Is the backend running?');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // realCategories depends on CategoriesController — ensure it's
    // registered (permanent, fetch-once) before anything reads from it.
    if (!Get.isRegistered<CategoriesController>()) {
      Get.put(CategoriesController(), permanent: true);
    }
    fetchStats();
    fetchProducts();
    ever(searchQuery, (_) => _applyFilters());
    ever(selectedCategory, (_) => _applyFilters());
    ever(selectedCategories, (_) => _applyFilters());
    ever(selectedSubCategories, (_) => _applyFilters());
    ever(selectedStatus, (_) => _applyFilters());
    ever(selectedStockStatus, (_) => _applyFilters());
    ever(sortOption, (_) => _applyFilters());
  }

  // Strips a leading "1. " / "12. " numeric prefix from a category name.
  static String _stripCatPrefix(String s) =>
      s.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();

  void _applyFilters() {
    currentPage.value = 1;
    List<ProductModel> result = List.from(products);

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.sku.toLowerCase().contains(q) ||
                p.categoryName.toLowerCase().contains(q),
          )
          .toList();
    }

    if (selectedCategories.isNotEmpty) {
      // Historically, category names carried a "1. " numeric prefix — strip
      // it on both sides just in case any stored data still has it.
      final selectedStripped = selectedCategories.map(_stripCatPrefix).toSet();
      result = result
          .where(
            (p) => selectedStripped.contains(_stripCatPrefix(p.categoryName)),
          )
          .toList();
    } else if (selectedCategory.value != 'All Categories') {
      result = result
          .where(
            (p) =>
                _stripCatPrefix(p.categoryName) ==
                _stripCatPrefix(selectedCategory.value),
          )
          .toList();
    }

    if (selectedSubCategories.isNotEmpty) {
      result = result
          .where((p) => selectedSubCategories.contains(p.subCategory))
          .toList();
    }

    if (selectedStatus.value == 'Active') {
      result = result.where((p) => p.isActive).toList();
    } else if (selectedStatus.value == 'Inactive') {
      result = result.where((p) => !p.isActive).toList();
    }

    if (selectedStockStatus.value != 'All') {
      result = result
          .where((p) => p.stockStatus == selectedStockStatus.value)
          .toList();
    }

    switch (sortOption.value) {
      case 'Product Name (A-Z)':
        result.sort((a, b) => a.name.compareTo(b.name));
      case 'Product Name (Z-A)':
        result.sort((a, b) => b.name.compareTo(a.name));
      case 'Price: Low to High':
        result.sort((a, b) => a.sellingPrice.compareTo(b.sellingPrice));
      case 'Price: High to Low':
        result.sort((a, b) => b.sellingPrice.compareTo(a.sellingPrice));
      case 'Stock: Low to High':
        result.sort((a, b) => a.currentStock.compareTo(b.currentStock));
      case 'Stock: High to Low':
        result.sort((a, b) => b.currentStock.compareTo(a.currentStock));
    }

    filteredProducts.assignAll(result);
  }

  List<ProductModel> get paginatedProducts {
    final start = (currentPage.value - 1) * rowsPerPage.value;
    final end = (start + rowsPerPage.value).clamp(0, filteredProducts.length);
    return filteredProducts.sublist(start, end);
  }

  int get totalPages =>
      (filteredProducts.length / rowsPerPage.value).ceil().clamp(1, 999);

  int get totalProducts => products.length;
  int get activeProducts => products.where((p) => p.isActive).length;
  int get lowStockProducts =>
      products.where((p) => p.stockStatus == 'Low Stock').length;
  int get outOfStockProducts =>
      products.where((p) => p.stockStatus == 'Out of Stock').length;
  double get totalStockValue =>
      products.fold(0.0, (sum, p) => sum + p.sellingPrice * p.currentStock);

  void resetFilters() {
    searchQuery.value = '';
    selectedCategory.value = 'All Categories';
    selectedCategories.clear();
    selectedSubCategories.clear();
    selectedStatus.value = 'All Status';
    selectedStockStatus.value = 'All';
    sortOption.value = 'Default';
  }

  /// Subcategory names available to filter by — scoped to the selected
  /// categories (if any), else every subcategory across all products.
  List<String> get subCategoryNames {
    final source = selectedCategories.isEmpty
        ? products
        : products.where(
            (p) => selectedCategories
                .map(_stripCatPrefix)
                .contains(_stripCatPrefix(p.categoryName)),
          );
    return (source.map((p) => p.subCategory).toSet().toList()..sort());
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _api.delete('/products/$id');
      products.removeWhere((p) => p.id == id);
      _applyFilters();
    } catch (e) {
      _showError('Failed to delete product.');
    }
  }

  /// Creates a product via the backend `/products` API.
  ///
  /// [categoryId]/[subCategoryId] must be the real DB ids (from
  /// `CategoriesController`) — pass the fields the API needs directly rather
  /// than a pre-built [ProductModel], since the server assigns the id and
  /// resolves the category/sub-category names.
  Future<bool> addProduct({
    required String name,
    required String sku,
    required int categoryId,
    int? subCategoryId,
    required String unit,
    required double sellingPrice,
    required double costPrice,
    int currentStock = 0,
    int minimumStock = 0,
    String? brand,
    String? hsnCode,
    String? description,
    double taxPercent = 18.0,
  }) async {
    try {
      final json = await _api.post('/products', {
        'name': name.trim(),
        'sku': sku.trim(),
        'categoryId': categoryId,
        if (subCategoryId != null) 'subCategoryId': subCategoryId,
        'unit': unit,
        'sellingPrice': sellingPrice,
        'costPrice': costPrice,
        'currentStock': currentStock,
        'minimumStock': minimumStock,
        if (brand != null && brand.isNotEmpty) 'brand': brand,
        if (hsnCode != null && hsnCode.isNotEmpty) 'hsnCode': hsnCode,
        if (description != null && description.isNotEmpty)
          'description': description,
        'taxPercent': taxPercent,
      });
      products.insert(0, ProductModel.fromJson(json as Map<String, dynamic>));
      _applyFilters();
      return true;
    } catch (e) {
      _showError('Failed to add product.');
      return false;
    }
  }

  /// Updates an existing product via `PUT /products/:id`.
  Future<bool> updateProduct({
    required String id,
    required String name,
    required String sku,
    required int categoryId,
    int? subCategoryId,
    required String unit,
    required double sellingPrice,
    required double costPrice,
    int currentStock = 0,
    int minimumStock = 0,
    String? brand,
    String? hsnCode,
    String? description,
    double taxPercent = 18.0,
  }) async {
    try {
      final json = await _api.put('/products/$id', {
        'name': name.trim(),
        'sku': sku.trim(),
        'categoryId': categoryId,
        if (subCategoryId != null) 'subCategoryId': subCategoryId,
        'unit': unit,
        'sellingPrice': sellingPrice,
        'costPrice': costPrice,
        'currentStock': currentStock,
        'minimumStock': minimumStock,
        if (brand != null && brand.isNotEmpty) 'brand': brand,
        if (hsnCode != null && hsnCode.isNotEmpty) 'hsnCode': hsnCode,
        if (description != null && description.isNotEmpty)
          'description': description,
        'taxPercent': taxPercent,
      });
      final updated = ProductModel.fromJson(json as Map<String, dynamic>);
      final idx = products.indexWhere((p) => p.id == id);
      if (idx != -1) products[idx] = updated;
      _applyFilters();
      return true;
    } catch (e) {
      _showError('Failed to update product.');
      return false;
    }
  }

  List<String> get subProductsForCategory {
    if (formCategory.value.isEmpty) return [];
    final cat = realCategories.firstWhereOrNull(
      (c) => c.name == formCategory.value,
    );
    return cat?.subProducts ?? [];
  }

  List<String> get categoryNames => [
    'All Categories',
    ...realCategories.map((c) => c.name),
  ];

  void onCategoryChanged(String cat) {
    formCategory.value = cat;
    formSubCategory.value = '';
  }

  void toggleDensity(String val) {
    if (selectedDensities.contains(val)) {
      selectedDensities.remove(val);
    } else {
      selectedDensities.add(val);
    }
  }

  void toggleBoardType(String val) {
    if (selectedBoardTypes.contains(val)) {
      selectedBoardTypes.remove(val);
    } else {
      selectedBoardTypes.add(val);
    }
  }

  void toggleThickness(String val) {
    if (selectedThicknesses.contains(val)) {
      selectedThicknesses.remove(val);
    } else {
      selectedThicknesses.add(val);
    }
  }

  void toggleReinforcement(String val) {
    if (selectedReinforcements.contains(val)) {
      selectedReinforcements.remove(val);
    } else {
      selectedReinforcements.add(val);
    }
  }
}

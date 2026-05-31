import 'package:get/get.dart';
import '../models/product_model.dart';

class ProductsController extends GetxController {
  // ── Observables ──────────────────────────────────────────────
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<ProductModel> filteredProducts = <ProductModel>[].obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedCategory = 'All Categories'.obs;
  final RxString selectedStatus = 'All Status'.obs;
  final RxString selectedStockStatus = 'All'.obs;
  final RxInt currentPage = 1.obs;
  final RxInt rowsPerPage = 10.obs;

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

  // ── Static Categories & Sub-products (SHC specific) ─────────
  static const List<ProductCategory> allCategories = [
    ProductCategory(
      id: 'cat_01',
      name: '1. Ceramic Fiber Products',
      subProducts: [
        'Ceramic Fiber Blanket',
        'Ceramic Fiber Bulk (Loose Fiber)',
        'Ceramic Fiber Module',
        'Ceramic Fiber Board',
        'Ceramic Fiber Paper',
        'Heatshield Blanket',
      ],
    ),
    ProductCategory(
      id: 'cat_02',
      name: '2. Ceramic Fiber Textile',
      subProducts: [
        'Ceramic Fiber Rope',
        'Ceramic Fiber Cloth',
        'Ceramic Fiber Tape',
      ],
    ),
    ProductCategory(
      id: 'cat_03',
      name: '3. Insulation Bricks',
      subProducts: [
        'HF/CF Insulation Bricks',
        'HFK Insulation Bricks',
        'Porosint Bricks',
      ],
    ),
    ProductCategory(
      id: 'cat_04',
      name: '4. Refractories',
      subProducts: [
        'Fire Bricks',
        'Sillimanite & Mullite Bricks',
        'Burner Block',
        'Hollow Bricks',
      ],
    ),
    ProductCategory(
      id: 'cat_05',
      name: '5. Mortars & Castables',
      subProducts: [
        'Refractory Mortar (ORTEX)',
        'Air Setting Mortar (ORTEX-HT)',
        'Castable Refractory',
      ],
    ),
    ProductCategory(
      id: 'cat_06',
      name: '6. Fire & Welding Protection',
      subProducts: [
        'Fire Blanket',
        'Welding Blanket',
      ],
    ),
    ProductCategory(
      id: 'cat_07',
      name: '7. Accessories & Services',
      subProducts: [
        'Stud & Washer Anchor',
        'Ceramic Fiber Lining Anchor',
        'Brick Anchor',
        'Refractory Anchor',
        'Hot Insulation Service',
      ],
    ),
  ];

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
  static final List<ProductModel> _seedProducts = [
    ProductModel(id: 'p001', name: 'CF Blanket 1260°C (64 kg/m³)', sku: 'CFB-1260-64', categoryId: 'cat_01', categoryName: 'Ceramic Fiber Products', subCategory: 'Ceramic Fiber Blanket', unit: 'Roll', sellingPrice: 2800, costPrice: 1900, currentStock: 45, minimumStock: 10, brand: 'SIMWOOL', hsnCode: '68061000', description: 'Standard grade ceramic fiber blanket for high temperature insulation up to 1260°C.', taxPercent: 18, createdAt: DateTime(2024, 5, 1), densityVariants: ['64 kg/m³']),
    ProductModel(id: 'p002', name: 'CF Blanket 1260°C (96 kg/m³)', sku: 'CFB-1260-96', categoryId: 'cat_01', categoryName: 'Ceramic Fiber Products', subCategory: 'Ceramic Fiber Blanket', unit: 'Roll', sellingPrice: 3500, costPrice: 2400, currentStock: 32, minimumStock: 10, brand: 'SIMWOOL', hsnCode: '68061000', taxPercent: 18, createdAt: DateTime(2024, 5, 2), densityVariants: ['96 kg/m³']),
    ProductModel(id: 'p003', name: 'CF Blanket 1260°C (128 kg/m³)', sku: 'CFB-1260-128', categoryId: 'cat_01', categoryName: 'Ceramic Fiber Products', subCategory: 'Ceramic Fiber Blanket', unit: 'Roll', sellingPrice: 4200, costPrice: 2900, currentStock: 8, minimumStock: 10, brand: 'SIMWOOL', hsnCode: '68061000', taxPercent: 18, createdAt: DateTime(2024, 5, 3), densityVariants: ['128 kg/m³']),
    ProductModel(id: 'p004', name: 'CF Blanket 1425°C (96 kg/m³)', sku: 'CFB-1425-96', categoryId: 'cat_01', categoryName: 'Ceramic Fiber Products', subCategory: 'Ceramic Fiber Blanket', unit: 'Roll', sellingPrice: 6500, costPrice: 4500, currentStock: 15, minimumStock: 5, brand: 'SIMWOOL', hsnCode: '68061000', taxPercent: 18, createdAt: DateTime(2024, 5, 4), densityVariants: ['96 kg/m³']),
    ProductModel(id: 'p005', name: 'CF Bulk (Standard 1260°C)', sku: 'CFB-SBF-001', categoryId: 'cat_01', categoryName: 'Ceramic Fiber Products', subCategory: 'Ceramic Fiber Bulk (Loose Fiber)', unit: 'Kilogram (kg)', sellingPrice: 350, costPrice: 250, currentStock: 120, minimumStock: 25, brand: 'SIMWOOL', hsnCode: '68061000', taxPercent: 18, createdAt: DateTime(2024, 5, 5)),
    ProductModel(id: 'p006', name: 'CF Module (1260°C)', sku: 'CFM-1260-001', categoryId: 'cat_01', categoryName: 'Ceramic Fiber Products', subCategory: 'Ceramic Fiber Module', unit: 'Piece (pcs)', sellingPrice: 1200, costPrice: 850, currentStock: 28, minimumStock: 5, brand: 'SIMWOOL', hsnCode: '68061000', taxPercent: 18, createdAt: DateTime(2024, 5, 6)),
    ProductModel(id: 'p007', name: 'CF Board Grade 1260', sku: 'CFBD-1260', categoryId: 'cat_01', categoryName: 'Ceramic Fiber Products', subCategory: 'Ceramic Fiber Board', unit: 'Piece (pcs)', sellingPrice: 850, costPrice: 600, currentStock: 40, minimumStock: 10, brand: 'SIMVAC', hsnCode: '68061000', taxPercent: 18, createdAt: DateTime(2024, 5, 7), boardVariants: ['Normal Board']),
    ProductModel(id: 'p008', name: 'CF Board Grade 1425 (Zirconia)', sku: 'CFBD-1425', categoryId: 'cat_01', categoryName: 'Ceramic Fiber Products', subCategory: 'Ceramic Fiber Board', unit: 'Piece (pcs)', sellingPrice: 1650, costPrice: 1100, currentStock: 0, minimumStock: 5, brand: 'SIMVAC', hsnCode: '68061000', taxPercent: 18, createdAt: DateTime(2024, 5, 7), boardVariants: ['Vacuum Formed Board']),
    ProductModel(id: 'p009', name: 'CF Paper (1260°C, 5mm)', sku: 'CFP-1260-5', categoryId: 'cat_01', categoryName: 'Ceramic Fiber Products', subCategory: 'Ceramic Fiber Paper', unit: 'Roll', sellingPrice: 480, costPrice: 320, currentStock: 22, minimumStock: 5, brand: 'SIMWOOL', hsnCode: '68061000', taxPercent: 18, createdAt: DateTime(2024, 5, 8), thicknessVariants: ['5 mm']),
    ProductModel(id: 'p010', name: 'Heatshield Blanket', sku: 'HSB-001', categoryId: 'cat_01', categoryName: 'Ceramic Fiber Products', subCategory: 'Heatshield Blanket', unit: 'Piece (pcs)', sellingPrice: 3200, costPrice: 2200, currentStock: 12, minimumStock: 3, hsnCode: '68061000', taxPercent: 18, createdAt: DateTime(2024, 5, 9)),
    ProductModel(id: 'p011', name: 'CF Rope (13mm dia, 1260°C)', sku: 'CFR-13-1260', categoryId: 'cat_02', categoryName: 'Ceramic Fiber Textile', subCategory: 'Ceramic Fiber Rope', unit: 'Meter (m)', sellingPrice: 95, costPrice: 65, currentStock: 200, minimumStock: 50, brand: 'SIMWOOL', hsnCode: '70190000', taxPercent: 18, createdAt: DateTime(2024, 5, 10), reinforcementTypes: ['Fiberglass reinforced']),
    ProductModel(id: 'p012', name: 'CF Rope (25mm dia, 1260°C)', sku: 'CFR-25-1260', categoryId: 'cat_02', categoryName: 'Ceramic Fiber Textile', subCategory: 'Ceramic Fiber Rope', unit: 'Meter (m)', sellingPrice: 175, costPrice: 120, currentStock: 150, minimumStock: 30, brand: 'SIMWOOL', hsnCode: '70190000', taxPercent: 18, createdAt: DateTime(2024, 5, 10), reinforcementTypes: ['SS wire reinforced']),
    ProductModel(id: 'p013', name: 'CF Cloth (1260°C)', sku: 'CFC-1260', categoryId: 'cat_02', categoryName: 'Ceramic Fiber Textile', subCategory: 'Ceramic Fiber Cloth', unit: 'Meter (m)', sellingPrice: 420, costPrice: 290, currentStock: 80, minimumStock: 20, hsnCode: '70190000', taxPercent: 18, createdAt: DateTime(2024, 5, 11)),
    ProductModel(id: 'p014', name: 'CF Tape (1260°C, 25mm)', sku: 'CFT-25-1260', categoryId: 'cat_02', categoryName: 'Ceramic Fiber Textile', subCategory: 'Ceramic Fiber Tape', unit: 'Meter (m)', sellingPrice: 85, costPrice: 58, currentStock: 5, minimumStock: 20, hsnCode: '70190000', taxPercent: 18, createdAt: DateTime(2024, 5, 11)),
    ProductModel(id: 'p015', name: 'HF/CF Insulation Bricks (Hot Face)', sku: 'HFCF-HF', categoryId: 'cat_03', categoryName: 'Insulation Bricks', subCategory: 'HF/CF Insulation Bricks', unit: 'Piece (pcs)', sellingPrice: 65, costPrice: 45, currentStock: 500, minimumStock: 100, hsnCode: '69021000', taxPercent: 18, createdAt: DateTime(2024, 5, 12)),
    ProductModel(id: 'p016', name: 'HF/CF Insulation Bricks (Cold Face)', sku: 'HFCF-CF', categoryId: 'cat_03', categoryName: 'Insulation Bricks', subCategory: 'HF/CF Insulation Bricks', unit: 'Piece (pcs)', sellingPrice: 55, costPrice: 38, currentStock: 350, minimumStock: 100, hsnCode: '69021000', taxPercent: 18, createdAt: DateTime(2024, 5, 12)),
    ProductModel(id: 'p017', name: 'HFK Insulation Bricks', sku: 'HFK-001', categoryId: 'cat_03', categoryName: 'Insulation Bricks', subCategory: 'HFK Insulation Bricks', unit: 'Piece (pcs)', sellingPrice: 72, costPrice: 50, currentStock: 280, minimumStock: 50, hsnCode: '69021000', taxPercent: 18, createdAt: DateTime(2024, 5, 13)),
    ProductModel(id: 'p018', name: 'Porosint Bricks (Grade 23)', sku: 'POR-23', categoryId: 'cat_03', categoryName: 'Insulation Bricks', subCategory: 'Porosint Bricks', unit: 'Piece (pcs)', sellingPrice: 88, costPrice: 62, currentStock: 0, minimumStock: 50, hsnCode: '69021000', taxPercent: 18, createdAt: DateTime(2024, 5, 13)),
    ProductModel(id: 'p019', name: 'Refractory Mortar (ORTEX)', sku: 'RM-ORTEX', categoryId: 'cat_05', categoryName: 'Mortars & Castables', subCategory: 'Refractory Mortar (ORTEX)', unit: 'Bag', sellingPrice: 950, costPrice: 680, currentStock: 30, minimumStock: 10, brand: 'ORTEX', hsnCode: '38244000', taxPercent: 18, createdAt: DateTime(2024, 5, 14)),
    ProductModel(id: 'p020', name: 'Air Setting Mortar (ORTEX-HT)', sku: 'RM-ORTEX-HT', categoryId: 'cat_05', categoryName: 'Mortars & Castables', subCategory: 'Air Setting Mortar (ORTEX-HT)', unit: 'Bag', sellingPrice: 1200, costPrice: 850, currentStock: 18, minimumStock: 10, brand: 'ORTEX', hsnCode: '38244000', taxPercent: 18, createdAt: DateTime(2024, 5, 14)),
    ProductModel(id: 'p021', name: 'Castable Refractory', sku: 'CR-001', categoryId: 'cat_05', categoryName: 'Mortars & Castables', subCategory: 'Castable Refractory', unit: 'Bag', sellingPrice: 1450, costPrice: 980, currentStock: 25, minimumStock: 8, hsnCode: '38244000', taxPercent: 18, createdAt: DateTime(2024, 5, 15)),
    ProductModel(id: 'p022', name: 'Fire Blanket (1×1m, 650°C)', sku: 'FB-1x1-650', categoryId: 'cat_06', categoryName: 'Fire & Welding Protection', subCategory: 'Fire Blanket', unit: 'Piece (pcs)', sellingPrice: 1800, costPrice: 1200, currentStock: 20, minimumStock: 5, hsnCode: '63049200', taxPercent: 18, createdAt: DateTime(2024, 5, 16)),
    ProductModel(id: 'p023', name: 'Fire Blanket (2×2m, 1200°C)', sku: 'FB-2x2-1200', categoryId: 'cat_06', categoryName: 'Fire & Welding Protection', subCategory: 'Fire Blanket', unit: 'Piece (pcs)', sellingPrice: 4500, costPrice: 3100, currentStock: 8, minimumStock: 3, hsnCode: '63049200', taxPercent: 18, createdAt: DateTime(2024, 5, 16)),
    ProductModel(id: 'p024', name: 'Welding Blanket (2×3m)', sku: 'WB-2x3', categoryId: 'cat_06', categoryName: 'Fire & Welding Protection', subCategory: 'Welding Blanket', unit: 'Piece (pcs)', sellingPrice: 3800, costPrice: 2600, currentStock: 12, minimumStock: 3, hsnCode: '63049200', taxPercent: 18, createdAt: DateTime(2024, 5, 17)),
    ProductModel(id: 'p025', name: 'Stud & Washer Anchor (SS 304)', sku: 'SWA-SS304', categoryId: 'cat_07', categoryName: 'Accessories & Services', subCategory: 'Stud & Washer Anchor', unit: 'Piece (pcs)', sellingPrice: 45, costPrice: 30, currentStock: 800, minimumStock: 200, hsnCode: '73182900', taxPercent: 18, createdAt: DateTime(2024, 5, 18)),
    ProductModel(id: 'p026', name: 'Refractory Anchor (SS 310)', sku: 'RA-SS310', categoryId: 'cat_07', categoryName: 'Accessories & Services', subCategory: 'Refractory Anchor', unit: 'Piece (pcs)', sellingPrice: 85, costPrice: 58, currentStock: 350, minimumStock: 100, hsnCode: '73182900', taxPercent: 18, createdAt: DateTime(2024, 5, 19)),
  ];

  @override
  void onInit() {
    super.onInit();
    products.addAll(_seedProducts);
    filteredProducts.addAll(_seedProducts);
    ever(searchQuery, (_) => _applyFilters());
    ever(selectedCategory, (_) => _applyFilters());
    ever(selectedStatus, (_) => _applyFilters());
    ever(selectedStockStatus, (_) => _applyFilters());
  }

  void _applyFilters() {
    currentPage.value = 1;
    List<ProductModel> result = List.from(products);

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.sku.toLowerCase().contains(q) ||
        p.categoryName.toLowerCase().contains(q)
      ).toList();
    }

    if (selectedCategory.value != 'All Categories') {
      result = result.where((p) => p.categoryName == selectedCategory.value).toList();
    }

    if (selectedStatus.value == 'Active') {
      result = result.where((p) => p.isActive).toList();
    } else if (selectedStatus.value == 'Inactive') {
      result = result.where((p) => !p.isActive).toList();
    }

    if (selectedStockStatus.value != 'All') {
      result = result.where((p) => p.stockStatus == selectedStockStatus.value).toList();
    }

    filteredProducts.assignAll(result);
  }

  List<ProductModel> get paginatedProducts {
    final start = (currentPage.value - 1) * rowsPerPage.value;
    final end = (start + rowsPerPage.value).clamp(0, filteredProducts.length);
    return filteredProducts.sublist(start, end);
  }

  int get totalPages => (filteredProducts.length / rowsPerPage.value).ceil().clamp(1, 999);

  int get totalProducts => products.length;
  int get activeProducts => products.where((p) => p.isActive).length;
  int get lowStockProducts => products.where((p) => p.stockStatus == 'Low Stock').length;
  int get outOfStockProducts => products.where((p) => p.stockStatus == 'Out of Stock').length;

  void resetFilters() {
    searchQuery.value = '';
    selectedCategory.value = 'All Categories';
    selectedStatus.value = 'All Status';
    selectedStockStatus.value = 'All';
  }

  List<String> get subProductsForCategory {
    if (formCategory.value.isEmpty) return [];
    final cat = allCategories.firstWhereOrNull((c) => c.name == formCategory.value);
    return cat?.subProducts ?? [];
  }

  List<String> get categoryNames =>
      ['All Categories', ...allCategories.map((c) => c.name)];

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

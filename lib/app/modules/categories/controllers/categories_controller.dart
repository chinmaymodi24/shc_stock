import 'dart:typed_data';
import 'package:get/get.dart';
import '../../products/models/product_model.dart';

class CategoriesController extends GetxController {
  // ── Observable category list ─────────────────────────────────
  final RxList<ProductCategory> categories = <ProductCategory>[].obs;

  /// Total number of top-level categories.
  int get totalCategories => categories.length;

  /// Total number of sub-categories across all categories.
  int get totalSubCategories =>
      categories.fold(0, (sum, c) => sum + c.subProducts.length);

  // ── Seed data (SHC categories with descriptions) ─────────────
  static final List<ProductCategory> _seedCategories = [
    ProductCategory(
      id: 'cat_01',
      name: 'Ceramic Fiber Products',
      description: 'High-temperature insulation products made from ceramic fibers. '
          'Used in industrial furnaces, kilns, and thermal processing equipment. '
          'Available in various temperature ratings from 1000°C to 1600°C.',
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
      name: 'Ceramic Fiber Textile',
      description: 'Woven and braided ceramic fiber products for flexible thermal '
          'sealing, gasketing, and insulation in high-heat environments.',
      subProducts: [
        'Ceramic Fiber Rope',
        'Ceramic Fiber Cloth',
        'Ceramic Fiber Tape',
      ],
    ),
    ProductCategory(
      id: 'cat_03',
      name: 'Insulation Bricks',
      description: 'Lightweight refractory bricks for kiln and furnace lining. '
          'Provides excellent thermal shock resistance and low thermal conductivity.',
      subProducts: [
        'HF/CF Insulation Bricks',
        'HFK Insulation Bricks',
        'Porosint Bricks',
      ],
    ),
    ProductCategory(
      id: 'cat_04',
      name: 'Refractories',
      description: 'Dense refractory bricks and shapes designed to withstand '
          'extreme heat and mechanical stress in furnaces and process equipment.',
      subProducts: [
        'Fire Bricks',
        'Sillimanite & Mullite Bricks',
        'Burner Block',
        'Hollow Bricks',
      ],
    ),
    ProductCategory(
      id: 'cat_05',
      name: 'Mortars & Castables',
      description: 'Refractory mortars and castable compounds used for bonding, '
          'coating, and casting applications in high-temperature environments.',
      subProducts: [
        'Refractory Mortar (ORTEX)',
        'Air Setting Mortar (ORTEX-HT)',
        'Castable Refractory',
      ],
    ),
    ProductCategory(
      id: 'cat_06',
      name: 'Fire & Welding Protection',
      description: 'Fire-resistant blankets and welding protection products made '
          'from ceramic fiber and other fire-grade materials for safety applications.',
      subProducts: [
        'Fire Blanket',
        'Welding Blanket',
      ],
    ),
    ProductCategory(
      id: 'cat_07',
      name: 'Accessories & Services',
      description: 'Anchors, fasteners, and on-site hot insulation services that '
          'complement the primary product range for complete thermal solutions.',
      subProducts: [
        'Stud & Washer Anchor',
        'Ceramic Fiber Lining Anchor',
        'Brick Anchor',
        'Refractory Anchor',
        'Hot Insulation Service',
      ],
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    categories.assignAll(List.from(_seedCategories));
  }

  // ── CRUD — Categories ─────────────────────────────────────────

  /// Add a new top-level category.
  void addCategory(String name, {String desc = '', Uint8List? imageBytes}) {
    final id = 'cat_${DateTime.now().millisecondsSinceEpoch}';
    categories.add(ProductCategory(
      id: id,
      name: name.trim(),
      description: desc.trim(),
      subProducts: const [],
      subDescriptions: const [],
      imageBytes: imageBytes,
    ));
  }

  /// Update an existing category's name, description, and/or image.
  void updateCategory(String catId, String name, {String desc = '', Uint8List? imageBytes}) {
    final idx = categories.indexWhere((c) => c.id == catId);
    if (idx == -1) return;
    final old = categories[idx];
    categories[idx] = ProductCategory(
      id: old.id,
      name: name.trim(),
      description: desc.trim(),
      subProducts: List.from(old.subProducts),
      subDescriptions: List.from(old.subDescriptions),
      // If a new image was provided use it; otherwise keep the old one.
      imageBytes: imageBytes ?? old.imageBytes,
    );
  }

  /// Delete a category by ID.
  void deleteCategory(String catId) =>
      categories.removeWhere((c) => c.id == catId);

  /// Reorder categories (drag & drop).
  void reorderCategory(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final list = List<ProductCategory>.from(categories);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    categories.assignAll(list);
  }

  // ── CRUD — Sub-Categories ─────────────────────────────────────

  /// Add a new sub-category to a given parent category.
  void addSubCategory(String catId, String name, {String desc = ''}) {
    final idx = categories.indexWhere((c) => c.id == catId);
    if (idx == -1) return;
    final old = categories[idx];
    final newSubs  = List<String>.from(old.subProducts)..add(name.trim());
    final newDescs = List<String>.from(old.subDescriptions)..add(desc.trim());
    categories[idx] = ProductCategory(
      id: old.id, name: old.name, description: old.description,
      subProducts: newSubs, subDescriptions: newDescs,
    );
  }

  /// Update an existing sub-category's name and/or description.
  void updateSubCategory(
      String catId, int subIdx, String name, {String desc = ''}) {
    final idx = categories.indexWhere((c) => c.id == catId);
    if (idx == -1) return;
    final old      = categories[idx];
    final newSubs  = List<String>.from(old.subProducts);
    final newDescs = List<String>.from(old.subDescriptions);
    if (subIdx < newSubs.length)  newSubs[subIdx]  = name.trim();
    // Grow descriptions list if it's shorter than subs
    while (newDescs.length < newSubs.length) { newDescs.add(''); }
    if (subIdx < newDescs.length) newDescs[subIdx] = desc.trim();
    categories[idx] = ProductCategory(
      id: old.id, name: old.name, description: old.description,
      subProducts: newSubs, subDescriptions: newDescs,
    );
  }

  /// Delete a sub-category by index.
  void deleteSubCategory(String catId, int subIdx) {
    final idx = categories.indexWhere((c) => c.id == catId);
    if (idx == -1) return;
    final old      = categories[idx];
    final newSubs  = List<String>.from(old.subProducts);
    final newDescs = List<String>.from(old.subDescriptions);
    if (subIdx < newSubs.length)  newSubs.removeAt(subIdx);
    if (subIdx < newDescs.length) newDescs.removeAt(subIdx);
    categories[idx] = ProductCategory(
      id: old.id, name: old.name, description: old.description,
      subProducts: newSubs, subDescriptions: newDescs,
    );
  }

  /// Reorder sub-categories within a parent (drag & drop).
  void reorderSubCategory(String catId, int oldSi, int newSi) {
    if (oldSi == newSi) return;
    final idx = categories.indexWhere((c) => c.id == catId);
    if (idx == -1) return;
    final old      = categories[idx];
    final newSubs  = List<String>.from(old.subProducts);
    final newDescs = List<String>.from(old.subDescriptions);
    // Keep descriptions same length as subs
    while (newDescs.length < newSubs.length) { newDescs.add(''); }
    if (newSi > oldSi) newSi -= 1;
    newSubs.insert(newSi, newSubs.removeAt(oldSi));
    newDescs.insert(newSi, newDescs.removeAt(oldSi));
    categories[idx] = ProductCategory(
      id: old.id, name: old.name, description: old.description,
      subProducts: newSubs, subDescriptions: newDescs,
    );
  }
}

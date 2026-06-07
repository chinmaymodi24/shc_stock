import 'package:get/get.dart';
import '../../products/models/product_model.dart';

class CategoriesController extends GetxController {
  // ── Observable category list ─────────────────────────────────
  final RxList<ProductCategory> categories = <ProductCategory>[].obs;

  // ── Seed data (SHC categories) ───────────────────────────────
  static final List<ProductCategory> _seedCategories = [
    ProductCategory(id: 'cat_01', name: 'Ceramic Fiber Products', subProducts: [
      'Ceramic Fiber Blanket',
      'Ceramic Fiber Bulk (Loose Fiber)',
      'Ceramic Fiber Module',
      'Ceramic Fiber Board',
      'Ceramic Fiber Paper',
      'Heatshield Blanket',
    ]),
    ProductCategory(id: 'cat_02', name: 'Ceramic Fiber Textile', subProducts: [
      'Ceramic Fiber Rope',
      'Ceramic Fiber Cloth',
      'Ceramic Fiber Tape',
    ]),
    ProductCategory(id: 'cat_03', name: 'Insulation Bricks', subProducts: [
      'HF/CF Insulation Bricks',
      'HFK Insulation Bricks',
      'Porosint Bricks',
    ]),
    ProductCategory(id: 'cat_04', name: 'Refractories', subProducts: [
      'Fire Bricks',
      'Sillimanite & Mullite Bricks',
      'Burner Block',
      'Hollow Bricks',
    ]),
    ProductCategory(id: 'cat_05', name: 'Mortars & Castables', subProducts: [
      'Refractory Mortar (ORTEX)',
      'Air Setting Mortar (ORTEX-HT)',
      'Castable Refractory',
    ]),
    ProductCategory(id: 'cat_06', name: 'Fire & Welding Protection', subProducts: [
      'Fire Blanket',
      'Welding Blanket',
    ]),
    ProductCategory(id: 'cat_07', name: 'Accessories & Services', subProducts: [
      'Stud & Washer Anchor',
      'Ceramic Fiber Lining Anchor',
      'Brick Anchor',
      'Refractory Anchor',
      'Hot Insulation Service',
    ]),
  ];

  @override
  void onInit() {
    super.onInit();
    categories.addAll(_seedCategories);
  }

  // ── Getters ──────────────────────────────────────────────────
  int get totalCategories => categories.length;
  int get totalSubCategories =>
      categories.fold(0, (sum, c) => sum + c.subProducts.length);

  // ── Category CRUD ────────────────────────────────────────────
  void addCategory(String name) {
    if (name.trim().isEmpty) return;
    final id = 'cat_${DateTime.now().millisecondsSinceEpoch}';
    categories.add(ProductCategory(id: id, name: name.trim(), subProducts: []));
  }

  void updateCategory(String id, String newName) {
    if (newName.trim().isEmpty) return;
    final idx = categories.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    final old = categories[idx];
    categories[idx] = ProductCategory(
      id: old.id,
      name: newName.trim(),
      subProducts: old.subProducts,
    );
    categories.refresh();
  }

  void deleteCategory(String id) {
    categories.removeWhere((c) => c.id == id);
  }

  // ── Sub-category CRUD ────────────────────────────────────────
  void addSubCategory(String categoryId, String subName) {
    if (subName.trim().isEmpty) return;
    final idx = categories.indexWhere((c) => c.id == categoryId);
    if (idx == -1) return;
    final old = categories[idx];
    final updated = List<String>.from(old.subProducts)..add(subName.trim());
    categories[idx] = ProductCategory(
      id: old.id,
      name: old.name,
      subProducts: updated,
    );
    categories.refresh();
  }

  void updateSubCategory(String categoryId, int subIdx, String newName) {
    if (newName.trim().isEmpty) return;
    final idx = categories.indexWhere((c) => c.id == categoryId);
    if (idx == -1) return;
    final old = categories[idx];
    final updated = List<String>.from(old.subProducts);
    updated[subIdx] = newName.trim();
    categories[idx] = ProductCategory(
      id: old.id,
      name: old.name,
      subProducts: updated,
    );
    categories.refresh();
  }

  void deleteSubCategory(String categoryId, int subIdx) {
    final idx = categories.indexWhere((c) => c.id == categoryId);
    if (idx == -1) return;
    final old = categories[idx];
    final updated = List<String>.from(old.subProducts)..removeAt(subIdx);
    categories[idx] = ProductCategory(
      id: old.id,
      name: old.name,
      subProducts: updated,
    );
    categories.refresh();
  }

  void reorderSubCategory(String categoryId, int oldIdx, int newIdx) {
    final idx = categories.indexWhere((c) => c.id == categoryId);
    if (idx == -1) return;
    final old = categories[idx];
    final updated = List<String>.from(old.subProducts);
    final item = updated.removeAt(oldIdx);
    updated.insert(newIdx, item);
    categories[idx] = ProductCategory(
      id: old.id,
      name: old.name,
      subProducts: updated,
    );
    categories.refresh();
  }
}

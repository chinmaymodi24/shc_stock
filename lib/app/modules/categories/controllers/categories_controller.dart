import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/categories/models/category_model.dart';

class CategoriesController extends GetxController {
  /// Summary cards for this page — values *and* month-over-month trends come
  /// from GET /api/stats/categories, so nothing on the cards is computed here or
  /// hardcoded.
  final stats = StatsSnapshot.empty.obs;

  Future<void> fetchStats() async {
    try {
      stats.value = await StatsSnapshot.fetch('categories');
    } catch (e) {
      // Cards fall back to zeros; the list fetch already reported any outage.
    }
  }

  final _api = ApiClient.instance;

  // ── Observable category list ─────────────────────────────────
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxnString selectedCatId = RxnString();
  final RxBool isLoading = false.obs;
  final searchCtrl = TextEditingController();
  final RxString searchQuery = ''.obs;

  bool get hasActiveFilters => searchQuery.value.isNotEmpty;

  void resetFilters() {
    searchCtrl.clear();
    searchQuery.value = '';
  }

  /// Categories narrowed by the search box — what the list actually renders.
  List<CategoryModel> get visibleCategories {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return categories;
    return categories.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  /// Total number of top-level categories.
  int get totalCategories => categories.length;

  /// Total number of sub-categories across all categories.
  int get totalSubCategories =>
      categories.fold(0, (sum, c) => sum + c.subCategories.length);

  @override
  void onInit() {
    super.onInit();
    fetchStats();
    fetchCategories();
  }

  void _showError(String message) {
    showAppToast(
      'Error',
      message,
      backgroundColor: const Color(0xFFEF4444),
      colorText: Colors.white,
    );
  }

  // ── Fetch ────────────────────────────────────────────────────
  Future<void> fetchCategories() async {
    isLoading.value = true;
    try {
      final data = await _api.get('/categories') as List<dynamic>;
      categories.assignAll(
        data.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)),
      );
      // Keep the sidebar highlight in sync with the detail panel's fallback
      // selection (first category) when nothing is selected yet.
      if (categories.isNotEmpty &&
          !categories.any((c) => c.id == selectedCatId.value)) {
        selectedCatId.value = categories.first.id;
      }
    } catch (e) {
      _showError('Failed to load categories. Is the backend running?');
    } finally {
      isLoading.value = false;
    }
  }

  // ── CRUD — Categories ─────────────────────────────────────────

  /// Add a new top-level category.
  Future<void> addCategory(String name, {String desc = ''}) async {
    try {
      final json = await _api.post('/categories', {
        'name': name.trim(),
        'description': desc.trim(),
      });
      categories.add(CategoryModel.fromJson(json as Map<String, dynamic>));
    } catch (e) {
      _showError('Failed to add category.');
    }
  }

  /// Update an existing category's name and/or description.
  Future<void> updateCategory(
    String catId,
    String name, {
    String desc = '',
  }) async {
    try {
      final json = await _api.put('/categories/$catId', {
        'name': name.trim(),
        'description': desc.trim(),
      });
      final idx = categories.indexWhere((c) => c.id == catId);
      if (idx != -1) {
        categories[idx] = CategoryModel.fromJson(json as Map<String, dynamic>);
      }
    } catch (e) {
      _showError('Failed to update category.');
    }
  }

  /// Delete a category by ID.
  Future<void> deleteCategory(String catId) async {
    try {
      await _api.delete('/categories/$catId');
      categories.removeWhere((c) => c.id == catId);
    } catch (e) {
      _showError('Failed to delete category.');
    }
  }

  /// Reorder categories (drag & drop). Optimistically updates the UI, then
  /// persists the new order; reverts by re-fetching if the request fails.
  Future<void> reorderCategory(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final list = List<CategoryModel>.from(categories);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    categories.assignAll(list);
    try {
      await _api.patch('/categories/reorder', {
        'orderedIds': list.map((c) => c.apiId).toList(),
      });
    } catch (e) {
      _showError('Failed to save new order.');
      await fetchCategories();
    }
  }

  // ── CRUD — Sub-Categories ─────────────────────────────────────

  /// Add a new sub-category to a given parent category.
  Future<void> addSubCategory(
    String catId,
    String name, {
    String desc = '',
  }) async {
    final idx = categories.indexWhere((c) => c.id == catId);
    if (idx == -1) return;
    try {
      final json = await _api.post('/categories/$catId/sub-categories', {
        'name': name.trim(),
        'description': desc.trim(),
      });
      final old = categories[idx];
      final newSubs = List<SubCategoryItem>.from(old.subCategories)
        ..add(SubCategoryItem.fromJson(json as Map<String, dynamic>));
      categories[idx] = old.copyWith(subCategories: newSubs);
    } catch (e) {
      _showError('Failed to add sub-category.');
    }
  }

  /// Update an existing sub-category's name and/or description.
  Future<void> updateSubCategory(
    String catId,
    int subIdx,
    String name, {
    String desc = '',
  }) async {
    final idx = categories.indexWhere((c) => c.id == catId);
    if (idx == -1) return;
    final old = categories[idx];
    if (subIdx < 0 || subIdx >= old.subCategories.length) return;
    final sub = old.subCategories[subIdx];
    try {
      final json = await _api.put('/sub-categories/${sub.id}', {
        'name': name.trim(),
        'description': desc.trim(),
      });
      final newSubs = List<SubCategoryItem>.from(old.subCategories);
      newSubs[subIdx] = SubCategoryItem.fromJson(json as Map<String, dynamic>);
      categories[idx] = old.copyWith(subCategories: newSubs);
    } catch (e) {
      _showError('Failed to update sub-category.');
    }
  }

  /// Delete a sub-category by index.
  Future<void> deleteSubCategory(String catId, int subIdx) async {
    final idx = categories.indexWhere((c) => c.id == catId);
    if (idx == -1) return;
    final old = categories[idx];
    if (subIdx < 0 || subIdx >= old.subCategories.length) return;
    final sub = old.subCategories[subIdx];
    try {
      await _api.delete('/sub-categories/${sub.id}');
      final newSubs = List<SubCategoryItem>.from(old.subCategories)
        ..removeAt(subIdx);
      categories[idx] = old.copyWith(subCategories: newSubs);
    } catch (e) {
      _showError('Failed to delete sub-category.');
    }
  }

  /// Reorder sub-categories within a parent (drag & drop).
  Future<void> reorderSubCategory(String catId, int oldSi, int newSi) async {
    if (oldSi == newSi) return;
    final idx = categories.indexWhere((c) => c.id == catId);
    if (idx == -1) return;
    final old = categories[idx];
    final newSubs = List<SubCategoryItem>.from(old.subCategories);
    if (newSi > oldSi) newSi -= 1;
    newSubs.insert(newSi, newSubs.removeAt(oldSi));
    categories[idx] = old.copyWith(subCategories: newSubs);
    try {
      await _api.patch('/sub-categories/reorder', {
        'categoryId': old.apiId,
        'orderedIds': newSubs.map((s) => s.id).toList(),
      });
    } catch (e) {
      _showError('Failed to save new order.');
      await fetchCategories();
    }
  }
}

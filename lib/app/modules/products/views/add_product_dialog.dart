import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/categories/controllers/categories_controller.dart';
import 'package:shc_stock/app/modules/categories/models/category_model.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';

CategoriesController _categoriesController() {
  if (Get.isRegistered<CategoriesController>()) {
    return Get.find<CategoriesController>();
  }
  return Get.put(CategoriesController(), permanent: true);
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit Product — compact dialog, wired to the real backend API
// (categories/sub-categories come from CategoriesController; saving goes
// through ProductsController.addProduct / updateProduct, both dio-backed).
// ─────────────────────────────────────────────────────────────────────────────
class AddProductDialog extends StatefulWidget {
  /// Pass an existing product to edit it; omit to add a new one.
  final ProductModel? product;
  const AddProductDialog({super.key, this.product});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _hsnCtrl;
  late final TextEditingController _costPriceCtrl;
  late final TextEditingController _sellPriceCtrl;
  late final TextEditingController _stockCtrl;
  // Dialog-local reactive selects — kept as Rx on the persistent State
  // object (not setState) so only the dependent dropdowns repaint.
  final _category = ''.obs;
  final _subCategory = ''.obs;
  final _unit = ''.obs;
  final _saving = false.obs;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _hsnCtrl = TextEditingController(text: p?.hsnCode ?? '');
    _costPriceCtrl = TextEditingController(
      text: p == null ? '' : p.costPrice.toStringAsFixed(0),
    );
    _sellPriceCtrl = TextEditingController(
      text: p == null ? '' : p.sellingPrice.toStringAsFixed(0),
    );
    _stockCtrl = TextEditingController(
      text: p == null ? '' : p.currentStock.toString(),
    );
    _category.value = p?.categoryName ?? '';
    _subCategory.value = p?.subCategory ?? '';
    _unit.value = p?.unit ?? '';
  }

  List<CategoryModel> get _categories => _categoriesController().categories;

  List<String> _subCategoryOptionsFor(String categoryName) {
    final cat = _categories.firstWhereOrNull((c) => c.name == categoryName);
    return cat?.subProducts ?? const [];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _hsnCtrl.dispose();
    _costPriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _stockCtrl.dispose();
    _category.close();
    _subCategory.close();
    _unit.close();
    _saving.close();
    super.dispose();
  }

  void _error(String msg) {
    showAppToast(
      'Validation Error',
      msg,
      backgroundColor: const Color(0xFFEF4444),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      return _error('Product Name is required.');
    }
    if (_skuCtrl.text.trim().isEmpty) return _error('SKU is required.');
    if (_category.value.isEmpty) return _error('Category is required.');
    if (_unit.value.isEmpty) return _error('Unit is required.');
    final sellPrice = double.tryParse(_sellPriceCtrl.text.trim());
    final costPrice = double.tryParse(_costPriceCtrl.text.trim());
    if (sellPrice == null) return _error('Selling Price is required.');
    if (costPrice == null) return _error('Cost Price is required.');

    final cat = _categories.firstWhereOrNull((c) => c.name == _category.value);
    if (cat == null) return _error('Selected category is invalid.');
    final subIdx = cat.subProducts.indexOf(_subCategory.value);
    final subId = subIdx == -1 ? null : cat.subCategories[subIdx].id;

    _saving.value = true;
    final c = Get.find<ProductsController>();
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;
    final ok = _isEdit
        ? await c.updateProduct(
            id: widget.product!.id,
            name: _nameCtrl.text.trim(),
            sku: _skuCtrl.text.trim(),
            categoryId: cat.apiId,
            subCategoryId: subId,
            unit: _unit.value,
            sellingPrice: sellPrice,
            costPrice: costPrice,
            currentStock: stock,
            hsnCode: _hsnCtrl.text.trim(),
          )
        : await c.addProduct(
            name: _nameCtrl.text.trim(),
            sku: _skuCtrl.text.trim(),
            categoryId: cat.apiId,
            subCategoryId: subId,
            unit: _unit.value,
            sellingPrice: sellPrice,
            costPrice: costPrice,
            currentStock: stock,
            hsnCode: _hsnCtrl.text.trim(),
          );
    _saving.value = false;
    if (!ok) return; // controller already showed the error toast

    Get.back();
    showAppToast(
      _isEdit ? '✅ Product Updated' : '✅ Product Added',
      '${_nameCtrl.text.trim()} has been ${_isEdit ? 'updated' : 'added'}.',
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEdit ? 'Edit Product' : 'Add Product',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label(text: 'Product Name', colors: colors),
                            const SizedBox(height: 6),
                            _TextBox(
                              controller: _nameCtrl,
                              hint: 'Product name...',
                              colors: colors,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label(text: 'SKU', colors: colors),
                            const SizedBox(height: 6),
                            _TextBox(
                              controller: _skuCtrl,
                              hint: 'SKU...',
                              colors: colors,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _Label(text: 'Category', colors: colors),
                  const SizedBox(height: 6),
                  Obx(
                    () => _DropBox(
                      hint: 'Select category...',
                      value: _category.value.isEmpty ? null : _category.value,
                      items: _categories.map((c) => c.name).toList(),
                      colors: colors,
                      onChanged: (v) {
                        _category.value = v ?? '';
                        _subCategory.value = '';
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  _Label(text: 'Subcategory', colors: colors),
                  const SizedBox(height: 6),
                  Obx(
                    () => _DropBox(
                      hint: 'Select subcategory...',
                      value: _subCategory.value.isEmpty
                          ? null
                          : _subCategory.value,
                      items: _subCategoryOptionsFor(_category.value),
                      colors: colors,
                      onChanged: (v) => _subCategory.value = v ?? '',
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label(text: 'Unit', colors: colors),
                            const SizedBox(height: 6),
                            Obx(
                              () => _DropBox(
                                hint: 'Select unit...',
                                value: _unit.value.isEmpty ? null : _unit.value,
                                items: ProductsController.units,
                                colors: colors,
                                onChanged: (v) => _unit.value = v ?? '',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label(text: 'HSN Code', colors: colors),
                            const SizedBox(height: 6),
                            _TextBox(
                              controller: _hsnCtrl,
                              hint: 'e.g. 68061000',
                              colors: colors,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label(text: 'Cost Price (₹)', colors: colors),
                            const SizedBox(height: 6),
                            _TextBox(
                              controller: _costPriceCtrl,
                              hint: '0',
                              colors: colors,
                              numeric: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label(text: 'Selling Price (₹)', colors: colors),
                            const SizedBox(height: 6),
                            _TextBox(
                              controller: _sellPriceCtrl,
                              hint: '0',
                              colors: colors,
                              numeric: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _Label(text: 'Stock Qty', colors: colors),
                  const SizedBox(height: 6),
                  _TextBox(
                    controller: _stockCtrl,
                    hint: '0',
                    colors: colors,
                    numeric: true,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: colors.rowEven,
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(
                          () => ElevatedButton(
                            onPressed: _saving.value ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _saving.value
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isEdit ? 'Update' : 'Save',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final AppThemeColors colors;
  const _Label({required this.text, required this.colors});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: colors.textPrimary,
      fontFamily: 'Poppins',
    ),
  );
}

class _TextBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final AppThemeColors colors;
  final bool numeric;
  const _TextBox({
    required this.controller,
    required this.hint,
    required this.colors,
    this.numeric = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : null,
      style: TextStyle(
        fontSize: 13,
        color: colors.textPrimary,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: colors.textHint,
          fontFamily: 'Poppins',
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        filled: true,
        fillColor: colors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.primaryOrange,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _DropBox extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final AppThemeColors colors;
  final ValueChanged<String?> onChanged;

  const _DropBox({
    required this.hint,
    required this.value,
    required this.items,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeVal = (value != null && items.contains(value)) ? value : null;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeVal,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 13,
              color: colors.textHint,
              fontFamily: 'Poppins',
            ),
          ),
          isDense: true,
          isExpanded: true,
          dropdownColor: colors.surface,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: colors.textSecondary,
          ),
          style: TextStyle(
            fontSize: 13,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
          items: items
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(v, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/products_controller.dart';
import '../models/product_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_toast.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Add Product — compact dialog (quick-add, replaces the full add-product page)
// ─────────────────────────────────────────────────────────────────────────────
class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _nameCtrl = TextEditingController();
  final _hsnCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  // Dialog-local reactive selects — kept as Rx on the persistent State
  // object (not setState) so only the dependent dropdowns repaint.
  final _category = ''.obs;
  final _subCategory = ''.obs;

  static String _stripPrefix(String s) =>
      s.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();

  List<String> _subCategoryOptionsFor(String category) {
    if (category.isEmpty) return const [];
    final cat = ProductsController.allCategories.firstWhereOrNull(
      (c) => c.name == category,
    );
    return cat?.subProducts ?? const [];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hsnCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _category.close();
    _subCategory.close();
    super.dispose();
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      showAppToast(
        'Validation Error',
        'Product Name is required.',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    final c = Get.find<ProductsController>();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;
    c.addProduct(
      ProductModel(
        id: 'p_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameCtrl.text.trim(),
        sku: _nameCtrl.text
            .trim()
            .substring(0, _nameCtrl.text.trim().length.clamp(0, 3))
            .toUpperCase(),
        categoryId: '',
        categoryName: _category.value.isEmpty
            ? 'Uncategorized'
            : _stripPrefix(_category.value),
        subCategory: _subCategory.value,
        unit: '',
        sellingPrice: price,
        costPrice: price,
        currentStock: stock,
        minimumStock: 10,
        hsnCode: _hsnCtrl.text.trim().isEmpty ? null : _hsnCtrl.text.trim(),
        createdAt: DateTime.now(),
        modifiedBy: 'Admin',
        modifiedAt: DateTime.now(),
      ),
    );
    Get.back();
    showAppToast(
      '✅ Product Added',
      '${_nameCtrl.text.trim()} has been added.',
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
          constraints: const BoxConstraints(maxWidth: 400),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Product',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 18),

                _Label(text: 'Product Name', colors: colors),
                const SizedBox(height: 6),
                _TextBox(
                  controller: _nameCtrl,
                  hint: 'Product name...',
                  colors: colors,
                ),
                const SizedBox(height: 16),

                _Label(text: 'Category', colors: colors),
                const SizedBox(height: 6),
                Obx(
                  () => _DropBox(
                    hint: 'Select category...',
                    value: _category.value.isEmpty ? null : _category.value,
                    items: ProductsController.allCategories
                        .map((c) => c.name)
                        .toList(),
                    displayLabel: _stripPrefix,
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

                _Label(text: 'HSN Code', colors: colors),
                const SizedBox(height: 6),
                _TextBox(
                  controller: _hsnCtrl,
                  hint: 'e.g. 68061000',
                  colors: colors,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label(text: 'Price (₹)', colors: colors),
                          const SizedBox(height: 6),
                          _TextBox(
                            controller: _priceCtrl,
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
                          _Label(text: 'Stock Qty', colors: colors),
                          const SizedBox(height: 6),
                          _TextBox(
                            controller: _stockCtrl,
                            hint: '0',
                            colors: colors,
                            numeric: true,
                          ),
                        ],
                      ),
                    ),
                  ],
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
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Poppins',
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
  final String Function(String)? displayLabel;

  const _DropBox({
    required this.hint,
    required this.value,
    required this.items,
    required this.colors,
    required this.onChanged,
    this.displayLabel,
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
                  child: Text(
                    displayLabel?.call(v) ?? v,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

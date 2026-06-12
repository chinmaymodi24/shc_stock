import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/products_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../dashboard/widgets/app_drawer.dart';

class MobileAddProductLayout extends StatelessWidget {
  const MobileAddProductLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProductsController>();
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      drawer: const AppDrawer(activeRoute: AppRoutes.products),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MobileAddInfoSection(c: c),
            const SizedBox(height: 16),
            _MobileVariantsSection(c: c),
            const SizedBox(height: 16),
            const _MobilePricingSection(),
            const SizedBox(height: 16),
            const _MobileImageSection(),
            const SizedBox(height: 16),
            _MobileStatusSection(c: c),
            const SizedBox(height: 24),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE0DFF5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B6B8A),
                            fontFamily: 'Poppins')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.snackbar(
                        'Success',
                        'Product saved successfully!',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: const Color(0xFF22C55E),
                        colorText: Colors.white,
                        margin: const EdgeInsets.all(16),
                        borderRadius: 12,
                      );
                      Get.back();
                    },
                    icon: const Icon(Icons.save_rounded,
                        color: Colors.white, size: 18),
                    label: const Text('Save Product',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Poppins')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colors = context.appColors;
    return AppBar(
      backgroundColor: colors.topBarBg,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary, size: 24),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ),
      title: Text('Add Product',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              fontFamily: 'Poppins')),
      actions: [
        Stack(children: [
          IconButton(
              icon: Icon(Icons.notifications_outlined, color: colors.textPrimary, size: 24),
              onPressed: () {}),
          Positioned(
              top: 10,
              right: 10,
              child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle))),
        ]),
      ],
      bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: colors.divider)),
    );
  }
}

// ── Shared Mobile Form Section Card ──────────────────────────────────────────
class _MobileSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _MobileSectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Mobile Form Field ─────────────────────────────────────────────────────────
class _MobileFormField extends StatelessWidget {
  final String label;
  final Widget child;
  final bool required;

  const _MobileFormField(
      {required this.label, required this.child, this.required = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
                fontFamily: 'Poppins'),
            children: [
              TextSpan(text: label),
              if (required)
                const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Color(0xFFEF4444))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ── Mobile Styled TextField ───────────────────────────────────────────────────
class _MobileTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _MobileTextField({
    this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(
          fontSize: 13, color: colors.textPrimary, fontFamily: 'Poppins'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontSize: 13, color: colors.textHint, fontFamily: 'Poppins'),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
          borderSide:
              const BorderSide(color: AppColors.primaryOrange, width: 1.5),
        ),
        filled: true,
        fillColor: colors.inputFill,
      ),
    );
  }
}

// ── Mobile Styled Dropdown ────────────────────────────────────────────────────
class _MobileDropdown extends StatelessWidget {
  final String? value;
  final String? hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _MobileDropdown({
    this.value,
    this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DropdownButtonFormField<String>(
      value: value,
      isDense: true,
      isExpanded: true,
      dropdownColor: colors.surface,
      style: TextStyle(
          fontSize: 13, color: colors.textPrimary, fontFamily: 'Poppins'),
      hint: hint != null
          ? Text(hint!,
              style: TextStyle(
                  fontSize: 13,
                  color: colors.textHint,
                  fontFamily: 'Poppins'))
          : null,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
          borderSide:
              const BorderSide(color: AppColors.primaryOrange, width: 1.5),
        ),
        filled: true,
        fillColor: colors.inputFill,
      ),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child:
                    Text(e, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ── Section: Add Information (Mobile) ────────────────────────────────────────
class _MobileAddInfoSection extends StatefulWidget {
  final ProductsController c;
  const _MobileAddInfoSection({required this.c});

  @override
  State<_MobileAddInfoSection> createState() => _MobileAddInfoSectionState();
}

class _MobileAddInfoSectionState extends State<_MobileAddInfoSection> {
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _brandCtrl = TextEditingController(text: 'Secure Heat Care');
  final _hsnCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedUnit = 'Kilogram (kg)';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _brandCtrl.dispose();
    _hsnCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return _MobileSectionCard(
      title: 'Product Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category
          Obx(() => _MobileFormField(
                label: 'Category',
                required: true,
                child: _MobileDropdown(
                  hint: 'Select Category',
                  value:
                      c.formCategory.value.isEmpty ? null : c.formCategory.value,
                  items:
                      ProductsController.allCategories.map((e) => e.name).toList(),
                  onChanged: (v) {
                    if (v != null) c.onCategoryChanged(v);
                  },
                ),
              )),
          const SizedBox(height: 12),
          // Sub Category
          Obx(() => _MobileFormField(
                label: 'Sub Category / Product',
                required: true,
                child: _MobileDropdown(
                  hint: 'Select Sub Category',
                  value: c.formSubCategory.value.isEmpty
                      ? null
                      : c.formSubCategory.value,
                  items: c.subProductsForCategory,
                  onChanged: (v) {
                    if (v != null) c.formSubCategory.value = v;
                  },
                ),
              )),
          const SizedBox(height: 12),
          // Product Name
          _MobileFormField(
            label: 'Product Name',
            required: true,
            child: _MobileTextField(
                controller: _nameCtrl, hint: 'Enter product name'),
          ),
          const SizedBox(height: 12),
          // SKU
          _MobileFormField(
            label: 'SKU / Product Code',
            required: true,
            child: _MobileTextField(
                controller: _skuCtrl, hint: 'e.g. CFB-1260-64'),
          ),
          const SizedBox(height: 12),
          // Unit
          _MobileFormField(
            label: 'Unit',
            required: true,
            child: _MobileDropdown(
              hint: 'Select Unit',
              value: _selectedUnit,
              items: ProductsController.units,
              onChanged: (v) {
                if (v != null) setState(() => _selectedUnit = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          // Brand
          _MobileFormField(
            label: 'Brand (Optional)',
            child: _MobileTextField(
                controller: _brandCtrl, hint: 'e.g. SIMWOOL'),
          ),
          const SizedBox(height: 12),
          // HSN Code
          _MobileFormField(
            label: 'HSN Code (Optional)',
            child: _MobileTextField(
                controller: _hsnCtrl, hint: 'e.g. 68061000'),
          ),
          const SizedBox(height: 12),
          // Description
          _MobileFormField(
            label: 'Description',
            child: _MobileTextField(
                controller: _descCtrl,
                hint: 'Enter product description...',
                maxLines: 3),
          ),
        ],
      ),
    );
  }
}

// ── Section: Variants (Mobile) ────────────────────────────────────────────────
class _MobileVariantsSection extends StatelessWidget {
  final ProductsController c;
  const _MobileVariantsSection({required this.c});

  @override
  Widget build(BuildContext context) {
    return _MobileSectionCard(
      title: 'Variants / Specifications',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MobileVariantToggle(
            label: 'Density Variants (Blanket)',
            enabledObs: c.densityVariantsEnabled,
            options: ProductsController.densityOptions,
            selectedObs: c.selectedDensities,
            onToggle: c.toggleDensity,
          ),
          const SizedBox(height: 12),
          _MobileVariantToggle(
            label: 'Board Variants',
            enabledObs: c.boardVariantsEnabled,
            options: ProductsController.boardVariantOptions,
            selectedObs: c.selectedBoardTypes,
            onToggle: c.toggleBoardType,
          ),
          const SizedBox(height: 12),
          _MobileVariantToggle(
            label: 'Thickness Variants (Paper)',
            enabledObs: c.thicknessVariantsEnabled,
            options: ProductsController.thicknessOptions,
            selectedObs: c.selectedThicknesses,
            onToggle: c.toggleThickness,
          ),
          const SizedBox(height: 12),
          _MobileVariantToggle(
            label: 'Reinforcement Types (Rope & Textiles)',
            enabledObs: c.reinforcementEnabled,
            options: ProductsController.reinforcementOptions,
            selectedObs: c.selectedReinforcements,
            onToggle: c.toggleReinforcement,
          ),
          const SizedBox(height: 12),
          _MobileFormField(
            label: 'Other Specifications (Optional)',
            child: _MobileTextField(
                hint: 'Enter any other specifications...'),
          ),
        ],
      ),
    );
  }
}

class _MobileVariantToggle extends StatelessWidget {
  final String label;
  final RxBool enabledObs;
  final List<String> options;
  final RxSet<String> selectedObs;
  final void Function(String) onToggle;

  const _MobileVariantToggle({
    required this.label,
    required this.enabledObs,
    required this.options,
    required this.selectedObs,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Obx(() => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.comingSoonBadge,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins')),
                  ),
                  Switch(
                    value: enabledObs.value,
                    onChanged: (v) => enabledObs.value = v,
                    activeColor: AppColors.primaryOrange,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              if (enabledObs.value) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: options.map((opt) {
                    final isSelected = selectedObs.contains(opt);
                    return GestureDetector(
                      onTap: () => onToggle(opt),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryOrange
                              : colors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryOrange
                                : colors.border,
                          ),
                        ),
                        child: Text(opt,
                            style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Poppins',
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? Colors.white
                                    : colors.textSecondary)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ));
  }
}

// ── Section: Pricing & Stock (Mobile) ────────────────────────────────────────
class _MobilePricingSection extends StatefulWidget {
  const _MobilePricingSection();

  @override
  State<_MobilePricingSection> createState() => _MobilePricingSectionState();
}

class _MobilePricingSectionState extends State<_MobilePricingSection> {
  final _sellPriceCtrl = TextEditingController(text: '0.00');
  final _costPriceCtrl = TextEditingController(text: '0.00');
  final _openStockCtrl = TextEditingController(text: '0');
  final _minStockCtrl = TextEditingController(text: '10');
  String _tax = '18% GST';
  String _location = 'Main Warehouse';

  @override
  void dispose() {
    _sellPriceCtrl.dispose();
    _costPriceCtrl.dispose();
    _openStockCtrl.dispose();
    _minStockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MobileSectionCard(
      title: 'Pricing & Stock',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: _MobileFormField(
                label: 'Selling Price (₹)',
                required: true,
                child: _MobileTextField(
                    controller: _sellPriceCtrl,
                    hint: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MobileFormField(
                label: 'Cost Price (₹)',
                child: _MobileTextField(
                    controller: _costPriceCtrl,
                    hint: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true)),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _MobileFormField(
                label: 'Opening Stock',
                required: true,
                child: _MobileTextField(
                    controller: _openStockCtrl,
                    hint: '0',
                    keyboardType: TextInputType.number),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MobileFormField(
                label: 'Min Stock Level',
                child: _MobileTextField(
                    controller: _minStockCtrl,
                    hint: '10',
                    keyboardType: TextInputType.number),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _MobileFormField(
                label: 'Tax (%)',
                child: _MobileDropdown(
                  value: _tax,
                  items: ProductsController.taxOptions,
                  onChanged: (v) {
                    if (v != null) setState(() => _tax = v);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MobileFormField(
                label: 'Stock Location',
                child: _MobileDropdown(
                  value: _location,
                  items: ProductsController.stockLocations,
                  onChanged: (v) {
                    if (v != null) setState(() => _location = v);
                  },
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Section: Product Image (Mobile) ──────────────────────────────────────────
class _MobileImageSection extends StatelessWidget {
  const _MobileImageSection();

  @override
  Widget build(BuildContext context) {
    return _MobileSectionCard(
      title: 'Product Image',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FF),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFFE0DFF5), style: BorderStyle.solid),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                      color: Color(0xFFEEECFF), shape: BoxShape.circle),
                  child: const Icon(Icons.cloud_upload_outlined,
                      color: AppColors.primaryPurple, size: 26),
                ),
                const SizedBox(height: 10),
                const Text('Tap to upload image',
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B6B8A),
                        fontFamily: 'Poppins')),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Browse Image',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontFamily: 'Poppins')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('JPG, PNG or WEBP. Max size of 2MB.',
              style: TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF9B9BB4),
                  fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}

// ── Section: Status (Mobile) ──────────────────────────────────────────────────
class _MobileStatusSection extends StatefulWidget {
  final ProductsController c;
  const _MobileStatusSection({required this.c});

  @override
  State<_MobileStatusSection> createState() => _MobileStatusSectionState();
}

class _MobileStatusSectionState extends State<_MobileStatusSection> {
  String _productStatus = 'Active';

  @override
  Widget build(BuildContext context) {
    return _MobileSectionCard(
      title: 'Status',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MobileFormField(
            label: 'Product Status',
            required: true,
            child: _MobileDropdown(
              value: _productStatus,
              items: const ['Active', 'Inactive'],
              onChanged: (v) {
                if (v != null) setState(() => _productStatus = v);
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Low Stock Alert',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1240),
                      fontFamily: 'Poppins')),
              Obx(() => Switch(
                    value: widget.c.lowStockAlertEnabled.value,
                    onChanged: (v) => widget.c.lowStockAlertEnabled.value = v,
                    activeColor: AppColors.primaryOrange,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

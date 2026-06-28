import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:get/get.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import '../controllers/products_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/widgets/web_sidebar.dart';
import 'mobile_add_product_layout.dart';
import 'web_add_product_layout.dart';

class AddProductView extends StatelessWidget {
  const AddProductView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) return const WebAddProductLayout();
        return const MobileAddProductLayout();
      },
    );
  }
}

class _WebAddProductLayout extends StatelessWidget {
  const _WebAddProductLayout();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProductsController>();
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          const WebSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBreadcrumb(context),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: Main form
                            Expanded(
                              flex: 7,
                              child: Column(
                                children: [
                                  _AddInfoSection(c: c),
                                  const SizedBox(height: 20),
                                  _VariantsSection(c: c),
                                  const SizedBox(height: 20),
                                  _PricingSection(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Right: Image + Status
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _ImageSection(),
                                  const SizedBox(height: 20),
                                  _StatusSection(c: c),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Get.back(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE0DFF5)),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('Cancel', style: TextStyle(fontSize: 14, color: colors.textSecondary, fontFamily: 'Poppins')),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                Get.snackbar('Success', 'Product saved successfully!',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: const Color(0xFF22C55E),
                                  colorText: Colors.white,
                                );
                                Get.back();
                              },
                              icon: const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                              label: const Text('Save Product', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryOrange,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colors.topBarBg,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          const Spacer(),
          Stack(children: [
            IconButton(icon: Icon(Icons.notifications_outlined, color: colors.textPrimary, size: 24), onPressed: () {}),
            Positioned(top: 8, right: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
          ]),
          const SizedBox(width: 4),
          CircleAvatar(radius: 18, backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15), child: const Icon(Icons.person_rounded, color: AppColors.primaryOrange, size: 20)),
          const SizedBox(width: 8),
          const Text('Admin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
          Icon(Icons.keyboard_arrow_down_rounded, color: colors.textSecondary, size: 18),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: Text('Home', style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Poppins')),
        ),
        Icon(Icons.chevron_right_rounded, size: 16, color: colors.textHint),
        GestureDetector(
          onTap: () => Get.back(),
          child: Text('Products', style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Poppins')),
        ),
        Icon(Icons.chevron_right_rounded, size: 16, color: colors.textHint),
        Text('Add Product', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary, fontFamily: 'Poppins')),
      ],
    );
  }
}

// ── Section: Add Information ──────────────────────────────────────────────────
class _AddInfoSection extends StatefulWidget {
  final ProductsController c;
  const _AddInfoSection({required this.c});
  @override
  State<_AddInfoSection> createState() => _AddInfoSectionState();
}

class _AddInfoSectionState extends State<_AddInfoSection> {
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _brandCtrl = TextEditingController(text: 'Secure Heat Care');
  final _hsnCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedUnit = 'Kilogram (kg)';

  @override
  void dispose() {
    _nameCtrl.dispose(); _skuCtrl.dispose(); _brandCtrl.dispose();
    _hsnCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return _FormCard(
      title: 'Add Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Category | Sub Category | Product Name
          Row(children: [
            Expanded(child: Obx(() => _FormField(
              label: 'Category *',
              child: _StyledDropdown(
                hint: 'Select Category',
                value: c.formCategory.value.isEmpty ? null : c.formCategory.value,
                items: ProductsController.allCategories.map((e) => e.name).toList(),
                onChanged: (v) { if (v != null) c.onCategoryChanged(v); },
              ),
            ))),
            const SizedBox(width: 16),
            Expanded(child: Obx(() => _FormField(
              label: 'Sub Category / Product *',
              child: _StyledDropdown(
                hint: 'Select Sub Category',
                value: c.formSubCategory.value.isEmpty ? null : c.formSubCategory.value,
                items: c.subProductsForCategory,
                onChanged: (v) { if (v != null) { c.formSubCategory.value = v; } },
              ),
            ))),
            const SizedBox(width: 16),
            Expanded(child: _FormField(
              label: 'Product Name *',
              child: _StyledTextField(controller: _nameCtrl, hint: 'Enter product name'),
            )),
          ]),
          const SizedBox(height: 16),
          // Row 2: SKU | Unit | Brand | HSN Code
          Row(children: [
            Expanded(child: _FormField(label: 'SKU / Product Code *', child: _StyledTextField(controller: _skuCtrl, hint: 'e.g. CFB-1260-64'))),
            const SizedBox(width: 16),
            Expanded(child: _FormField(
              label: 'Unit *',
              child: _StyledDropdown(
                hint: 'Select Unit',
                value: _selectedUnit,
                items: ProductsController.units,
                onChanged: (v) { if (v != null) setState(() => _selectedUnit = v); },
              ),
            )),
            const SizedBox(width: 16),
            Expanded(child: _FormField(label: 'Brand (Optional)', child: _StyledTextField(controller: _brandCtrl, hint: 'e.g. SIMWOOL'))),
            const SizedBox(width: 16),
            Expanded(child: _FormField(label: 'HSN Code (Optional)', child: _StyledTextField(controller: _hsnCtrl, hint: 'e.g. 68061000'))),
          ]),
          const SizedBox(height: 16),
          // Description
          _FormField(
            label: 'Description',
            child: _StyledTextField(controller: _descCtrl, hint: 'Enter product description...', maxLines: 3),
          ),
        ],
      ),
    );
  }
}

// ── Section: Variants / Specifications ───────────────────────────────────────
class _VariantsSection extends StatelessWidget {
  final ProductsController c;
  const _VariantsSection({required this.c});

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Variants / Specifications',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _VariantToggleGroup(
                label: 'Density Variants (Blanket)',
                enabledObs: c.densityVariantsEnabled,
                options: ProductsController.densityOptions,
                selectedObs: c.selectedDensities,
                onToggle: c.toggleDensity,
              )),
              const SizedBox(width: 16),
              Expanded(child: _VariantToggleGroup(
                label: 'Board Variants',
                enabledObs: c.boardVariantsEnabled,
                options: ProductsController.boardVariantOptions,
                selectedObs: c.selectedBoardTypes,
                onToggle: c.toggleBoardType,
              )),
              const SizedBox(width: 16),
              Expanded(child: _VariantToggleGroup(
                label: 'Thickness Variants (Paper)',
                enabledObs: c.thicknessVariantsEnabled,
                options: ProductsController.thicknessOptions,
                selectedObs: c.selectedThicknesses,
                onToggle: c.toggleThickness,
              )),
              const SizedBox(width: 16),
              Expanded(child: _VariantToggleGroup(
                label: 'Reinforcement Types (Rope & Textiles)',
                enabledObs: c.reinforcementEnabled,
                options: ProductsController.reinforcementOptions,
                selectedObs: c.selectedReinforcements,
                onToggle: c.toggleReinforcement,
              )),
            ],
          ),
          const SizedBox(height: 16),
          _FormField(
            label: 'Other Specifications (Optional)',
            child: _StyledTextField(hint: 'Enter any other specifications...'),
          ),
        ],
      ),
    );
  }
}

// ── Section: Pricing & Stock ──────────────────────────────────────────────────
class _PricingSection extends StatefulWidget {
  const _PricingSection();
  @override
  State<_PricingSection> createState() => _PricingSectionState();
}

class _PricingSectionState extends State<_PricingSection> {
  final _sellPriceCtrl = TextEditingController(text: '0.00');
  final _costPriceCtrl = TextEditingController(text: '0.00');
  final _openStockCtrl = TextEditingController(text: '0');
  final _minStockCtrl = TextEditingController(text: '10');
  String _tax = '18% GST';
  String _location = 'Main Warehouse';

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Pricing & Stock',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: Column(
            children: [
              Row(children: [
                Expanded(child: _FormField(label: 'Selling Price (₹) *', child: _StyledTextField(controller: _sellPriceCtrl, hint: '0.00', keyboardType: TextInputType.number))),
                const SizedBox(width: 16),
                Expanded(child: _FormField(label: 'Cost Price (₹)', child: _StyledTextField(controller: _costPriceCtrl, hint: '0.00', keyboardType: TextInputType.number))),
                const SizedBox(width: 16),
                Expanded(child: _FormField(label: 'Opening Stock *', child: _StyledTextField(controller: _openStockCtrl, hint: '0', keyboardType: TextInputType.number))),
                const SizedBox(width: 16),
                Expanded(child: _FormField(label: 'Minimum Stock Level', child: _StyledTextField(controller: _minStockCtrl, hint: '10', keyboardType: TextInputType.number))),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _FormField(
                  label: 'Tax (%)',
                  child: _StyledDropdown(value: _tax, items: ProductsController.taxOptions, onChanged: (v) { if (v != null) setState(() => _tax = v); }),
                )),
                const SizedBox(width: 16),
                Expanded(child: _FormField(
                  label: 'Stock Location',
                  child: _StyledDropdown(value: _location, items: ProductsController.stockLocations, onChanged: (v) { if (v != null) setState(() => _location = v); }),
                )),
                const Expanded(child: SizedBox()),
                const Expanded(child: SizedBox()),
              ]),
            ],
          )),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sellPriceCtrl.dispose(); _costPriceCtrl.dispose();
    _openStockCtrl.dispose(); _minStockCtrl.dispose();
    super.dispose();
  }
}

// ── Section: Product Image ────────────────────────────────────────────────────
class _ImageSection extends StatefulWidget {
  const _ImageSection();

  @override
  State<_ImageSection> createState() => _ImageSectionState();
}

class _ImageSectionState extends State<_ImageSection> {
  bool _isDragging = false;
  final List<XFile> _files = [];

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: kIsWeb, // Important for Web to get bytes
    );

    if (result == null) return;

    final pickedFiles = result.files.map((e) {
      if (kIsWeb) {
        return XFile.fromData(e.bytes!, name: e.name);
      }
      return XFile(e.path!);
    }).toList();

    setState(() {
      _files.addAll(pickedFiles);
    });
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
  }

  void _showImagePopup(XFile file) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black,
              ),
              clipBehavior: Clip.antiAlias,
              child: InteractiveViewer(
                child: kIsWeb
                    ? Image.network(file.path, fit: BoxFit.contain)
                    : Image.file(io.File(file.path), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product Image', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins')),
          const SizedBox(height: 16),
          DropTarget(
            onDragEntered: (_) => setState(() => _isDragging = true),
            onDragExited: (_) => setState(() => _isDragging = false),
            onDragDone: (details) {
              setState(() {
                _isDragging = false;
                _files.addAll(details.files);
              });
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _pickFiles,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: _isDragging ? AppColors.primaryPurple.withValues(alpha: 0.05) : colors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isDragging ? AppColors.primaryPurple : colors.border,
                      style: BorderStyle.solid,
                      width: _isDragging ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: _isDragging ? AppColors.primaryPurple.withValues(alpha: 0.2) : const Color(0xFFEEECFF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isDragging ? Icons.download_rounded : Icons.cloud_upload_outlined,
                          color: AppColors.primaryPurple,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isDragging ? 'Release to upload' : 'Drag & drop image here',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _isDragging ? FontWeight.w600 : FontWeight.w400,
                          color: _isDragging ? AppColors.primaryPurple : colors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (!_isDragging) ...[
                        Text('or', style: TextStyle(fontSize: 12, color: colors.textHint, fontFamily: 'Poppins')),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _pickFiles,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Browse Image', style: TextStyle(fontSize: 13, color: Colors.white, fontFamily: 'Poppins')),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_files.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _files.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return Stack(
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _showImagePopup(file),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.divider),
                            image: DecorationImage(
                              image: kIsWeb
                                  ? NetworkImage(file.path)
                                  : FileImage(io.File(file.path)) as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _removeFile(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          Text('JPG, PNG or WEBP. Max size of 2MB.', style: TextStyle(fontSize: 11.5, color: colors.textHint, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}

// ── Section: Status ───────────────────────────────────────────────────────────
class _StatusSection extends StatefulWidget {
  final ProductsController c;
  const _StatusSection({required this.c});
  @override
  State<_StatusSection> createState() => _StatusSectionState();
}

class _StatusSectionState extends State<_StatusSection> {
  String _productStatus = 'Active';

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins')),
          const SizedBox(height: 16),
          _FormField(
            label: 'Product Status *',
            child: _StyledDropdown(
              value: _productStatus,
              items: const ['Active', 'Inactive'],
              onChanged: (v) { if (v != null) setState(() => _productStatus = v); },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Low Stock Alert', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textPrimary, fontFamily: 'Poppins')),
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

// ── Variant Toggle Group ──────────────────────────────────────────────────────
class _VariantToggleGroup extends StatelessWidget {
  final String label;
  final RxBool enabledObs;
  final List<String> options;
  final RxSet<String> selectedObs;
  final void Function(String) onToggle;

  const _VariantToggleGroup({required this.label, required this.enabledObs, required this.options, required this.selectedObs, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colors.textPrimary, fontFamily: 'Poppins'))),
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
          ...options.map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              SizedBox(
                width: 20, height: 20,
                child: Checkbox(
                  value: selectedObs.contains(opt),
                  onChanged: (_) => onToggle(opt),
                  activeColor: AppColors.primaryOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  side: const BorderSide(color: Color(0xFFE0DFF5)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              Text(opt, style: TextStyle(fontSize: 12.5, color: colors.textPrimary, fontFamily: 'Poppins')),
            ]),
          )),
        ],
      ],
    ));
  }
}

// ── Shared Form Widgets ───────────────────────────────────────────────────────
class _FormCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _FormCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins')),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;
  const _FormField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: colors.textPrimary, fontFamily: 'Poppins')),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _StyledTextField({this.controller, required this.hint, this.maxLines = 1, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Poppins'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: colors.textHint, fontFamily: 'Poppins'),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
        ),
        filled: true,
        fillColor: colors.inputFill,
      ),
    );
  }
}

// ── _StyledDropdown — matches _StyledTextField height exactly ─────────────────
class _StyledDropdown extends StatelessWidget {
  final String? value;
  final String? hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _StyledDropdown({
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
        fontSize: 13,
        color: colors.textPrimary,
        fontFamily: 'Poppins',
      ),
      hint: hint != null
          ? Text(
              hint!,
              style: TextStyle(
                fontSize: 13,
                color: colors.textHint,
                fontFamily: 'Poppins',
              ),
            )
          : null,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
        ),
        filled: true,
        fillColor: colors.inputFill,
      ),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:get/get.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../dashboard/widgets/web_sidebar.dart';
import '../../dashboard/widgets/web_top_bar.dart';
import '../../../routes/app_routes.dart';
import '../controllers/add_product_form_controller.dart';

// ── Dropdown options ─────────────────────────────────────────────────────────
const _kCategories = [
  'Ceramic Fiber Bulk',
  'Ceramic Fiber Blanket',
  'Ceramic Fiber Board',
  'Ceramic Fiber Paper',
  'Ceramic Fiber Rope',
  'Ceramic Fiber Textiles',
];

const _kSubCats = <String, List<String>>{
  'Ceramic Fiber Bulk': [
    'Standard Grade',
    'High Purity Grade',
    'Super Wool Grade',
    'Blow Wool',
  ],
  'Ceramic Fiber Blanket': [
    '1260°C Grade',
    '1400°C Grade',
    '1430°C Grade',
    '1600°C Grade',
  ],
  'Ceramic Fiber Board': [
    'Standard Board',
    'High Density Board',
    'High Purity Board',
    'Zirconia Board',
  ],
  'Ceramic Fiber Paper': ['3mm Paper', '6mm Paper', '12mm Paper', '25mm Paper'],
  'Ceramic Fiber Rope': [
    'Twisted Rope',
    'Braided Rope',
    'Square Rope',
    'Lagging Rope',
  ],
  'Ceramic Fiber Textiles': [
    'Cloth',
    'Tape 25mm',
    'Tape 50mm',
    'Yarn',
    'Sleeve',
  ],
};

const _kUnits = [
  'Kg',
  'Roll',
  'Piece',
  'Meter',
  'Liter',
  'Box',
  'Set',
  'Nos',
  'Ton',
  'Bundle',
];
const _kBrands = ['Kaowool', 'Unifrax', 'Morgan', 'HPS', 'Fibre Cast', 'Other'];
const _kGstRates = ['Select GST rate', '0%', '5%', '12%', '18%', '28%'];
const _kLocations = [
  'Select location',
  'Main Warehouse',
  'Secondary Warehouse',
  'Shop Floor',
  'Raw Material Store',
];

// ─────────────────────────────────────────────────────────────────────────────
// Main Widget
// ─────────────────────────────────────────────────────────────────────────────
class WebAddProductLayout extends GetView<AddProductFormController> {
  const WebAddProductLayout({super.key});

  // ── Image helpers ──────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: kIsWeb,
    );
    if (r == null) return;
    final files = r.files
        .map(
          (e) =>
              kIsWeb ? XFile.fromData(e.bytes!, name: e.name) : XFile(e.path!),
        )
        .toList();
    controller.images.addAll(files);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          const WebSidebar(),
          Expanded(
            child: Column(
              children: [
                const WebTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Breadcrumb ─────────────────────────────────────────────
                        Row(
                          children: [
                            InkWell(
                              onTap: () => Get.offNamed(AppRoutes.products),
                              child: Text(
                                'Products',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primaryOrange,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: colors.textHint,
                              ),
                            ),
                            Text(
                              'Add New Item',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Page Header + Buttons ──────────────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add New Item',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Create a new product item and manage its details.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textSecondary,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            _OBtn(
                              'Cancel',
                              onTap: () => Get.back(),
                              colors: colors,
                            ),
                            const SizedBox(width: 10),
                            _OBtn(
                              'Save as Draft',
                              bold: true,
                              onTap: () {},
                              colors: colors,
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: _saveItem,
                              icon: const Icon(
                                Icons.save_rounded,
                                color: Colors.white,
                                size: 17,
                              ),
                              label: const Text(
                                'Save Item',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryOrange,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Section 1: Basic Information ───────────────────────────
                        _Card(
                          title: 'Basic Information',
                          colors: colors,
                          child: Obx(
                            () => Column(
                              children: [
                                // Row 1: Item Name | Item Code (SKU) | Barcode
                                Row(
                                  children: [
                                    Expanded(
                                      child: _F(
                                        label: 'Item Name',
                                        required: true,
                                        ctrl: controller.nameCtrl,
                                        hint: 'Enter item name',
                                        colors: colors,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _F(
                                        label: 'Item Code (SKU)',
                                        required: true,
                                        ctrl: controller.skuCtrl,
                                        hint: 'Enter item code (SKU)',
                                        colors: colors,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _F(
                                        label: 'Barcode',
                                        ctrl: controller.barcodeCtrl,
                                        hint: 'Enter barcode (optional)',
                                        colors: colors,
                                        suffixIcon: Icon(
                                          Icons.qr_code_scanner_rounded,
                                          color: colors.textHint,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Row 2: Category | Sub-Category | Unit
                                Row(
                                  children: [
                                    Expanded(
                                      child: _DD(
                                        label: 'Category',
                                        required: true,
                                        colors: colors,
                                        value: controller.category.value.isEmpty
                                            ? null
                                            : controller.category.value,
                                        hint: 'Select category',
                                        items: _kCategories,
                                        onChange: (v) {
                                          controller.category.value = v ?? '';
                                          controller.subCat.value = '';
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _DD(
                                        label: 'Sub-Category',
                                        required: true,
                                        colors: colors,
                                        value: controller.subCat.value.isEmpty
                                            ? null
                                            : controller.subCat.value,
                                        hint: 'Select sub-category',
                                        items:
                                            _kSubCats[controller
                                                .category
                                                .value] ??
                                            [],
                                        onChange: (v) =>
                                            controller.subCat.value = v ?? '',
                                        enabled: controller
                                            .category
                                            .value
                                            .isNotEmpty,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _DD(
                                        label: 'Unit',
                                        required: true,
                                        colors: colors,
                                        value: controller.unit.value.isEmpty
                                            ? null
                                            : controller.unit.value,
                                        hint: 'Select unit',
                                        items: _kUnits,
                                        onChange: (v) =>
                                            controller.unit.value = v ?? '',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Row 3: Brand | HSN/SAC Code | Item Type
                                Row(
                                  children: [
                                    Expanded(
                                      child: _DD(
                                        label: 'Brand',
                                        colors: colors,
                                        value: controller.brand.value.isEmpty
                                            ? null
                                            : controller.brand.value,
                                        hint: 'Select brand (optional)',
                                        items: _kBrands,
                                        onChange: (v) =>
                                            controller.brand.value = v ?? '',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _F(
                                        label: 'HSN / SAC Code',
                                        ctrl: controller.hsnCtrl,
                                        hint: 'Enter HSN / SAC code',
                                        colors: colors,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _ItemTypeField(
                                        value: controller.isStock.value,
                                        onChanged: (v) =>
                                            controller.isStock.value = v,
                                        colors: colors,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Row 4: Description | Item Image
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 11,
                                      child: _DescField(
                                        ctrl: controller.descCtrl,
                                        colors: colors,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 9,
                                      child: _ImageUpload(
                                        images: controller.images,
                                        isDragging: controller.isDragging.value,
                                        onDragEnter: () =>
                                            controller.isDragging.value = true,
                                        onDragExit: () =>
                                            controller.isDragging.value = false,
                                        onDrop: (files) {
                                          controller.isDragging.value = false;
                                          controller.images.addAll(files);
                                        },
                                        onBrowse: _pickImage,
                                        onRemove: (i) =>
                                            controller.images.removeAt(i),
                                        colors: colors,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Section 2: Pricing & Tax + Inventory (side by side) ────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 11,
                              child: _Card(
                                title: 'Pricing & Tax',
                                colors: colors,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _F(
                                            label: 'Purchase Price (₹)',
                                            required: true,
                                            ctrl: controller.purPriceCtrl,
                                            hint: 'Enter purchase price',
                                            colors: colors,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: _F(
                                            label: 'Selling Price (₹)',
                                            required: true,
                                            ctrl: controller.selPriceCtrl,
                                            hint: 'Enter selling price',
                                            colors: colors,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: _F(
                                            label: 'MRP (₹)',
                                            ctrl: controller.mrpCtrl,
                                            hint: 'Enter MRP (optional)',
                                            colors: colors,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Obx(
                                            () => _DD(
                                              label: 'GST Rate',
                                              required: true,
                                              colors: colors,
                                              value:
                                                  controller.gstRate.value ==
                                                      'Select GST rate'
                                                  ? null
                                                  : controller.gstRate.value,
                                              hint: 'Select GST rate',
                                              items: _kGstRates
                                                  .skip(1)
                                                  .toList(),
                                              onChange: (v) =>
                                                  controller.gstRate.value =
                                                      v ??
                                                      controller.gstRate.value,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: _F(
                                            label: 'CESS (%)',
                                            ctrl: controller.cessCtrl,
                                            hint: 'Enter cess (optional)',
                                            colors: colors,
                                            keyboardType: TextInputType.number,
                                            suffixText: '%',
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: _F(
                                            label: 'Discount (%)',
                                            ctrl: controller.discCtrl,
                                            hint: 'Enter discount (optional)',
                                            colors: colors,
                                            keyboardType: TextInputType.number,
                                            suffixText: '%',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            Expanded(
                              flex: 9,
                              child: _Card(
                                title: 'Inventory',
                                colors: colors,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _F(
                                            label: 'Opening Stock',
                                            required: true,
                                            ctrl: controller.openStockCtrl,
                                            hint: 'Enter opening stock',
                                            colors: colors,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: _F(
                                            label: 'Reorder Level',
                                            ctrl: controller.reorderCtrl,
                                            hint: 'Enter reorder level',
                                            colors: colors,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Obx(
                                            () => _DD(
                                              label: 'Stock Location',
                                              colors: colors,
                                              value:
                                                  controller.location.value ==
                                                      'Select location'
                                                  ? null
                                                  : controller.location.value,
                                              hint: 'Select location',
                                              items: _kLocations
                                                  .skip(1)
                                                  .toList(),
                                              onChange: (v) =>
                                                  controller.location.value =
                                                      v ??
                                                      controller.location.value,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _F(
                                            label: 'Minimum Order Qty',
                                            ctrl: controller.minQtyCtrl,
                                            hint:
                                                'Enter minimum order qty (optional)',
                                            colors: colors,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: _F(
                                            label: 'Maximum Order Qty',
                                            ctrl: controller.maxQtyCtrl,
                                            hint:
                                                'Enter maximum order qty (optional)',
                                            colors: colors,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        const Expanded(child: SizedBox()),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Section 3: Additional Information ──────────────────────
                        _Card(
                          title: 'Additional Information',
                          colors: colors,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _F(
                                      label: 'Shelf Life',
                                      ctrl: controller.shelfCtrl,
                                      hint: 'Enter shelf life (optional)',
                                      colors: colors,
                                      keyboardType: TextInputType.number,
                                      suffixText: 'days',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _F(
                                      label: 'Warranty Period',
                                      ctrl: controller.warrantyCtrl,
                                      hint: 'Enter warranty period (optional)',
                                      colors: colors,
                                      keyboardType: TextInputType.number,
                                      suffixText: 'months',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _F(
                                      label: 'Weight',
                                      ctrl: controller.weightCtrl,
                                      hint: 'Enter weight (optional)',
                                      colors: colors,
                                      keyboardType: TextInputType.number,
                                      suffixText: 'kg',
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _F(
                                      label: 'Dimensions (L × W × H)',
                                      ctrl: controller.dimCtrl,
                                      hint: 'Enter dimensions (optional)',
                                      colors: colors,
                                      suffixText: 'cm',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Active checkbox
                              Obx(
                                () => Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Checkbox(
                                        value: controller.isActive.value,
                                        onChanged: (v) =>
                                            controller.isActive.value =
                                                v ?? true,
                                        activeColor: AppColors.primaryOrange,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        side: BorderSide(
                                          color: controller.isActive.value
                                              ? AppColors.primaryOrange
                                              : colors.border,
                                          width: 1.5,
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Active',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: colors.textPrimary,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        Text(
                                          'Item will be active and available for transactions',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colors.textSecondary,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
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

  void _saveItem() {
    if (controller.nameCtrl.text.trim().isEmpty) {
      showAppToast(
        'Validation Error',
        'Item Name is required.',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    showAppToast(
      'Success',
      'Item saved successfully!',
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
    Get.back();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item Type Radio Field
// ─────────────────────────────────────────────────────────────────────────────
class _ItemTypeField extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppThemeColors colors;
  const _ItemTypeField({
    required this.value,
    required this.onChanged,
    required this.colors,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabelText('Item Type', required: true, colors: colors),
        const SizedBox(height: 6),
        SizedBox(
          height: 42,
          child: Row(
            children: [
              // Stock Item radio
              Radio<bool>(
                value: true,
                groupValue: value,
                onChanged: (v) => onChanged(v ?? true),
                activeColor: AppColors.primaryOrange,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              InkWell(
                onTap: () => onChanged(true),
                child: Text(
                  'Stock Item',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Service Item radio
              Radio<bool>(
                value: false,
                groupValue: value,
                onChanged: (v) => onChanged(!(v ?? false)),
                activeColor: AppColors.primaryOrange,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              InkWell(
                onTap: () => onChanged(false),
                child: Text(
                  'Service Item',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Description Text Area with character counter
// ─────────────────────────────────────────────────────────────────────────────
class _DescField extends StatefulWidget {
  final TextEditingController ctrl;
  final AppThemeColors colors;
  const _DescField({required this.ctrl, required this.colors});
  @override
  State<_DescField> createState() => _DescFieldState();
}

class _DescFieldState extends State<_DescField> {
  // Local, widget-scoped char counter — kept as an Rx on the persistent
  // State object (not setState).
  final _count = 0.obs;

  @override
  void initState() {
    super.initState();
    _count.value = widget.ctrl.text.length;
    widget.ctrl.addListener(() => _count.value = widget.ctrl.text.length);
  }

  @override
  void dispose() {
    _count.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabelText('Description', colors: c),
        const SizedBox(height: 6),
        Obx(
          () => TextField(
            controller: widget.ctrl,
            maxLines: 7,
            maxLength: 500,
            style: TextStyle(
              fontSize: 13,
              color: c.textPrimary,
              fontFamily: 'Poppins',
            ),
            decoration: InputDecoration(
              hintText: 'Enter item description (optional)',
              hintStyle: TextStyle(
                fontSize: 13,
                color: c.textHint,
                fontFamily: 'Poppins',
              ),
              filled: true,
              fillColor: c.inputFill,
              counterText: '${_count.value}/500',
              counterStyle: TextStyle(
                fontSize: 11,
                color: c.textHint,
                fontFamily: 'Poppins',
              ),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: c.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primaryOrange,
                  width: 1.5,
                ),
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image Upload Drop Zone
// ─────────────────────────────────────────────────────────────────────────────
class _ImageUpload extends StatelessWidget {
  final List<XFile> images;
  final bool isDragging;
  final VoidCallback onDragEnter, onDragExit, onBrowse;
  final ValueChanged<List<XFile>> onDrop;
  final ValueChanged<int> onRemove;
  final AppThemeColors colors;

  const _ImageUpload({
    required this.images,
    required this.isDragging,
    required this.onDragEnter,
    required this.onDragExit,
    required this.onDrop,
    required this.onBrowse,
    required this.onRemove,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabelText('Item Image', colors: colors),
        const SizedBox(height: 6),
        DropTarget(
          onDragEntered: (_) => onDragEnter(),
          onDragExited: (_) => onDragExit(),
          onDragDone: (d) => onDrop(d.files),
          child: InkWell(
            onTap: onBrowse,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              height: 182,
              decoration: BoxDecoration(
                color: isDragging
                    ? AppColors.primaryOrange.withValues(alpha: 0.05)
                    : colors.inputFill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: isDragging ? AppColors.primaryOrange : colors.border,
                  radius: 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDragging
                            ? Icons.download_rounded
                            : Icons.cloud_upload_outlined,
                        color: AppColors.primaryOrange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isDragging
                          ? 'Release to upload'
                          : 'Drag & drop an image here',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDragging
                            ? AppColors.primaryOrange
                            : colors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (!isDragging) ...[
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'or click to ',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textHint,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const TextSpan(
                              text: 'browse',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Allowed formats: JPG, PNG, WEBP (Max 2MB)',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textHint,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (images.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: images.asMap().entries.map((e) {
              final f = e.value;
              final i = e.key;
              return Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.divider),
                      image: DecorationImage(
                        image: kIsWeb
                            ? NetworkImage(f.path)
                            : FileImage(io.File(f.path)) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: InkWell(
                      onTap: () => onRemove(i),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedBorderPainter({required this.color, this.radius = 8});
  @override
  void paint(Canvas canvas, Size size) {
    const dashW = 6.0;
    const dashSp = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          Radius.circular(radius),
        ),
      );
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + dashW), paint);
        d += dashW + dashSp;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Outlined Button helper
// ─────────────────────────────────────────────────────────────────────────────
class _OBtn extends StatelessWidget {
  final String label;
  final bool bold;
  final VoidCallback onTap;
  final AppThemeColors colors;
  const _OBtn(
    this.label, {
    required this.onTap,
    this.bold = false,
    required this.colors,
  });
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: colors.border),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: colors.textPrimary,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Card
// ─────────────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  final AppThemeColors colors;
  const _Card({required this.title, required this.child, required this.colors});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Labeled Text Field
// ─────────────────────────────────────────────────────────────────────────────
class _F extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final bool required;
  final TextInputType keyboardType;
  final AppThemeColors colors;
  final String? suffixText;
  final Widget? suffixIcon;

  const _F({
    required this.label,
    required this.ctrl,
    this.hint = '',
    this.required = false,
    this.keyboardType = TextInputType.text,
    required this.colors,
    this.suffixText,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabelText(label, required: required, colors: colors),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
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
            filled: true,
            fillColor: colors.inputFill,
            suffixText: suffixText,
            suffixStyle: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
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
              borderSide: const BorderSide(
                color: AppColors.primaryOrange,
                width: 1.5,
              ),
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Labeled Dropdown Field
// ─────────────────────────────────────────────────────────────────────────────
class _DD extends StatelessWidget {
  final String label;
  final String? value, hint;
  final List<String> items;
  final ValueChanged<String?> onChange;
  final bool required, enabled;
  final AppThemeColors colors;

  const _DD({
    required this.label,
    this.value,
    this.hint,
    required this.items,
    required this.onChange,
    this.required = false,
    this.enabled = true,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabelText(label, required: required, colors: colors),
        const SizedBox(height: 6),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: enabled
                ? colors.inputFill
                : colors.background.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: enabled ? colors.border : colors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                hint ?? 'Select',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textHint,
                  fontFamily: 'Poppins',
                ),
              ),
              style: TextStyle(
                fontSize: 13,
                color: colors.textPrimary,
                fontFamily: 'Poppins',
              ),
              dropdownColor: colors.surface,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: enabled ? colors.textSecondary : colors.textHint,
              ),
              items: items
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: enabled ? onChange : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Label with optional asterisk
// ─────────────────────────────────────────────────────────────────────────────
class _LabelText extends StatelessWidget {
  final String label;
  final bool required;
  final AppThemeColors colors;
  const _LabelText(this.label, {this.required = false, required this.colors});
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

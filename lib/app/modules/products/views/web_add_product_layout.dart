import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'package:get/get.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cross_file/cross_file.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/widgets/web_sidebar.dart';
import '../../../routes/app_routes.dart';

// ── Dropdown options ─────────────────────────────────────────────────────────
const _kCategories = [
  'Ceramic Fiber Bulk', 'Ceramic Fiber Blanket', 'Ceramic Fiber Board',
  'Ceramic Fiber Paper', 'Ceramic Fiber Rope', 'Ceramic Fiber Textiles',
];

const _kSubCats = <String, List<String>>{
  'Ceramic Fiber Bulk':     ['Standard Grade', 'High Purity Grade', 'Super Wool Grade', 'Blow Wool'],
  'Ceramic Fiber Blanket':  ['1260°C Grade', '1400°C Grade', '1430°C Grade', '1600°C Grade'],
  'Ceramic Fiber Board':    ['Standard Board', 'High Density Board', 'High Purity Board', 'Zirconia Board'],
  'Ceramic Fiber Paper':    ['3mm Paper', '6mm Paper', '12mm Paper', '25mm Paper'],
  'Ceramic Fiber Rope':     ['Twisted Rope', 'Braided Rope', 'Square Rope', 'Lagging Rope'],
  'Ceramic Fiber Textiles': ['Cloth', 'Tape 25mm', 'Tape 50mm', 'Yarn', 'Sleeve'],
};

const _kUnits    = ['Kg', 'Roll', 'Piece', 'Meter', 'Liter', 'Box', 'Set', 'Nos', 'Ton', 'Bundle'];
const _kBrands   = ['Kaowool', 'Unifrax', 'Morgan', 'HPS', 'Fibre Cast', 'Other'];
const _kGstRates = ['Select GST rate', '0%', '5%', '12%', '18%', '28%'];
const _kLocations= ['Select location', 'Main Warehouse', 'Secondary Warehouse', 'Shop Floor', 'Raw Material Store'];

// ─────────────────────────────────────────────────────────────────────────────
// Main Widget
// ─────────────────────────────────────────────────────────────────────────────
class WebAddProductLayout extends StatefulWidget {
  const WebAddProductLayout({super.key});
  @override
  State<WebAddProductLayout> createState() => _WebAddProductLayoutState();
}

class _WebAddProductLayoutState extends State<WebAddProductLayout> {
  // ── Basic Info ─────────────────────────────────────────────────────────
  final _nameCtrl    = TextEditingController();
  final _skuCtrl     = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  String _category   = '';
  String _subCat     = '';
  String _unit       = '';
  String _brand      = '';
  final _hsnCtrl     = TextEditingController();
  bool   _isStock    = true; // Stock Item vs Service Item
  final _descCtrl    = TextEditingController();

  // ── Pricing & Tax ──────────────────────────────────────────────────────
  final _purPriceCtrl  = TextEditingController();
  final _selPriceCtrl  = TextEditingController();
  final _mrpCtrl       = TextEditingController();
  String _gstRate      = 'Select GST rate';
  final _cessCtrl      = TextEditingController();
  final _discCtrl      = TextEditingController();

  // ── Inventory ──────────────────────────────────────────────────────────
  final _openStockCtrl = TextEditingController();
  final _reorderCtrl   = TextEditingController();
  String _location     = 'Select location';
  final _minQtyCtrl    = TextEditingController();
  final _maxQtyCtrl    = TextEditingController();

  // ── Additional Info ────────────────────────────────────────────────────
  final _shelfCtrl     = TextEditingController();
  final _warrantyCtrl  = TextEditingController();
  final _weightCtrl    = TextEditingController();
  final _dimCtrl       = TextEditingController();
  bool   _isActive     = true;

  // ── Image ──────────────────────────────────────────────────────────────
  final List<XFile> _images = [];
  bool _isDragging = false;

  List<String> get _subCatList => _kSubCats[_category] ?? [];

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _skuCtrl, _barcodeCtrl, _hsnCtrl, _descCtrl,
      _purPriceCtrl, _selPriceCtrl, _mrpCtrl, _cessCtrl, _discCtrl,
      _openStockCtrl, _reorderCtrl, _minQtyCtrl, _maxQtyCtrl,
      _shelfCtrl, _warrantyCtrl, _weightCtrl, _dimCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  // ── Image helpers ──────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.image, withData: kIsWeb);
    if (r == null) return;
    final files = r.files.map((e) => kIsWeb ? XFile.fromData(e.bytes!, name: e.name) : XFile(e.path!)).toList();
    setState(() => _images.addAll(files));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Row(children: [
        const WebSidebar(),
        Expanded(child: Column(children: [
          _TopBar(colors: colors),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Breadcrumb ─────────────────────────────────────────────
              Row(children: [
                MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
                  onTap: () => Get.offNamed(AppRoutes.products),
                  child: Text('Products', style: TextStyle(fontSize: 13, color: AppColors.primaryOrange, fontFamily: 'Poppins', fontWeight: FontWeight.w500)))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.chevron_right_rounded, size: 16, color: colors.textHint)),
                Text('Add New Item', style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Poppins')),
              ]),
              const SizedBox(height: 16),

              // ── Page Header + Buttons ──────────────────────────────────
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Add New Item', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins')),
                  const SizedBox(height: 3),
                  Text('Create a new product item and manage its details.',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Poppins')),
                ]),
                const Spacer(),
                _OBtn('Cancel', onTap: () => Get.back(), colors: colors),
                const SizedBox(width: 10),
                _OBtn('Save as Draft', bold: true, onTap: () {}, colors: colors),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _saveItem,
                  icon: const Icon(Icons.save_rounded, color: Colors.white, size: 17),
                  label: const Text('Save Item', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange, elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
              ]),
              const SizedBox(height: 20),

              // ── Section 1: Basic Information ───────────────────────────
              _Card(title: 'Basic Information', colors: colors, child: Column(children: [
                // Row 1: Item Name | Item Code (SKU) | Barcode
                Row(children: [
                  Expanded(child: _F(label: 'Item Name', required: true, ctrl: _nameCtrl, hint: 'Enter item name', colors: colors)),
                  const SizedBox(width: 16),
                  Expanded(child: _F(label: 'Item Code (SKU)', required: true, ctrl: _skuCtrl, hint: 'Enter item code (SKU)', colors: colors)),
                  const SizedBox(width: 16),
                  Expanded(child: _F(
                    label: 'Barcode', ctrl: _barcodeCtrl, hint: 'Enter barcode (optional)', colors: colors,
                    suffixIcon: Icon(Icons.qr_code_scanner_rounded, color: colors.textHint, size: 20),
                  )),
                ]),
                const SizedBox(height: 14),

                // Row 2: Category | Sub-Category | Unit
                Row(children: [
                  Expanded(child: _DD(
                    label: 'Category', required: true, colors: colors,
                    value: _category.isEmpty ? null : _category, hint: 'Select category',
                    items: _kCategories, onChange: (v) => setState(() { _category = v ?? ''; _subCat = ''; }),
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _DD(
                    label: 'Sub-Category', required: true, colors: colors,
                    value: _subCat.isEmpty ? null : _subCat, hint: 'Select sub-category',
                    items: _subCatList, onChange: (v) => setState(() => _subCat = v ?? ''),
                    enabled: _category.isNotEmpty,
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _DD(
                    label: 'Unit', required: true, colors: colors,
                    value: _unit.isEmpty ? null : _unit, hint: 'Select unit',
                    items: _kUnits, onChange: (v) => setState(() => _unit = v ?? ''),
                  )),
                ]),
                const SizedBox(height: 14),

                // Row 3: Brand | HSN/SAC Code | Item Type
                Row(children: [
                  Expanded(child: _DD(
                    label: 'Brand', colors: colors,
                    value: _brand.isEmpty ? null : _brand, hint: 'Select brand (optional)',
                    items: _kBrands, onChange: (v) => setState(() => _brand = v ?? ''),
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _F(label: 'HSN / SAC Code', ctrl: _hsnCtrl, hint: 'Enter HSN / SAC code', colors: colors)),
                  const SizedBox(width: 16),
                  Expanded(child: _ItemTypeField(value: _isStock, onChanged: (v) => setState(() => _isStock = v), colors: colors)),
                ]),
                const SizedBox(height: 14),

                // Row 4: Description | Item Image
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 11, child: _DescField(ctrl: _descCtrl, colors: colors)),
                  const SizedBox(width: 16),
                  Expanded(flex: 9, child: _ImageUpload(
                    images: _images,
                    isDragging: _isDragging,
                    onDragEnter: () => setState(() => _isDragging = true),
                    onDragExit: () => setState(() => _isDragging = false),
                    onDrop: (files) => setState(() { _isDragging = false; _images.addAll(files); }),
                    onBrowse: _pickImage,
                    onRemove: (i) => setState(() => _images.removeAt(i)),
                    colors: colors,
                  )),
                ]),
              ])),
              const SizedBox(height: 16),

              // ── Section 2: Pricing & Tax + Inventory (side by side) ────
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 11, child: _Card(title: 'Pricing & Tax', colors: colors, child: Column(children: [
                  Row(children: [
                    Expanded(child: _F(label: 'Purchase Price (₹)', required: true, ctrl: _purPriceCtrl, hint: 'Enter purchase price', colors: colors, keyboardType: TextInputType.number)),
                    const SizedBox(width: 14),
                    Expanded(child: _F(label: 'Selling Price (₹)', required: true, ctrl: _selPriceCtrl, hint: 'Enter selling price', colors: colors, keyboardType: TextInputType.number)),
                    const SizedBox(width: 14),
                    Expanded(child: _F(label: 'MRP (₹)', ctrl: _mrpCtrl, hint: 'Enter MRP (optional)', colors: colors, keyboardType: TextInputType.number)),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _DD(
                      label: 'GST Rate', required: true, colors: colors,
                      value: _gstRate == 'Select GST rate' ? null : _gstRate, hint: 'Select GST rate',
                      items: _kGstRates.skip(1).toList(), onChange: (v) => setState(() => _gstRate = v ?? _gstRate),
                    )),
                    const SizedBox(width: 14),
                    Expanded(child: _F(label: 'CESS (%)', ctrl: _cessCtrl, hint: 'Enter cess (optional)', colors: colors, keyboardType: TextInputType.number, suffixText: '%')),
                    const SizedBox(width: 14),
                    Expanded(child: _F(label: 'Discount (%)', ctrl: _discCtrl, hint: 'Enter discount (optional)', colors: colors, keyboardType: TextInputType.number, suffixText: '%')),
                  ]),
                ]))),

                const SizedBox(width: 16),

                Expanded(flex: 9, child: _Card(title: 'Inventory', colors: colors, child: Column(children: [
                  Row(children: [
                    Expanded(child: _F(label: 'Opening Stock', required: true, ctrl: _openStockCtrl, hint: 'Enter opening stock', colors: colors, keyboardType: TextInputType.number)),
                    const SizedBox(width: 14),
                    Expanded(child: _F(label: 'Reorder Level', ctrl: _reorderCtrl, hint: 'Enter reorder level', colors: colors, keyboardType: TextInputType.number)),
                    const SizedBox(width: 14),
                    Expanded(child: _DD(
                      label: 'Stock Location', colors: colors,
                      value: _location == 'Select location' ? null : _location, hint: 'Select location',
                      items: _kLocations.skip(1).toList(), onChange: (v) => setState(() => _location = v ?? _location),
                    )),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _F(label: 'Minimum Order Qty', ctrl: _minQtyCtrl, hint: 'Enter minimum order qty (optional)', colors: colors, keyboardType: TextInputType.number)),
                    const SizedBox(width: 14),
                    Expanded(child: _F(label: 'Maximum Order Qty', ctrl: _maxQtyCtrl, hint: 'Enter maximum order qty (optional)', colors: colors, keyboardType: TextInputType.number)),
                    const SizedBox(width: 14),
                    const Expanded(child: SizedBox()),
                  ]),
                ]))),
              ]),
              const SizedBox(height: 16),

              // ── Section 3: Additional Information ──────────────────────
              _Card(title: 'Additional Information', colors: colors, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: _F(label: 'Shelf Life', ctrl: _shelfCtrl, hint: 'Enter shelf life (optional)', colors: colors, keyboardType: TextInputType.number, suffixText: 'days')),
                    const SizedBox(width: 16),
                    Expanded(child: _F(label: 'Warranty Period', ctrl: _warrantyCtrl, hint: 'Enter warranty period (optional)', colors: colors, keyboardType: TextInputType.number, suffixText: 'months')),
                    const SizedBox(width: 16),
                    Expanded(child: _F(label: 'Weight', ctrl: _weightCtrl, hint: 'Enter weight (optional)', colors: colors, keyboardType: TextInputType.number, suffixText: 'kg')),
                    const SizedBox(width: 16),
                    Expanded(child: _F(label: 'Dimensions (L × W × H)', ctrl: _dimCtrl, hint: 'Enter dimensions (optional)', colors: colors, suffixText: 'cm')),
                  ]),
                  const SizedBox(height: 16),
                  // Active checkbox
                  Row(children: [
                    SizedBox(width: 20, height: 20,
                      child: Checkbox(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v ?? true),
                        activeColor: AppColors.primaryOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        side: BorderSide(color: _isActive ? AppColors.primaryOrange : colors.border, width: 1.5),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Active', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: colors.textPrimary, fontFamily: 'Poppins')),
                      Text('Item will be active and available for transactions', style: TextStyle(fontSize: 12, color: colors.textSecondary, fontFamily: 'Poppins')),
                    ]),
                  ]),
                ],
              )),
              const SizedBox(height: 24),
            ]),
          )),
        ])),
      ]),
    );
  }

  void _saveItem() {
    if (_nameCtrl.text.trim().isEmpty) {
      Get.snackbar('Validation Error', 'Item Name is required.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444), colorText: Colors.white,
        duration: const Duration(seconds: 2), margin: const EdgeInsets.all(16), borderRadius: 10);
      return;
    }
    Get.snackbar('Success', 'Item saved successfully!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF22C55E), colorText: Colors.white,
      duration: const Duration(seconds: 2), margin: const EdgeInsets.all(16), borderRadius: 10);
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
  const _ItemTypeField({required this.value, required this.onChanged, required this.colors});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _LabelText('Item Type', required: true, colors: colors),
      const SizedBox(height: 6),
      SizedBox(height: 42, child: Row(children: [
        // Stock Item radio
        Radio<bool>(value: true, groupValue: value, onChanged: (v) => onChanged(v ?? true), activeColor: AppColors.primaryOrange, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        GestureDetector(onTap: () => onChanged(true), child: Text('Stock Item', style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Poppins'))),
        const SizedBox(width: 12),
        // Service Item radio
        Radio<bool>(value: false, groupValue: value, onChanged: (v) => onChanged(!(v ?? false)), activeColor: AppColors.primaryOrange, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        GestureDetector(onTap: () => onChanged(false), child: Text('Service Item', style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Poppins'))),
      ])),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Description Text Area with character counter
// ─────────────────────────────────────────────────────────────────────────────
class _DescField extends StatefulWidget {
  final TextEditingController ctrl; final AppThemeColors colors;
  const _DescField({required this.ctrl, required this.colors});
  @override State<_DescField> createState() => _DescFieldState();
}

class _DescFieldState extends State<_DescField> {
  int _count = 0;
  @override void initState() { super.initState(); widget.ctrl.addListener(() => setState(() => _count = widget.ctrl.text.length)); }
  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _LabelText('Description', colors: c),
      const SizedBox(height: 6),
      TextField(
        controller: widget.ctrl, maxLines: 7, maxLength: 500,
        style: TextStyle(fontSize: 13, color: c.textPrimary, fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: 'Enter item description (optional)',
          hintStyle: TextStyle(fontSize: 13, color: c.textHint, fontFamily: 'Poppins'),
          filled: true, fillColor: c.inputFill,
          counterText: '$_count/500',
          counterStyle: TextStyle(fontSize: 11, color: c.textHint, fontFamily: 'Poppins'),
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5)),
          isDense: true,
        ),
      ),
    ]);
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

  const _ImageUpload({required this.images, required this.isDragging, required this.onDragEnter,
    required this.onDragExit, required this.onDrop, required this.onBrowse,
    required this.onRemove, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _LabelText('Item Image', colors: colors),
      const SizedBox(height: 6),
      DropTarget(
        onDragEntered: (_) => onDragEnter(),
        onDragExited:  (_) => onDragExit(),
        onDragDone: (d) => onDrop(d.files),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onBrowse,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity, height: 182,
              decoration: BoxDecoration(
                color: isDragging ? AppColors.primaryOrange.withValues(alpha: 0.05) : colors.inputFill,
                borderRadius: BorderRadius.circular(8)),
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: isDragging ? AppColors.primaryOrange : colors.border,
                  radius: 8),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 46, height: 46,
                    decoration: BoxDecoration(color: AppColors.primaryOrange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                    child: Icon(isDragging ? Icons.download_rounded : Icons.cloud_upload_outlined,
                      color: AppColors.primaryOrange, size: 24)),
                  const SizedBox(height: 10),
                  Text(isDragging ? 'Release to upload' : 'Drag & drop an image here',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                      color: isDragging ? AppColors.primaryOrange : colors.textSecondary, fontFamily: 'Poppins')),
                  if (!isDragging) ...[
                    const SizedBox(height: 2),
                    RichText(text: TextSpan(children: [
                      TextSpan(text: 'or click to ', style: TextStyle(fontSize: 12, color: colors.textHint, fontFamily: 'Poppins')),
                      const TextSpan(text: 'browse', style: TextStyle(fontSize: 12, color: AppColors.primaryOrange, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                    ])),
                  ],
                  const SizedBox(height: 8),
                  Text('Allowed formats: JPG, PNG, WEBP (Max 2MB)',
                    style: TextStyle(fontSize: 11, color: colors.textHint, fontFamily: 'Poppins')),
                ]),
              ),
            ),
          ),
        ),
      ),
      if (images.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: images.asMap().entries.map((e) {
          final f = e.value; final i = e.key;
          return Stack(children: [
            Container(width: 60, height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.divider),
                image: DecorationImage(
                  image: kIsWeb ? NetworkImage(f.path) : FileImage(io.File(f.path)) as ImageProvider,
                  fit: BoxFit.cover)),
            ),
            Positioned(top: 2, right: 2, child: GestureDetector(
              onTap: () => onRemove(i),
              child: Container(padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, size: 10, color: Colors.white)))),
          ]);
        }).toList()),
      ],
    ]);
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color; final double radius;
  const _DashedBorderPainter({required this.color, this.radius = 8});
  @override
  void paint(Canvas canvas, Size size) {
    const dashW = 6.0; const dashSp = 4.0;
    final paint = Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final path = Path()..addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2), Radius.circular(radius)));
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + dashW), paint);
        d += dashW + dashSp;
      }
    }
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final AppThemeColors colors;
  const _TopBar({required this.colors});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64, padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(color: colors.topBarBg, border: Border(bottom: BorderSide(color: colors.divider))),
      child: Row(children: [
        Container(width: 320, height: 38,
          decoration: BoxDecoration(color: colors.inputFill, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.border)),
          child: Row(children: [
            const SizedBox(width: 10),
            Icon(Icons.search_rounded, color: colors.textHint, size: 17),
            const SizedBox(width: 8),
            Expanded(child: Text('Search anything...', style: TextStyle(fontSize: 13, color: colors.textHint, fontFamily: 'Poppins'))),
            Container(margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: colors.divider, borderRadius: BorderRadius.circular(5)),
              child: Text('Ctrl + K', style: TextStyle(fontSize: 10, color: colors.textSecondary, fontFamily: 'Poppins'))),
          ])),
        const Spacer(),
        _IBtn(icon: Icons.notifications_outlined, badge: '3', colors: colors),
        const SizedBox(width: 8),
        _IBtn(icon: Icons.chat_bubble_outline_rounded, badge: '2', colors: colors),
        const SizedBox(width: 8),
        _IBtn(icon: Icons.calendar_today_outlined, colors: colors),
        const SizedBox(width: 14),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
          label: Row(children: const [
            Text('Quick Action', style: TextStyle(fontSize: 13, color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
          ]),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange, elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
        const SizedBox(width: 14),
        Container(width: 1, height: 30, color: colors.divider),
        const SizedBox(width: 14),
        CircleAvatar(radius: 16, backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15),
          child: const Icon(Icons.person_rounded, color: AppColors.primaryOrange, size: 18)),
        const SizedBox(width: 8),
        Text('Admin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary, fontFamily: 'Poppins')),
        Icon(Icons.keyboard_arrow_down_rounded, color: colors.textSecondary, size: 18),
      ]),
    );
  }
}

class _IBtn extends StatelessWidget {
  final IconData icon; final String? badge; final AppThemeColors colors;
  const _IBtn({required this.icon, this.badge, required this.colors});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(width: 38, height: 38,
        decoration: BoxDecoration(color: colors.inputFill, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.border)),
        child: Icon(icon, color: colors.textSecondary, size: 19)),
      if (badge != null)
        Positioned(top: 0, right: 0, child: Container(width: 17, height: 17,
          decoration: const BoxDecoration(color: AppColors.primaryOrange, shape: BoxShape.circle),
          child: Center(child: Text(badge!, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Poppins'))))),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Outlined Button helper
// ─────────────────────────────────────────────────────────────────────────────
class _OBtn extends StatelessWidget {
  final String label; final bool bold; final VoidCallback onTap; final AppThemeColors colors;
  const _OBtn(this.label, {required this.onTap, this.bold = false, required this.colors});
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: colors.border),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      child: Text(label, style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w600 : FontWeight.w400, color: colors.textPrimary, fontFamily: 'Poppins')),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Card
// ─────────────────────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final String title; final Widget child; final AppThemeColors colors;
  const _Card({required this.title, required this.child, required this.colors});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary, fontFamily: 'Poppins')),
        const SizedBox(height: 16),
        child,
      ]));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Labeled Text Field
// ─────────────────────────────────────────────────────────────────────────────
class _F extends StatelessWidget {
  final String label; final TextEditingController ctrl; final String hint;
  final bool required; final TextInputType keyboardType;
  final AppThemeColors colors; final String? suffixText; final Widget? suffixIcon;

  const _F({required this.label, required this.ctrl, this.hint = '',
    this.required = false, this.keyboardType = TextInputType.text,
    required this.colors, this.suffixText, this.suffixIcon});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _LabelText(label, required: required, colors: colors),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl, keyboardType: keyboardType,
        style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: colors.textHint, fontFamily: 'Poppins'),
          filled: true, fillColor: colors.inputFill,
          suffixText: suffixText,
          suffixStyle: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Poppins'),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5)),
          isDense: true,
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Labeled Dropdown Field
// ─────────────────────────────────────────────────────────────────────────────
class _DD extends StatelessWidget {
  final String label; final String? value, hint; final List<String> items;
  final ValueChanged<String?> onChange; final bool required, enabled; final AppThemeColors colors;

  const _DD({required this.label, this.value, this.hint, required this.items,
    required this.onChange, this.required = false, this.enabled = true, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _LabelText(label, required: required, colors: colors),
      const SizedBox(height: 6),
      Container(height: 42, padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: enabled ? colors.inputFill : colors.background.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: enabled ? colors.border : colors.divider)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value, isExpanded: true,
            hint: Text(hint ?? 'Select', style: TextStyle(fontSize: 13, color: colors.textHint, fontFamily: 'Poppins')),
            style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Poppins'),
            dropdownColor: colors.surface,
            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: enabled ? colors.textSecondary : colors.textHint),
            items: items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: enabled ? onChange : null,
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Label with optional asterisk
// ─────────────────────────────────────────────────────────────────────────────
class _LabelText extends StatelessWidget {
  final String label; final bool required; final AppThemeColors colors;
  const _LabelText(this.label, {this.required = false, required this.colors});
  @override
  Widget build(BuildContext context) {
    return RichText(text: TextSpan(children: [
      TextSpan(text: label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: colors.textPrimary, fontFamily: 'Poppins')),
      if (required) const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w700)),
    ]));
  }
}

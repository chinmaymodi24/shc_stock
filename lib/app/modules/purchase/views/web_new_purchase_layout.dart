import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/purchase_controller.dart';
import '../models/purchase_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/widgets/web_sidebar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// New Purchase Order (matches screenshot 2)
// ─────────────────────────────────────────────────────────────────────────────
class WebNewPurchaseLayout extends StatefulWidget {
  const WebNewPurchaseLayout({super.key});

  @override
  State<WebNewPurchaseLayout> createState() => _WebNewPurchaseLayoutState();
}

class _WebNewPurchaseLayoutState extends State<WebNewPurchaseLayout> {
  // Purchase Details
  String _supplier = '';
  DateTime _purchaseDate = DateTime(2024, 5, 31);
  DateTime _deliveryDate = DateTime(2024, 6, 7);
  final _invoiceCtrl = TextEditingController();
  String _paymentTerms = '';
  String _currency = 'INR - Indian Rupee (₹)';
  final _referenceCtrl = TextEditingController();
  String _purchaser = 'Admin';

  // Items
  final List<_ItemRow> _items = [
    _ItemRow(),
    _ItemRow(),
    _ItemRow(),
    _ItemRow(),
  ];

  // Summary extras
  double _discountPercent = 0;
  double _transportCharges = 0;
  double _otherCharges = 0;

  // Payment
  String _paymentMethod = '';
  final _advancePaidCtrl = TextEditingController(text: '0.00');

  // Notes / Attachments
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _referenceCtrl.dispose();
    _advancePaidCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Computed summary values ──────────────────────────────────
  double get _itemsTotal =>
      _items.fold(0.0, (s, row) => s + row.qty * row.rate);
  double get _discountAmount => _itemsTotal * _discountPercent / 100;
  double get _subTotal =>
      _itemsTotal - _discountAmount + _transportCharges + _otherCharges;
  double get _cgst => _subTotal * 0.09;
  double get _sgst => _subTotal * 0.09;
  double get _grandTotal => _subTotal + _cgst + _sgst;

  String _amountInWords(double amount) {
    // Simple converter for display
    final crore = (amount / 10000000).floor();
    final lakh = ((amount % 10000000) / 100000).floor();
    final thousand = ((amount % 100000) / 1000).floor();
    final rest = (amount % 1000).floor();
    final parts = <String>[];
    if (crore > 0) parts.add('${_numWord(crore)} Crore');
    if (lakh > 0) parts.add('${_numWord(lakh)} Lakh');
    if (thousand > 0) parts.add('${_numWord(thousand)} Thousand');
    if (rest > 0) parts.add(_numWord(rest));
    if (parts.isEmpty) return 'INR Zero Only';
    return 'INR ${parts.join(' ')} Only';
  }

  String _numWord(int n) {
    const ones = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight',
      'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
      'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
    ];
    const tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy',
      'Eighty', 'Ninety'
    ];
    if (n < 20) return ones[n];
    if (n < 100) {
      return tens[n ~/ 10] + (n % 10 != 0 ? ' ${ones[n % 10]}' : '');
    }
    return '${ones[n ~/ 100]} Hundred${n % 100 != 0 ? ' ${_numWord(n % 100)}' : ''}';
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
                _WebTopBarSimple(colors: colors),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Breadcrumb + Title + Buttons ──────
                        _Breadcrumb(colors: colors),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'New Purchase Order',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  Text(
                                    'Create a new purchase order by adding supplier and item details.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.textSecondary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Cancel
                            OutlinedButton(
                              onPressed: () => Get.back(),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colors.border),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 13),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9)),
                              ),
                              child: Text('Cancel',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    color: colors.textSecondary,
                                  )),
                            ),
                            const SizedBox(width: 10),
                            // Save as Draft
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colors.border),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 13),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9)),
                              ),
                              child: Text('Save as Draft',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ),
                            const SizedBox(width: 10),
                            // Save & Send
                            ElevatedButton.icon(
                              onPressed: _saveAndSend,
                              icon: const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 16),
                              label: const Text('Save & Send',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                  )),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryOrange,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 13),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Two-column layout: form + summary ─
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT: Main form
                            Expanded(
                              flex: 68,
                              child: Column(
                                children: [
                                  // Purchase Details card
                                  _SectionCard(
                                    colors: colors,
                                    title: 'Purchase Details',
                                    child: Column(
                                      children: [
                                        // Row 1: Supplier, Purchase Date, Expected Delivery, Invoice
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: _FieldLabel(
                                                label: 'Supplier',
                                                isRequired: true,
                                                colors: colors,
                                                child: _SupplierField(
                                                  colors: colors,
                                                  value: _supplier,
                                                  onChanged: (v) => setState(
                                                      () => _supplier = v),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              flex: 2,
                                              child: _FieldLabel(
                                                label: 'Purchase Date',
                                                isRequired: true,
                                                colors: colors,
                                                child: _DateField(
                                                  date: _purchaseDate,
                                                  colors: colors,
                                                  onTap: () =>
                                                      _pickDate(true),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              flex: 2,
                                              child: _FieldLabel(
                                                label: 'Expected Delivery Date',
                                                colors: colors,
                                                child: _DateField(
                                                  date: _deliveryDate,
                                                  colors: colors,
                                                  onTap: () =>
                                                      _pickDate(false),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              flex: 2,
                                              child: _FieldLabel(
                                                label: 'Invoice Number',
                                                colors: colors,
                                                child: _InputField(
                                                  controller: _invoiceCtrl,
                                                  hint: 'Enter invoice number',
                                                  colors: colors,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        // Row 2: Payment Terms, Currency, Reference, Purchaser
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: _FieldLabel(
                                                label: 'Payment Terms',
                                                colors: colors,
                                                child: _DropField(
                                                  hint: 'Select payment terms',
                                                  value: _paymentTerms.isEmpty
                                                      ? null
                                                      : _paymentTerms,
                                                  items: const [
                                                    'Net 30',
                                                    'Net 60',
                                                    'Immediate',
                                                    'On Delivery',
                                                  ],
                                                  colors: colors,
                                                  onChanged: (v) => setState(
                                                      () => _paymentTerms =
                                                          v ?? ''),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              flex: 2,
                                              child: _FieldLabel(
                                                label: 'Currency',
                                                colors: colors,
                                                child: _DropField(
                                                  hint: 'Select currency',
                                                  value: _currency,
                                                  items: const [
                                                    'INR - Indian Rupee (₹)',
                                                    'USD - US Dollar (\$)',
                                                    'EUR - Euro (€)',
                                                  ],
                                                  colors: colors,
                                                  onChanged: (v) => setState(
                                                      () =>
                                                          _currency = v ?? ''),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              flex: 2,
                                              child: _FieldLabel(
                                                label: 'Reference (Optional)',
                                                colors: colors,
                                                child: _InputField(
                                                  controller: _referenceCtrl,
                                                  hint: 'Enter reference',
                                                  colors: colors,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              flex: 2,
                                              child: _FieldLabel(
                                                label: 'Purchaser',
                                                colors: colors,
                                                child: _DropField(
                                                  hint: 'Select purchaser',
                                                  value: _purchaser,
                                                  items: const [
                                                    'Admin',
                                                    'Manager',
                                                    'Purchase Team',
                                                  ],
                                                  colors: colors,
                                                  onChanged: (v) => setState(
                                                      () =>
                                                          _purchaser = v ?? ''),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Items Table card
                                  _SectionCard(
                                    colors: colors,
                                    title: 'Items',
                                    trailing: TextButton.icon(
                                      onPressed: () =>
                                          setState(() => _items.add(_ItemRow())),
                                      icon: const Icon(Icons.add_rounded,
                                          size: 16,
                                          color: AppColors.primaryOrange),
                                      label: const Text('Add Item',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.primaryOrange,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w600,
                                          )),
                                      style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero),
                                    ),
                                    child: _ItemsTable(
                                      items: _items,
                                      colors: colors,
                                      onChanged: () => setState(() {}),
                                      onDelete: (i) =>
                                          setState(() => _items.removeAt(i)),
                                      onAddRow: () =>
                                          setState(() => _items.add(_ItemRow())),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Attachments + Notes row
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _SectionCard(
                                          colors: colors,
                                          title: 'Attachments',
                                          child: _AttachmentArea(colors: colors),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _SectionCard(
                                          colors: colors,
                                          title: 'Notes (Optional)',
                                          child: TextField(
                                            controller: _notesCtrl,
                                            maxLines: 5,
                                            maxLength: 500,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: colors.textPrimary,
                                              fontFamily: 'Poppins',
                                            ),
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Enter any additional notes...',
                                              hintStyle: TextStyle(
                                                  fontSize: 13,
                                                  color: colors.textHint,
                                                  fontFamily: 'Poppins'),
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.all(12),
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              counterStyle: TextStyle(
                                                  fontSize: 11,
                                                  color: colors.textHint,
                                                  fontFamily: 'Poppins'),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),

                            // RIGHT: Purchase Summary
                            SizedBox(
                              width: 260,
                              child: Column(
                                children: [
                                  _PurchaseSummaryCard(
                                    colors: colors,
                                    itemsTotal: _itemsTotal,
                                    discountPercent: _discountPercent,
                                    discountAmount: _discountAmount,
                                    transportCharges: _transportCharges,
                                    otherCharges: _otherCharges,
                                    subTotal: _subTotal,
                                    cgst: _cgst,
                                    sgst: _sgst,
                                    grandTotal: _grandTotal,
                                    amountInWords: _amountInWords(_grandTotal),
                                    onDiscountChanged: (v) =>
                                        setState(() => _discountPercent = v),
                                    onTransportChanged: (v) =>
                                        setState(() => _transportCharges = v),
                                    onOtherChanged: (v) =>
                                        setState(() => _otherCharges = v),
                                    itemCount: _items.length,
                                  ),
                                  const SizedBox(height: 16),
                                  _PaymentInfoCard(
                                    colors: colors,
                                    paymentMethod: _paymentMethod,
                                    advancePaidCtrl: _advancePaidCtrl,
                                    onMethodChanged: (v) =>
                                        setState(() => _paymentMethod = v ?? ''),
                                  ),
                                ],
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

  Future<void> _pickDate(bool isPurchaseDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isPurchaseDate ? _purchaseDate : _deliveryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isPurchaseDate) {
          _purchaseDate = picked;
        } else {
          _deliveryDate = picked;
        }
      });
    }
  }

  void _saveAndSend() {
    final c = Get.find<PurchaseController>();
    final newId = 'po_${DateTime.now().millisecondsSinceEpoch}';
    final newPoNum =
        'PO-2024-${(10000 + c.orders.length + 1).toString().padLeft(5, '0')}';
    c.addOrder(PurchaseOrder(
      id: newId,
      poNumber: newPoNum,
      supplier: _supplier.isEmpty ? 'Unknown Supplier' : _supplier,
      supplierIcon: _supplier.isEmpty ? 'US' : _supplier.substring(0, 2).toUpperCase(),
      date: _purchaseDate,
      itemCount: _items.length,
      amount: _grandTotal,
      status: PurchaseStatus.pending,
    ));
    Get.back();
    Get.snackbar(
      '✅ Purchase Order Created',
      '$newPoNum has been successfully created.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item Row data model
// ─────────────────────────────────────────────────────────────────────────────
class _ItemRow {
  String product = '';
  String description = '';
  String hsnSac = '—';
  double qty = 1;
  String unit = '';
  double rate = 0;
  double gst = 18;

  double get amount => qty * rate;
}

// ─────────────────────────────────────────────────────────────────────────────
// Items Table
// ─────────────────────────────────────────────────────────────────────────────
class _ItemsTable extends StatelessWidget {
  final List<_ItemRow> items;
  final AppThemeColors colors;
  final VoidCallback onChanged;
  final void Function(int) onDelete;
  final VoidCallback onAddRow;

  const _ItemsTable({
    required this.items,
    required this.colors,
    required this.onChanged,
    required this.onDelete,
    required this.onAddRow,
  });

  TextStyle get _header => TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: colors.textSecondary,
      fontFamily: 'Poppins');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Column headers
        Container(
          color: colors.rowEven,
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                  width: 28,
                  child: Text('#', style: _header, textAlign: TextAlign.center)),
              Expanded(
                  flex: 18,
                  child: Text('Product *', style: _header)),
              const SizedBox(width: 8),
              Expanded(
                  flex: 18,
                  child: Text('Description', style: _header)),
              const SizedBox(width: 8),
              SizedBox(
                  width: 50,
                  child: Text('HSN/SAC', style: _header)),
              const SizedBox(width: 8),
              SizedBox(
                  width: 50,
                  child: Text('Qty *', style: _header)),
              const SizedBox(width: 8),
              SizedBox(
                  width: 70,
                  child: Text('Unit *', style: _header)),
              const SizedBox(width: 8),
              SizedBox(
                  width: 70,
                  child: Text('Rate (₹) *', style: _header)),
              const SizedBox(width: 8),
              SizedBox(
                  width: 60,
                  child: Text('GST (%) *', style: _header)),
              const SizedBox(width: 8),
              SizedBox(
                  width: 70,
                  child: Text('Amount (₹)', style: _header)),
              const SizedBox(width: 8),
              SizedBox(
                  width: 36,
                  child: Text('Actions', style: _header)),
            ],
          ),
        ),
        Divider(height: 1, color: colors.divider),

        // Item rows
        ...items.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          return _ItemRowWidget(
            index: i,
            row: row,
            colors: colors,
            onChanged: onChanged,
            onDelete: () => onDelete(i),
          );
        }),

        // Add Another Row button
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: GestureDetector(
            onTap: onAddRow,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Icon(Icons.add_rounded, size: 15, color: AppColors.primaryOrange),
                SizedBox(width: 4),
                Text(
                  'Add Another Row',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryOrange,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemRowWidget extends StatelessWidget {
  final int index;
  final _ItemRow row;
  final AppThemeColors colors;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _ItemRowWidget({
    required this.index,
    required this.row,
    required this.colors,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider, width: 0.8)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // #
          SizedBox(
            width: 28,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                  fontSize: 12.5,
                  color: colors.textSecondary,
                  fontFamily: 'Poppins'),
              textAlign: TextAlign.center,
            ),
          ),

          // Product dropdown
          Expanded(
            flex: 18,
            child: _SmallDrop(
              hint: 'Search product...',
              items: const ['Ceramic Fiber Blanket', 'Fire Bricks', 'Castable Refractory', 'Fire Blanket', 'Ceramic Fiber Rope'],
              value: row.product.isEmpty ? null : row.product,
              colors: colors,
              onChanged: (v) {
                row.product = v ?? '';
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),

          // Description
          Expanded(
            flex: 18,
            child: _SmallInput(
              hint: 'Enter description',
              value: row.description,
              colors: colors,
              onChanged: (v) {
                row.description = v;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),

          // HSN/SAC
          SizedBox(
            width: 50,
            child: Text('—',
                style: TextStyle(
                    fontSize: 12.5,
                    color: colors.textSecondary,
                    fontFamily: 'Poppins'),
                textAlign: TextAlign.center),
          ),
          const SizedBox(width: 8),

          // Qty
          SizedBox(
            width: 50,
            child: _SmallNumberInput(
              value: row.qty,
              colors: colors,
              onChanged: (v) {
                row.qty = v;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),

          // Unit
          SizedBox(
            width: 70,
            child: _SmallDrop(
              hint: 'Unit',
              items: const ['Kg', 'Pcs', 'Mtr', 'Ltr', 'Box', 'Set'],
              value: row.unit.isEmpty ? null : row.unit,
              colors: colors,
              onChanged: (v) {
                row.unit = v ?? '';
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),

          // Rate
          SizedBox(
            width: 70,
            child: _SmallNumberInput(
              value: row.rate,
              colors: colors,
              onChanged: (v) {
                row.rate = v;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),

          // GST
          SizedBox(
            width: 60,
            child: _SmallDrop(
              hint: 'GST%',
              items: const ['0%', '5%', '12%', '18%', '28%'],
              value: '${row.gst.toInt()}%',
              colors: colors,
              onChanged: (v) {
                row.gst =
                    double.tryParse(v?.replaceAll('%', '') ?? '18') ?? 18;
                onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),

          // Amount
          SizedBox(
            width: 70,
            child: Text(
              '₹ ${row.amount.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins'),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 8),

          // Delete
          SizedBox(
            width: 36,
            child: IconButton(
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              icon: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444), size: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Purchase Summary Card
// ─────────────────────────────────────────────────────────────────────────────
class _PurchaseSummaryCard extends StatelessWidget {
  final AppThemeColors colors;
  final double itemsTotal, discountPercent, discountAmount;
  final double transportCharges, otherCharges, subTotal;
  final double cgst, sgst, grandTotal;
  final String amountInWords;
  final int itemCount;
  final ValueChanged<double> onDiscountChanged;
  final ValueChanged<double> onTransportChanged;
  final ValueChanged<double> onOtherChanged;

  const _PurchaseSummaryCard({
    required this.colors,
    required this.itemsTotal,
    required this.discountPercent,
    required this.discountAmount,
    required this.transportCharges,
    required this.otherCharges,
    required this.subTotal,
    required this.cgst,
    required this.sgst,
    required this.grandTotal,
    required this.amountInWords,
    required this.itemCount,
    required this.onDiscountChanged,
    required this.onTransportChanged,
    required this.onOtherChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Purchase Summary',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 14),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: 12),

          // Items Total
          _SummaryRow(
            label: 'Items Total ($itemCount Items)',
            value: '₹ ${itemsTotal.toStringAsFixed(2)}',
            colors: colors,
          ),
          const SizedBox(height: 10),

          // Discount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text('Discount',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: colors.textSecondary,
                          fontFamily: 'Poppins')),
                  const SizedBox(width: 4),
                  Icon(Icons.info_outline_rounded,
                      size: 13, color: colors.textHint),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: 50,
                    height: 28,
                    child: TextField(
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                          fontSize: 12,
                          color: colors.textPrimary,
                          fontFamily: 'Poppins'),
                      decoration: InputDecoration(
                        hintText: '0',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                              color: AppColors.primaryOrange, width: 1.5),
                        ),
                      ),
                      onChanged: (v) => onDiscountChanged(
                          double.tryParse(v) ?? 0),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.inputFill,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text('%',
                        style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontFamily: 'Poppins')),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '₹ ${discountAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Transport Charges
          _EditableSummaryRow(
            label: 'Transport Charges',
            value: transportCharges,
            colors: colors,
            onChanged: onTransportChanged,
          ),
          const SizedBox(height: 10),

          // Other Charges
          _EditableSummaryRow(
            label: 'Other Charges',
            value: otherCharges,
            colors: colors,
            onChanged: onOtherChanged,
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: 10),

          _SummaryRow(
            label: 'Sub Total',
            value: '₹ ${subTotal.toStringAsFixed(2)}',
            colors: colors,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'CGST (9%)',
            value: '₹ ${cgst.toStringAsFixed(2)}',
            colors: colors,
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'SGST (9%)',
            value: '₹ ${sgst.toStringAsFixed(2)}',
            colors: colors,
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: 12),

          // Grand Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins')),
              Text(
                '₹ ${grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryOrange,
                    fontFamily: 'Poppins'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Amount in words
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.rowEven,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount in words',
                    style: TextStyle(
                        fontSize: 11,
                        color: colors.textHint,
                        fontFamily: 'Poppins')),
                const SizedBox(height: 3),
                Text(amountInWords,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                        fontFamily: 'Poppins')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Payment Info Card
class _PaymentInfoCard extends StatelessWidget {
  final AppThemeColors colors;
  final String paymentMethod;
  final TextEditingController advancePaidCtrl;
  final ValueChanged<String?> onMethodChanged;

  const _PaymentInfoCard({
    required this.colors,
    required this.paymentMethod,
    required this.advancePaidCtrl,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Info',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 14),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: 12),

          // Payment Method
          Text('Payment Method',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 6),
          _DropField(
            hint: 'Select payment method',
            value: paymentMethod.isEmpty ? null : paymentMethod,
            items: const ['Cash', 'Bank Transfer', 'Cheque', 'UPI', 'Credit'],
            colors: colors,
            onChanged: onMethodChanged,
          ),
          const SizedBox(height: 12),

          // Advance Paid
          Text('Advance Paid',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 6),
          TextField(
            controller: advancePaidCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(
                fontSize: 13,
                color: colors.textPrimary,
                fontFamily: 'Poppins'),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              filled: true,
              fillColor: colors.inputFill,
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
                    color: AppColors.primaryOrange, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Info note
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4A3AFF).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF4A3AFF).withValues(alpha: 0.15)),
            ),
            child: const Text(
              'You can record payment after saving the purchase order.',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF4A3AFF),
                fontFamily: 'Poppins',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable small widgets
// ─────────────────────────────────────────────────────────────────────────────
class _Breadcrumb extends StatelessWidget {
  final AppThemeColors colors;
  const _Breadcrumb({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: Text('Purchase',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryOrange,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500)),
        ),
        Icon(Icons.chevron_right_rounded,
            size: 16, color: colors.textHint),
        Text('New Purchase Order',
            style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                fontFamily: 'Poppins')),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final AppThemeColors colors;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard(
      {required this.colors,
      required this.title,
      required this.child,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins')),
              if (trailing != null) ...[
                const Spacer(),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool isRequired;
  final AppThemeColors colors;
  final Widget child;

  const _FieldLabel(
      {required this.label,
      this.isRequired = false,
      required this.colors,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
                fontFamily: 'Poppins'),
            children: isRequired
                ? const [
                    TextSpan(
                        text: ' *',
                        style: TextStyle(color: Color(0xFFEF4444)))
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final AppThemeColors colors;

  const _InputField(
      {required this.controller, required this.hint, required this.colors});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(
          fontSize: 13, color: colors.textPrimary, fontFamily: 'Poppins'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontSize: 13, color: colors.textHint, fontFamily: 'Poppins'),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        filled: true,
        fillColor: colors.inputFill,
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
          borderSide:
              const BorderSide(color: AppColors.primaryOrange, width: 1.5),
        ),
      ),
    );
  }
}

class _DropField extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final AppThemeColors colors;
  final ValueChanged<String?> onChanged;

  const _DropField({
    required this.hint,
    required this.value,
    required this.items,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint,
              style: TextStyle(
                  fontSize: 13,
                  color: colors.textHint,
                  fontFamily: 'Poppins')),
          isDense: true,
          isExpanded: true,
          dropdownColor: colors.surface,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: colors.textSecondary),
          style: TextStyle(
              fontSize: 13,
              color: colors.textPrimary,
              fontFamily: 'Poppins'),
          items: items
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime date;
  final AppThemeColors colors;
  final VoidCallback onTap;

  const _DateField(
      {required this.date, required this.colors, required this.onTap});

  String get _formatted {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colors.inputFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 15, color: AppColors.primaryOrange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_formatted,
                  style: TextStyle(
                      fontSize: 13,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierField extends StatelessWidget {
  final AppThemeColors colors;
  final String value;
  final ValueChanged<String> onChanged;

  const _SupplierField(
      {required this.colors, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 15, color: colors.textHint),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: TextStyle(
                  fontSize: 13,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins'),
              decoration: InputDecoration(
                hintText: 'Search supplier...',
                hintStyle: TextStyle(
                    fontSize: 13,
                    color: colors.textHint,
                    fontFamily: 'Poppins'),
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Icon(Icons.add_circle_outline_rounded,
              size: 16, color: colors.textSecondary),
        ],
      ),
    );
  }
}

class _SmallInput extends StatelessWidget {
  final String hint;
  final String value;
  final AppThemeColors colors;
  final ValueChanged<String> onChanged;

  const _SmallInput(
      {required this.hint,
      required this.value,
      required this.colors,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      style: TextStyle(
          fontSize: 12, color: colors.textPrimary, fontFamily: 'Poppins'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontSize: 12, color: colors.textHint, fontFamily: 'Poppins'),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true,
        fillColor: colors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: AppColors.primaryOrange, width: 1.2),
        ),
      ),
    );
  }
}

class _SmallDrop extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final AppThemeColors colors;
  final ValueChanged<String?> onChanged;

  const _SmallDrop(
      {required this.hint,
      required this.value,
      required this.items,
      required this.colors,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final safeVal = (value != null && items.contains(value)) ? value : null;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: colors.inputFill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeVal,
          hint: Text(hint,
              style: TextStyle(
                  fontSize: 11.5,
                  color: colors.textHint,
                  fontFamily: 'Poppins'),
              overflow: TextOverflow.ellipsis),
          isDense: true,
          isExpanded: true,
          dropdownColor: colors.surface,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 14, color: colors.textSecondary),
          style: TextStyle(
              fontSize: 11.5,
              color: colors.textPrimary,
              fontFamily: 'Poppins'),
          items: items
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SmallNumberInput extends StatelessWidget {
  final double value;
  final AppThemeColors colors;
  final ValueChanged<double> onChanged;

  const _SmallNumberInput(
      {required this.value, required this.colors, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value == 0 ? '0' : value.toStringAsFixed(0),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
      ],
      onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
      style: TextStyle(
          fontSize: 12,
          color: colors.textPrimary,
          fontFamily: 'Poppins'),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        filled: true,
        fillColor: colors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: AppColors.primaryOrange, width: 1.2),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final AppThemeColors colors;

  const _SummaryRow(
      {required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12.5,
                color: colors.textSecondary,
                fontFamily: 'Poppins')),
        Text(value,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                fontFamily: 'Poppins')),
      ],
    );
  }
}

class _EditableSummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final AppThemeColors colors;
  final ValueChanged<double> onChanged;

  const _EditableSummaryRow(
      {required this.label,
      required this.value,
      required this.colors,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12.5,
                color: colors.textSecondary,
                fontFamily: 'Poppins')),
        SizedBox(
          width: 70,
          height: 28,
          child: TextFormField(
            initialValue: value.toStringAsFixed(2),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
            style: TextStyle(
                fontSize: 12,
                color: colors.textPrimary,
                fontFamily: 'Poppins'),
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                    color: AppColors.primaryOrange, width: 1.2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AttachmentArea extends StatelessWidget {
  final AppThemeColors colors;
  const _AttachmentArea({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: colors.rowEven,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.divider,
          style: BorderStyle.solid,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload_outlined,
              size: 32, color: colors.textSecondary),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              text: 'Drag & drop files here or ',
              style: TextStyle(
                  fontSize: 12.5,
                  color: colors.textSecondary,
                  fontFamily: 'Poppins'),
              children: const [
                TextSpan(
                  text: 'click to upload',
                  style: TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text('Supports: PDF, JPG, PNG (Max. 8MB)',
              style: TextStyle(
                  fontSize: 11,
                  color: colors.textHint,
                  fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}

// Simple top bar for the new purchase form page
class _WebTopBarSimple extends StatelessWidget {
  final AppThemeColors colors;
  const _WebTopBarSimple({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colors.topBarBg,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 320,
            height: 38,
            decoration: BoxDecoration(
              color: colors.inputFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(Icons.search_rounded, color: colors.textHint, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Search anything...',
                      style: TextStyle(
                          fontSize: 13,
                          color: colors.textHint,
                          fontFamily: 'Poppins')),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text('Ctrl + K',
                      style: TextStyle(
                          fontSize: 10,
                          color: colors.textSecondary,
                          fontFamily: 'Poppins')),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: colors.inputFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Icon(Icons.notifications_outlined,
                color: colors.textSecondary, size: 19),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: colors.inputFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Icon(Icons.chat_bubble_outline_rounded,
                color: colors.textSecondary, size: 19),
          ),
          const SizedBox(width: 14),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
            label: Row(children: const [
              Text('Quick Action',
                  style: TextStyle(fontSize: 13, color: Colors.white,
                      fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
              SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
            ]),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 30, color: colors.divider),
          const SizedBox(width: 14),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15),
            child: const Icon(Icons.person_rounded,
                color: AppColors.primaryOrange, size: 18),
          ),
          const SizedBox(width: 8),
          Text('Admin',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins')),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: colors.textSecondary, size: 18),
        ],
      ),
    );
  }
}

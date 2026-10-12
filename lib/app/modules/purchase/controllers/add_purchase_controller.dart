import 'package:shc_stock/app/core/utils/dispose_later.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/shared/widgets/app_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/billing/controllers/billing_profile_controller.dart';
import 'package:shc_stock/app/core/utils/gst.dart';
import 'package:shc_stock/app/modules/purchase/controllers/purchase_controller.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/core/utils/order_checks.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/core/utils/doc_number.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/purchase/models/purchase_model.dart';
import 'package:shc_stock/app/modules/settings/controllers/settings_controller.dart';
import 'package:shc_stock/app/shared/models/order_payment.dart';

class PurchaseItemRow {
  // Stable identity for list-item Keys, and a version bump whenever fields
  // are set programmatically (product autofill) so the small text-field
  // cells below re-seed their displayed text instead of keeping stale
  // TextFormField state from the initial build (TextFormField only reads
  // `initialValue` once — it never syncs to later prop changes on its own).
  static int _seq = 0;
  final int id = _seq++;
  int version = 0;

  /// Backend product id, set when the row is filled from the product
  /// autocomplete. Sent to the API so the server moves this product's stock.
  int? productId;
  String product = '';
  String hsn = '';
  String grade = '';
  String density = '';

  // Defaults to one, not zero: amount is totalQty * netPrice, so a zero here
  // pinned every row's amount — and the whole invoice total — to ₹0 until the
  // box was filled in, which read as "the price isn't updating".
  double noPkg = 1;

  String uom = 'BOX';
  double netPrice = 0;

  /// GST rate (percent) — the picked product's own, 18% for a typed line.
  double taxPercent = kDefaultGstRate;

  /// What the API stores as the line's `qty`. There used to be an average
  /// contents-per-pack multiplier between the two; it was dropped because it
  /// never round-tripped (a saved order always came back with it at 1), so
  /// the total is simply the pack count.
  double get totalQty => noPkg;
  set totalQty(double v) => noPkg = v < 0 ? 0 : v;

  double get amount => totalQty * netPrice;
}

/// Marks a "Duplicate" navigation: the form loads from [order] but never
/// tracks it as `editing`, so Save always POSTs a brand-new record and the
/// original order is left untouched.
class DuplicatePurchaseOrder {
  final PurchaseOrder order;
  const DuplicatePurchaseOrder(this.order);
}

class AddPurchaseController extends GetxController {
  final client = ''.obs;
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final pinCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final buyerGstCtrl = TextEditingController();
  final panCtrl = TextEditingController();
  final invoiceNoCtrl = TextEditingController();
  final invoiceDate = Rx<DateTime?>(null);
  final poNoCtrl = TextEditingController();
  final poDate = Rx<DateTime?>(null);
  final despatchThrough = 'DIRECT VEHICLE'.obs;
  final lrNoCtrl = TextEditingController();
  final lrDate = Rx<DateTime?>(null);
  final vehicleNoCtrl = TextEditingController();
  final freightCtrl = TextEditingController();
  final placeOfSupplyCtrl = TextEditingController();
  final dueDate = Rx<DateTime?>(null);

  /// Optional expected delivery date. Left empty the order keeps whatever
  /// status it has; set, the backend marks it Received on that date and books
  /// the stock then.
  final expectedDelivery = Rx<DateTime?>(null);

  /// "Order Paid" — the dropdown choice and the amount behind it.
  final paymentType = OrderPaymentType.none.obs;
  final paidAmountCtrl = TextEditingController();

  final items = <PurchaseItemRow>[PurchaseItemRow()].obs;

  /// The order being edited, when the page was opened from the list's Edit
  /// action. Null for a new purchase. Its id, PO number and status are
  /// carried through the save so an edit updates the record in place instead
  /// of creating a second one.
  PurchaseOrder? editing;
  bool get isEditing => editing != null;

  @override
  void onInit() {
    super.onInit();
    // The party's state decides CGST + SGST vs IGST; the totals redraw off
    // `items`, so poke it whenever one of the boxes that names the state
    // changes.
    for (final c in [buyerGstCtrl, placeOfSupplyCtrl, stateCtrl, addressCtrl]) {
      c.addListener(items.refresh);
    }
    final arg = Get.arguments;
    if (arg is DuplicatePurchaseOrder) {
      loadFrom(arg.order, asDuplicate: true);
      // A duplicate loads every field of the source order, so saving it as-is
      // would create a byte-for-byte copy — same invoice number, same date.
      // Force a fresh invoice number (regardless of the auto-numbering
      // preference) and today's dates so the new record is distinct.
      _fillNextNumber();
      final today = DateTime.now();
      invoiceDate.value = today;
      poDate.value = today;
    } else if (arg is PurchaseOrder) {
      loadFrom(arg);
    } else {
      _prefillInvoiceNo();
      // A new purchase starts as fully paid; the amount follows the grand total
      // until it is typed over (or another option is picked).
      paymentType.value = OrderPaymentType.full;
    }
  }

  /// Writes the server's next order number into "Invoice No.".
  Future<void> _fillNextNumber() async {
    final n = await nextOrderNumber(OrderSeries.purchase);
    if (n.isNotEmpty) invoiceNoCtrl.text = n;
  }

  /// Fills "Invoice No." with the next number, unless the user turned
  /// auto-numbering off in Settings › Preferences.
  Future<void> _prefillInvoiceNo() async {
    if (isEditing) return;
    if (!await autoNumberPurchaseEnabled()) return;
    await _fillNextNumber();
  }

  /// Fills the form from an existing order. When [asDuplicate] is true,
  /// `editing` is left null so Save (see WebNewPurchaseLayout._savePurchase)
  /// creates a fresh record instead of updating the one it was copied from.
  void loadFrom(PurchaseOrder o, {bool asDuplicate = false}) {
    if (!asDuplicate) editing = o;
    client.value = o.supplier;
    addressCtrl.text = o.supplierAddress;
    buyerGstCtrl.text = o.buyerGst;
    panCtrl.text = o.pan;
    invoiceNoCtrl.text = o.invoiceNo;
    invoiceDate.value = o.invoiceDate ?? o.date;
    poNoCtrl.text = o.poNumber;
    poDate.value = o.date;
    if (o.despatchThrough.isNotEmpty) despatchThrough.value = o.despatchThrough;
    lrNoCtrl.text = o.lrNo;
    lrDate.value = o.lrDate;
    vehicleNoCtrl.text = o.vehicleNo;
    freightCtrl.text = o.freight == 0 ? '' : o.freight.toString();
    placeOfSupplyCtrl.text = o.placeOfSupply;
    dueDate.value = o.dueDate;
    expectedDelivery.value = o.expectedDelivery;
    paymentType.value = o.paymentType;
    paidAmountCtrl.text = o.paidAmount == 0 ? '' : trimAmount(o.paidAmount);
    // The saved figure is the person's own; do not re-derive it from the total.
    _paidTyped = true;

    items.assignAll(
      o.items.isEmpty
          ? [PurchaseItemRow()]
          : o.items.map((i) {
              final row = PurchaseItemRow()
                ..productId = i.productId
                ..product = i.product
                ..hsn = i.hsn
                ..grade = i.grade
                ..density = i.density
                ..noPkg = i.qty
                ..uom = i.unit.isEmpty ? 'BOX' : i.unit
                ..netPrice = i.rate
                ..taxPercent = i.taxPercent;
              return row;
            }).toList(),
    );
  }

  /// Applies a dropdown pick and prefills the amount box: Full Payment fills
  /// the grand total, Half Payment half of it, Other is left for the user to
  /// type. The value stays editable in every case.
  void setPaymentType(OrderPaymentType type) {
    paymentType.value = type;
    _paidTyped = false;
    final suggested = type.suggestedAmount(grandTotal);
    paidAmountCtrl.text = suggested == null ? '' : trimAmount(suggested);
  }

  /// True once the person typed their own figure in the amount box; the box
  /// then stops following the grand total.
  bool _paidTyped = false;
  void paidAmountTyped() => _paidTyped = true;

  /// Keeps a Full / Half amount in step with the grand total as lines change.
  void _followGrandTotal() {
    if (_paidTyped) return;
    final suggested = paymentType.value.suggestedAmount(grandTotal);
    if (suggested == null) return;
    paidAmountCtrl.text = suggested > 0 ? trimAmount(suggested) : '';
  }

  /// The amount actually paid — whatever is in the box, 0 when it is empty or
  /// no payment type was chosen.
  double get paidAmount {
    if (paymentType.value == OrderPaymentType.none) return 0;
    return double.tryParse(paidAmountCtrl.text.trim()) ?? 0;
  }

  double get subTotal => items.fold(0.0, (s, r) => s + r.amount);

  /// The party's GST state: GSTIN first, then place of supply, state, address.
  String? get partyStateCode => gstStateOf(buyerGstCtrl.text, [
    placeOfSupplyCtrl.text,
    stateCtrl.text,
    addressCtrl.text,
  ]);

  /// Inter-state supply → IGST; same state (or either side unknown) → CGST +
  /// SGST. The seller's state comes from Settings › Billing.
  bool get interState =>
      isInterState(BillingProfileController.sellerStateCode, partyStateCode);

  /// Tax on the lines, each at its own product's rate.
  GstBreakup get gst => computeGst([
    for (final r in items) GstLine(r.amount, r.taxPercent),
  ], interState: interState);
  double get sgst => gst.sgst;
  double get cgst => gst.cgst;
  double get igst => gst.igst;
  double get grandTotal => subTotal + gst.totalTax;

  void applyClient(ClientModel c) {
    client.value = c.name;
    addressCtrl.text = c.addressOnly;
    cityCtrl.text = c.city;
    pinCtrl.text = c.pin;
    stateCtrl.text = c.state;
    if (c.state.isNotEmpty) placeOfSupplyCtrl.text = c.state;
    buyerGstCtrl.text = c.gstin;
    panCtrl.text = c.pan;
  }

  void addItemRow() => items.add(PurchaseItemRow());

  void removeItemRow(int index) {
    items.removeAt(index);
    _followGrandTotal();
  }

  void notifyItemsChanged() {
    items.refresh();
    _followGrandTotal();
  }

  Future<void> pickDate(BuildContext context, Rx<DateTime?> target) async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) target.value = picked;
  }

  @override
  void onClose() {
    // Disposed once the page has gone, not while it is still on screen
    // for its exit transition — see dispose_later.dart.
    disposeAfterPageExit([
      addressCtrl,
      cityCtrl,
      pinCtrl,
      stateCtrl,
      buyerGstCtrl,
      panCtrl,
      invoiceNoCtrl,
      poNoCtrl,
      lrNoCtrl,
      vehicleNoCtrl,
      freightCtrl,
      placeOfSupplyCtrl,
      paidAmountCtrl,
    ]);
    super.onClose();
  }

  /// The rows that get sent — the empty one left at the bottom is not.
  List<PurchaseItemRow> sentRows() => withoutBlankRows(
    items,
    (r) => (
      name: r.product,
      productId: r.productId,
      qty: r.totalQty,
      rate: r.netPrice,
    ),
  );

  /// Validates, saves (create or update), then returns to the list with a
  /// toast. Shared by the web and the mobile form, so the two can never save
  /// different things.
  Future<void> save() async {
    final c = Get.find<PurchaseController>();
    // Editing keeps the record's own id, PO number and status — only the
    // details being edited change.
    final editing = this.editing;
    final newId = editing?.id ?? 'po_${DateTime.now().millisecondsSinceEpoch}';
    // Blank for a new order: the server numbers it (PO/0001/26-27).
    final newPoNum = editing?.poNumber ?? '';
    final supplierName = client.value.trim();
    // No supplier used to save as the literal "Unknown Supplier", and a
    // one-letter name crashed the badge below on substring(0, 2).
    final problem = supplierName.isEmpty
        ? 'Please select or enter a supplier before saving.'
        : checkOrderLines([
                for (final r in items)
                  (
                    name: r.product,
                    productId: r.productId,
                    qty: r.totalQty,
                    rate: r.netPrice,
                  ),
              ]) ??
              checkPayment(paid: paidAmount, total: grandTotal) ??
              checkDateOrder(
                later: dueDate.value,
                earlier: invoiceDate.value ?? DateTime.now(),
                laterName: 'Due date',
                earlierName: 'the invoice date',
              ) ??
              checkDateOrder(
                later: expectedDelivery.value,
                earlier: invoiceDate.value ?? DateTime.now(),
                laterName: 'Expected delivery',
                earlierName: 'the invoice date',
              );
    if (problem != null) {
      showAppToast(
        'Check the order',
        problem,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
      );
      return;
    }
    final order = PurchaseOrder(
      id: newId,
      poNumber: newPoNum,
      supplier: supplierName,
      supplierIcon: supplierName
          .substring(0, supplierName.length < 2 ? supplierName.length : 2)
          .toUpperCase(),
      date: invoiceDate.value ?? DateTime.now(),
      itemCount: sentRows().length,
      amount: grandTotal,
      status: editing?.status ?? PurchaseStatus.pending,
      modifiedBy: currentActorName,
      modifiedAt: DateTime.now(),
      supplierAddress: addressCtrl.text.trim(),
      buyerGst: buyerGstCtrl.text.trim(),
      pan: panCtrl.text.trim(),
      invoiceNo: invoiceNoCtrl.text.trim().isEmpty
          ? newPoNum
          : invoiceNoCtrl.text.trim(),
      invoiceDate: invoiceDate.value,
      despatchThrough: despatchThrough.value,
      lrNo: lrNoCtrl.text.trim(),
      lrDate: lrDate.value,
      vehicleNo: vehicleNoCtrl.text.trim(),
      freight: double.tryParse(freightCtrl.text.trim()) ?? 0,
      placeOfSupply: placeOfSupplyCtrl.text.trim(),
      dueDate: dueDate.value,
      expectedDelivery: expectedDelivery.value,
      paymentType: paymentType.value,
      paidAmount: paidAmount,
      interState: interState,
      items: sentRows()
          .map(
            (r) => PurchaseDetailItem(
              productId: r.productId,
              product: r.product,
              hsn: r.hsn,
              grade: r.grade,
              density: r.density,
              qty: r.totalQty,
              unit: r.uom,
              rate: r.netPrice,
              taxPercent: r.taxPercent,
            ),
          )
          .toList(),
    );

    final ok = editing == null
        ? await c.addOrder(order)
        : await c.updateOrder(order);
    if (!ok) return; // controller already showed the error toast
    // A new order's number is the one the server gave it (newest first).
    final number = editing == null && c.orders.isNotEmpty
        ? c.orders.first.poNumber
        : newPoNum;
    Get.offNamed(AppRoutes.purchase);
    final unlinked = unlinkedItemsNote(
      sentRows().where((r) => r.productId == null).length,
    );
    showAppToast(
      editing == null ? '✅ Purchase Saved' : '✅ Purchase Updated',
      editing == null
          ? '$number has been successfully created.$unlinked'
          : '$number has been successfully updated.$unlinked',
      backgroundColor: AppColors.success,
      colorText: Colors.white,
    );
  }
}

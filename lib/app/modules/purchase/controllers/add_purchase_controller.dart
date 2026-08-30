import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/core/utils/doc_number.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/purchase/controllers/purchase_controller.dart';
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

  // Default to a single unit per row. Amount is (noPkg * avgContPerPkg) *
  // netPrice, so starting these at 0 pinned every row's amount — and the
  // whole invoice total — to ₹0 until the user filled in both boxes, which
  // read as "the price isn't updating". 1 x 1 makes the selected product's
  // price show up immediately and still scales once real packing is entered.
  double noPkg = 1;
  double avgContPerPkg = 1;

  String uom = 'BOX';
  double netPrice = 0;

  double get totalQty => noPkg * avgContPerPkg;

  /// Total quantity is normally packs x per-pack, but it is also editable
  /// directly (and steppable) — entering a total keeps the per-pack figure
  /// and back-solves the pack count, so the three fields never contradict
  /// each other.
  set totalQty(double v) {
    final per = avgContPerPkg <= 0 ? 1.0 : avgContPerPkg;
    avgContPerPkg = per;
    noPkg = (v < 0 ? 0 : v) / per;
  }

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
  final statePinCtrl = TextEditingController();
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
    final arg = Get.arguments;
    if (arg is DuplicatePurchaseOrder) {
      loadFrom(arg.order, asDuplicate: true);
      // A duplicate loads every field of the source order, so saving it as-is
      // would create a byte-for-byte copy — same invoice number, same date.
      // Force a fresh invoice number (regardless of the auto-numbering
      // preference) and today's dates so the new record is distinct.
      invoiceNoCtrl.text = _nextInvoiceNo();
      final today = DateTime.now();
      invoiceDate.value = today;
      poDate.value = today;
    } else if (arg is PurchaseOrder) {
      loadFrom(arg);
    } else {
      _prefillInvoiceNo();
    }
  }

  /// The next number in the PO-2024 series, from the loaded orders.
  String _nextInvoiceNo() {
    final orders = Get.isRegistered<PurchaseController>()
        ? Get.find<PurchaseController>().orders
        : const <PurchaseOrder>[];
    return nextDocNumber(
      prefix: 'PO-2024',
      existing: orders.map((o) => o.poNumber),
    );
  }

  /// Fills "Invoice No." with [_nextInvoiceNo], unless the user turned
  /// auto-numbering off in Settings › Preferences.
  Future<void> _prefillInvoiceNo() async {
    if (isEditing) return;
    if (!await autoNumberDocsEnabled()) return;
    invoiceNoCtrl.text = _nextInvoiceNo();
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
    paidAmountCtrl.text = o.paidAmount == 0
        ? ''
        : trimAmount(o.paidAmount);

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
                // The API stores a single total quantity; the form splits it
                // into packs x per-pack, so the whole amount goes in the pack
                // count and the multiplier stays at 1.
                ..noPkg = i.qty
                ..avgContPerPkg = 1
                ..uom = i.unit.isEmpty ? 'BOX' : i.unit
                ..netPrice = i.rate;
              return row;
            }).toList(),
    );
  }

  /// Applies a dropdown pick and prefills the amount box: Full Payment fills
  /// the grand total, Half Payment half of it, Other is left for the user to
  /// type. The value stays editable in every case.
  void setPaymentType(OrderPaymentType type) {
    paymentType.value = type;
    final suggested = type.suggestedAmount(grandTotal);
    paidAmountCtrl.text = suggested == null ? '' : trimAmount(suggested);
  }

  /// The amount actually paid — whatever is in the box, 0 when it is empty or
  /// no payment type was chosen.
  double get paidAmount {
    if (paymentType.value == OrderPaymentType.none) return 0;
    return double.tryParse(paidAmountCtrl.text.trim()) ?? 0;
  }

  double get subTotal => items.fold(0.0, (s, r) => s + r.amount);
  double get sgst => subTotal * 0.09;
  double get cgst => subTotal * 0.09;
  double get grandTotal => subTotal + sgst + cgst;

  void applyClient(ClientModel c) {
    client.value = c.name;
    addressCtrl.text = c.address;
    if (c.state.isNotEmpty) {
      statePinCtrl.text = c.state;
      placeOfSupplyCtrl.text = c.state;
    }
    buyerGstCtrl.text = c.gstin;
    panCtrl.text = c.pan;
  }

  void addItemRow() => items.add(PurchaseItemRow());

  void removeItemRow(int index) => items.removeAt(index);

  void notifyItemsChanged() => items.refresh();

  Future<void> pickDate(BuildContext context, Rx<DateTime?> target) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) target.value = picked;
  }

  @override
  void onClose() {
    addressCtrl.dispose();
    cityCtrl.dispose();
    statePinCtrl.dispose();
    buyerGstCtrl.dispose();
    panCtrl.dispose();
    invoiceNoCtrl.dispose();
    poNoCtrl.dispose();
    lrNoCtrl.dispose();
    vehicleNoCtrl.dispose();
    freightCtrl.dispose();
    placeOfSupplyCtrl.dispose();
    paidAmountCtrl.dispose();
    super.onClose();
  }
}

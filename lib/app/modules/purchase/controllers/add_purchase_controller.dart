import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/purchase/models/purchase_model.dart';

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
    if (arg is PurchaseOrder) loadFrom(arg);
  }

  /// Fills the form from an existing order.
  void loadFrom(PurchaseOrder o) {
    editing = o;
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
    super.onClose();
  }
}

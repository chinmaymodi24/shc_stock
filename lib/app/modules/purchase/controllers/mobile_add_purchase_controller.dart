import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';

class MobilePurchaseItemRow {
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

  String uom = '';
  double netPrice = 0;

  double get totalQty => noPkg * avgContPerPkg;

  /// Same as the web form: the total is editable and steppable, keeping the
  /// per-pack figure and back-solving the pack count so the three boxes
  /// never contradict each other.
  set totalQty(double v) {
    final per = avgContPerPkg <= 0 ? 1.0 : avgContPerPkg;
    avgContPerPkg = per;
    noPkg = (v < 0 ? 0 : v) / per;
  }

  double get amount => totalQty * netPrice;
}

class MobileAddPurchaseController extends GetxController {
  final consigneeCtrl = TextEditingController();
  final buyerGstCtrl = TextEditingController();
  final client = ''.obs;
  final invoiceNoCtrl = TextEditingController();
  final invoiceDate = Rx<DateTime?>(null);
  final poNoCtrl = TextEditingController();
  final poDate = Rx<DateTime?>(null);
  final despatchThrough = 'DIRECT VEHICLE'.obs;
  final lrNoCtrl = TextEditingController();
  final vehicleNoCtrl = TextEditingController();
  final freightCtrl = TextEditingController();
  final placeOfSupplyCtrl = TextEditingController();
  final dueDate = Rx<DateTime?>(null);

  final items = <MobilePurchaseItemRow>[MobilePurchaseItemRow()].obs;

  double get subTotal => items.fold(0.0, (s, r) => s + r.amount);
  double get sgst => subTotal * 0.09;
  double get cgst => subTotal * 0.09;
  double get grandTotal => subTotal + sgst + cgst;

  void applyClient(ClientModel c) {
    client.value = c.name;
    if (c.state.isNotEmpty) placeOfSupplyCtrl.text = c.state;
  }

  void addItemRow() => items.add(MobilePurchaseItemRow());

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
    consigneeCtrl.dispose();
    buyerGstCtrl.dispose();
    invoiceNoCtrl.dispose();
    poNoCtrl.dispose();
    lrNoCtrl.dispose();
    vehicleNoCtrl.dispose();
    freightCtrl.dispose();
    placeOfSupplyCtrl.dispose();
    super.onClose();
  }
}

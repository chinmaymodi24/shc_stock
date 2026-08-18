import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';

class SaleItemRow {
  // Stable identity for list-item Keys, and a version bump whenever fields
  // are set programmatically (product autofill) so the small text-field
  // cells re-seed their displayed text instead of keeping stale
  // TextFormField state — `initialValue` is read once and never syncs to
  // later prop changes on its own.
  static int _seq = 0;
  final int id = _seq++;
  int version = 0;

  /// Backend product id, set when the row is filled from the product
  /// autocomplete. Sent to the API so the server moves this product's stock.
  int? productId;
  String product = '';
  String hsn = '';
  double qty = 0;
  String unit = '';
  double rate = 0;

  double get amount => qty * rate;
}

class AddSaleController extends GetxController {
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

  final items = <SaleItemRow>[SaleItemRow()].obs;

  /// The order being edited, when the page was opened from the list's Edit
  /// action. Null for a new sale. Its id, SO number and statuses are carried
  /// through the save so an edit updates the record in place instead of
  /// creating a second one.
  SalesOrder? editing;
  bool get isEditing => editing != null;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is SalesOrder) loadFrom(arg);
  }

  /// Fills the form from an existing order.
  void loadFrom(SalesOrder o) {
    editing = o;
    client.value = o.client;
    addressCtrl.text = o.clientAddress;
    buyerGstCtrl.text = o.buyerGstin;
    panCtrl.text = o.pan;
    invoiceNoCtrl.text = o.invoiceNo;
    invoiceDate.value = o.invoiceDate ?? o.date;
    poNoCtrl.text = o.soNumber;
    poDate.value = o.date;
    if (o.despatchedThrough.isNotEmpty) {
      despatchThrough.value = o.despatchedThrough;
    }
    placeOfSupplyCtrl.text = o.destination;

    items.assignAll(
      o.items.isEmpty
          ? [SaleItemRow()]
          : o.items
                .map(
                  (i) => SaleItemRow()
                    ..productId = i.productId
                    ..product = i.product
                    ..hsn = i.hsn
                    ..qty = i.qty
                    ..unit = i.unit
                    ..rate = i.rate,
                )
                .toList(),
    );
  }

  double get taxableValue => items.fold(0.0, (s, r) => s + r.amount);
  double get cgst => taxableValue * 0.09;
  double get sgst => taxableValue * 0.09;
  double get grandTotal => taxableValue + cgst + sgst;

  void applyClient(ClientModel c) {
    client.value = c.name;
    addressCtrl.text = c.address;
    statePinCtrl.text = c.state;
    buyerGstCtrl.text = c.gstin;
    panCtrl.text = c.pan;
    if (c.state.isNotEmpty) placeOfSupplyCtrl.text = c.state;
  }

  void addItemRow() => items.add(SaleItemRow());

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

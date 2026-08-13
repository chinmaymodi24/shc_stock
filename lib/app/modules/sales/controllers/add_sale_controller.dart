import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';

class SaleItemRow {
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

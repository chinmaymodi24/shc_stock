import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../clients/models/client_model.dart';

class PurchaseItemRow {
  String product = '';
  String hsn = '';
  String grade = '';
  String density = '';
  double noPkg = 0;
  double avgContPerPkg = 0;
  String uom = 'BOX';
  double netPrice = 0;

  double get totalQty => noPkg * avgContPerPkg;
  double get amount => totalQty * netPrice;
}

class AddPurchaseController extends GetxController {
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

  final items = <PurchaseItemRow>[PurchaseItemRow()].obs;

  double get subTotal => items.fold(0.0, (s, r) => s + r.amount);
  double get sgst => subTotal * 0.09;
  double get cgst => subTotal * 0.09;
  double get grandTotal => subTotal + sgst + cgst;

  void applyClient(ClientModel c) {
    client.value = c.name;
    if (c.state.isNotEmpty) placeOfSupplyCtrl.text = c.state;
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

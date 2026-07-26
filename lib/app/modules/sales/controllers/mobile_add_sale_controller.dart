import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../clients/models/client_model.dart';

class MobileSaleItemRow {
  String product = '';
  String hsn = '';
  double qty = 0;
  String unit = '';
  double rate = 0;

  double get amount => qty * rate;
}

class MobileAddSaleController extends GetxController {
  final client = ''.obs;
  final buyerAddressCtrl = TextEditingController();
  final buyerGstinCtrl = TextEditingController();
  final invoiceNoCtrl = TextEditingController();
  final invoiceDate = Rx<DateTime?>(null);
  final deliveryNoteCtrl = TextEditingController();
  final paymentTermsCtrl = TextEditingController();
  final buyerOrderNoCtrl = TextEditingController();
  final dispatchDocNoCtrl = TextEditingController();
  final deliveryNoteDate = Rx<DateTime?>(null);
  final dispatchedThroughCtrl = TextEditingController();
  final destinationCtrl = TextEditingController();
  final termsOfDeliveryCtrl = TextEditingController();

  final items = <MobileSaleItemRow>[MobileSaleItemRow()].obs;

  double get taxableValue => items.fold(0.0, (s, r) => s + r.amount);
  double get cgst => taxableValue * 0.09;
  double get sgst => taxableValue * 0.09;
  double get grandTotal => taxableValue + cgst + sgst;

  void applyClient(ClientModel c) {
    client.value = c.name;
    buyerAddressCtrl.text = c.address;
    buyerGstinCtrl.text = c.gstin;
  }

  void addItemRow() => items.add(MobileSaleItemRow());

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
    buyerAddressCtrl.dispose();
    buyerGstinCtrl.dispose();
    invoiceNoCtrl.dispose();
    deliveryNoteCtrl.dispose();
    paymentTermsCtrl.dispose();
    buyerOrderNoCtrl.dispose();
    dispatchDocNoCtrl.dispose();
    dispatchedThroughCtrl.dispose();
    destinationCtrl.dispose();
    termsOfDeliveryCtrl.dispose();
    super.onClose();
  }
}

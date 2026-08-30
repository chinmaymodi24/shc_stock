import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/shared/models/order_payment.dart';
import 'package:shc_stock/app/core/utils/doc_number.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/modules/settings/controllers/settings_controller.dart';

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

/// Marks a "Duplicate" navigation: the form loads from [order] but never
/// tracks it as `editing`, so Save always POSTs a brand-new record and the
/// original order is left untouched.
class DuplicateSalesOrder {
  final SalesOrder order;
  const DuplicateSalesOrder(this.order);
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

  /// Optional expected delivery date. Left empty the order keeps whatever
  /// status it has; set, the backend marks it Delivered on that date and books
  /// the stock out then.
  final expectedDelivery = Rx<DateTime?>(null);

  /// "Order Paid" — the dropdown choice and the amount behind it.
  final paymentType = OrderPaymentType.none.obs;
  final paidAmountCtrl = TextEditingController();

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
    if (arg is DuplicateSalesOrder) {
      loadFrom(arg.order, asDuplicate: true);
      // A duplicate loads every field of the source order, so saving it as-is
      // would create a byte-for-byte copy — same invoice number, same date.
      // Force a fresh invoice number (regardless of the auto-numbering
      // preference) and today's dates so the new record is distinct.
      invoiceNoCtrl.text = _nextInvoiceNo();
      final today = DateTime.now();
      invoiceDate.value = today;
      poDate.value = today;
    } else if (arg is SalesOrder) {
      loadFrom(arg);
    } else {
      _prefillInvoiceNo();
    }
  }

  /// The next number in the SO-2024 series, from the loaded orders.
  String _nextInvoiceNo() {
    final orders = Get.isRegistered<SalesController>()
        ? Get.find<SalesController>().orders
        : const <SalesOrder>[];
    return nextDocNumber(
      prefix: 'SO-2024',
      existing: orders.map((o) => o.soNumber),
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
  /// `editing` is left null so Save (see WebNewSalesLayout._saveSale) creates
  /// a fresh record instead of updating the one it was copied from.
  void loadFrom(SalesOrder o, {bool asDuplicate = false}) {
    if (!asDuplicate) editing = o;
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
    expectedDelivery.value = o.expectedDelivery;
    paymentType.value = o.paymentType;
    paidAmountCtrl.text = o.paidAmount == 0 ? '' : trimAmount(o.paidAmount);

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
    paidAmountCtrl.dispose();
    super.onClose();
  }
}

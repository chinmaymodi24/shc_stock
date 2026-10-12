import 'package:shc_stock/app/core/utils/dispose_later.dart';
import 'package:shc_stock/app/shared/widgets/app_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/billing/controllers/billing_profile_controller.dart';
import 'package:shc_stock/app/core/utils/gst.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/core/utils/order_checks.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/shared/models/order_payment.dart';
import 'package:shc_stock/app/core/utils/doc_number.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/modules/sales/models/sale_payment.dart';
import 'package:shc_stock/app/modules/sales/utils/sale_stock_guard.dart';
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

  /// GST rate (percent) — the picked product's own, 18% for a typed line.
  double taxPercent = kDefaultGstRate;

  double get amount => qty * rate;
}

/// One payment line of the form's "Payments" section. Its text boxes own
/// their controllers, so the row keeps what was typed as rows are added or
/// removed around it; date and mode are reactive.
class SalePaymentRow {
  static int _seq = 0;
  final int id = _seq++;

  final amountCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final date = Rx<DateTime>(DateTime.now());
  final mode = 'Cash'.obs;

  /// While true the amount follows the sale's balance (see
  /// [AddSaleController._followGrandTotal]); typing an amount stops that.
  bool followsTotal = false;

  SalePaymentRow({
    double? amount,
    DateTime? date,
    String? mode,
    String? notes,
  }) {
    if (amount != null && amount > 0) amountCtrl.text = trimAmount(amount);
    if (date != null) this.date.value = date;
    if (mode != null) this.mode.value = mode;
    if (notes != null) notesCtrl.text = notes;
  }

  double get amount => double.tryParse(amountCtrl.text.trim()) ?? 0;

  /// Nothing typed: the row is not sent.
  bool get isBlank =>
      amountCtrl.text.trim().isEmpty && notesCtrl.text.trim().isEmpty;

  SalePayment toPayment() => SalePayment(
    date: date.value,
    amount: amount,
    mode: mode.value,
    notes: notesCtrl.text.trim(),
  );

  void dispose() {
    amountCtrl.dispose();
    notesCtrl.dispose();
  }
}

/// Marks a "Duplicate" navigation: the form loads from [order] but never
/// tracks it as `editing`, so Save always POSTs a brand-new record and the
/// original order is left untouched.
class DuplicateSalesOrder {
  final SalesOrder order;
  const DuplicateSalesOrder(this.order);
}

class AddSaleController extends GetxController {
  /// Keeps the quantities within what inventory holds — see [SaleStockGuard].
  late final SaleStockGuard stock = SaleStockGuard(
    lines: () => [for (final r in items) (productId: r.productId, qty: r.qty)],
  );

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
  /// status it has; set, the backend marks it Delivered on that date and books
  /// the stock out then.
  final expectedDelivery = Rx<DateTime?>(null);

  /// The payments received on this sale — as many as were made, like item
  /// rows. Each becomes a row of the Transactions list under the sale's SO
  /// number; together they are what the sale counts as paid.
  final payments = <SalePaymentRow>[].obs;

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
    // The party's state decides CGST + SGST vs IGST; the totals redraw off
    // `items`, so poke it whenever one of the boxes that names the state
    // changes.
    for (final c in [buyerGstCtrl, placeOfSupplyCtrl, stateCtrl, addressCtrl]) {
      c.addListener(notifyItemsChanged);
    }
    final arg = Get.arguments;
    if (arg is DuplicateSalesOrder) {
      loadFrom(arg.order, asDuplicate: true);
      // A duplicate loads every field of the source order, so saving it as-is
      // would create a byte-for-byte copy — same invoice number, same date.
      // Force a fresh invoice number (regardless of the auto-numbering
      // preference) and today's dates so the new record is distinct.
      _fillNextNumber();
      final today = DateTime.now();
      invoiceDate.value = today;
      poDate.value = today;
      // The copy is a new sale: nothing has been paid on it yet.
      _startWithFullPayment();
    } else if (arg is SalesOrder) {
      loadFrom(arg);
    } else {
      _prefillInvoiceNo();
      _startWithFullPayment();
    }
  }

  /// A new sale starts as paid in full today: one payment whose amount
  /// follows the grand total until it is typed over or another row is added.
  void _startWithFullPayment() {
    _disposeRows(payments);
    payments.assignAll([SalePaymentRow()..followsTotal = true]);
    _followGrandTotal();
  }

  /// Writes the server's next order number into "Invoice No.".
  Future<void> _fillNextNumber() async {
    final n = await nextOrderNumber(OrderSeries.sale);
    if (n.isNotEmpty) invoiceNoCtrl.text = n;
  }

  /// Fills "Invoice No." with the next number, unless the user turned
  /// auto-numbering off in Settings › Preferences.
  Future<void> _prefillInvoiceNo() async {
    if (isEditing) return;
    if (!await autoNumberSalesEnabled()) return;
    await _fillNextNumber();
  }

  /// Fills the form from an existing order. When [asDuplicate] is true,
  /// `editing` is left null so Save (see WebNewSalesLayout._saveSale) creates
  /// a fresh record instead of updating the one it was copied from.
  void loadFrom(SalesOrder o, {bool asDuplicate = false}) {
    if (!asDuplicate) {
      editing = o;
      // This order's own units are already out of stock; editing it may keep
      // or lower them without counting as a new draw on inventory.
      stock.returnable.clear();
      for (final i in o.items) {
        final id = i.productId;
        if (id != null) {
          stock.returnable[id] = (stock.returnable[id] ?? 0) + i.qty;
        }
      }
    }
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
    if (!asDuplicate) {
      // The saved payments, as they were entered. An order saved before
      // payments were itemised only has its total: it becomes one payment on
      // the order date, so re-saving keeps what it said.
      _disposeRows(payments);
      payments.assignAll(
        o.payments.isNotEmpty
            ? [
                for (final p in o.payments)
                  SalePaymentRow(
                    amount: p.amount,
                    date: p.date,
                    mode: p.mode,
                    notes: p.notes,
                  ),
              ]
            : [
                if (o.paidAmount > 0)
                  SalePaymentRow(amount: o.paidAmount, date: o.date, mode: ''),
              ],
      );
    }

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
                    ..rate = i.rate
                    ..taxPercent = i.taxPercent,
                )
                .toList(),
    );
  }

  // ── Payments ────────────────────────────────────────────────────────────

  /// Adds a payment for whatever is still due (blank when nothing is), dated
  /// today. The first row stops following the total once there are two.
  void addPayment() {
    for (final p in payments) {
      p.followsTotal = false;
    }
    final due = balanceDue;
    payments.add(SalePaymentRow(amount: due > 0 ? _round2(due) : null));
  }

  void removePayment(int index) {
    if (index < 0 || index >= payments.length) return;
    final row = payments.removeAt(index);
    // Its boxes may still be drawn (and focused) this frame.
    disposeAfterPageExit([row.amountCtrl, row.notesCtrl]);
  }

  /// The person typed in a payment's amount (or note): it is theirs now, and
  /// the summary under the rows redraws.
  void paymentTyped(SalePaymentRow row) {
    row.followsTotal = false;
    payments.refresh();
  }

  void setPaymentMode(SalePaymentRow row, String? mode) {
    row.mode.value = mode ?? '';
  }

  Future<void> pickPaymentDate(BuildContext context, SalePaymentRow row) async {
    final picked = await showAppDatePicker(
      context: context,
      initialDate: row.date.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) row.date.value = picked;
  }

  /// Keeps a new sale's single "paid in full" row in step with the grand
  /// total as lines change.
  void _followGrandTotal() {
    if (payments.length != 1 || !payments.first.followsTotal) return;
    final total = grandTotal;
    payments.first.amountCtrl.text = total > 0
        ? trimAmount(_round2(total))
        : '';
    payments.refresh();
  }

  static double _round2(double v) => (v * 100).roundToDouble() / 100;

  static void _disposeRows(Iterable<SalePaymentRow> rows) {
    for (final r in rows) {
      r.dispose();
    }
  }

  /// What has been paid: the payment rows added up.
  double get paidAmount => _round2(payments.fold(0.0, (s, p) => s + p.amount));

  /// What is still owed (never below 0).
  double get balanceDue {
    final due = grandTotal - paidAmount;
    return due > 0.005 ? _round2(due) : 0;
  }

  /// The payments that get sent — an untouched empty row is not.
  List<SalePayment> sentPayments() => [
    for (final p in payments)
      if (!p.isBlank) p.toPayment(),
  ];

  /// What the list's Payment column will read once saved — the same rule as
  /// the server (salePayments.js).
  PaymentStatus get paymentStatusPreview {
    final paid = paidAmount;
    if (editing?.paymentStatus == PaymentStatus.refunded) {
      return PaymentStatus.refunded;
    }
    if (grandTotal > 0 && paid + 1 >= grandTotal) return PaymentStatus.paid;
    return paid > 0 ? PaymentStatus.partial : PaymentStatus.pending;
  }

  double get taxableValue => items.fold(0.0, (s, r) => s + r.amount);

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
  double get cgst => gst.cgst;
  double get sgst => gst.sgst;
  double get igst => gst.igst;
  double get grandTotal => taxableValue + gst.totalTax;

  void applyClient(ClientModel c) {
    client.value = c.name;
    addressCtrl.text = c.addressOnly;
    cityCtrl.text = c.city;
    pinCtrl.text = c.pin;
    stateCtrl.text = c.state;
    buyerGstCtrl.text = c.gstin;
    panCtrl.text = c.pan;
    if (c.state.isNotEmpty) placeOfSupplyCtrl.text = c.state;
  }

  void addItemRow() => items.add(SaleItemRow());

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
      for (final r in payments) ...[r.amountCtrl, r.notesCtrl],
    ]);
    super.onClose();
  }

  /// The rows that get sent — the empty one left at the bottom is not.
  List<SaleItemRow> sentRows() => withoutBlankRows(
    items,
    (r) => (name: r.product, productId: r.productId, qty: r.qty, rate: r.rate),
  );

  /// Validates, saves (create or update), then returns to the list with a
  /// toast. Shared by the web and the mobile form, so the two can never save
  /// different things.
  Future<void> save() async {
    final c = Get.find<SalesController>();
    // A sale with no client silently saved as the literal string "New
    // Client" before — indistinguishable from a real client of that name,
    // and unmatchable to anyone in the Item Details / client history views.
    // Block the save instead so every order carries a real client.
    if (client.value.trim().isEmpty) {
      showAppToast(
        'Error',
        'Please select or enter a client before saving.',
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
      );
      return;
    }
    // The same rules the server applies, so a bad order is stopped here with a
    // plain message instead of coming back as an error.
    final problem =
        checkOrderLines([
          for (final r in items)
            (name: r.product, productId: r.productId, qty: r.qty, rate: r.rate),
        ]) ??
        checkPaymentRows([
          for (final p in payments)
            (amount: p.amountCtrl.text, notes: p.notesCtrl.text),
        ], total: grandTotal) ??
        checkDateOrder(
          later: expectedDelivery.value,
          earlier: invoiceDate.value,
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
    // Never send a sale the inventory can't cover — the rows already say what
    // is wrong, this stops the Save button from being a way around them.
    final stockError = stock.firstError();
    if (stockError != null) {
      showAppToast(
        'Not enough stock',
        stockError,
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
      );
      return;
    }
    // Editing keeps the record's own id, SO number and statuses — only the
    // details being edited change.
    final editing = this.editing;
    final newId = editing?.id ?? 'so_${DateTime.now().millisecondsSinceEpoch}';
    // Blank for a new order: the server numbers it (SO/0001/26-27).
    final newSoNum = editing?.soNumber ?? '';
    final clientName = client.value.trim();
    final order = SalesOrder(
      id: newId,
      soNumber: newSoNum,
      client: clientName,
      clientBadge: clientName
          .substring(0, clientName.length < 2 ? clientName.length : 2)
          .toUpperCase(),
      clientColor: AppColors.primaryOrange,
      date: invoiceDate.value ?? DateTime.now(),
      itemCount: sentRows().length,
      amount: grandTotal,
      status: editing?.status ?? SalesStatus.confirmed,
      // The server works these out again from the payments; sent so an
      // older server still gets a consistent order.
      paymentStatus: paymentStatusPreview,
      modifiedBy: currentActorName,
      modifiedAt: DateTime.now(),
      clientAddress: addressCtrl.text.trim(),
      buyerGstin: buyerGstCtrl.text.trim(),
      pan: panCtrl.text.trim(),
      invoiceNo: invoiceNoCtrl.text.trim().isEmpty
          ? newSoNum
          : invoiceNoCtrl.text.trim(),
      invoiceDate: invoiceDate.value,
      despatchedThrough: despatchThrough.value,
      destination: placeOfSupplyCtrl.text.trim(),
      expectedDelivery: expectedDelivery.value,
      paymentType: paymentStatusPreview == PaymentStatus.paid
          ? OrderPaymentType.full
          : paidAmount > 0
          ? OrderPaymentType.other
          : OrderPaymentType.none,
      paidAmount: paidAmount,
      payments: sentPayments(),
      interState: interState,
      items: sentRows()
          .map(
            (r) => SaleDetailItem(
              productId: r.productId,
              product: r.product,
              hsn: r.hsn,
              qty: r.qty,
              unit: r.unit,
              rate: r.rate,
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
        ? c.orders.first.soNumber
        : newSoNum;
    Get.offNamed(AppRoutes.sales);
    final unlinked = unlinkedItemsNote(
      sentRows().where((r) => r.productId == null).length,
    );
    showAppToast(
      editing == null ? '✅ Sale Saved' : '✅ Sale Updated',
      editing == null
          ? '$number has been successfully created.$unlinked'
          : '$number has been successfully updated.$unlinked',
      backgroundColor: AppColors.success,
      colorText: Colors.white,
    );
  }
}

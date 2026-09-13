import 'package:shc_stock/app/core/session/app_modules.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/export/export_format.dart';
import 'package:shc_stock/app/core/export/export_service.dart';
import 'package:shc_stock/app/core/export/file_saver.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/brand_controller.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/billing/controllers/billing_profile_controller.dart';
import 'package:shc_stock/app/modules/billing/controllers/billing_summary_controller.dart';
import 'package:shc_stock/app/modules/billing/models/bill_format.dart';
import 'package:shc_stock/app/modules/billing/models/bill_model.dart';
import 'package:shc_stock/app/modules/billing/models/billing_profile.dart';
import 'package:shc_stock/app/modules/billing/models/invoice_totals.dart';
import 'package:shc_stock/app/core/export/writers/pdf_document.dart';
import 'package:shc_stock/app/modules/billing/writers/pdf_cash_memo_writer.dart';
import 'package:shc_stock/app/modules/billing/writers/pdf_invoice_writer.dart';
import 'package:shc_stock/app/modules/billing/writers/pdf_thermal_writer.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The bill screen's state.
//
// It owns the sale being billed, the bill record behind it, and the five
// display toggles. Every figure on the document comes from
// [computeInvoiceTotals] — nothing here does its own arithmetic.
// ─────────────────────────────────────────────────────────────────────────────
class BillController extends GetxController {
  /// Route argument: a [SalesOrder] when navigating from the sales list, or
  /// its id when arriving by URL.
  final Object? routeArgument;

  BillController(this.routeArgument);

  final _api = ApiClient.instance;

  final Rxn<SalesOrder> order = Rxn<SalesOrder>();
  final Rxn<BillModel> bill = Rxn<BillModel>();
  final RxBool isLoading = true.obs;
  final RxBool isBusy = false.obs;
  final RxString error = ''.obs;

  /// The live toggles. Seeded from the bill (or the profile defaults before
  /// one exists) and written back on every change.
  final Rx<BillOptions> options = const BillOptions().obs;

  /// Which of the three layouts is on screen. A view state only — the bill,
  /// its number and its figures are the same whichever one is showing, so
  /// nothing about this is persisted.
  final Rx<BillFormat> format = BillFormat.taxInvoice.obs;

  void showFormat(BillFormat next) => format.value = next;

  BillingProfile get profile => Get.isRegistered<BillingProfileController>()
      ? BillingProfileController.to.profile.value
      : BillingProfile.empty;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  // ── Loading ───────────────────────────────────────────────────────────────
  Future<void> load() async {
    isLoading.value = true;
    error.value = '';
    try {
      final resolved = await _resolveOrder();
      if (resolved == null) {
        error.value = 'That sale could not be found.';
        return;
      }
      order.value = resolved;
      // Not awaited: the document renders from the sale straight away and
      // fills in the client's address when the lookup answers.
      _resolveClient(resolved.client);

      final json = await _api.get('/bills/sale/${resolved.id}');
      if (json is Map<String, dynamic>) {
        _adopt(BillModel.fromJson(json));
      } else {
        // Never billed: show the document as it will print, seeded with the
        // profile's defaults, and let the user press Generate.
        bill.value = null;
        options.value = profile.defaults;
      }
    } catch (e) {
      error.value = 'Could not load this bill. Is the backend running?';
    } finally {
      isLoading.value = false;
    }
  }

  void _adopt(BillModel model) {
    bill.value = model;
    options.value = model.options;
  }

  Future<SalesOrder?> _resolveOrder() async {
    final argument = routeArgument;
    if (argument is SalesOrder) return argument;

    final id = argument is int ? argument.toString() : argument?.toString();
    if (id == null || id.isEmpty) return null;

    // Prefer the already-loaded list — the sales controller is permanent, so
    // this is the common path and costs no request.
    if (Get.isRegistered<SalesController>()) {
      final match = Get.find<SalesController>().orders.firstWhereOrNull(
        (o) => o.id == id,
      );
      if (match != null) return match;
    }
    final json = await _api.get('/sales-orders/$id');
    return json is Map<String, dynamic> ? SalesOrder.fromJson(json) : null;
  }

  // ── The document ──────────────────────────────────────────────────────────
  /// The sale's lines, with each product's own description pulled in as the
  /// small spec line under the name where one exists.
  List<InvoiceLine> get invoiceLines {
    final sale = order.value;
    if (sale == null) return const [];
    return [
      for (final item in sale.items)
        InvoiceLine(
          name: item.product,
          spec: _specFor(item.productId),
          hsn: item.hsn,
          qty: item.qty,
          uom: item.unit,
          rate: item.rate,
        ),
    ];
  }

  String _specFor(int? productId) {
    if (productId == null || !Get.isRegistered<ProductsController>()) return '';
    final product = Get.find<ProductsController>().products.firstWhereOrNull(
      (p) => p.id == productId.toString(),
    );
    if (product == null) return '';
    final description = (product.description ?? '').trim();
    if (description.isNotEmpty) return description;
    return (product.brand ?? '').trim();
  }

  InvoiceTotals get totals =>
      computeInvoiceTotals(invoiceLines, tax: profile.tax);

  /// The client record behind the sale — it carries the shipping address and
  /// contact details the sale itself does not.
  ///
  /// Resolved once, when the sale loads, rather than read straight out of the
  /// Clients list: that list is paged by the server now, so the client this
  /// invoice is for is usually not among the rows in memory. Null until the
  /// lookup answers, and null for a client that no longer exists - the
  /// document then falls back to the fields the sale carries itself.
  final Rxn<ClientModel> client = Rxn<ClientModel>();

  Future<void> _resolveClient(String name) async {
    if (!Get.isRegistered<ClientsController>()) return;
    client.value = await Get.find<ClientsController>().findByName(name);
  }

  /// Invoice number to print: the issued one, or a preview of what the series
  /// will assign once the bill is generated.
  String get invoiceNo {
    final issued = bill.value?.invoiceNo;
    if (issued != null && issued.isNotEmpty) return issued;
    final typed = order.value?.invoiceNo ?? '';
    return typed.isNotEmpty ? typed : 'Not generated';
  }

  DateTime get invoiceDate =>
      bill.value?.issuedOn ??
      order.value?.invoiceDate ??
      order.value?.date ??
      DateTime.now();

  bool get isGenerated => bill.value != null;

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> generate() async {
    if (!requireWrite('Sales')) return;
    final sale = order.value;
    if (sale == null || isBusy.value) return;
    isBusy.value = true;
    try {
      final json = await _api.post('/bills', {
        'salesOrderId': int.tryParse(sale.id) ?? sale.id,
        'prefix': profile.invoicePrefix,
      });
      if (json is Map<String, dynamic>) _adopt(BillModel.fromJson(json));
      // The sales list shows the invoice number; refresh so it appears there
      // without a manual reload.
      if (Get.isRegistered<SalesController>()) {
        await Get.find<SalesController>().fetchOrders();
      }
      // The Sale page's Billing card counts bills, so it is now one out.
      BillingSummaryController.refreshIfLoaded();
    } catch (e) {
      _error(e is ApiException ? e.message : 'Could not generate the bill.');
    } finally {
      isBusy.value = false;
    }
  }

  /// Flips one toggle. The document reacts immediately; the write-back only
  /// matters once a bill exists to remember it.
  Future<void> setOption(BillOptions next) async {
    options.value = next;
    final current = bill.value;
    // A read-only viewer can still flip sections for their own look at the
    // document; only someone with Sales write saves the choice to the bill.
    if (current == null || !canWriteModule('Sales')) return;
    try {
      final json = await _api.put(
        '/bills/${current.id}/options',
        next.toJson(),
      );
      if (json is Map<String, dynamic>) {
        // Adopt the server's copy but keep the user's toggle on screen — the
        // two agree, and re-seeding from the response avoids a flicker.
        bill.value = BillModel.fromJson(json);
      }
    } catch (e) {
      _error('Could not save that option.');
    }
  }

  Future<void> _record(String type, {String note = ''}) async {
    final current = bill.value;
    if (current == null) return;
    try {
      final json = await _api.post('/bills/${current.id}/events', {
        'type': type,
        'note': note,
      });
      if (json is Map<String, dynamic>) bill.value = BillModel.fromJson(json);
    } catch (e) {
      // A missing trail entry must not cost the user the action itself.
    }
  }

  String get _generatedLine => Get.isRegistered<ExportService>()
      ? ExportService.to.generatedLine()
      : 'Generated by $currentActorName';

  /// The document as bytes, in whichever layout is on screen. All three read
  /// the same [totals], so the three files carry the same figures.
  Uint8List buildPdf() => switch (format.value) {
    BillFormat.taxInvoice => buildInvoicePdf(
      profile: profile,
      sellerName: sellerName,
      order: order.value!,
      client: client.value,
      bill: bill.value,
      totals: totals,
      options: options.value,
      generatedLine: _generatedLine,
    ),
    BillFormat.cashMemo => buildCashMemoPdf(
      profile: profile,
      sellerName: sellerName,
      order: order.value!,
      client: client.value,
      totals: totals,
      options: options.value,
      invoiceNo: invoiceNo,
      invoiceDate: invoiceDate,
      generatedLine: _generatedLine,
      accent: PdfColor.of(AppColors.primaryOrange),
    ),
    BillFormat.thermal => buildThermalPdf(
      profile: profile,
      sellerName: sellerName,
      order: order.value!,
      bill: bill.value,
      totals: totals,
      options: options.value,
      invoiceNo: invoiceNo,
      invoiceDate: invoiceDate,
      generatedLine: _generatedLine,
    ),
  };

  /// One file name per format, so downloading all three of a bill does not
  /// leave two of them overwritten.
  String get fileName {
    final safe = invoiceNo
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return '${safe.isEmpty ? 'invoice' : safe}${format.value.fileSuffix}.pdf';
  }

  /// Saves the PDF through the shared export pipeline, so a bill lands in the
  /// same Downloads panel as every other export.
  Future<void> downloadPdf() async {
    if (order.value == null) return;
    isBusy.value = true;
    try {
      final bytes = buildPdf();
      if (Get.isRegistered<ExportService>()) {
        await ExportService.to.startPrebuiltBytes(
          filename: fileName,
          format: ExportFormat.pdf,
          bytes: bytes,
          rowCount: totals.itemCount,
        );
      } else {
        await saveExportFile(fileName, bytes, ExportFormat.pdf.mimeType);
      }
      await _record('downloaded', note: fileName);
    } catch (e) {
      _error('Could not build the PDF.');
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> printBill() async {
    if (order.value == null) return;
    isBusy.value = true;
    try {
      final bytes = buildPdf();
      final printed = await printPdfBytes(fileName, bytes);
      if (printed) {
        await _record('printed');
      } else {
        // No print API on this platform — hand over the file instead of
        // pretending the dialog opened.
        await saveExportFile(fileName, bytes, ExportFormat.pdf.mimeType);
        await _record('downloaded', note: fileName);
        _info(
          'Saved as $fileName — open it to print. Direct printing is only '
          'available in the browser.',
        );
      }
    } catch (e) {
      _error('Could not print the bill.');
    } finally {
      isBusy.value = false;
    }
  }

  // ── Share ─────────────────────────────────────────────────────────────────
  String get buyerPhone {
    final c = client.value;
    final fromClient = (c?.phone ?? '').trim();
    if (fromClient.isNotEmpty) return fromClient;
    return (c?.contactPhone ?? '').trim();
  }

  String get buyerEmail {
    final c = client.value;
    final fromClient = (c?.email ?? '').trim();
    if (fromClient.isNotEmpty) return fromClient;
    return (c?.contactEmail ?? '').trim();
  }

  String get shareMessage {
    final sale = order.value;
    return 'Invoice $invoiceNo from $sellerName for '
        '₹${totals.grandTotalText}. Order ${sale?.soNumber ?? ''}.';
  }

  /// The name the invoice is issued under: the billing profile's legal name,
  /// falling back to the brand's company name so a buyer who never opened
  /// Settings still gets their own name on the paper.
  String get sellerName {
    final configured = profile.legalName.trim();
    return configured.isNotEmpty ? configured : brand.companyName;
  }

  /// Digits only, with India's country code when the number is a bare 10-digit
  /// mobile — wa.me rejects anything else.
  String get whatsAppNumber {
    final digits = buyerPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return '91$digits';
    return digits;
  }

  Future<void> sendOnWhatsApp() async {
    if (whatsAppNumber.isEmpty) {
      _error('This client has no phone number on record.');
      return;
    }
    final url =
        'https://wa.me/$whatsAppNumber?text=${Uri.encodeComponent(shareMessage)}';
    final opened = await openExternalUrl(url);
    if (!opened) {
      await Clipboard.setData(ClipboardData(text: url));
      _info('WhatsApp link copied — paste it to send.');
    }
    await _record('sent_whatsapp', note: buyerPhone);
  }

  Future<void> emailPdf() async {
    if (buyerEmail.isEmpty) {
      _error('This client has no email address on record.');
      return;
    }
    // The PDF has to be attached by hand: there is no mail transport in this
    // system, so we save it and open a pre-addressed draft.
    await downloadPdf();
    final url =
        'mailto:$buyerEmail?subject=${Uri.encodeComponent('Invoice $invoiceNo')}'
        '&body=${Uri.encodeComponent(shareMessage)}';
    final opened = await openExternalUrl(url);
    if (!opened) {
      await Clipboard.setData(ClipboardData(text: buyerEmail));
      _info('Address copied. Attach $fileName from your downloads.');
    }
    await _record('sent_email', note: buyerEmail);
  }

  /// A UPI intent link the client can pay from. Built from the profile's UPI
  /// id — without one there is nothing to link to.
  String get paymentLink {
    final upi = profile.upiId.trim();
    if (upi.isEmpty) return '';
    return 'upi://pay?pa=$upi&pn=${Uri.encodeComponent(sellerName)}'
        '&am=${totals.grandTotal.toStringAsFixed(2)}&cu=INR'
        '&tn=${Uri.encodeComponent(invoiceNo)}';
  }

  Future<void> copyPaymentLink() async {
    final link = paymentLink;
    if (link.isEmpty) {
      _error('Add a UPI id in Settings › Billing to share a payment link.');
      return;
    }
    await Clipboard.setData(ClipboardData(text: link));
    _info('Payment link copied.');
  }

  // ── Toasts ────────────────────────────────────────────────────────────────
  void _error(String message) => showAppToast(
    'Error',
    message,
    backgroundColor: appColors.error,
    colorText: Colors.white,
  );

  void _info(String message) => showAppToast(
    'Billing',
    message,
    backgroundColor: AppColors.primaryPurple,
    colorText: Colors.white,
    duration: const Duration(seconds: 3),
  );
}

import 'package:shc_stock/app/modules/billing/models/invoice_totals.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Everything a tax invoice prints that is not part of the sale.
//
// Seller identity, bank details, the declaration, the numbering series and the
// default "what appears on the bill" toggles. Portal-wide and editable from
// Settings › Billing — the invoice is the company's document, so none of this
// is hardcoded into the layout.
// ─────────────────────────────────────────────────────────────────────────────

/// The five per-invoice display switches.
class BillOptions {
  final bool showHsnSummary;
  final bool showBankDetails;
  final bool showUpiQr;
  final bool showEInvoice;
  final bool showDeclaration;

  const BillOptions({
    this.showHsnSummary = true,
    this.showBankDetails = true,
    this.showUpiQr = true,
    this.showEInvoice = true,
    this.showDeclaration = true,
  });

  BillOptions copyWith({
    bool? showHsnSummary,
    bool? showBankDetails,
    bool? showUpiQr,
    bool? showEInvoice,
    bool? showDeclaration,
  }) => BillOptions(
    showHsnSummary: showHsnSummary ?? this.showHsnSummary,
    showBankDetails: showBankDetails ?? this.showBankDetails,
    showUpiQr: showUpiQr ?? this.showUpiQr,
    showEInvoice: showEInvoice ?? this.showEInvoice,
    showDeclaration: showDeclaration ?? this.showDeclaration,
  );

  Map<String, dynamic> toJson() => {
    'showHsnSummary': showHsnSummary,
    'showBankDetails': showBankDetails,
    'showUpiQr': showUpiQr,
    'showEInvoice': showEInvoice,
    'showDeclaration': showDeclaration,
  };

  factory BillOptions.fromJson(Map<String, dynamic> json) {
    bool pick(String key, bool fallback) =>
        json[key] is bool ? json[key] as bool : fallback;
    return BillOptions(
      showHsnSummary: pick('showHsnSummary', true),
      showBankDetails: pick('showBankDetails', true),
      showUpiQr: pick('showUpiQr', true),
      showEInvoice: pick('showEInvoice', true),
      showDeclaration: pick('showDeclaration', true),
    );
  }
}

class BillingProfile {
  // ── Seller ──────────────────────────────────────────────────────────────
  /// Blank means "use the brand's company name", so renaming the business in
  /// Appearance renames it on the invoice too.
  final String legalName;
  final String addressLine1;
  final String addressLine2;
  final String gstin;
  final String pan;
  final String stateName;
  final String stateCode;
  final String phone;
  final String email;

  // ── Bank ────────────────────────────────────────────────────────────────
  final String bankName;
  final String accountNo;
  final String branchAndIfsc;
  final String upiId;

  // ── Document ────────────────────────────────────────────────────────────
  /// Series prefix — "ST" produces ST/0248/26-27.
  final String invoicePrefix;

  /// Total GST charged, split evenly into CGST and SGST on the invoice.
  final double gstPercent;
  final String declaration;
  final String footerNote;

  /// The authorised signature as base64 PNG/JPG bytes, drawn above the
  /// signatory rule at the bottom right of the invoice. Null for none, and
  /// then the invoice leaves the whitespace for a pen.
  final String? signatureBase64;

  /// What a freshly generated bill starts with.
  final BillOptions defaults;

  const BillingProfile({
    this.legalName = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.gstin = '',
    this.pan = '',
    this.stateName = '',
    this.stateCode = '',
    this.phone = '',
    this.email = '',
    this.bankName = '',
    this.accountNo = '',
    this.branchAndIfsc = '',
    this.upiId = '',
    this.invoicePrefix = 'INV',
    this.gstPercent = 18,
    this.declaration = defaultDeclaration,
    this.footerNote = defaultFooterNote,
    this.signatureBase64,
    this.defaults = const BillOptions(),
  });

  static const defaultDeclaration =
      'We declare that this invoice shows the actual price of the goods '
      'described and that all particulars are true and correct. Goods once '
      'sold will not be taken back. Interest at 18% p.a. is chargeable on '
      'bills not paid within the agreed credit period.';

  static const defaultFooterNote = 'This is a Computer Generated Invoice';

  static const empty = BillingProfile();

  InvoiceTaxConfig get tax => InvoiceTaxConfig(gstPercent: gstPercent);

  /// True once someone has filled in the parts a tax invoice legally needs.
  /// The bill screen warns rather than printing a document with no GSTIN.
  bool get isConfigured => gstin.trim().isNotEmpty;

  BillingProfile copyWith({
    String? legalName,
    String? addressLine1,
    String? addressLine2,
    String? gstin,
    String? pan,
    String? stateName,
    String? stateCode,
    String? phone,
    String? email,
    String? bankName,
    String? accountNo,
    String? branchAndIfsc,
    String? upiId,
    String? invoicePrefix,
    double? gstPercent,
    String? declaration,
    String? footerNote,
    String? signatureBase64,

    /// copyWith cannot null a field, so removing the signature needs its own
    /// flag — the same shape [BrandTheme.clearLogo] uses.
    bool clearSignature = false,
    BillOptions? defaults,
  }) => BillingProfile(
    legalName: legalName ?? this.legalName,
    addressLine1: addressLine1 ?? this.addressLine1,
    addressLine2: addressLine2 ?? this.addressLine2,
    gstin: gstin ?? this.gstin,
    pan: pan ?? this.pan,
    stateName: stateName ?? this.stateName,
    stateCode: stateCode ?? this.stateCode,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    bankName: bankName ?? this.bankName,
    accountNo: accountNo ?? this.accountNo,
    branchAndIfsc: branchAndIfsc ?? this.branchAndIfsc,
    upiId: upiId ?? this.upiId,
    invoicePrefix: invoicePrefix ?? this.invoicePrefix,
    gstPercent: gstPercent ?? this.gstPercent,
    declaration: declaration ?? this.declaration,
    footerNote: footerNote ?? this.footerNote,
    signatureBase64: clearSignature
        ? null
        : (signatureBase64 ?? this.signatureBase64),
    defaults: defaults ?? this.defaults,
  );

  Map<String, dynamic> toJson() => {
    'legalName': legalName,
    'addressLine1': addressLine1,
    'addressLine2': addressLine2,
    'gstin': gstin,
    'pan': pan,
    'stateName': stateName,
    'stateCode': stateCode,
    'phone': phone,
    'email': email,
    'bankName': bankName,
    'accountNo': accountNo,
    'branchAndIfsc': branchAndIfsc,
    'upiId': upiId,
    'invoicePrefix': invoicePrefix,
    'gstPercent': gstPercent,
    'declaration': declaration,
    'footerNote': footerNote,
    'signatureBase64': signatureBase64,
    'defaults': defaults.toJson(),
  };

  /// Any missing field falls back to its default, so a half-written blob
  /// degrades to "mostly default" instead of refusing to load.
  factory BillingProfile.fromJson(Map<String, dynamic> json) {
    String pick(String key, [String fallback = '']) {
      final raw = json[key];
      return raw is String && raw.trim().isNotEmpty ? raw.trim() : fallback;
    }

    final gst = json['gstPercent'];
    return BillingProfile(
      legalName: pick('legalName'),
      addressLine1: pick('addressLine1'),
      addressLine2: pick('addressLine2'),
      gstin: pick('gstin'),
      pan: pick('pan'),
      stateName: pick('stateName'),
      stateCode: pick('stateCode'),
      phone: pick('phone'),
      email: pick('email'),
      bankName: pick('bankName'),
      accountNo: pick('accountNo'),
      branchAndIfsc: pick('branchAndIfsc'),
      upiId: pick('upiId'),
      invoicePrefix: pick('invoicePrefix', 'INV'),
      gstPercent: gst is num && gst >= 0 && gst <= 100 ? gst.toDouble() : 18,
      declaration: pick('declaration', defaultDeclaration),
      footerNote: pick('footerNote', defaultFooterNote),
      signatureBase64: json['signatureBase64'] as String?,
      defaults: json['defaults'] is Map<String, dynamic>
          ? BillOptions.fromJson(json['defaults'] as Map<String, dynamic>)
          : const BillOptions(),
    );
  }
}

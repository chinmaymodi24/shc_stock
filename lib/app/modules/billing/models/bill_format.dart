import 'package:shc_stock/app/modules/billing/models/billing_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The three ways one bill can be printed.
//
// A format is a *rendering* of the bill, never a second bill: the sale, the
// figures and the document number are the same whichever one is on screen.
// That is why there is no per-format numbering series here — see the note on
// [BillFormat.cashMemo].
// ─────────────────────────────────────────────────────────────────────────────
enum BillFormat {
  /// The ruled A4 tax invoice — the legal document.
  taxInvoice,

  /// An A5 counter memo. The same money, laid out for a customer standing at
  /// the counter: no HSN column, no consignee, no e-invoice block.
  ///
  /// It carries the invoice's own number rather than a "CM-…" of its own.
  /// A second series would mean two numbers for one sale, and nothing in the
  /// backend allocates one — the same reason an IRN is never invented.
  cashMemo,

  /// An 80 mm roll receipt for an ESC/POS printer.
  thermal;

  String get label => switch (this) {
    BillFormat.taxInvoice => 'GST Tax Invoice',
    BillFormat.cashMemo => 'Cash Memo',
    BillFormat.thermal => 'Thermal 80mm',
  };

  /// The caption printed across the top of the document itself.
  String get documentTitle => switch (this) {
    BillFormat.taxInvoice => 'TAX INVOICE',
    BillFormat.cashMemo => 'CASH MEMO',
    BillFormat.thermal => 'TAX INVOICE',
  };

  /// Goes into the exported file name, so three formats of one bill do not
  /// overwrite each other in the Downloads panel.
  String get fileSuffix => switch (this) {
    BillFormat.taxInvoice => '',
    BillFormat.cashMemo => '-memo',
    BillFormat.thermal => '-thermal',
  };

  /// Title recorded in the PDF's metadata.
  String get pdfTitle => switch (this) {
    BillFormat.taxInvoice => 'Tax Invoice',
    BillFormat.cashMemo => 'Cash Memo',
    BillFormat.thermal => 'Thermal Receipt',
  };

  /// Whether one of the five display switches reaches this format.
  ///
  /// The panel greys the rows that do not, rather than offering a toggle that
  /// quietly does nothing: a cash memo has no HSN summary, no bank block and
  /// no IRN to show, and a 72 mm receipt has room for neither bank details nor
  /// a QR.
  bool applies(BillOption option) => switch (this) {
    BillFormat.taxInvoice => true,
    BillFormat.cashMemo => option == BillOption.declaration,
    BillFormat.thermal =>
      option == BillOption.hsnSummary || option == BillOption.declaration,
  };
}

/// The five switches, named so [BillFormat.applies] can talk about them.
enum BillOption {
  hsnSummary,
  bankDetails,
  upiQr,
  eInvoice,
  declaration;

  String get label => switch (this) {
    BillOption.hsnSummary => 'HSN-wise tax summary',
    BillOption.bankDetails => "Company's bank details",
    BillOption.upiQr => 'UPI QR code',
    BillOption.eInvoice => 'e-Invoice IRN block',
    BillOption.declaration => 'Declaration & terms',
  };

  bool read(BillOptions options) => switch (this) {
    BillOption.hsnSummary => options.showHsnSummary,
    BillOption.bankDetails => options.showBankDetails,
    BillOption.upiQr => options.showUpiQr,
    BillOption.eInvoice => options.showEInvoice,
    BillOption.declaration => options.showDeclaration,
  };

  BillOptions write(BillOptions options, bool value) => switch (this) {
    BillOption.hsnSummary => options.copyWith(showHsnSummary: value),
    BillOption.bankDetails => options.copyWith(showBankDetails: value),
    BillOption.upiQr => options.copyWith(showUpiQr: value),
    BillOption.eInvoice => options.copyWith(showEInvoice: value),
    BillOption.declaration => options.copyWith(showDeclaration: value),
  };
}

/// How a payment was made. Mirrors PAYMENT_MODES in backend/src/salePayments.js.
const List<String> kPaymentModes = [
  'Cash',
  'UPI',
  'Bank Transfer',
  'Cheque',
  'Card',
  'Other',
];

/// Checks the payment rows of the form the way the server does: a row left
/// completely empty is ignored, any other row needs an amount above 0, and the
/// rows together may not exceed the sale's [total] (a rupee of slack — the
/// total is rounded on screen). Returns the problem, or null.
String? checkPaymentRows(
  List<({String amount, String notes})> rows, {
  required double total,
}) {
  var sum = 0.0;
  for (var i = 0; i < rows.length; i++) {
    final text = rows[i].amount.trim();
    if (text.isEmpty && rows[i].notes.trim().isEmpty) continue;
    final v = double.tryParse(text);
    if (v == null || v <= 0) {
      return 'Payment ${i + 1}: enter an amount more than ₹0.';
    }
    sum += v;
  }
  if (sum > total + 1) {
    return 'Payments add up to ₹${sum.toStringAsFixed(0)}, more than the '
        'sale total (₹${total.toStringAsFixed(0)}).';
  }
  return null;
}

/// One payment received on a sale — ₹500 cash today, ₹700 by UPI next week.
/// The server keeps each one as a row of the Transactions list, carrying the
/// sale's SO number, and the sale's paidAmount is their sum.
class SalePayment {
  /// The Transactions row id; null before the sale is saved.
  final int? id;
  final DateTime date;
  final double amount;

  /// One of [kPaymentModes], or '' when it was not recorded.
  final String mode;
  final String notes;

  const SalePayment({
    this.id,
    required this.date,
    required this.amount,
    this.mode = '',
    this.notes = '',
  });

  factory SalePayment.fromJson(Map<String, dynamic> json) => SalePayment(
    id: json['id'] as int?,
    date:
        DateTime.tryParse(json['date'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    mode: json['mode'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'amount': amount,
    'mode': mode,
    'notes': notes,
  };
}

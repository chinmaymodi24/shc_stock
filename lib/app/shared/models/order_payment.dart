// ─────────────────────────────────────────────────────────────────────────────
// "Order Paid" — how much of an order has actually been settled.
//
// Shared by purchases (money we owe the supplier) and sales (money the client
// owes us) so the dropdown, the stored value and the details panel read the
// same on both sides. The amount itself lives on the order as `paidAmount`;
// this enum only says which of the three the user picked.
// ─────────────────────────────────────────────────────────────────────────────

enum OrderPaymentType { none, full, half, other }

extension OrderPaymentTypeX on OrderPaymentType {
  /// The exact string stored in the database and shown in the dropdown.
  /// [none] is the empty label — nothing chosen yet.
  String get label {
    switch (this) {
      case OrderPaymentType.none:
        return '';
      case OrderPaymentType.full:
        return 'Full Payment';
      case OrderPaymentType.half:
        return 'Half Payment';
      case OrderPaymentType.other:
        return 'Other';
    }
  }

  /// What the details panels show when there is nothing to show.
  String get displayLabel => this == OrderPaymentType.none ? '—' : label;

  /// The amount to prefill when this option is picked, given the order's
  /// [grandTotal]. "Other" starts blank so the user types their own figure.
  double? suggestedAmount(double grandTotal) {
    switch (this) {
      case OrderPaymentType.full:
        return grandTotal;
      case OrderPaymentType.half:
        return grandTotal / 2;
      case OrderPaymentType.none:
      case OrderPaymentType.other:
        return null;
    }
  }
}

/// The three options offered in the dropdown — [OrderPaymentType.none] is the
/// unset placeholder, never a choice.
const kOrderPaymentOptions = [
  OrderPaymentType.full,
  OrderPaymentType.half,
  OrderPaymentType.other,
];

/// Parses the stored string back to an enum, tolerating older records that
/// have no payment recorded at all.
OrderPaymentType orderPaymentTypeFrom(String? value) {
  final v = (value ?? '').trim();
  return OrderPaymentType.values.firstWhere(
    (t) => t.label == v && t != OrderPaymentType.none,
    orElse: () => OrderPaymentType.none,
  );
}

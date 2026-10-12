import 'package:shc_stock/app/modules/sales/utils/sale_stock_guard.dart';

/// What the Add Sale / Add Purchase forms check before sending an order, so a
/// bad one is stopped with a plain message instead of coming back from the
/// server as an error (or, before the server checked, being saved).
///
/// Mirrors backend/src/orderValidation.js — keep the two in step.

/// One row of an order form, reduced to what the checks need.
typedef OrderLineCheck = ({
  String name,
  int? productId,
  double qty,
  double rate,
});

/// The empty row a form leaves at the bottom: no name, no quantity, no rate.
bool isBlankLine(OrderLineCheck l) =>
    l.name.trim().isEmpty && l.productId == null && l.qty == 0 && l.rate == 0;

/// Only the rows that carry something — what actually gets sent.
List<T> withoutBlankRows<T>(
  Iterable<T> rows,
  OrderLineCheck Function(T) toCheck,
) => rows.where((r) => !isBlankLine(toCheck(r))).toList();

/// The first problem with an order's lines, or null when they are fine.
String? checkOrderLines(List<OrderLineCheck> all) {
  final lines = all.where((l) => !isBlankLine(l)).toList();
  if (lines.isEmpty) return 'Add at least one item to the order.';
  for (var i = 0; i < lines.length; i++) {
    final l = lines[i];
    final n = i + 1;
    if (l.name.trim().isEmpty) {
      return 'Item $n: pick a product or type an item name.';
    }
    if (l.qty <= 0) {
      return 'Item $n (${l.name.trim()}): quantity must be greater than 0.';
    }
    if (l.rate < 0) {
      return 'Item $n (${l.name.trim()}): rate cannot be negative.';
    }
    final whole = wholeQtyError(
      productId: l.productId,
      qty: l.qty,
      productName: l.name.trim(),
    );
    if (whole != null) return whole;
  }
  return null;
}

/// Money paid against an order: not negative, and not more than the total
/// (an overpayment made the receivable negative while still reading "Paid").
String? checkPayment({required double paid, required double total}) {
  if (paid < 0) return 'Amount paid cannot be negative.';
  // A rupee of slack: the total is rounded to whole rupees on screen.
  if (paid > total + 1) {
    return 'Amount paid (₹${paid.toStringAsFixed(0)}) is more than the order '
        'total (₹${total.toStringAsFixed(0)}).';
  }
  return null;
}

/// A later date must not come before an earlier one.
String? checkDateOrder({
  required DateTime? later,
  required DateTime? earlier,
  required String laterName,
  required String earlierName,
}) {
  if (later == null || earlier == null) return null;
  DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  if (day(later).isBefore(day(earlier))) {
    return '$laterName cannot be before $earlierName.';
  }
  return null;
}

/// A line typed by hand rather than picked from the product list has no
/// product behind it, so saving the order does not move inventory for it. The
/// forms say so after saving instead of letting stock stay quietly unchanged.
/// Empty when every line is linked.
String unlinkedItemsNote(int count) {
  if (count <= 0) return '';
  final items = count == 1 ? '1 item is' : '$count items are';
  return ' Note: $items not linked to a product, so inventory will not change for '
      '${count == 1 ? 'it' : 'them'}.';
}

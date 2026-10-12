import 'package:flutter_test/flutter_test.dart';
import 'package:shc_stock/app/core/utils/order_checks.dart';

// The Add Sale / Add Purchase forms stop a bad order with a plain message
// before it is sent. These are the same rules as backend/src/orderValidation.js.

OrderLineCheck _l({
  String name = 'Brick',
  int? productId = 1,
  double qty = 2,
  double rate = 100,
}) => (name: name, productId: productId, qty: qty, rate: rate);

void main() {
  group('checkOrderLines', () {
    test('a normal line is fine', () {
      expect(checkOrderLines([_l()]), isNull);
    });

    test('no lines, or only the empty row, is refused', () {
      expect(checkOrderLines([]), contains('at least one item'));
      expect(
        checkOrderLines([_l(name: '', productId: null, qty: 0, rate: 0)]),
        contains('at least one item'),
      );
    });

    test('the empty row at the bottom is ignored, not an error', () {
      expect(
        checkOrderLines([_l(), _l(name: '', productId: null, qty: 0, rate: 0)]),
        isNull,
      );
    });

    test('a half-filled line names the item and what is wrong', () {
      expect(checkOrderLines([_l(qty: 0)]), contains('Item 1 (Brick)'));
      expect(checkOrderLines([_l(qty: 0)]), contains('greater than 0'));
      expect(checkOrderLines([_l(qty: -2)]), contains('greater than 0'));
      expect(checkOrderLines([_l(rate: -1)]), contains('cannot be negative'));
      expect(
        checkOrderLines([_l(), _l(name: '', productId: null, qty: 3)]),
        contains('Item 2'),
      );
    });

    test(
      'a fraction is left to the product unit; on a typed line it is fine',
      () {
        // No loaded product to say "counted": nothing to refuse here (the
        // unit rule itself is covered in sale_stock_guard_test).
        expect(checkOrderLines([_l(qty: 2.5)]), isNull);
        expect(checkOrderLines([_l(productId: null, qty: 2.5)]), isNull);
      },
    );
  });

  group('checkPayment', () {
    test('up to the total is fine, a rupee of rounding slack included', () {
      expect(checkPayment(paid: 0, total: 1000), isNull);
      expect(checkPayment(paid: 1000, total: 1000), isNull);
      expect(checkPayment(paid: 1000.6, total: 1000), isNull);
    });

    test('more than the total, or negative, is refused', () {
      expect(checkPayment(paid: 500000, total: 1000), contains('more than'));
      expect(checkPayment(paid: -5, total: 1000), contains('negative'));
    });
  });

  group('checkDateOrder', () {
    test('a later date before an earlier one is refused', () {
      expect(
        checkDateOrder(
          later: DateTime(2026, 1, 1),
          earlier: DateTime(2026, 2, 1),
          laterName: 'Due date',
          earlierName: 'the invoice date',
        ),
        'Due date cannot be before the invoice date.',
      );
    });

    test('same day, later day and missing dates are fine', () {
      final d = DateTime(2026, 2, 1, 9);
      expect(
        checkDateOrder(
          later: DateTime(2026, 2, 1, 20),
          earlier: d,
          laterName: 'a',
          earlierName: 'b',
        ),
        isNull,
      );
      expect(
        checkDateOrder(
          later: null,
          earlier: d,
          laterName: 'a',
          earlierName: 'b',
        ),
        isNull,
      );
    });
  });

  test('withoutBlankRows keeps only rows with something in them', () {
    final rows = [_l(), _l(name: '', productId: null, qty: 0, rate: 0)];
    expect(withoutBlankRows(rows, (r) => r).length, 1);
  });

  test('unlinkedItemsNote is empty when every line is a product', () {
    expect(unlinkedItemsNote(0), '');
  });

  test('unlinkedItemsNote says inventory will not change for typed lines', () {
    expect(unlinkedItemsNote(1), contains('1 item is not linked'));
    expect(unlinkedItemsNote(1), contains('for it'));
    expect(unlinkedItemsNote(3), contains('3 items are not linked'));
    expect(unlinkedItemsNote(3), contains('for them'));
  });
}

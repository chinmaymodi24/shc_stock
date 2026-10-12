import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/products/widgets/stock_badge.dart';
import 'package:shc_stock/app/modules/sales/utils/sale_stock_guard.dart';

// The Add Sale form must tell the user about missing or short stock while they
// are filling it in — in the suggestions, under the row, on the quantity — and
// refuse to save a sale the inventory can't cover.

ProductModel _p(
  String id,
  String name,
  int stock, {
  String status = '',
  int committed = 0,
}) => ProductModel(
  id: id,
  name: name,
  sku: 'SKU-$id',
  categoryId: '1',
  categoryName: 'Cat',
  subCategory: 'Sub',
  unit: 'PCS',
  sellingPrice: 100,
  costPrice: 60,
  currentStock: stock.toDouble(),
  committedStock: committed.toDouble(),
  minimumStock: 0,
  serverStockStatus: status,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  late List<SaleStockLine> lines;
  late List<ProductModel> products;
  late SaleStockGuard guard;

  setUp(() {
    products = [
      _p('1', 'Brick A', 5),
      _p('2', 'Brick B', 0, status: 'outOfStock'),
      _p('3', 'Brick C', 3, status: 'lowStock'),
    ];
    lines = [];
    guard = SaleStockGuard(lines: () => lines, products: () => products);
  });

  group('errors', () {
    test('a product with no stock is reported as not in inventory', () {
      lines = [(productId: 2, qty: 1)];
      expect(guard.errorFor(2), contains('not in inventory'));
      expect(guard.firstError(), isNotNull);
    });

    test('stock of 5: selling 4 or 5 is fine, 6 says only 5 are in stock', () {
      lines = [(productId: 1, qty: 4)];
      expect(guard.errorFor(1), isNull);
      lines = [(productId: 1, qty: 5)];
      expect(guard.errorFor(1), isNull);
      lines = [(productId: 1, qty: 6)];
      expect(guard.errorFor(1), contains('Only 5 PCS'));
      expect(guard.errorFor(1), contains('Brick A'));
    });

    test('two rows of the same product are added together', () {
      lines = [(productId: 1, qty: 3), (productId: 1, qty: 3)];
      expect(guard.errorFor(1), contains('Only 5 PCS'));
      expect(guard.firstError(), isNotNull);
    });

    test('a hand-typed line (no product) is never checked', () {
      lines = [(productId: null, qty: 999)];
      expect(guard.errorFor(null), isNull);
      expect(guard.firstError(), isNull);
    });

    test('a product the list does not know is not checked', () {
      lines = [(productId: 99, qty: 10)];
      expect(guard.errorFor(99), isNull);
    });

    test('a healthy sale has no error', () {
      lines = [(productId: 1, qty: 2), (productId: 3, qty: 1)];
      expect(guard.firstError(), isNull);
    });
  });

  group('low stock heads-up', () {
    test('a low-stock product gets a note, not an error', () {
      lines = [(productId: 3, qty: 1)];
      expect(guard.errorFor(3), isNull);
      expect(guard.lowNoteFor(3), contains('Low stock'));
      expect(guard.lowNoteFor(3), contains('3 PCS'));
    });

    test('healthy stock has no note, and an error replaces the note', () {
      lines = [(productId: 1, qty: 1)];
      expect(guard.lowNoteFor(1), isNull);
      lines = [(productId: 3, qty: 9)];
      expect(guard.lowNoteFor(3), isNull);
      expect(guard.errorFor(3), isNotNull);
    });
  });

  group('capping a quantity', () {
    test('the cap is the stock minus what other rows already take', () {
      lines = [(productId: 1, qty: 2), (productId: 1, qty: 1)];
      // The second row (qty 1) may grow until 2 + qty == 5.
      expect(guard.maxQtyFor(1, thisLineQty: 1), 3);
      expect(guard.maxQtyFor(1, thisLineQty: 2), 4);
    });

    test('no cap for hand-typed lines or an out-of-stock product', () {
      lines = [(productId: null, qty: 1), (productId: 2, qty: 1)];
      expect(guard.maxQtyFor(null, thisLineQty: 1), isNull);
      expect(guard.maxQtyFor(2, thisLineQty: 1), isNull);
    });

    test('the limit message names the stock and the product', () {
      expect(guard.limitMessage(1), 'Only 5 PCS of "Brick A" available.');
    });
  });

  group('editing an existing order', () {
    test('its own units count as available again', () {
      // Stock is 5 after this order took 4 out of 9. Re-saving 4 is fine, and
      // so is raising it to 9 — but not 10.
      products = [_p('1', 'Brick A', 5)];
      guard.returnable[1] = 4;
      lines = [(productId: 1, qty: 4)];
      expect(guard.errorFor(1), isNull);
      lines = [(productId: 1, qty: 9)];
      expect(guard.errorFor(1), isNull);
      lines = [(productId: 1, qty: 10)];
      expect(guard.errorFor(1), contains('Only 9 PCS'));
    });

    test('a product this order sold out entirely can still be re-saved', () {
      products = [_p('2', 'Brick B', 0, status: 'outOfStock')];
      guard.returnable[2] = 3;
      lines = [(productId: 2, qty: 3)];
      expect(guard.errorFor(2), isNull);
    });
  });

  group('open sales hold stock back', () {
    test('stock 10 with 6 promised leaves 4 to sell', () {
      products = [_p('1', 'Brick A', 10, committed: 6)];
      expect(guard.available(1), 4);
      lines = [(productId: 1, qty: 4)];
      expect(guard.errorFor(1), isNull);
      lines = [(productId: 1, qty: 5)];
      final e = guard.errorFor(1)!;
      expect(e, contains('Only 4 PCS'));
      expect(e, contains('6 already promised to other open sales'));
    });

    test('everything promised: says so instead of "not in inventory"', () {
      products = [_p('1', 'Brick A', 5, committed: 5)];
      lines = [(productId: 1, qty: 1)];
      final e = guard.errorFor(1)!;
      expect(e, contains('already promised to other open sales'));
      expect(e, isNot(contains('not in inventory')));
    });

    test('editing an OPEN order: its own units are inside the held figure', () {
      // 10 in stock, this order holds 6 and another holds 3 (committed 9).
      products = [_p('1', 'Brick A', 10, committed: 9)];
      guard.returnable[1] = 6;
      lines = [(productId: 1, qty: 7)]; // 10 - 9 + 6 = 7 free for this order
      expect(guard.errorFor(1), isNull);
      lines = [(productId: 1, qty: 8)];
      expect(guard.errorFor(1), contains('Only 7 PCS'));
    });

    test('availableStock on the model never goes below zero', () {
      expect(_p('1', 'x', 2, committed: 5).availableStock, 0);
      expect(_p('1', 'x', 9, committed: 4).availableStock, 5);
    });

    test('the limit message follows the free quantity', () {
      products = [_p('1', 'Brick A', 10, committed: 6)];
      expect(guard.limitMessage(1), 'Only 4 PCS of "Brick A" available.');
    });
  });

  group('whole units', () {
    test('2.5 of a product is an error; 2.5 of a free-typed line is fine', () {
      lines = [(productId: 1, qty: 2.5)];
      expect(guard.errorFor(1), contains('whole number'));
      expect(guard.firstError(), isNotNull);
      lines = [(productId: null, qty: 2.5)];
      expect(guard.firstError(), isNull);
    });

    test('wholeQtyError: whole for a counted unit, decimals for a measured one', () {
      expect(
        wholeQtyError(productId: 3, qty: 1.5, productName: 'Brick A', unit: 'PCS'),
        contains('whole number'),
      );
      expect(
        wholeQtyError(
          productId: 3,
          qty: 12.5,
          productName: 'Fibre',
          unit: 'Kilogram (kg)',
        ),
        isNull,
        reason: 'kg can be split',
      );
      expect(
        wholeQtyError(productId: 3, qty: 2, productName: 'Brick A'),
        isNull,
      );
      expect(
        wholeQtyError(productId: null, qty: 1.5, productName: 'x'),
        isNull,
      );
    });
  });

  group('badge with reservations', () {
    Future<void> show(WidgetTester tester, ProductModel p) => tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AppThemeColors.light]),
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                StockBadge(product: p, colors: context.appColors),
          ),
        ),
      ),
    );

    testWidgets('all units promised -> All reserved', (tester) async {
      await show(tester, _p('1', 'x', 5, committed: 5));
      expect(find.text('All reserved'), findsOneWidget);
    });

    testWidgets('some promised -> shows the free count', (tester) async {
      await show(tester, _p('1', 'x', 10, committed: 4));
      expect(find.text('6 free'), findsOneWidget);
    });
  });

  group('suggestion badge', () {
    Future<void> show(WidgetTester tester, ProductModel p) => tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AppThemeColors.light]),
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                StockBadge(product: p, colors: context.appColors),
          ),
        ),
      ),
    );

    testWidgets('out of stock', (tester) async {
      await show(tester, products[1]);
      expect(find.text('Out of stock'), findsOneWidget);
    });

    testWidgets('low stock shows how many are left', (tester) async {
      await show(tester, products[2]);
      expect(find.text('Low · 3 left'), findsOneWidget);
    });

    testWidgets('healthy stock shows the count', (tester) async {
      await show(tester, products[0]);
      expect(find.text('5 in stock'), findsOneWidget);
    });
  });
}

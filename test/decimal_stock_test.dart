import 'package:flutter_test/flutter_test.dart';
import 'package:shc_stock/app/core/utils/units.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/sales/utils/sale_stock_guard.dart';
import 'package:shc_stock/app/modules/stock/models/stock_item_model.dart';

// Stock used to be whole numbers only: 12.5 kg of bulk fibre could not be
// bought or sold. Measured units (kg, m…) now take decimals; counted units
// (pieces, rolls, bags) stay whole.

ProductModel _p(String id, String unit, double stock) => ProductModel(
  id: id,
  name: 'Item $id',
  sku: 'SKU-$id',
  categoryId: '1',
  categoryName: 'Cat',
  subCategory: 'Sub',
  unit: unit,
  sellingPrice: 100,
  costPrice: 60,
  currentStock: stock,
  minimumStock: 0,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  test('measured units split, counted ones stay whole', () {
    for (final u in [
      'Kilogram (kg)',
      'Meter (m)',
      'Square Meter (sqm)',
      'Cubic Meter (m³)',
      '',
    ]) {
      expect(unitAllowsFraction(u), isTrue, reason: u);
    }
    for (final u in [
      'Piece (pcs)',
      'Roll',
      'Bag',
      'Box',
      'Set',
      'PCS',
      'Nos',
    ]) {
      expect(unitAllowsFraction(u), isFalse, reason: u);
    }
  });

  test('quantities print without trailing zeros, up to 3 decimals', () {
    expect(fmtStockQty(14), '14');
    expect(fmtStockQty(12.5), '12.5');
    expect(fmtStockQty(13.875), '13.875');
    expect(fmtStockQty(0.125), '0.125');
  });

  test('decimal stock survives the API JSON', () {
    final p = ProductModel.fromJson({
      'id': 9,
      'name': 'Bulk Fibre',
      'sku': 'BF',
      'unit': 'Kilogram (kg)',
      'sellingPrice': 100,
      'costPrice': 60,
      'currentStock': 12.5,
      'committedStock': 2.25,
      'minimumStock': 5.5,
      'createdAt': '2026-10-10T00:00:00.000Z',
    });
    expect(p.currentStock, 12.5);
    expect(p.availableStock, 10.25);
    expect(p.minimumStock, 5.5);

    final s = StockItemModel.fromJson({
      'id': 9,
      'name': 'Bulk Fibre',
      'unit': 'Kilogram (kg)',
      'stockInHand': 12.5,
      'availableStock': 10.25,
      'minimumStock': 5.5,
    });
    expect(s.stockInHand, 12.5);
    expect(s.availableStock, 10.25);
  });

  group('the Add Sale guard', () {
    late List<SaleStockLine> lines;
    late SaleStockGuard guard;
    final products = [
      _p('1', 'Kilogram (kg)', 12.5),
      _p('2', 'Piece (pcs)', 10),
    ];

    setUp(() {
      lines = [];
      guard = SaleStockGuard(lines: () => lines, products: () => products);
    });

    test('2.5 kg of a kg product is fine', () {
      lines = [(productId: 1, qty: 2.5)];
      expect(guard.errorFor(1), isNull);
    });

    test('12.5 kg is all of it; 12.75 is too much', () {
      lines = [(productId: 1, qty: 12.5)];
      expect(guard.errorFor(1), isNull);
      lines = [(productId: 1, qty: 12.75)];
      expect(guard.errorFor(1), contains('12.5'));
    });

    test('2.5 of a piece product is refused', () {
      lines = [(productId: 2, qty: 2.5)];
      expect(guard.errorFor(2), contains('whole number'));
      expect(guard.errorFor(2), contains('Piece (pcs)'));
    });
  });
}

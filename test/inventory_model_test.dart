import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shc_stock/app/modules/purchase/models/purchase_model.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/modules/stock/models/stock_item_model.dart';

// Verbatim rows from GET /api/inventory and GET /api/inventory/movements.
const _inventoryRow = '''
{"id":31,"productId":31,"code":"E2E-SKU-001","sku":"E2E-SKU-001",
 "name":"E2E Widget v2","category":"E2E Renamed","subCategory":"",
 "unit":"Piece","stockInHand":8,"availableStock":8,"minimumStock":500,
 "costPrice":300,"sellingPrice":550,"stockValue":2400,
 "stockLocation":"Bay 3","isActive":true,"status":"lowStock",
 "modifiedBy":"Admin","modifiedAt":"2026-08-10T03:30:00.000Z"}
''';

const _purchaseMovement = '''
{"id":9,"productId":31,"type":"IN","qty":40,"refType":"purchase","refId":4,
 "reference":"E2E-PO-001","note":"Purchase E2E-PO-001","createdBy":"Admin",
 "createdAt":"2026-08-10T03:29:00.000Z",
 "product":{"name":"E2E Widget v2","sku":"E2E-SKU-001","unit":"Piece"}}
''';

const _manualMovement = '''
{"id":11,"productId":31,"type":"OUT","qty":2,"refType":"manual","refId":null,
 "reference":"Manual adjustment","note":"damaged","createdBy":"Admin",
 "createdAt":"2026-08-10T03:31:00.000Z",
 "product":{"name":"E2E Widget v2","sku":"E2E-SKU-001","unit":"Piece"}}
''';

T _parse<T>(String raw, T Function(Map<String, dynamic>) f) =>
    f(jsonDecode(raw) as Map<String, dynamic>);

void main() {
  group('StockItemModel', () {
    test('maps an inventory row including the derived status', () {
      final s = _parse(_inventoryRow, StockItemModel.fromJson);

      expect(s.productId, 31);
      expect(s.sku, 'E2E-SKU-001');
      expect(s.name, 'E2E Widget v2');
      expect(s.category, 'E2E Renamed');
      expect(s.stockInHand, 8);
      expect(s.minimumStock, 500);
      expect(s.stockValue, 2400);
      expect(s.stockLocation, 'Bay 3');
      // Status is derived server-side so the app can't disagree with the API.
      expect(s.status, StockStatus.lowStock);
      expect(s.statusLabel, 'Low Stock');
    });

    test('falls back safely on a sparse row', () {
      final s = StockItemModel.fromJson({'id': 1, 'productId': 1});
      expect(s.stockInHand, 0);
      expect(s.status, StockStatus.inStock);
      expect(s.stockLocation, 'Main Warehouse');
    });
  });

  group('StockMovement', () {
    test('maps a purchase movement and marks it non-deletable', () {
      final m = _parse(_purchaseMovement, StockMovement.fromJson);
      expect(m.type, 'IN');
      expect(m.isIn, isTrue);
      expect(m.qty, 40);
      expect(m.refType, 'purchase');
      expect(m.refId, 4);
      expect(m.reference, 'E2E-PO-001');
      expect(m.productName, 'E2E Widget v2');
      // Purchase/sale rows are reversed by deleting the order, not the row.
      expect(m.isDeletable, isFalse);
    });

    test('marks a manual adjustment deletable', () {
      final m = _parse(_manualMovement, StockMovement.fromJson);
      expect(m.type, 'OUT');
      expect(m.isIn, isFalse);
      expect(m.refType, 'manual');
      expect(m.refId, isNull);
      expect(m.isDeletable, isTrue);
    });
  });

  group('order items carry productId', () {
    test('PurchaseDetailItem sends productId so stock can move', () {
      const item = PurchaseDetailItem(
        productId: 31,
        product: 'E2E Widget v2',
        qty: 40,
        rate: 300,
      );
      expect(item.toJson()['productId'], 31);
      expect(item.amount, 12000);
    });

    test('SaleDetailItem sends productId so stock can move', () {
      const item = SaleDetailItem(
        productId: 31,
        product: 'E2E Widget v2',
        qty: 10,
        rate: 550,
      );
      expect(item.toJson()['productId'], 31);
      expect(item.amount, 5500);
    });

    test('free-typed lines omit productId entirely', () {
      const item = PurchaseDetailItem(
        product: 'Typed by hand',
        qty: 5,
        rate: 1,
      );
      expect(item.toJson().containsKey('productId'), isFalse);
    });

    test('round-trips productId back from the API response', () {
      final item = PurchaseDetailItem.fromJson({
        'productId': 31,
        'product': 'E2E Widget v2',
        'qty': 40,
        'rate': 300,
      });
      expect(item.productId, 31);
    });
  });
}

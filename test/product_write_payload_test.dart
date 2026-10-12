import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/categories/controllers/categories_controller.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'support/session.dart';

// What the product screens send to the server, and what they show back.
//
// The server's PUT changes only the fields it is sent. Before this, a photo
// removed in the dialog (or an HSN code cleared) was simply left out of the
// request, so the server kept the old value and the edit looked like it had
// not worked.

late List<({String method, String path, dynamic body})> calls;

/// Answer for DELETE /products/:id.
int deleteStatus = 204;
Map<String, dynamic> deleteBody = const {};

class _Categories extends CategoriesController {
  @override
  Future<void> fetchCategories() async {}
  @override
  Future<void> fetchStats() async {}
}

class _Products extends ProductsController {
  @override
  Future<void> fetchStats() async {}
  @override
  Future<void> fetchProducts() async {}
}

ProductModel _p(String id) => ProductModel(
  id: id,
  name: 'Brick $id',
  sku: 'SKU-$id',
  categoryId: '1',
  categoryName: 'Cat',
  subCategory: 'Sub',
  unit: 'PCS',
  sellingPrice: 100,
  costPrice: 60,
  currentStock: 5,
  minimumStock: 0,
  hsnCode: '6902',
  createdAt: DateTime(2026, 1, 1),
);

void _fakeBackend() {
  calls = [];
  deleteStatus = 204;
  deleteBody = const {};
  ApiClient.useFakeBackend((o) async {
    calls.add((method: o.method, path: o.path, body: o.data));
    if (o.method == 'DELETE') {
      final res = dio.Response<dynamic>(
        requestOptions: o,
        statusCode: deleteStatus,
        data: deleteBody,
      );
      if (deleteStatus >= 400) {
        throw dio.DioException(requestOptions: o, response: res);
      }
      return res;
    }
    return dio.Response<dynamic>(
      requestOptions: o,
      statusCode: 200,
      data: {
        'id': 1,
        'name': 'Brick 1',
        'sku': 'SKU-1',
        'categoryId': 1,
        'unit': 'PCS',
        'sellingPrice': 100,
        'costPrice': 60,
        'currentStock': 5,
        'minimumStock': 0,
        'isActive': (o.data is Map ? (o.data as Map)['isActive'] : null) ?? true,
        'createdAt': '2026-01-01T00:00:00.000Z',
      },
    );
  });
}

void main() {
  setUp(_fakeBackend);
  tearDown(() {
    ApiClient.clearFakeBackend();
    Get.reset();
  });

  test('an edit with no photo sends an empty imageUrl so the old one is cleared', () async {
    signInSuperAdmin();
    Get.put<CategoriesController>(_Categories());
    final c = Get.put<ProductsController>(_Products());
    await c.updateProduct(
      id: '1',
      name: 'Brick 1',
      sku: 'SKU-1',
      categoryId: 1,
      unit: 'PCS',
      sellingPrice: 100,
      costPrice: 60,
      imageUrl: null,
      hsnCode: '',
    );
    final put = calls.singleWhere((c) => c.method == 'PUT');
    final body = put.body as Map;
    expect(body['imageUrl'], '');
    expect(body['hsnCode'], '', reason: 'a cleared field must reach the server');
    expect(body.containsKey('brand'), isFalse, reason: 'a field the form does not edit is left alone');
    expect(body.containsKey('isActive'), isFalse);
  });

  test('an edit that keeps its photo sends it back', () async {
    signInSuperAdmin();
    Get.put<CategoriesController>(_Categories());
    final c = Get.put<ProductsController>(_Products());
    await c.updateProduct(
      id: '1',
      name: 'Brick 1',
      sku: 'SKU-1',
      categoryId: 1,
      unit: 'PCS',
      sellingPrice: 100,
      costPrice: 60,
      imageUrl: '/uploads/a.png',
    );
    expect((calls.single.body as Map)['imageUrl'], '/uploads/a.png');
  });

  test('switching a product to inactive sends isActive:false', () async {
    signInSuperAdmin();
    Get.put<CategoriesController>(_Categories());
    final c = Get.put<ProductsController>(_Products());
    await c.updateProduct(
      id: '1',
      name: 'Brick 1',
      sku: 'SKU-1',
      categoryId: 1,
      unit: 'PCS',
      sellingPrice: 100,
      costPrice: 60,
      isActive: false,
    );
    expect((calls.single.body as Map)['isActive'], false);
  });

  testWidgets('a refused delete keeps the product and says why', (tester) async {
    signInSuperAdmin();
    Get.put<CategoriesController>(_Categories());
    final c = Get.put<ProductsController>(_Products());
    c.products.assignAll([_p('1'), _p('2')]);
    deleteStatus = 409;
    deleteBody = const {
      'error': 'This product has history (3 stock movements), so it cannot be deleted. Mark it Inactive instead.',
    };
    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData(extensions: [AppThemeColors.light]),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.runAsync(() => c.deleteProduct('1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(c.products.length, 2, reason: 'a refused delete must not drop the row');
    expect(find.textContaining('has history'), findsOneWidget);
    expect(find.textContaining('Mark it Inactive instead'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 4));
    }
  });

  testWidgets('a delete that goes through removes the row', (tester) async {
    signInSuperAdmin();
    Get.put<CategoriesController>(_Categories());
    final c = Get.put<ProductsController>(_Products());
    c.products.assignAll([_p('1'), _p('2')]);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData(extensions: [AppThemeColors.light]),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.runAsync(() => c.deleteProduct('1'));
    await tester.pump();
    expect(c.products.map((p) => p.id), ['2']);
  });

  test('an inactive product reads as Inactive, not In Stock', () {
    final p = ProductModel.fromJson({
      'id': 1,
      'name': 'Old',
      'sku': 'S',
      'categoryId': 1,
      'unit': 'PCS',
      'sellingPrice': 1,
      'costPrice': 1,
      'currentStock': 4,
      'minimumStock': 0,
      'isActive': false,
      'stockStatus': 'inactive',
      'createdAt': '2026-01-01T00:00:00.000Z',
    });
    expect(p.isActive, isFalse);
    expect(p.stockStatus, 'Inactive');
  });
}

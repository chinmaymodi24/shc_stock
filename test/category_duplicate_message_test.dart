import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/categories/controllers/categories_controller.dart';
import 'package:shc_stock/app/modules/categories/models/category_model.dart';
import 'support/session.dart';

// A duplicate category / sub-category name comes back from the server as a 409
// with the reason. The screen must show THAT, not "Failed to add category."

class _Categories extends CategoriesController {
  @override
  Future<void> fetchCategories() async {}
  @override
  Future<void> fetchStats() async {}
}

void _fake(String message) {
  ApiClient.useFakeBackend((o) async {
    throw dio.DioException(
      requestOptions: o,
      response: dio.Response<dynamic>(
        requestOptions: o,
        statusCode: 409,
        data: {'error': message},
      ),
    );
  });
}

Future<CategoriesController> _pump(WidgetTester tester) async {
  signInSuperAdmin();
  final c = Get.put<CategoriesController>(_Categories());
  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(extensions: [AppThemeColors.light]),
      home: const Scaffold(body: SizedBox()),
    ),
  );
  return c;
}

Future<void> _drain(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _expire(WidgetTester tester) async {
  // Snackbars queue in static state that outlives a test; clear it so the next
  // test's toast can show.
  Get.closeAllSnackbars();
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(seconds: 4));
  }
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    ApiClient.clearFakeBackend();
    Get.reset();
  });

  testWidgets('a duplicate category shows the server reason', (tester) async {
    final c = await _pump(tester);
    _fake('A category named "Bricks" already exists');
    final saved = await tester.runAsync(() => c.addCategory('Bricks'));
    expect(saved, isFalse, reason: 'the dialog must stay open on a refusal');
    await _drain(tester);
    expect(find.text('A category named "Bricks" already exists'), findsOneWidget);
    expect(find.text('Failed to add category.'), findsNothing);
    expect(c.categories, isEmpty);
    await _expire(tester);
  });

  testWidgets('a duplicate sub-category shows the server reason', (tester) async {
    final c = await _pump(tester);
    c.categories.add(
      CategoryModel.fromJson({'id': 1, 'name': 'Cat', 'description': '', 'subCategories': []}),
    );
    _fake('This category already has a sub-category named "Fine"');
    final savedSub = await tester.runAsync(() => c.addSubCategory('1', 'Fine'));
    expect(savedSub, isFalse);
    await _drain(tester);
    expect(find.textContaining('already has a sub-category named "Fine"'), findsOneWidget);
    await _expire(tester);
  });

  testWidgets('a network failure still gets the generic message', (tester) async {
    final c = await _pump(tester);
    ApiClient.useFakeBackend((o) async {
      throw dio.DioException(requestOptions: o, type: dio.DioExceptionType.connectionError);
    });
    await tester.runAsync(() => c.addCategory('Bricks'));
    await _drain(tester);
    expect(find.text('Failed to add category.'), findsOneWidget);
    await _expire(tester);
  });
}

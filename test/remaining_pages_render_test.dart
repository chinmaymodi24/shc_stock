import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_ripple_controller.dart';
import 'package:shc_stock/app/modules/categories/controllers/categories_controller.dart';
import 'package:shc_stock/app/modules/categories/models/category_model.dart';
import 'package:shc_stock/app/modules/categories/views/web_categories_layout.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/products/views/web_products_layout.dart';
import 'package:shc_stock/app/modules/purchase/controllers/add_purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/controllers/purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/models/purchase_model.dart';
import 'package:shc_stock/app/modules/purchase/views/web_new_purchase_layout.dart';
import 'package:shc_stock/app/modules/purchase/views/web_purchase_layout.dart';
import 'package:shc_stock/app/modules/sales/controllers/add_sale_controller.dart';
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/views/web_new_sales_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The pages that had no render coverage: Products, Categories, Purchase list,
// and the two order-entry forms. Pumped at a real laptop viewport, so any
// RenderFlex overflow fails the test.
// ─────────────────────────────────────────────────────────────────────────────

const _signedIn = SessionUser(
  id: 1,
  name: 'Chinmay Modi',
  email: 'shc@gmail.com',
  role: 'Admin',
);

class _StubSession extends SessionController {
  @override
  Future<void> restore() async => user.value = _signedIn;
}

ProductModel _product(String id, String name, String sku) => ProductModel(
  id: id,
  name: name,
  sku: sku,
  categoryId: '1',
  categoryName: 'Ceramic Fiber Products',
  subCategory: 'Blanket',
  unit: 'Roll',
  sellingPrice: 2800,
  costPrice: 1900,
  currentStock: 45,
  minimumStock: 10,
  createdAt: DateTime(2026, 1, 1),
  modifiedBy: 'Chinmay Modi',
  modifiedAt: DateTime(2026, 7, 10),
);

class _StubProducts extends ProductsController {
  @override
  Future<void> fetchProducts() async {
    final rows = [
      _product('1', 'CF Blanket 1260°C (64 kg/m³)', 'CFB-1260-64'),
      _product('2', 'Air Setting Mortar (ORTEX-HT)', 'RM-ORTEX-HT'),
    ];
    products.assignAll(rows);
    filteredProducts.assignAll(rows);
  }

  @override
  Future<void> fetchStats() async {
    stats.value = StatsSnapshot.fromJson(const {
      'totalProducts': 28,
      'lowStock': 2,
      'outOfStock': 3,
      'totalValue': 653274,
      'trends': {'totalProducts': null},
    });
  }
}

class _StubCategories extends CategoriesController {
  @override
  Future<void> fetchCategories() async {
    categories.assignAll([
      const CategoryModel(
        id: '1',
        name: 'Ceramic Fiber Products',
        description: 'Blankets, boards and bulk fiber',
        subCategories: [
          SubCategoryItem(id: 1, name: 'Ceramic Fiber Blanket'),
          SubCategoryItem(id: 2, name: 'Ceramic Fiber Board'),
        ],
      ),
      const CategoryModel(
        id: '2',
        name: 'Fire & Welding Protection',
        description: 'Fire blankets and curtains',
        subCategories: [],
      ),
    ]);
    selectedCatId.value = '1';
  }

  @override
  Future<void> fetchStats() async {
    stats.value = StatsSnapshot.fromJson(const {
      'totalCategories': 8,
      'totalSubCategories': 29,
      'trends': {'totalCategories': null},
    });
  }
}

class _StubPurchase extends PurchaseController {
  @override
  Future<void> fetchOrders() async {
    orders.assignAll([
      PurchaseOrder(
        id: '1',
        poNumber: 'PO-2024-10001',
        supplier: 'Ashoka Metals',
        supplierIcon: 'AM',
        date: DateTime(2026, 8, 1),
        itemCount: 3,
        amount: 102000,
        status: PurchaseStatus.received,
        modifiedBy: 'Chinmay Modi',
        modifiedAt: DateTime(2026, 8, 1, 10, 30),
      ),
      PurchaseOrder(
        id: '2',
        poNumber: 'PO-2024-10002',
        supplier: 'ThermoTech Industries',
        supplierIcon: 'TI',
        date: DateTime(2026, 8, 2),
        itemCount: 1,
        amount: 28900,
        status: PurchaseStatus.pending,
        // No modifier — must render a dash, not a fabricated name.
        modifiedBy: '',
      ),
    ]);
  }

  @override
  Future<void> fetchStats() async {
    stats.value = StatsSnapshot.fromJson(const {
      'totalOrders': 12,
      'purchaseMTD': 1245000,
      'amountPaid': 1126500,
      'amountDue': 118500,
      'trends': {'purchaseMTD': 12.5, 'totalOrders': null},
    });
  }
}

class _StubSales extends SalesController {
  @override
  Future<void> fetchOrders() async {}

  @override
  Future<void> fetchStats() async {
    stats.value = StatsSnapshot.empty;
  }
}

class _StubClients extends ClientsController {
  @override
  Future<void> fetchClients() async {}

  @override
  Future<void> fetchStats() async {}
}

Future<void> _pump(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  Get.put(ThemeController(), permanent: true);
  Get.put(ThemeRippleController(), permanent: true);
  Get.put<SessionController>(_StubSession(), permanent: true);

  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(extensions: const [AppThemeColors.light]),
      home: page,
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  testWidgets('Products page renders rows and API summary cards', (
    tester,
  ) async {
    Get.put<ProductsController>(_StubProducts());
    await _pump(tester, WebProductsLayout());

    expect(find.text('CF Blanket 1260°C (64 kg/m³)'), findsWidgets);
    expect(find.text('CFB-1260-64'), findsWidgets);
    // Cards come from /api/stats/products, not products.length (which is 2).
    expect(find.text('28'), findsWidgets);
  });

  testWidgets('Categories page renders the tree and API cards', (tester) async {
    Get.put<ProductsController>(_StubProducts());
    Get.put<CategoriesController>(_StubCategories());
    await _pump(tester, const WebCategoriesLayout());

    expect(find.text('Ceramic Fiber Products'), findsWidgets);
    expect(find.text('Fire & Welding Protection'), findsWidgets);
    expect(find.text('8'), findsWidgets); // totalCategories
    expect(find.text('29'), findsWidgets); // totalSubCategories
  });

  testWidgets('Purchase list renders orders, API cards and a dash modifier', (
    tester,
  ) async {
    Get.put<PurchaseController>(_StubPurchase());
    await _pump(tester, const WebPurchaseLayout());

    expect(find.text('PO-2024-10001'), findsWidgets);
    expect(find.text('Ashoka Metals'), findsWidgets);
    // Money cards formatted from the stats payload.
    expect(find.text('₹12,45,000'), findsWidgets);
    expect(find.text('₹1,18,500'), findsWidgets);
    expect(find.text('+12.5%'), findsWidgets);
    // Real modifier renders; the missing one degrades to a dash.
    expect(find.text('Chinmay Modi'), findsWidgets);
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('Add Purchase form renders with a usable default row', (
    tester,
  ) async {
    Get.put<ProductsController>(_StubProducts());
    Get.put<ClientsController>(_StubClients());
    Get.put<PurchaseController>(_StubPurchase());
    Get.put(AddPurchaseController());
    await _pump(tester, const WebNewPurchaseLayout());

    expect(find.text('Add Purchase'), findsWidgets);
    expect(find.text('Item Details'), findsWidgets);
    expect(find.text('Grand Total'), findsWidgets);

    // The row defaults to 1 pkg x 1 per pkg so a selected product's price
    // shows up immediately instead of being pinned to ₹0.
    final c = Get.find<AddPurchaseController>();
    expect(c.items.single.noPkg, 1);
    expect(c.items.single.avgContPerPkg, 1);
    c.items.single.netPrice = 250;
    expect(c.subTotal, 250);
  });

  testWidgets('Add Sales form renders', (tester) async {
    Get.put<ProductsController>(_StubProducts());
    Get.put<ClientsController>(_StubClients());
    Get.put<SalesController>(_StubSales());
    Get.put(AddSaleController());
    await _pump(tester, const WebNewSalesLayout());

    expect(find.text('Item Details'), findsWidgets);
    expect(find.text('Grand Total'), findsWidgets);
  });
}

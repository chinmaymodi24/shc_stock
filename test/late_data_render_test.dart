import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/app_theme.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_ripple_controller.dart';
import 'package:shc_stock/app/modules/categories/controllers/categories_controller.dart';
import 'package:shc_stock/app/modules/categories/models/category_model.dart';
import 'package:shc_stock/app/modules/categories/views/web_categories_layout.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/clients/views/web_clients_layout.dart';
import 'package:shc_stock/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:shc_stock/app/modules/dashboard/models/dashboard_models.dart';
import 'package:shc_stock/app/modules/dashboard/views/dashboard_view.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';
import 'package:shc_stock/app/modules/products/views/web_products_layout.dart';
import 'package:shc_stock/app/modules/purchase/controllers/purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/models/purchase_model.dart';
import 'package:shc_stock/app/modules/purchase/views/web_purchase_layout.dart';
import 'package:shc_stock/app/modules/reports/controllers/reports_controller.dart';
import 'package:shc_stock/app/modules/reports/views/reports_view.dart';
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/views/web_sales_layout.dart';
import 'package:shc_stock/app/modules/settings/controllers/settings_controller.dart';
import 'package:shc_stock/app/modules/settings/views/web_settings_layout.dart';
import 'package:shc_stock/app/modules/stock/controllers/stock_controller.dart';
import 'package:shc_stock/app/modules/stock/views/web_stock_layout.dart';
import 'package:shc_stock/app/modules/transactions/controllers/transactions_controller.dart';
import 'package:shc_stock/app/modules/transactions/models/transaction_model.dart';
import 'package:shc_stock/app/modules/transactions/views/web_transactions_layout.dart';
import 'package:shc_stock/app/modules/users/controllers/users_controller.dart';
import 'package:shc_stock/app/modules/users/models/user_model.dart';
import 'package:shc_stock/app/modules/users/views/web_users_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Every page, one scenario: the API answers AFTER the first frame (which is
// what really happens — each call carries a deliberate ~1s delay), and then
// the user flips the theme.
//
// This is the shape of the dashboard bug: that page read its controller's
// lists straight out of build() with no Obx, so it painted empty and only
// filled in when an unrelated rebuild — a theme switch — happened to come
// along. Any page missing its reactive wrapper fails the first expectation
// here; any page that loses its data on a theme change fails the second.
// ─────────────────────────────────────────────────────────────────────────────

/// How long every stubbed fetch takes to answer.
const _latency = Duration(milliseconds: 300);
Future<void> _wait() => Future.delayed(_latency);

class _StubSession extends SessionController {
  @override
  Future<void> restore() async => user.value = const SessionUser(
    id: 1,
    name: 'Chinmay Modi',
    email: 'shc@gmail.com',
    role: 'Admin',
  );
}

// ── Per-page controllers, each answering late ────────────────────────────────

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

class _LateProducts extends ProductsController {
  @override
  Future<void> fetchProducts() async {
    await _wait();
    final rows = [_product('1', 'CF Blanket 1260°C (64 kg/m³)', 'CFB-1260-64')];
    products.assignAll(rows);
    filteredProducts.assignAll(rows);
  }

  @override
  Future<void> fetchStats() async {
    await _wait();
    stats.value = StatsSnapshot.fromJson(const {
      'totalProducts': 28,
      'lowStock': 2,
      'outOfStock': 3,
      'totalValue': 653274,
      'trends': {'totalProducts': null},
    });
  }
}

class _LateCategories extends CategoriesController {
  @override
  Future<void> fetchCategories() async {
    await _wait();
    categories.assignAll([
      const CategoryModel(
        id: '1',
        name: 'Ceramic Fiber Products',
        description: 'Blankets, boards and bulk fiber',
        subCategories: [SubCategoryItem(id: 1, name: 'Ceramic Fiber Blanket')],
      ),
    ]);
    selectedCatId.value = '1';
  }

  @override
  Future<void> fetchStats() async {
    await _wait();
    stats.value = StatsSnapshot.fromJson(const {
      'totalCategories': 8,
      'totalSubCategories': 29,
      'trends': {'totalCategories': null},
    });
  }
}

class _LateStock extends StockController {
  @override
  Future<void> fetchItems() async => _wait();

  @override
  Future<void> fetchStats() async {
    await _wait();
    stats.value = StatsSnapshot.fromJson(const {
      'totalItems': 28,
      'inStock': 23,
      'lowStock': 2,
      'outOfStock': 3,
      'totalQty': 3152,
      'totalValue': 653274,
      'trends': {'totalItems': null, 'movement': 42.0},
    });
  }
}

class _LateTransactions extends TransactionsController {
  @override
  Future<void> fetchTransactions() async {
    await _wait();
    transactions.assignAll([
      TransactionModel(
        id: '1',
        item: 'Copper Pipe 15mm',
        type: TransactionType.inbound,
        party: 'Ashoka Metals',
        poNumber: '#4421',
        date: DateTime(2026, 7, 10),
        status: TransactionStatus.received,
        modifiedBy: 'Riya Patel',
        modifiedAt: DateTime(2026, 7, 10),
      ),
    ]);
  }

  @override
  Future<void> fetchStats() async {
    await _wait();
    stats.value = StatsSnapshot.fromJson(const {
      'totalTransactions': 6,
      'inbound': 3,
      'outbound': 3,
      'pending': 1,
      'trends': {'totalTransactions': null},
    });
  }
}

class _LatePurchase extends PurchaseController {
  @override
  Future<void> fetchOrders() async {
    await _wait();
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
    ]);
  }

  @override
  Future<void> fetchStats() async {
    await _wait();
    stats.value = StatsSnapshot.fromJson(const {
      'totalOrders': 12,
      'purchaseMTD': 1245000,
      'amountPaid': 1126500,
      'amountDue': 118500,
      'trends': {'purchaseMTD': 12.5, 'totalOrders': null},
    });
  }
}

class _LateSales extends SalesController {
  @override
  Future<void> fetchOrders() async => _wait();

  @override
  Future<void> fetchStats() async {
    await _wait();
    stats.value = StatsSnapshot.fromJson(const {
      'salesMTD': 2485600,
      'totalOrders': 47,
      'amountDue': 325400,
      'receivedMTD': 2160200,
      'totalSales': 3000000,
      'totalReceived': 2500000,
      'avgOrderValue': 15932,
      'trends': {'salesMTD': 18.6},
    });
  }
}

class _LateClients extends ClientsController {
  @override
  Future<void> fetchClients() async {
    await _wait();
    clients.assignAll(const [
      ClientModel(
        id: '1',
        code: 'CLT-0001',
        name: 'Aavkar Enterprise',
        address: 'Ramnagar, Sabarmati, Ahmedabad - 380005',
        regState: 'Gujarat',
        gstin: '24AQTPM1621J1ZP',
      ),
    ]);
  }

  @override
  Future<void> fetchStats() async {
    await _wait();
    stats.value = StatsSnapshot.fromJson(const {
      'totalClients': 1037,
      'gstRegistered': 931,
      'unregistered': 106,
      'statesCovered': 27,
      'trends': {'totalClients': 12.5},
    });
    topStates.assignAll(const [TopStateEntry(state: 'Gujarat', count: 1)]);
  }
}

class _LateUsers extends UsersController {
  static const _adminRow = '''
{"id":1,"code":"USR-0001","name":"Chinmay Modi","email":"shc@gmail.com",
 "role":"Admin","phone":"+91 98765 00001","department":"Management",
 "isActive":true,"lastLoginAt":"2026-08-09T14:32:00.000Z",
 "modifiedBy":"Admin","modifiedAt":null,
 "createdAt":"2026-01-01T00:00:00.000Z"}
''';

  @override
  Future<void> fetchUsers() async {
    await _wait();
    users.assignAll([
      UserModel.fromJson(jsonDecode(_adminRow) as Map<String, dynamic>),
    ]);
  }

  @override
  Future<void> fetchStats() async {
    await _wait();
    stats.value = StatsSnapshot.fromJson(const {
      'totalUsers': 15,
      'activeUsers': 12,
      'inactiveUsers': 3,
      'adminCount': 1,
      'trends': {'totalUsers': 7.1},
    });
    roleCounts.assignAll(const [RoleCount(role: 'Salesman', count: 6)]);
  }
}

class _LateReports extends ReportsController {
  @override
  Future<void> fetchReport() async {
    await _wait();
    salesLines.assignAll(const [
      ReportLine('Orders', '12'),
      ReportLine('Total Sales', '2485600'),
    ]);
    purchaseLines.assignAll(const [ReportLine('Orders', '8')]);
    stockLines.assignAll(const [ReportLine('Stock Value', '653274')]);
    netMovement.value = '1285600';
    topProducts.assignAll(const [
      ReportRank(
        name: 'Ceramic Fiber Blanket',
        detail: 'units sold',
        value: '120',
      ),
    ]);
    topClients.assignAll(const [
      ReportRank(
        name: 'Aavkar Enterprise',
        detail: '4 orders',
        value: '985600',
      ),
    ]);
  }
}

class _LateSettings extends SettingsController {
  @override
  Future<void> fetchSettings() async {
    await _wait();
    nameCtrl.text = 'Chinmay Modi';
    emailCtrl.text = 'shc@gmail.com';
    phoneCtrl.text = '+91 98765 00001';
    lowStock.value = true;
    rowsPerPage.value = 20;
  }
}

/// The page the bug was found on. Five tiles because the mobile layout lays
/// them out 2x2 plus a top-selling banner.
class _LateDashboard extends DashboardController {
  @override
  Future<void> fetchNotes() async {
    await _wait();
    notes.assignAll(const [NoteItem(id: 1, text: 'Follow up on restock')]);
  }

  @override
  Future<void> fetchDashboard() async {
    await _wait();
    dashboardStats.assignAll([
      const DashboardStatData(
        title: 'Total Stock Items',
        value: '3,152',
        icon: Icons.inventory_2_rounded,
        iconColor: Color(0xFF3B6FE0),
      ),
      const DashboardStatData(
        title: 'Out of Stock Items',
        value: '3',
        icon: Icons.block_rounded,
        iconColor: Color(0xFFE0473B),
      ),
      const DashboardStatData(
        title: 'Low Stock Items',
        value: '2',
        icon: Icons.warning_amber_rounded,
        iconColor: Color(0xFFDB9A1E),
      ),
      const DashboardStatData(
        title: 'Dues from Clients',
        value: '₹1,25,000',
        icon: Icons.description_outlined,
        iconColor: Color(0xFF2FA85C),
      ),
      const DashboardStatData(
        title: 'Top Selling Product',
        value: 'Ceramic Fiber Blanket',
        icon: Icons.emoji_events_rounded,
        iconColor: Color(0xFF2B1888),
      ),
    ]);
    purchasesData.assignAll(const [ChartPoint(label: 'Aug', value: 47)]);
    recentTransactions.assignAll(const [
      TransactionRow(
        item: 'Copper Pipe 15mm',
        type: 'Inbound',
        warehouse: 'Ashoka Metals',
        date: '09 Jul 2026',
        status: 'Received',
      ),
    ]);
    categorySlices.assignAll(const [
      CategorySlice(
        label: 'Ceramic Fiber Products',
        percent: 56,
        color: Color(0xFF2B1888),
      ),
    ]);
  }
}

// ── Harness ──────────────────────────────────────────────────────────────────

/// Pumps [page] under the same root the app uses: a GetMaterialApp inside an
/// Obx driven by the ThemeController, so flipping the theme rebuilds exactly
/// what it rebuilds in production.
Future<ThemeController> _pumpApp(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(1440, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final themeController = Get.put(ThemeController(), permanent: true);
  Get.put(ThemeRippleController(), permanent: true);
  Get.put<SessionController>(_StubSession(), permanent: true);

  await tester.pumpWidget(
    Obx(
      () => GetMaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode,
        home: page,
      ),
    ),
  );
  return themeController;
}

/// The whole scenario for one page: values must be absent before the fetch
/// answers, present once it does — with no interaction — and still present
/// after switching to dark mode.
Future<void> _expectsLateData(
  WidgetTester tester,
  Widget page, {
  required List<String> values,
  Size size = const Size(1440, 900),
}) async {
  final theme = await _pumpApp(tester, page, size: size);

  for (final v in values) {
    expect(
      find.text(v),
      findsNothing,
      reason: '"$v" showed before the API answered — stub is not late',
    );
  }

  // The API answers. Nothing else happens: no tap, no hover, no theme change.
  await tester.pump(_latency + const Duration(milliseconds: 100));
  await tester.pump();

  for (final v in values) {
    expect(
      find.text(v),
      findsWidgets,
      reason: '"$v" never rendered — the page is missing its Obx',
    );
  }

  await theme.setTheme(ThemeMode.dark);
  await tester.pumpAndSettle();

  for (final v in values) {
    expect(
      find.text(v),
      findsWidgets,
      reason: '"$v" disappeared when the theme changed',
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  testWidgets('Products', (tester) async {
    Get.put<ProductsController>(_LateProducts());
    await _expectsLateData(
      tester,
      WebProductsLayout(),
      values: ['CF Blanket 1260°C (64 kg/m³)', '28'],
    );
  });

  testWidgets('Categories', (tester) async {
    Get.put<ProductsController>(_LateProducts());
    Get.put<CategoriesController>(_LateCategories());
    await _expectsLateData(
      tester,
      const WebCategoriesLayout(),
      values: ['Ceramic Fiber Products', '29'],
    );
  });

  testWidgets('Inventory', (tester) async {
    Get.put<StockController>(_LateStock());
    await _expectsLateData(
      tester,
      const WebStockLayout(),
      values: ['28', '₹6,53,274'],
    );
  });

  testWidgets('Transactions', (tester) async {
    Get.put<TransactionsController>(_LateTransactions());
    await _expectsLateData(
      tester,
      const WebTransactionsLayout(),
      values: ['Copper Pipe 15mm', 'Ashoka Metals'],
    );
  });

  testWidgets('Purchase', (tester) async {
    Get.put<PurchaseController>(_LatePurchase());
    await _expectsLateData(
      tester,
      const WebPurchaseLayout(),
      values: ['PO-2024-10001', '₹12,45,000'],
    );
  });

  testWidgets('Sales', (tester) async {
    Get.put<SalesController>(_LateSales());
    await _expectsLateData(
      tester,
      const WebSalesLayout(),
      values: ['₹24,85,600', '47'],
    );
  });

  testWidgets('Clients', (tester) async {
    Get.put<ClientsController>(_LateClients());
    await _expectsLateData(
      tester,
      const WebClientsLayout(),
      values: ['Aavkar Enterprise', '1037'],
    );
  });

  testWidgets('Employee', (tester) async {
    Get.put<UsersController>(_LateUsers());
    await _expectsLateData(
      tester,
      const WebUsersLayout(),
      values: ['Chinmay Modi', '15'],
    );
  });

  testWidgets('Reports', (tester) async {
    Get.put<ReportsController>(_LateReports());
    await _expectsLateData(
      tester,
      const ReportsView(),
      values: ['₹24,85,600', 'Aavkar Enterprise'],
    );
  });

  testWidgets('Dashboard (web)', (tester) async {
    Get.put<DashboardController>(_LateDashboard(), permanent: true);
    await _expectsLateData(
      tester,
      const DashboardView(),
      values: ['3,152', 'Aug', 'Copper Pipe 15mm'],
    );
  });

  testWidgets('Dashboard (mobile)', (tester) async {
    Get.put<DashboardController>(_LateDashboard(), permanent: true);
    await _expectsLateData(
      tester,
      const DashboardView(),
      values: ['3,152', 'Ceramic Fiber Products'],
      size: const Size(430, 1600),
    );
  });

  testWidgets('Settings', (tester) async {
    Get.put<SettingsController>(_LateSettings());
    await _expectsLateData(
      tester,
      const WebSettingsLayout(),
      values: ['Chinmay Modi'],
    );
  });
}

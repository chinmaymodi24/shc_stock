import 'package:get/get.dart';
import '../modules/splash/splash_view.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/products/views/products_view.dart';
import '../modules/products/views/add_product_view.dart';
import '../modules/categories/views/categories_view.dart';
import '../modules/purchase/views/purchase_view.dart';
import '../modules/sales/views/sales_view.dart';
import '../modules/clients/views/clients_view.dart';
import '../modules/clients/views/add_client_view.dart';
import '../modules/stock/views/stock_view.dart';
import '../modules/users/views/users_view.dart';
import '../modules/users/views/add_employee_view.dart';
import 'app_routes.dart';
import 'products_binding.dart';
import 'categories_binding.dart';
import 'purchase_binding.dart';
import 'sales_binding.dart';
import 'clients_binding.dart';
import 'stock_binding.dart';
import 'users_binding.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.products,
      page: () => const ProductsView(),
      binding: ProductsBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.addProduct,
      page: () => const AddProductView(),
      binding: ProductsBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.categories,
      page: () => const CategoriesView(),
      binding: CategoriesBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.purchase,
      page: () => const PurchaseView(),
      binding: PurchaseBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.sales,
      page: () => const SalesView(),
      binding: SalesBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.clients,
      page: () => const ClientsView(),
      binding: ClientsBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.addClient,
      page: () => const AddClientView(),
      binding: ClientsBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.stock,
      page: () => const StockView(),
      binding: StockBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.users,
      page: () => const UsersView(),
      binding: UsersBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.addEmployee,
      page: () => const AddEmployeeView(),
      binding: UsersBinding(),
      transition: Transition.fadeIn,
    ),
  ];
}


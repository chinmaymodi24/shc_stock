abstract class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const products = '/products';
  static const addProduct = '/products/add';
  static const categories = '/categories';
  static const stock = '/stock';
  static const transactions = '/transactions';
  static const purchase = '/purchase';
  static const addPurchase = '/purchase/add';
  static const sales = '/sales';
  static const addSale = '/sales/add';

  /// The bill raised against one sale. The sale travels as the route
  /// argument.
  static const saleBill = '/sales/bill';
  static const clients = '/clients';
  static const addClient = '/clients/add';
  static const reports = '/reports';

  /// One report, opened from the catalog. The report key travels as the
  /// route argument.
  static const reportDetail = '/reports/detail';

  /// The older consolidated snapshot + analytics + gross-profit tabs. Kept
  /// alongside the catalog rather than deleted — it is a dashboard, not a
  /// statement, so it never became a catalog entry.
  static const reportsInsights = '/reports/insights';
  static const users = '/users';
  static const addEmployee = '/users/add';
  static const settings = '/settings';
  static const settingsDetail = '/settings/detail';
  static const profile = '/profile';
}

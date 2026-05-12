import 'package:get/get.dart';
import '../models/dashboard_models.dart';

class DashboardController extends GetxController {
  final RxInt selectedNavIndex = 0.obs;
  final RxString selectedSalesFilter = 'This Month'.obs;
  final List<String> salesFilters = ['This Month', 'Last Month', 'This Year'];

  final List<StatCardData> webStatCards = const [
    StatCardData(title: 'Total Stock Items', value: '1,245', change: '+12% from last month', isPositive: true, icon: StatCardIcon.box),
    StatCardData(title: 'Low Stock Items', value: '23', change: '-5% from last month', isPositive: false, icon: StatCardIcon.warning),
    StatCardData(title: "Today's Sales", value: '₹ 1,25,000', change: '+18% from yesterday', isPositive: true, icon: StatCardIcon.cart),
    StatCardData(title: 'Total Sales (This Month)', value: '₹ 18,75,000', change: '+22% from last month', isPositive: true, icon: StatCardIcon.chart),
  ];

  final List<TransactionData> recentTransactions = const [
    TransactionData(type: 'Sales', invoiceNo: 'INV-000125', amount: '₹ 25,000', date: '20 May 2024'),
    TransactionData(type: 'Purchase', invoiceNo: 'PUR-000089', amount: '₹ 40,000', date: '20 May 2024'),
    TransactionData(type: 'Sales', invoiceNo: 'INV-000124', amount: '₹ 15,500', date: '19 May 2024'),
    TransactionData(type: 'Purchase', invoiceNo: 'PUR-000088', amount: '₹ 22,000', date: '19 May 2024'),
    TransactionData(type: 'Sales', invoiceNo: 'INV-000123', amount: '₹ 18,750', date: '19 May 2024'),
  ];

  final List<LowStockItem> lowStockItems = const [
    LowStockItem(product: 'Tubular Heater 1000W', currentStock: 5, minimumStock: 10),
    LowStockItem(product: 'Cartridge Heater 500W', currentStock: 3, minimumStock: 8),
    LowStockItem(product: 'Thermocouple Type K', currentStock: 2, minimumStock: 5),
    LowStockItem(product: 'Industrial Coil Heater', currentStock: 1, minimumStock: 4),
  ];

  final List<SalesChartPoint> salesChartData = const [
    SalesChartPoint(label: '1 May', value: 50000),
    SalesChartPoint(label: '7 May', value: 120000),
    SalesChartPoint(label: '13 May', value: 95000),
    SalesChartPoint(label: '19 May', value: 175000),
    SalesChartPoint(label: '25 May', value: 145000),
    SalesChartPoint(label: '31 May', value: 190000),
  ];

  final double inStockPercent = 80.4;
  final double lowStockPercent = 14.4;
  final double outOfStockPercent = 5.2;
  final int totalItems = 1245;

  void onNavTap(int index) => selectedNavIndex.value = index;
  void changeSalesFilter(String filter) => selectedSalesFilter.value = filter;
}

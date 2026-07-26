import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../models/dashboard_models.dart';

class DashboardController extends GetxController {
  final RxInt selectedNavIndex = 0.obs;
  final RxString selectedSalesFilter = 'This Month'.obs;
  final RxBool chartsExpanded = false.obs;
  final List<String> salesFilters = ['This Month', 'Last Month', 'This Year'];

  final String greetingName = 'Chinmay';

  // ── Shared with mobile_dashboard_layout.dart / StatCard widget ──────────
  final List<StatCardData> webStatCards = const [
    StatCardData(
      title: 'Total Stock Items',
      value: '1,245',
      change: '+12% from last month',
      isPositive: true,
      icon: StatCardIcon.box,
    ),
    StatCardData(
      title: 'Low Stock Items',
      value: '23',
      change: '-5% from last month',
      isPositive: false,
      icon: StatCardIcon.warning,
    ),
    StatCardData(
      title: "Today's Sales",
      value: '₹ 1,25,000',
      change: '+18% from yesterday',
      isPositive: true,
      icon: StatCardIcon.cart,
    ),
    StatCardData(
      title: 'Total Sales (This Month)',
      value: '₹ 18,75,000',
      change: '+22% from last month',
      isPositive: true,
      icon: StatCardIcon.chart,
    ),
  ];

  // ── Web dashboard — pastel summary tiles ─────────────────────────────────
  final List<DashboardStatData> dashboardStats = [
    DashboardStatData(
      title: 'Total Stock Items',
      value: '4,812',
      change: '↑ 3.2% vs last month',
      icon: Icons.inventory_2_rounded,
      bgColor: const Color(0xFFE7EEFC),
      iconColor: const Color(0xFF3B6FE0),
    ),
    DashboardStatData(
      title: 'Out of Stock Items',
      value: '3',
      icon: Icons.block_rounded,
      bgColor: const Color(0xFFFBE9E9),
      iconColor: const Color(0xFFE0473B),
    ),
    DashboardStatData(
      title: 'Low Stock Items',
      value: '27',
      icon: Icons.warning_amber_rounded,
      bgColor: const Color(0xFFFCF0DC),
      iconColor: const Color(0xFFDB9A1E),
    ),
    DashboardStatData(
      title: 'Dues from Clients',
      value: '₹18.4L',
      icon: Icons.description_outlined,
      bgColor: const Color(0xFFE4F5E9),
      iconColor: const Color(0xFF2FA85C),
    ),
    DashboardStatData(
      title: 'Top Selling Product',
      value: 'Copper Pipe',
      icon: Icons.emoji_events_rounded,
      bgColor: const Color(0xFFEEE9F8),
      iconColor: AppColors.primaryPurple,
    ),
  ];

  // ── Chart data (6 months) ────────────────────────────────────────────────
  final List<ChartPoint> purchasesData = const [
    ChartPoint(label: 'Feb', value: 42),
    ChartPoint(label: 'Mar', value: 58),
    ChartPoint(label: 'Apr', value: 30),
    ChartPoint(label: 'May', value: 64),
    ChartPoint(label: 'Jun', value: 48),
    ChartPoint(label: 'Jul', value: 72),
  ];
  final String purchasesChange = '↑ 12% vs last month';

  final List<ChartPoint> salesData = const [
    ChartPoint(label: 'Feb', value: 28),
    ChartPoint(label: 'Mar', value: 38),
    ChartPoint(label: 'Apr', value: 44),
    ChartPoint(label: 'May', value: 40),
    ChartPoint(label: 'Jun', value: 56),
    ChartPoint(label: 'Jul', value: 66),
  ];
  final String salesChange = '↑ 8.4% vs last month';

  final List<ChartPoint> newClientsData = const [
    ChartPoint(label: 'Feb', value: 4),
    ChartPoint(label: 'Mar', value: 5),
    ChartPoint(label: 'Apr', value: 6),
    ChartPoint(label: 'May', value: 9),
    ChartPoint(label: 'Jun', value: 8),
    ChartPoint(label: 'Jul', value: 13),
  ];
  final String newClientsChange = '↑ 6 new this month';

  final List<CategorySlice> categorySlices = [
    CategorySlice(
      label: 'Pipes & Fittings',
      percent: 38,
      color: AppColors.primaryPurple,
    ),
    const CategorySlice(
      label: 'Valves',
      percent: 24,
      color: AppColors.primaryOrange,
    ),
    const CategorySlice(
      label: 'Heating Units',
      percent: 19,
      color: AppColors.accentPurple,
    ),
    CategorySlice(
      label: 'Insulation',
      percent: 19,
      color: AppColors.primaryPurple.withValues(alpha: 0.35),
    ),
  ];

  // ── Recent transactions ──────────────────────────────────────────────────
  final List<TransactionRow> recentTransactions = const [
    TransactionRow(
      item: 'Copper Pipe 15mm',
      type: 'Inbound',
      warehouse: 'Ahmedabad',
      date: 'Jul 10',
      status: 'Received',
    ),
    TransactionRow(
      item: 'PEX Fitting Kit',
      type: 'Outbound',
      warehouse: 'Surat',
      date: 'Jul 10',
      status: 'Shipped',
    ),
    TransactionRow(
      item: 'Water Heater Coil',
      type: 'Inbound',
      warehouse: 'Vadodara',
      date: 'Jul 9',
      status: 'Pending',
    ),
    TransactionRow(
      item: 'Brass Valve 3/4"',
      type: 'Outbound',
      warehouse: 'Ahmedabad',
      date: 'Jul 8',
      status: 'Delivered',
    ),
  ];

  // ── Incoming deliveries ───────────────────────────────────────────────────
  final List<DeliveryItem> incomingDeliveries = const [
    DeliveryItem(
      item: 'Copper Pipe 15mm',
      poRef: '4421',
      warehouse: 'Ahmedabad',
      eta: 'today',
      accentColor: AppColors.primaryOrange,
    ),
    DeliveryItem(
      item: 'Brass Valve 3/4"',
      poRef: '4418',
      warehouse: 'Vadodara',
      eta: 'today',
      accentColor: AppColors.primaryOrange,
    ),
    DeliveryItem(
      item: 'Water Heater Coil',
      poRef: '4425',
      warehouse: 'Surat',
      eta: 'tomorrow',
      accentColor: AppColors.primaryPurple,
    ),
    DeliveryItem(
      item: 'PVC Elbow Joint',
      poRef: '4430',
      warehouse: 'Ahmedabad',
      eta: 'tomorrow',
      accentColor: AppColors.primaryPurple,
    ),
  ];

  // ── Low stock alerts ──────────────────────────────────────────────────────
  final List<LowStockAlertItem> lowStockAlerts = const [
    LowStockAlertItem(product: 'Copper Fitting 1/2"', current: 4, max: 50),
    LowStockAlertItem(product: 'Insulation Tape', current: 9, max: 60),
  ];

  // ── Notes & to-dos ────────────────────────────────────────────────────────
  final RxList<NoteItem> notes = <NoteItem>[
    NoteItem(
      text: 'Confirm PO #4421 delivery slot with Ahmedabad warehouse',
      done: true,
    ),
    NoteItem(text: 'Follow up with supplier on Copper Fitting 1/2" restock'),
    NoteItem(text: 'Reconcile Surat warehouse stock count before month-end'),
    NoteItem(text: 'Review pending order #18 approvals'),
  ].obs;

  void toggleNote(int index) {
    notes[index].done = !notes[index].done;
    notes.refresh();
  }

  void addNote(String text) {
    notes.add(NoteItem(text: text));
  }

  void onNavTap(int index) => selectedNavIndex.value = index;
  void changeSalesFilter(String filter) => selectedSalesFilter.value = filter;
}

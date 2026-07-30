import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/sales_model.dart';

class SalesController extends GetxController {
  // ── Observable list ──────────────────────────────────────────
  final RxList<SalesOrder> orders = <SalesOrder>[].obs;
  final RxInt mobileTabIndex = 0.obs; // 0 = All, 1 = Confirmed, 2 = Delivered
  final RxString searchQuery = ''.obs;
  final RxSet<String> statusFilters = <String>{}.obs;
  final RxSet<String> paymentFilters = <String>{}.obs;
  final RxString sortOption = 'Default'.obs;
  final RxInt rowsPerPage = 10.obs;
  final RxInt currentPage = 1.obs;

  static const statusOptions = [
    'Confirmed',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];
  static const paymentOptions = ['Paid', 'Partial', 'Pending', 'Refunded'];
  static const sortOptions = [
    'Default',
    'Date: Newest First',
    'Date: Oldest First',
    'Amount: Low to High',
    'Amount: High to Low',
  ];

  void resetFilters() {
    searchQuery.value = '';
    statusFilters.clear();
    paymentFilters.clear();
    sortOption.value = 'Default';
    currentPage.value = 1;
  }

  // ── Client color map ─────────────────────────────────────────
  static const Map<String, Color> _clientColors = {
    'AE': Color(0xFFF47B20), // Arvind Enterprises    → orange
    'SRT': Color(0xFF3B82F6), // Shree Ram Traders     → blue
    'JMD': Color(0xFF7C3AED), // Jai Mata Di Suppliers → purple
    'GH': Color(0xFF64748B), // Gupta Hardware        → slate
    'NIC': Color(0xFF0D9488), // National Insulation   → teal
    'TMC': Color(0xFFDC2626), // Thermo Materials      → red
    'BS': Color(0xFF16A34A), // Buildwell Supply      → green
    'OST': Color(0xFF1D4ED8), // Om Sai Traders        → indigo
    'SE': Color(0xFF9333EA), // Shakti Enterprises    → purple
    'LI': Color(0xFF4F46E5), // Lakshmi Industries    → indigo
    'RS': Color(0xFF0891B2), // Rajesh & Sons         → cyan
    'PS': Color(0xFFB45309), // Patel Suppliers       → amber
    'BT': Color(0xFF059669), // Bharat Traders        → emerald
    'VE': Color(0xFF6D28D9), // Vimal Enterprises     → violet
    'SI': Color(0xFF0369A1), // Sriram Industries     → sky
  };

  static Color _colorFor(String badge) =>
      _clientColors[badge] ?? const Color(0xFF4A3AFF);

  // ── Seed data matching screenshot exactly ────────────────────
  static final List<SalesOrder> _seed = [
    SalesOrder(
      id: 'so_01',
      soNumber: 'SO-2024-00156',
      client: 'Arvind Enterprises',
      clientBadge: 'AE',
      clientColor: _colorFor('AE'),
      date: DateTime(2024, 5, 31),
      itemCount: 12,
      amount: 85600,
      status: SalesStatus.delivered,
      paymentStatus: PaymentStatus.paid,
    ),
    SalesOrder(
      id: 'so_02',
      soNumber: 'SO-2024-00155',
      client: 'Shree Ram Traders',
      clientBadge: 'SRT',
      clientColor: _colorFor('SRT'),
      date: DateTime(2024, 5, 30),
      itemCount: 8,
      amount: 48750,
      status: SalesStatus.shipped,
      paymentStatus: PaymentStatus.partial,
    ),
    SalesOrder(
      id: 'so_03',
      soNumber: 'SO-2024-00154',
      client: 'Jai Mata Di Suppliers',
      clientBadge: 'JMD',
      clientColor: _colorFor('JMD'),
      date: DateTime(2024, 5, 30),
      itemCount: 15,
      amount: 102300,
      status: SalesStatus.delivered,
      paymentStatus: PaymentStatus.paid,
    ),
    SalesOrder(
      id: 'so_04',
      soNumber: 'SO-2024-00153',
      client: 'Gupta Hardware',
      clientBadge: 'GH',
      clientColor: _colorFor('GH'),
      date: DateTime(2024, 5, 29),
      itemCount: 10,
      amount: 35600,
      status: SalesStatus.confirmed,
      paymentStatus: PaymentStatus.paid,
    ),
    SalesOrder(
      id: 'so_05',
      soNumber: 'SO-2024-00152',
      client: 'National Insulation Co.',
      clientBadge: 'NIC',
      clientColor: _colorFor('NIC'),
      date: DateTime(2024, 5, 28),
      itemCount: 20,
      amount: 125800,
      status: SalesStatus.shipped,
      paymentStatus: PaymentStatus.partial,
    ),
    SalesOrder(
      id: 'so_06',
      soNumber: 'SO-2024-00151',
      client: 'Thermo Materials Pvt. Ltd.',
      clientBadge: 'TMC',
      clientColor: _colorFor('TMC'),
      date: DateTime(2024, 5, 27),
      itemCount: 6,
      amount: 22400,
      status: SalesStatus.cancelled,
      paymentStatus: PaymentStatus.refunded,
    ),
    SalesOrder(
      id: 'so_07',
      soNumber: 'SO-2024-00150',
      client: 'Buildwell Supply',
      clientBadge: 'BS',
      clientColor: _colorFor('BS'),
      date: DateTime(2024, 5, 26),
      itemCount: 9,
      amount: 41600,
      status: SalesStatus.delivered,
      paymentStatus: PaymentStatus.paid,
    ),
    SalesOrder(
      id: 'so_08',
      soNumber: 'SO-2024-00149',
      client: 'Om Sai Traders',
      clientBadge: 'OST',
      clientColor: _colorFor('OST'),
      date: DateTime(2024, 5, 25),
      itemCount: 11,
      amount: 56700,
      status: SalesStatus.shipped,
      paymentStatus: PaymentStatus.partial,
    ),
    SalesOrder(
      id: 'so_09',
      soNumber: 'SO-2024-00148',
      client: 'Shakti Enterprises',
      clientBadge: 'SE',
      clientColor: _colorFor('SE'),
      date: DateTime(2024, 5, 24),
      itemCount: 7,
      amount: 29450,
      status: SalesStatus.confirmed,
      paymentStatus: PaymentStatus.paid,
    ),
    SalesOrder(
      id: 'so_10',
      soNumber: 'SO-2024-00147',
      client: 'Lakshmi Industries',
      clientBadge: 'LI',
      clientColor: _colorFor('LI'),
      date: DateTime(2024, 5, 23),
      itemCount: 14,
      amount: 74800,
      status: SalesStatus.delivered,
      paymentStatus: PaymentStatus.paid,
    ),
    SalesOrder(
      id: 'so_11',
      soNumber: 'SO-2024-00146',
      client: 'Rajesh & Sons',
      clientBadge: 'RS',
      clientColor: _colorFor('RS'),
      date: DateTime(2024, 5, 22),
      itemCount: 5,
      amount: 18900,
      status: SalesStatus.delivered,
      paymentStatus: PaymentStatus.paid,
    ),
    SalesOrder(
      id: 'so_12',
      soNumber: 'SO-2024-00145',
      client: 'Patel Suppliers',
      clientBadge: 'PS',
      clientColor: _colorFor('PS'),
      date: DateTime(2024, 5, 21),
      itemCount: 16,
      amount: 95400,
      status: SalesStatus.shipped,
      paymentStatus: PaymentStatus.partial,
    ),
    SalesOrder(
      id: 'so_13',
      soNumber: 'SO-2024-00144',
      client: 'Bharat Traders',
      clientBadge: 'BT',
      clientColor: _colorFor('BT'),
      date: DateTime(2024, 5, 20),
      itemCount: 3,
      amount: 12600,
      status: SalesStatus.confirmed,
      paymentStatus: PaymentStatus.paid,
    ),
    SalesOrder(
      id: 'so_14',
      soNumber: 'SO-2024-00143',
      client: 'Vimal Enterprises',
      clientBadge: 'VE',
      clientColor: _colorFor('VE'),
      date: DateTime(2024, 5, 19),
      itemCount: 18,
      amount: 108750,
      status: SalesStatus.delivered,
      paymentStatus: PaymentStatus.paid,
    ),
    SalesOrder(
      id: 'so_15',
      soNumber: 'SO-2024-00142',
      client: 'Sriram Industries',
      clientBadge: 'SI',
      clientColor: _colorFor('SI'),
      date: DateTime(2024, 5, 18),
      itemCount: 22,
      amount: 134500,
      status: SalesStatus.shipped,
      paymentStatus: PaymentStatus.partial,
    ),
  ];

  // Generate 141 more to reach total of 156
  static List<SalesOrder> _generate() {
    final clients = [
      ('Arvind Enterprises', 'AE'),
      ('Shree Ram Traders', 'SRT'),
      ('Jai Mata Di Suppliers', 'JMD'),
      ('Gupta Hardware', 'GH'),
      ('National Insulation Co.', 'NIC'),
      ('Buildwell Supply', 'BS'),
      ('Om Sai Traders', 'OST'),
      ('Shakti Enterprises', 'SE'),
      ('Lakshmi Industries', 'LI'),
      ('Rajesh & Sons', 'RS'),
    ];
    final statuses = SalesStatus.values;
    final payments = PaymentStatus.values;
    final result = <SalesOrder>[];

    for (int i = 16; i <= 156; i++) {
      final cl = clients[(i - 1) % clients.length];
      final so = statuses[(i - 1) % statuses.length];
      final pay = payments[(i - 1) % payments.length];
      final dayOffset = i - 15;
      final date = DateTime(2024, 5, 18).subtract(Duration(days: dayOffset));
      result.add(
        SalesOrder(
          id: 'so_$i',
          soNumber: 'SO-2024-00${156 - i + 1}'.padLeft(11, '0'),
          client: cl.$1,
          clientBadge: cl.$2,
          clientColor: _colorFor(cl.$2),
          date: date,
          itemCount: (i % 15) + 3,
          amount: ((i * 4350) % 98000 + 12000).toDouble(),
          status: so,
          paymentStatus: pay,
        ),
      );
    }
    return result;
  }

  @override
  void onInit() {
    super.onInit();
    orders.addAll(_seed);
    orders.addAll(_generate());
  }

  // ── Computed stats ────────────────────────────────────────────
  int get totalOrders => orders.length;
  double get totalSalesMTD => orders.fold(0, (s, o) => s + o.amount);
  double get totalDue => orders
      .where(
        (o) =>
            o.paymentStatus == PaymentStatus.partial ||
            o.paymentStatus == PaymentStatus.pending,
      )
      .fold(
        0,
        (s, o) => s + o.amount * 0.13,
      ); // ~13% outstanding on those orders
  double get totalReceived => totalSalesMTD - totalDue;
  double get avgOrderValue => totalOrders > 0 ? totalSalesMTD / totalOrders : 0;

  // ── Top Clients ───────────────────────────────────────────────
  List<TopClient> get topClients => const [
    TopClient(
      badge: 'AE',
      color: Color(0xFFF47B20),
      name: 'Arvind Enterprises',
      orderCount: 24,
      totalAmount: 425600,
    ),
    TopClient(
      badge: 'SRT',
      color: Color(0xFF3B82F6),
      name: 'Shree Ram Traders',
      orderCount: 18,
      totalAmount: 315800,
    ),
    TopClient(
      badge: 'JMD',
      color: Color(0xFF7C3AED),
      name: 'Jai Mata Di Suppliers',
      orderCount: 15,
      totalAmount: 245700,
    ),
    TopClient(
      badge: 'NIC',
      color: Color(0xFF0D9488),
      name: 'National Insulation Co.',
      orderCount: 12,
      totalAmount: 210400,
    ),
    TopClient(
      badge: 'GH',
      color: Color(0xFF64748B),
      name: 'Gupta Hardware',
      orderCount: 10,
      totalAmount: 185600,
    ),
  ];

  // ── CRUD ─────────────────────────────────────────────────────
  void addOrder(SalesOrder order) => orders.insert(0, order);
  void deleteOrder(String id) => orders.removeWhere((o) => o.id == id);
}

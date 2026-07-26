import 'package:get/get.dart';
import '../models/purchase_model.dart';

class PurchaseController extends GetxController {
  // ── Observable list ──────────────────────────────────────────
  final RxList<PurchaseOrder> orders = <PurchaseOrder>[].obs;
  final RxString searchQuery = ''.obs;
  final RxString supplierFilter = 'Supplier: All'.obs;
  final RxInt rowsPerPage = 10.obs;
  final RxInt currentPage = 1.obs;

  // ── Stats ────────────────────────────────────────────────────
  int get totalOrders => orders.length;
  double get totalPurchaseMTD => orders.fold(0, (s, o) => s + o.amount);
  double get totalAmountPaid => orders
      .where((o) => o.status == PurchaseStatus.received)
      .fold(0, (s, o) => s + o.amount);
  double get totalAmountDue => orders
      .where(
        (o) =>
            o.status == PurchaseStatus.pending ||
            o.status == PurchaseStatus.partial,
      )
      .fold(0, (s, o) => s + o.amount);
  double get averageOrderValue =>
      orders.isEmpty ? 0 : totalPurchaseMTD / orders.length;

  // ── Top Suppliers (by total amount) ─────────────────────────
  List<MapEntry<String, double>> get topSuppliers {
    final map = <String, double>{};
    for (final o in orders) {
      map[o.supplier] = (map[o.supplier] ?? 0) + o.amount;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(4).toList();
  }

  // ── Unique suppliers for filter ──────────────────────────────
  List<String> get supplierNames {
    final names = orders.map((o) => o.supplier).toSet().toList();
    names.sort();
    return names;
  }

  // ── Seed data (matching screenshot style) ───────────────────
  static final List<PurchaseOrder> _seed = [
    PurchaseOrder(
      id: 'po_01',
      poNumber: 'PO-2201',
      supplier: 'Ashoka Metals',
      supplierIcon: 'AM',
      date: DateTime(2026, 7, 10),
      itemCount: 1,
      amount: 102000,
      status: PurchaseStatus.received,
      modifiedBy: 'Chinmay Modi',
      modifiedAt: DateTime(2026, 7, 10, 10, 30),
    ),
    PurchaseOrder(
      id: 'po_02',
      poNumber: 'PO-1187',
      supplier: 'Precision Valves Co.',
      supplierIcon: 'PV',
      date: DateTime(2026, 7, 8),
      itemCount: 1,
      amount: 16800,
      status: PurchaseStatus.partial,
      modifiedBy: 'Riya Patel',
      modifiedAt: DateTime(2026, 7, 8, 11, 15),
    ),
    PurchaseOrder(
      id: 'po_03',
      poNumber: 'PO-5502',
      supplier: 'ThermoTech Industries',
      supplierIcon: 'TT',
      date: DateTime(2026, 7, 6),
      itemCount: 1,
      amount: 14500,
      status: PurchaseStatus.pending,
      modifiedBy: 'Chinmay Modi',
      modifiedAt: DateTime(2026, 7, 6, 9, 20),
    ),
    PurchaseOrder(
      id: 'po_04',
      poNumber: 'PO-3312',
      supplier: 'Gujarat Polymers',
      supplierIcon: 'GP',
      date: DateTime(2026, 7, 3),
      itemCount: 1,
      amount: 21000,
      status: PurchaseStatus.received,
      modifiedBy: 'Riya Patel',
      modifiedAt: DateTime(2026, 7, 3, 16, 00),
    ),
    PurchaseOrder(
      id: 'po_05',
      poNumber: 'PO-2980',
      supplier: 'Ashoka Metals',
      supplierIcon: 'AM',
      date: DateTime(2026, 7, 1),
      itemCount: 2,
      amount: 54500,
      status: PurchaseStatus.received,
      modifiedBy: 'Ravi Sharma',
      modifiedAt: DateTime(2026, 7, 1, 14, 45),
    ),
    PurchaseOrder(
      id: 'po_06',
      poNumber: 'PO-2750',
      supplier: 'National Insulation Co.',
      supplierIcon: 'NI',
      date: DateTime(2026, 6, 28),
      itemCount: 3,
      amount: 38200,
      status: PurchaseStatus.pending,
      modifiedBy: 'Amit Verma',
      modifiedAt: DateTime(2026, 6, 28, 10, 00),
    ),
    PurchaseOrder(
      id: 'po_07',
      poNumber: 'PO-2611',
      supplier: 'Gujarat Polymers',
      supplierIcon: 'GP',
      date: DateTime(2026, 6, 25),
      itemCount: 2,
      amount: 29100,
      status: PurchaseStatus.partial,
      modifiedBy: 'Sneha Gupta',
      modifiedAt: DateTime(2026, 6, 25, 16, 30),
    ),
    PurchaseOrder(
      id: 'po_08',
      poNumber: 'PO-2480',
      supplier: 'ThermoTech Industries',
      supplierIcon: 'TT',
      date: DateTime(2026, 6, 22),
      itemCount: 1,
      amount: 18600,
      status: PurchaseStatus.received,
      modifiedBy: 'Chinmay Modi',
      modifiedAt: DateTime(2026, 6, 22, 11, 00),
    ),
    PurchaseOrder(
      id: 'po_09',
      poNumber: 'PO-2310',
      supplier: 'Precision Valves Co.',
      supplierIcon: 'PV',
      date: DateTime(2026, 6, 20),
      itemCount: 1,
      amount: 22400,
      status: PurchaseStatus.cancelled,
      modifiedBy: 'Riya Patel',
      modifiedAt: DateTime(2026, 6, 20, 9, 15),
    ),
    PurchaseOrder(
      id: 'po_10',
      poNumber: 'PO-2150',
      supplier: 'Ashoka Metals',
      supplierIcon: 'AM',
      date: DateTime(2026, 6, 18),
      itemCount: 2,
      amount: 67800,
      status: PurchaseStatus.received,
      modifiedBy: 'Ravi Sharma',
      modifiedAt: DateTime(2026, 6, 18, 15, 20),
    ),
    PurchaseOrder(
      id: 'po_11',
      poNumber: 'PO-1990',
      supplier: 'National Insulation Co.',
      supplierIcon: 'NI',
      date: DateTime(2026, 6, 15),
      itemCount: 3,
      amount: 41000,
      status: PurchaseStatus.pending,
      modifiedBy: 'Vijay Joshi',
      modifiedAt: DateTime(2026, 6, 15, 13, 30),
    ),
    PurchaseOrder(
      id: 'po_12',
      poNumber: 'PO-1820',
      supplier: 'Gujarat Polymers',
      supplierIcon: 'GP',
      date: DateTime(2026, 6, 12),
      itemCount: 1,
      amount: 15300,
      status: PurchaseStatus.received,
      modifiedBy: 'Neha Iyer',
      modifiedAt: DateTime(2026, 6, 12, 10, 00),
    ),
    PurchaseOrder(
      id: 'po_13',
      poNumber: 'PO-1650',
      supplier: 'ThermoTech Industries',
      supplierIcon: 'TT',
      date: DateTime(2026, 6, 10),
      itemCount: 2,
      amount: 28900,
      status: PurchaseStatus.partial,
      modifiedBy: 'Chinmay Modi',
      modifiedAt: DateTime(2026, 6, 10, 16, 45),
    ),
    PurchaseOrder(
      id: 'po_14',
      poNumber: 'PO-1480',
      supplier: 'Precision Valves Co.',
      supplierIcon: 'PV',
      date: DateTime(2026, 6, 7),
      itemCount: 1,
      amount: 19700,
      status: PurchaseStatus.received,
      modifiedBy: 'Kiran Mehta',
      modifiedAt: DateTime(2026, 6, 7, 11, 00),
    ),
    PurchaseOrder(
      id: 'po_15',
      poNumber: 'PO-1300',
      supplier: 'Ashoka Metals',
      supplierIcon: 'AM',
      date: DateTime(2026, 6, 5),
      itemCount: 1,
      amount: 33000,
      status: PurchaseStatus.pending,
      modifiedBy: 'Suresh Kumar',
      modifiedAt: DateTime(2026, 6, 5, 14, 20),
    ),
    for (int i = 16; i <= 28; i++)
      PurchaseOrder(
        id: 'po_$i',
        poNumber: 'PO-${1300 - (i - 15) * 120}',
        supplier: [
          'Ashoka Metals',
          'Gujarat Polymers',
          'ThermoTech Industries',
          'Precision Valves Co.',
          'National Insulation Co.',
        ][(i - 16) % 5],
        supplierIcon: ['AM', 'GP', 'TT', 'PV', 'NI'][(i - 16) % 5],
        date: DateTime(2026, 6, 4 - (i - 16)),
        itemCount: i % 3 + 1,
        amount: (i * 3450.0),
        status: PurchaseStatus.values[i % 4],
        modifiedBy: 'Admin',
        modifiedAt: null,
      ),
  ];

  @override
  void onInit() {
    super.onInit();
    orders.addAll(_seed);
  }

  // ── CRUD ─────────────────────────────────────────────────────
  void addOrder(PurchaseOrder order) => orders.insert(0, order);
  void deleteOrder(String id) => orders.removeWhere((o) => o.id == id);
  void updateStatus(String id, PurchaseStatus status) {
    final idx = orders.indexWhere((o) => o.id == id);
    if (idx == -1) return;
    final o = orders[idx];
    orders[idx] = PurchaseOrder(
      id: o.id,
      poNumber: o.poNumber,
      supplier: o.supplier,
      supplierIcon: o.supplierIcon,
      date: o.date,
      itemCount: o.itemCount,
      amount: o.amount,
      status: status,
      modifiedBy: o.modifiedBy,
      modifiedAt: o.modifiedAt,
    );
    orders.refresh();
  }
}

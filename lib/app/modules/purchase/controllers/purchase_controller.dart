import 'package:get/get.dart';
import '../models/purchase_model.dart';

class PurchaseController extends GetxController {
  // ── Observable list ──────────────────────────────────────────
  final RxList<PurchaseOrder> orders = <PurchaseOrder>[].obs;

  // ── Stats ────────────────────────────────────────────────────
  int get totalOrders => orders.length;
  double get totalPurchaseMTD =>
      orders.fold(0, (s, o) => s + o.amount);
  double get totalAmountPaid => orders
      .where((o) => o.status == PurchaseStatus.received)
      .fold(0, (s, o) => s + o.amount);
  double get totalAmountDue => orders
      .where((o) =>
          o.status == PurchaseStatus.pending ||
          o.status == PurchaseStatus.partial)
      .fold(0, (s, o) => s + o.amount);
  int get itemsReceivedMTD => orders
      .where((o) => o.status == PurchaseStatus.received)
      .fold(0, (s, o) => s + o.itemCount);

  // ── Seed data (from screenshot) ──────────────────────────────
  static final List<PurchaseOrder> _seed = [
    PurchaseOrder(
      id: 'po_01', poNumber: 'PO-2024-00128',
      supplier: 'Arvind Enterprises',     supplierIcon: 'AE',
      date: DateTime(2024, 5, 5), itemCount: 12, amount: 45600,
      status: PurchaseStatus.received,
    ),
    PurchaseOrder(
      id: 'po_02', poNumber: 'PO-2024-00127',
      supplier: 'Shree Ram Traders',      supplierIcon: 'SR',
      date: DateTime(2024, 5, 4), itemCount: 8, amount: 28750,
      status: PurchaseStatus.partial,
    ),
    PurchaseOrder(
      id: 'po_03', poNumber: 'PO-2024-00126',
      supplier: 'Jai Mata Di Suppliers',  supplierIcon: 'JM',
      date: DateTime(2024, 5, 3), itemCount: 15, amount: 67890,
      status: PurchaseStatus.pending,
    ),
    PurchaseOrder(
      id: 'po_04', poNumber: 'PO-2024-00125',
      supplier: 'Gupta Hardware',         supplierIcon: 'GH',
      date: DateTime(2024, 5, 2), itemCount: 10, amount: 32400,
      status: PurchaseStatus.received,
    ),
    PurchaseOrder(
      id: 'po_05', poNumber: 'PO-2024-00124',
      supplier: 'National Insulation Co.',supplierIcon: 'NI',
      date: DateTime(2024, 5, 1), itemCount: 20, amount: 85200,
      status: PurchaseStatus.pending,
    ),
    PurchaseOrder(
      id: 'po_06', poNumber: 'PO-2024-00123',
      supplier: 'Thermo Materials Pvt. Ltd.', supplierIcon: 'TM',
      date: DateTime(2024, 4, 30), itemCount: 6, amount: 21300,
      status: PurchaseStatus.cancelled,
    ),
    PurchaseOrder(
      id: 'po_07', poNumber: 'PO-2024-00122',
      supplier: 'Buildwell Supply',       supplierIcon: 'BS',
      date: DateTime(2024, 4, 29), itemCount: 9, amount: 36800,
      status: PurchaseStatus.partial,
    ),
    PurchaseOrder(
      id: 'po_08', poNumber: 'PO-2024-00121',
      supplier: 'Om Sai Traders',         supplierIcon: 'OS',
      date: DateTime(2024, 4, 28), itemCount: 11, amount: 41600,
      status: PurchaseStatus.received,
    ),
    PurchaseOrder(
      id: 'po_09', poNumber: 'PO-2024-00120',
      supplier: 'Shakti Enterprises',     supplierIcon: 'SE',
      date: DateTime(2024, 4, 27), itemCount: 7, amount: 25460,
      status: PurchaseStatus.pending,
    ),
    PurchaseOrder(
      id: 'po_10', poNumber: 'PO-2024-00119',
      supplier: 'Lakshmi Industries',     supplierIcon: 'LI',
      date: DateTime(2024, 4, 26), itemCount: 14, amount: 49750,
      status: PurchaseStatus.received,
    ),
    PurchaseOrder(
      id: 'po_11', poNumber: 'PO-2024-00118',
      supplier: 'Rajesh & Sons',          supplierIcon: 'RS',
      date: DateTime(2024, 4, 25), itemCount: 5, amount: 18900,
      status: PurchaseStatus.received,
    ),
    PurchaseOrder(
      id: 'po_12', poNumber: 'PO-2024-00117',
      supplier: 'Patel Suppliers',        supplierIcon: 'PS',
      date: DateTime(2024, 4, 24), itemCount: 16, amount: 72300,
      status: PurchaseStatus.pending,
    ),
    PurchaseOrder(
      id: 'po_13', poNumber: 'PO-2024-00116',
      supplier: 'Bharat Traders',         supplierIcon: 'BT',
      date: DateTime(2024, 4, 23), itemCount: 3, amount: 14200,
      status: PurchaseStatus.received,
    ),
    PurchaseOrder(
      id: 'po_14', poNumber: 'PO-2024-00115',
      supplier: 'Vimal Enterprises',      supplierIcon: 'VE',
      date: DateTime(2024, 4, 22), itemCount: 18, amount: 93400,
      status: PurchaseStatus.partial,
    ),
    PurchaseOrder(
      id: 'po_15', poNumber: 'PO-2024-00114',
      supplier: 'Sriram Industries',      supplierIcon: 'SI',
      date: DateTime(2024, 4, 21), itemCount: 22, amount: 1,
      status: PurchaseStatus.pending,
    ),
    // ... more orders
    for (int i = 16; i <= 28; i++)
      PurchaseOrder(
        id: 'po_$i', poNumber: 'PO-2024-00${128 - i + 1}',
        supplier: 'Supplier ${129 - i}',  supplierIcon: 'S${129 - i}',
        date: DateTime(2024, 4, 20 - (i - 16)), itemCount: i % 10 + 3,
        amount: (i * 3450.0),
        status: PurchaseStatus.values[i % 4],
      ),
  ];

  @override
  void onInit() {
    super.onInit();
    orders.addAll(_seed);
    // Fix the wrong amount for po_15
    final idx = orders.indexWhere((o) => o.id == 'po_15');
    if (idx != -1) {
      orders[idx] = PurchaseOrder(
        id: 'po_15', poNumber: 'PO-2024-00114',
        supplier: 'Sriram Industries', supplierIcon: 'SI',
        date: DateTime(2024, 4, 21), itemCount: 22, amount: 1,
        status: PurchaseStatus.pending,
      );
    }
  }

  // ── CRUD ─────────────────────────────────────────────────────
  void addOrder(PurchaseOrder order) => orders.insert(0, order);
  void deleteOrder(String id) => orders.removeWhere((o) => o.id == id);
  void updateStatus(String id, PurchaseStatus status) {
    final idx = orders.indexWhere((o) => o.id == id);
    if (idx == -1) return;
    final o = orders[idx];
    orders[idx] = PurchaseOrder(
      id: o.id, poNumber: o.poNumber, supplier: o.supplier,
      supplierIcon: o.supplierIcon, date: o.date, itemCount: o.itemCount,
      amount: o.amount, status: status,
    );
    orders.refresh();
  }
}

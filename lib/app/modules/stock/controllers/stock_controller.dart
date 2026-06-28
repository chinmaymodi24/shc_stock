import 'package:get/get.dart';
import '../models/stock_item_model.dart';

class StockController extends GetxController {
  final RxList<StockItemModel> items = <StockItemModel>[].obs;

  static final _seed = [
    const StockItemModel(id:'1',  code:'CER-BULK-001',  sku:'SBF-001',       name:'Standard Bulk Fiber',            category:'Ceramic Fiber Bulk',      unit:'Kg',    stockInHand:2450, availableStock:2300, stockValue:122500, status:StockStatus.inStock),
    const StockItemModel(id:'2',  code:'CER-BLNK-002',  sku:'CFB-1260-25',   name:'1260°C Ceramic Fiber Blanket',   category:'Ceramic Fiber Blanket',    unit:'Roll',  stockInHand:120,  availableStock:85,   stockValue:240000, status:StockStatus.lowStock),
    const StockItemModel(id:'3',  code:'CER-BRD-003',   sku:'HPB-50',        name:'High Purity Board 50mm',         category:'Ceramic Fiber Board',      unit:'Piece', stockInHand:75,   availableStock:60,   stockValue:187500, status:StockStatus.inStock),
    const StockItemModel(id:'4',  code:'CER-PPR-004',   sku:'CFP-3MM',       name:'Ceramic Fiber Paper 3mm',        category:'Ceramic Fiber Paper',      unit:'Roll',  stockInHand:0,    availableStock:0,    stockValue:0,      status:StockStatus.outOfStock),
    const StockItemModel(id:'5',  code:'CER-ROP-005',   sku:'CTR-10MM',      name:'Twisted Rope 10mm',              category:'Ceramic Fiber Rope',       unit:'Meter', stockInHand:350,  availableStock:320,  stockValue:35000,  status:StockStatus.inStock),
    const StockItemModel(id:'6',  code:'CER-TAP-006',   sku:'CFT-50MM',      name:'Ceramic Fiber Tape 50mm',        category:'Ceramic Fiber Textiles',   unit:'Roll',  stockInHand:28,   availableStock:15,   stockValue:8400,   status:StockStatus.lowStock),
    const StockItemModel(id:'7',  code:'CER-CLT-007',   sku:'CFC-2MM',       name:'Ceramic Fiber Cloth 2mm',        category:'Ceramic Fiber Textiles',   unit:'Meter', stockInHand:150,  availableStock:150,  stockValue:22500,  status:StockStatus.inStock),
    const StockItemModel(id:'8',  code:'CER-YRN-008',   sku:'CFY-YG',        name:'Ceramic Fiber Yarn',             category:'Ceramic Fiber Textiles',   unit:'Kg',    stockInHand:18,   availableStock:10,   stockValue:9900,   status:StockStatus.lowStock),
    const StockItemModel(id:'9',  code:'CER-BLNK-009',  sku:'CFB-1430-35',   name:'1430°C Ceramic Fiber Blanket',   category:'Ceramic Fiber Blanket',    unit:'Roll',  stockInHand:45,   availableStock:45,   stockValue:135000, status:StockStatus.inStock),
    const StockItemModel(id:'10', code:'CER-BRD-010',   sku:'ZB-25',         name:'Zirconia Board 25mm',            category:'Ceramic Fiber Board',      unit:'Piece', stockInHand:12,   availableStock:5,    stockValue:15600,  status:StockStatus.lowStock),
    const StockItemModel(id:'11', code:'CER-WOL-011',   sku:'CFW-BLK',       name:'Ceramic Fiber Wool Bulk',        category:'Ceramic Fiber Bulk',       unit:'Kg',    stockInHand:500,  availableStock:500,  stockValue:75000,  status:StockStatus.inStock),
    const StockItemModel(id:'12', code:'CER-BLN-012',   sku:'RB-25MM',       name:'Refractory Blanket 25mm',        category:'Ceramic Fiber Blanket',    unit:'Roll',  stockInHand:0,    availableStock:0,    stockValue:0,      status:StockStatus.outOfStock),
    const StockItemModel(id:'13', code:'CER-BRD-013',   sku:'AFB-25',        name:'Alumina Fiber Board 25mm',       category:'Ceramic Fiber Board',      unit:'Piece', stockInHand:8,    availableStock:3,    stockValue:48000,  status:StockStatus.lowStock),
    const StockItemModel(id:'14', code:'CER-MOD-014',   sku:'CFM-128',       name:'Ceramic Fiber Module',           category:'Ceramic Fiber Bulk',       unit:'Piece', stockInHand:200,  availableStock:200,  stockValue:180000, status:StockStatus.inStock),
    const StockItemModel(id:'15', code:'CER-ROP-015',   sku:'IR-20MM',       name:'Insulation Rope 20mm',           category:'Ceramic Fiber Rope',       unit:'Meter', stockInHand:0,    availableStock:0,    stockValue:0,      status:StockStatus.outOfStock),
    const StockItemModel(id:'16', code:'CER-PPR-016',   sku:'CFP-6MM',       name:'Ceramic Fiber Paper 6mm',        category:'Ceramic Fiber Paper',      unit:'Roll',  stockInHand:60,   availableStock:60,   stockValue:42000,  status:StockStatus.inStock),
    const StockItemModel(id:'17', code:'CER-TAP-017',   sku:'CFT-25MM',      name:'Ceramic Fiber Tape 25mm',        category:'Ceramic Fiber Textiles',   unit:'Roll',  stockInHand:95,   availableStock:95,   stockValue:28500,  status:StockStatus.inStock),
    const StockItemModel(id:'18', code:'CER-BLNK-018',  sku:'CFB-1260-50',   name:'1260°C Blanket 50mm Thick',      category:'Ceramic Fiber Blanket',    unit:'Roll',  stockInHand:200,  availableStock:200,  stockValue:420000, status:StockStatus.inStock),
    const StockItemModel(id:'19', code:'CER-ROP-019',   sku:'CTR-6MM',       name:'Twisted Rope 6mm',               category:'Ceramic Fiber Rope',       unit:'Meter', stockInHand:22,   availableStock:10,   stockValue:3300,   status:StockStatus.lowStock),
    const StockItemModel(id:'20', code:'CER-BRD-020',   sku:'RCB-50',        name:'Recrystallized Ceramic Board',   category:'Ceramic Fiber Board',      unit:'Piece', stockInHand:40,   availableStock:40,   stockValue:96000,  status:StockStatus.inStock),
  ];

  @override
  void onInit() {
    super.onInit();
    items.addAll(_seed);
  }

  int get totalItems     => items.length;
  int get inStockCount   => items.where((i) => i.status == StockStatus.inStock).length;
  int get lowStockCount  => items.where((i) => i.status == StockStatus.lowStock).length;
  int get outOfStockCount=> items.where((i) => i.status == StockStatus.outOfStock).length;
  int get inactiveCount  => items.where((i) => i.status == StockStatus.inactive).length;
  int get totalQty       => items.fold(0, (s, i) => s + i.stockInHand);
  double get totalValue  => items.fold(0.0, (s, i) => s + i.stockValue);

  List<String> get categories => ['All Categories', ...items.map((i) => i.category).toSet().toList()..sort()];
  List<String> get units      => ['All Units', ...items.map((i) => i.unit).toSet().toList()..sort()];
}

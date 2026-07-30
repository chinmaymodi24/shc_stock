import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/transaction_model.dart';

class TransactionsController extends GetxController {
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final searchCtrl = TextEditingController();
  final RxString search = ''.obs;
  final RxSet<String> typeFilters = <String>{}.obs;
  final RxSet<String> statusFilters = <String>{}.obs;
  final RxString sortOption = 'Default'.obs;
  final RxInt rowsPerPage = 10.obs;
  final RxInt currentPage = 1.obs;

  static const List<String> sortOptions = [
    'Default',
    'Item Name (A-Z)',
    'Item Name (Z-A)',
    'Date: Newest First',
    'Date: Oldest First',
  ];

  static final _seed = [
    TransactionModel(
      id: '1',
      item: 'Copper Pipe 15mm',
      type: TransactionType.inbound,
      party: 'Ashoka Metals',
      poNumber: '#4421',
      date: DateTime(2026, 7, 10),
      status: TransactionStatus.received,
      modifiedBy: 'Chinmay Modi',
      modifiedAt: DateTime(2026, 7, 10, 14, 40),
    ),
    TransactionModel(
      id: '2',
      item: 'PEX Fitting Kit',
      type: TransactionType.outbound,
      party: 'Patel Plumbing Co.',
      poNumber: '#4419',
      date: DateTime(2026, 7, 10),
      status: TransactionStatus.shipped,
      modifiedBy: 'Riya Patel',
      modifiedAt: DateTime(2026, 7, 10, 11, 5),
    ),
    TransactionModel(
      id: '3',
      item: 'Water Heater Coil',
      type: TransactionType.inbound,
      party: 'ThermoTech Industries',
      poNumber: '#4425',
      date: DateTime(2026, 7, 9),
      status: TransactionStatus.pending,
      modifiedBy: 'Chinmay Modi',
      modifiedAt: DateTime(2026, 7, 9, 9, 30),
    ),
    TransactionModel(
      id: '4',
      item: 'Brass Valve 3/4"',
      type: TransactionType.outbound,
      party: 'Shah Hardware',
      poNumber: '#4408',
      date: DateTime(2026, 7, 8),
      status: TransactionStatus.delivered,
      modifiedBy: 'Riya Patel',
      modifiedAt: DateTime(2026, 7, 8, 16, 12),
    ),
    TransactionModel(
      id: '5',
      item: 'Insulation Tape',
      type: TransactionType.inbound,
      party: 'Gujarat Polymers',
      poNumber: '#4402',
      date: DateTime(2026, 7, 6),
      status: TransactionStatus.received,
      modifiedBy: 'Chinmay Modi',
      modifiedAt: DateTime(2026, 7, 6, 13, 47),
    ),
    TransactionModel(
      id: '6',
      item: 'Ball Valve 1"',
      type: TransactionType.outbound,
      party: 'Mehta Constructions',
      poNumber: '#4396',
      date: DateTime(2026, 7, 4),
      status: TransactionStatus.delivered,
      modifiedBy: 'Riya Patel',
      modifiedAt: DateTime(2026, 7, 4, 10, 58),
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    transactions.addAll(_seed);
  }

  // Monthly summary totals (independent of the seed rows shown in the table).
  int get totalThisMonth => 312;
  int get inboundCount => 178;
  int get outboundCount => 134;
  int get pendingCount => 9;

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }
}

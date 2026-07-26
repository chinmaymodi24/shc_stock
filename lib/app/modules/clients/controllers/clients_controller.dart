import 'package:get/get.dart';
import '../data/clients_seed_data.dart';
import '../models/client_model.dart';

class ClientsController extends GetxController {
  final RxList<ClientModel> clients = <ClientModel>[].obs;
  final RxString searchQuery = ''.obs;
  final RxInt rowsPerPage = 10.obs;
  final RxInt currentPage = 1.obs;

  @override
  void onInit() {
    super.onInit();
    clients.addAll(kClientsSeedData);
  }

  // ── Computed stats ────────────────────────────────────────────────────────
  int get totalClients => clients.length;

  int get registeredClients =>
      clients.where((c) => c.registrationType == 'Regular').length;

  int get unregisteredClients => clients.length - registeredClients;

  int get statesCovered =>
      clients.map((c) => c.state).where((s) => s.isNotEmpty).toSet().length;

  List<MapEntry<String, int>> get topStates {
    final byState = <String, int>{};
    for (final c in clients) {
      if (c.state.isEmpty) continue;
      byState[c.state] = (byState[c.state] ?? 0) + 1;
    }
    final entries = byState.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }
}

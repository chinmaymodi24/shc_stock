import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/users/models/user_model.dart';

class UsersController extends GetxController {
  final _api = ApiClient.instance;

  final RxList<UserModel> users = <UserModel>[].obs;
  final RxBool isLoading = false.obs;

  /// Summary cards — values and trends from GET /api/stats/users.
  final stats = StatsSnapshot.empty.obs;
  final RxList<RoleCount> roleCounts = <RoleCount>[].obs;
  final searchCtrl = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxString filterRole = 'All Roles'.obs;
  final RxString filterStatus = 'All Status'.obs;
  final RxInt rowsPerPage = 10.obs;
  final RxInt currentPage = 1.obs;

  bool get hasActiveFilters =>
      searchQuery.value.isNotEmpty ||
      filterRole.value != 'All Roles' ||
      filterStatus.value != 'All Status';

  void resetFilters() {
    searchCtrl.clear();
    searchQuery.value = '';
    filterRole.value = 'All Roles';
    filterStatus.value = 'All Status';
    currentPage.value = 1;
  }

  // ── RETIRED: badge palette + static seed ──────────────────────────────
  // The old 10-color palette and 15-employee seed list are archived in
  // static_data.txt at the project root. Employees now come from
  // GET /api/users, and badge colors are derived from the employee name.
  // ───────────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    // Fetch-once: registered permanent, so re-entering the Employee route
    // reuses the loaded list instead of refetching.
    fetchUsers();
    fetchStats();
  }

  void _showError(String message) {
    showAppToast(
      'Error',
      message,
      backgroundColor: const Color(0xFFEF4444),
      colorText: Colors.white,
    );
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────
  Future<void> fetchUsers() async {
    isLoading.value = true;
    try {
      final data = await _api.get('/users') as List<dynamic>;
      users.assignAll(
        data.map((e) => UserModel.fromJson(e as Map<String, dynamic>)),
      );
      _clampPage();
    } catch (e) {
      _showError('Failed to load employees. Is the backend running?');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStats() async {
    try {
      final json = await _api.get('/stats/users') as Map<String, dynamic>;
      stats.value = StatsSnapshot.fromJson(json);
      roleCounts.assignAll(
        ((json['roleBreakdown'] as List?) ?? []).map(
          (e) => RoleCount.fromJson(e as Map<String, dynamic>),
        ),
      );
    } catch (e) {
      // Cards fall back to zeros; the list fetch already reported any outage.
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Creates an employee. The backend assigns the USR-#### code and hashes a
  /// starter password. Returns the saved row, or null on failure.
  Future<UserModel?> addUser(Map<String, dynamic> body) async {
    try {
      final json = await _api.post('/users', body);
      final created = UserModel.fromJson(json as Map<String, dynamic>);
      users.add(created);
      await fetchStats();
      return created;
    } catch (e) {
      _showError(e is ApiException ? e.message : 'Failed to add employee.');
      return null;
    }
  }

  Future<UserModel?> updateUser(String id, Map<String, dynamic> body) async {
    try {
      final json = await _api.put('/users/$id', body);
      final updated = UserModel.fromJson(json as Map<String, dynamic>);
      // Last modified first: move the edited row back to the top.
      final idx = users.indexWhere((u) => u.id == id);
      if (idx != -1) {
        users.removeAt(idx);
        users.insert(0, updated);
      }
      await fetchStats();
      return updated;
    } catch (e) {
      _showError(e is ApiException ? e.message : 'Failed to update employee.');
      return null;
    }
  }

  /// Activate / deactivate without touching anything else.
  Future<void> setActive(String id, bool isActive) async {
    try {
      final json = await _api.patch('/users/$id/status', {
        'isActive': isActive,
      });
      final updated = UserModel.fromJson(json as Map<String, dynamic>);
      // Last modified first: move the edited row back to the top.
      final idx = users.indexWhere((u) => u.id == id);
      if (idx != -1) {
        users.removeAt(idx);
        users.insert(0, updated);
      }
      await fetchStats();
    } catch (e) {
      _showError(e is ApiException ? e.message : 'Failed to update status.');
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _api.delete('/users/$id');
      users.removeWhere((u) => u.id == id);
      _clampPage();
      await fetchStats();
    } catch (e) {
      // e.g. refusing to delete the last Admin comes back as a 409.
      _showError(e is ApiException ? e.message : 'Failed to delete employee.');
    }
  }

  void _clampPage() {
    final pages = users.isEmpty ? 1 : (users.length / rowsPerPage.value).ceil();
    if (currentPage.value > pages) currentPage.value = pages;
  }

  // ── Summary cards — served by GET /api/stats/users ────────────────────────
  int get totalUsers => stats.value.intOf('totalUsers');
  int get activeUsers => stats.value.intOf('activeUsers');
  int get inactiveUsers => stats.value.intOf('inactiveUsers');
  int get adminCount => stats.value.intOf('adminCount');

  /// Count of users per role, from the API.
  Map<UserRole, int> get roleBreakdown {
    final map = {for (final r in UserRole.values) r: 0};
    for (final rc in roleCounts) {
      map[userRoleFromLabel(rc.role)] = rc.count;
    }
    return map;
  }

  /// 5 most recently active users
  List<UserModel> get recentlyActive {
    final active = users.where((u) => u.isActive).toList();
    return active.take(5).toList();
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }
}

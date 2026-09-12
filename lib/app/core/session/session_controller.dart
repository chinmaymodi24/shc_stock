import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/routes/app_routes.dart';

/// What one employee may do in one module or Settings tab.
///
/// [summary] is the right to see the figures at the top of a page (the stat
/// cards, the dashboard KPIs and charts). It is separate from [read] so
/// someone can do their job on a page — say, stock entry on Inventory —
/// without learning how the whole business is doing.
class ModuleAccess {
  final bool read;
  final bool write;
  final bool summary;
  const ModuleAccess({
    this.read = false,
    this.write = false,
    this.summary = false,
  });

  static const none = ModuleAccess();
  static const full = ModuleAccess(read: true, write: true, summary: true);

  /// Write and summary mean nothing without read, so read is implied by
  /// either — the same rule the backend applies when it stores a map.
  factory ModuleAccess.fromJson(Map<String, dynamic> json) {
    final write = json['write'] == true;
    final summary = json['summary'] == true;
    return ModuleAccess(
      read: json['read'] == true || write || summary,
      write: write,
      summary: summary,
    );
  }

  Map<String, dynamic> toJson() => {
    'read': read,
    'write': write,
    'summary': summary,
  };
}

/// The signed-in user.
class SessionUser {
  final int id;
  final String code;
  final String name;
  final String email;

  /// Display name of the assigned role, e.g. "Store Staff".
  final String role;
  final int? roleId;
  final String phone;
  final String department;

  /// Holds every permission regardless of [permissions].
  final bool isSuperAdmin;

  /// Signed session token sent with every API request.
  final String token;

  /// Permission key (a module name, or "Settings: Billing" for a tab) → what this user may
  /// do there.
  final Map<String, ModuleAccess> permissions;

  const SessionUser({
    required this.id,
    required this.name,
    required this.email,
    this.code = '',
    this.role = '',
    this.roleId,
    this.phone = '',
    this.department = '',
    this.isSuperAdmin = false,
    this.token = '',
    this.permissions = const {},
  });

  ModuleAccess accessTo(String key) => permissions[key] ?? ModuleAccess.none;

  bool canRead(String key) => isSuperAdmin || accessTo(key).read;
  bool canWrite(String key) => isSuperAdmin || accessTo(key).write;
  bool canSummary(String key) => isSuperAdmin || accessTo(key).summary;

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'];
    final perms = <String, ModuleAccess>{};
    if (rawPerms is Map) {
      rawPerms.forEach((key, value) {
        if (value is Map) {
          perms[key.toString()] = ModuleAccess.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      });
    }
    return SessionUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      roleId: (json['roleId'] as num?)?.toInt(),
      phone: json['phone'] as String? ?? '',
      department: json['department'] as String? ?? '',
      isSuperAdmin: json['isSuperAdmin'] == true,
      token: json['token'] as String? ?? '',
      permissions: perms,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'email': email,
    'role': role,
    'roleId': roleId,
    'phone': phone,
    'department': department,
    'isSuperAdmin': isSuperAdmin,
    'token': token,
    'permissions': permissions.map((k, v) => MapEntry(k, v.toJson())),
  };

  /// Same session with edited profile fields — what Settings › Profile saves.
  SessionUser copyWithProfile({String? name, String? email, String? phone}) =>
      SessionUser(
        id: id,
        code: code,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role,
        roleId: roleId,
        phone: phone ?? this.phone,
        department: department,
        isSuperAdmin: isSuperAdmin,
        token: token,
        permissions: permissions,
      );

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length < 2 ? 1 : 2).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

/// Holds whoever is signed in, restored from disk on startup.
///
/// Read across the app for the top bar's avatar/name, `modifiedBy` on every
/// write, and every permission check (sidebar, routes, buttons, summary
/// cards, Settings tabs).
class SessionController extends GetxController {
  static const _key = 'session_user';

  final user = Rxn<SessionUser>();

  /// Whether the session is written to disk ("Remember me").
  bool _persist = true;

  bool get isSignedIn => user.value != null;

  /// Completes once [restore] has finished on startup — the splash screen
  /// awaits this before deciding between the login page and the dashboard.
  Future<void>? _restoreFuture;
  Future<void> get ready => _restoreFuture ?? Future.value();

  /// Name to stamp on writes. Falls back to 'Admin' — the same default the
  /// backend uses — rather than inventing a person.
  String get actorName => user.value?.name.trim().isNotEmpty == true
      ? user.value!.name.trim()
      : 'Admin';

  bool get isSuperAdmin => user.value?.isSuperAdmin ?? false;

  /// Signed out reads as "no access" rather than "everything" — every check
  /// fails closed.
  bool canRead(String key) => user.value?.canRead(key) ?? false;
  bool canWrite(String key) => user.value?.canWrite(key) ?? false;
  bool canSummary(String key) => user.value?.canSummary(key) ?? false;

  @override
  void onInit() {
    super.onInit();
    ApiClient.instance.tokenProvider = () => user.value?.token;
    ApiClient.instance.onUnauthorized = _onSessionRejected;
    _restoreFuture = restore();
  }

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final saved = SessionUser.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      // Saved before sessions carried a token — the backend would reject
      // every call, so start again from the login page.
      if (saved.token.isEmpty) {
        await prefs.remove(_key);
        return;
      }
      user.value = saved;
      await refreshFromServer();
    } catch (_) {
      // A corrupt blob just means "signed out"; never block startup.
    }
  }

  /// Re-reads the signed-in employee from `/api/auth/me`, so a remembered
  /// session picks up permission changes made since it was saved (and gets a
  /// fresh token). An unreachable backend keeps the saved session; a rejected
  /// one has already signed out through [_onSessionRejected].
  Future<void> refreshFromServer() async {
    if (user.value == null) return;
    try {
      final json = await ApiClient.instance.get('/auth/me');
      if (json is Map<String, dynamic>) {
        await _store(SessionUser.fromJson(json));
      }
    } catch (_) {}
  }

  /// [persist] mirrors the login page's "Remember me" checkbox: when true the
  /// session is written to disk so the next app launch skips the login page;
  /// when false it lives only for this run and any stored session is cleared.
  Future<void> signIn(
    Map<String, dynamic> loginResponse, {
    bool persist = true,
  }) async {
    _persist = persist;
    await _store(SessionUser.fromJson(loginResponse));
  }

  /// Keeps the top bar in step after Settings › Profile saves, without
  /// touching the token or the permissions.
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    final current = user.value;
    if (current == null) return;
    await _store(
      current.copyWithProfile(name: name, email: email, phone: phone),
    );
  }

  Future<void> _store(SessionUser u) async {
    user.value = u;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_persist) {
        await prefs.setString(_key, jsonEncode(u.toJson()));
      } else {
        await prefs.remove(_key);
      }
    } catch (_) {}
  }

  Future<void> signOut() async {
    user.value = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }

  bool _redirecting = false;

  /// The backend no longer accepts this session. Several requests usually
  /// fail together, so only the first one routes to the login page.
  Future<void> _onSessionRejected() async {
    if (user.value == null || _redirecting) return;
    _redirecting = true;
    await signOut();
    if (Get.currentRoute != AppRoutes.login &&
        Get.currentRoute != AppRoutes.splash) {
      Get.offAllNamed(AppRoutes.login);
    }
    _redirecting = false;
  }
}

/// Convenience for controllers stamping audit fields on a write.
String get currentActorName => Get.isRegistered<SessionController>()
    ? Get.find<SessionController>().actorName
    : 'Admin';

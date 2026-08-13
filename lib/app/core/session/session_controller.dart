import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The signed-in user.
class SessionUser {
  final int id;
  final String name;
  final String email;
  final String role;

  const SessionUser({
    required this.id,
    required this.name,
    required this.email,
    this.role = '',
  });

  factory SessionUser.fromJson(Map<String, dynamic> json) => SessionUser(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: json['role'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
  };

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
/// Two things across the app read this instead of a hardcoded name: the top
/// bar's avatar/name, and `modifiedBy` on every write — so audit columns
/// record the person who actually made the change.
class SessionController extends GetxController {
  static const _key = 'session_user';

  final user = Rxn<SessionUser>();

  bool get isSignedIn => user.value != null;

  /// Name to stamp on writes. Falls back to 'Admin' — the same default the
  /// backend uses — rather than inventing a person.
  String get actorName => user.value?.name.trim().isNotEmpty == true
      ? user.value!.name.trim()
      : 'Admin';

  @override
  void onInit() {
    super.onInit();
    restore();
  }

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      user.value = SessionUser.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      // A corrupt blob just means "signed out"; never block startup.
    }
  }

  Future<void> signIn(Map<String, dynamic> loginResponse) async {
    final u = SessionUser.fromJson(loginResponse);
    user.value = u;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(u.toJson()));
    } catch (_) {}
  }

  Future<void> signOut() async {
    user.value = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}

/// Convenience for controllers stamping audit fields on a write.
String get currentActorName => Get.isRegistered<SessionController>()
    ? Get.find<SessionController>().actorName
    : 'Admin';

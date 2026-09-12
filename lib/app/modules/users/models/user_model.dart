import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/users/models/role_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// User Model
// ─────────────────────────────────────────────────────────────────────────────
class UserModel {
  final String id;
  final String code; // USR-0001
  final String name;
  final String initials;
  final Color badgeColor;
  final String email;
  final String phone;

  /// The assigned role as the list shows it — name, colour and icon.
  final RoleBadge role;
  final bool isActive;
  final String lastLogin; // formatted string
  final String createdAt; // formatted string
  final String department;
  final String modifiedBy;
  final DateTime? modifiedAt;

  /// Module name → {read, write}, straight off the API. Carried so re-opening
  /// an employee in the wizard shows the access they actually have; without
  /// it, editing anyone silently reset their permissions to the defaults.
  final Map<String, ModuleAccess> permissions;

  const UserModel({
    required this.id,
    required this.code,
    required this.name,
    required this.initials,
    required this.badgeColor,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.lastLogin,
    required this.createdAt,
    this.department = '',
    this.modifiedBy = 'Admin',
    this.modifiedAt,
    this.permissions = const {},
  });

  /// Maps a row from GET /api/users. `passwordHash` is never sent by the API.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    DateTime? date(String key) {
      final v = json[key];
      return v == null ? null : DateTime.tryParse(v as String);
    }

    return UserModel(
      id: json['id'].toString(),
      code: json['code'] as String? ?? '',
      name: name,
      initials: _initialsOf(name),
      badgeColor: _badgeColorOf(name),
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: _roleOf(json),
      isActive: json['isActive'] as bool? ?? true,
      lastLogin: _formatDateTime(date('lastLoginAt')),
      createdAt: _formatDate(date('createdAt')),
      department: json['department'] as String? ?? '',
      modifiedBy: json['modifiedBy'] as String? ?? 'Admin',
      modifiedAt: date('modifiedAt'),
      permissions: _permissionsOf(json['permissions']),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role.label,
    'roleId': role.id,
    'department': department,
    'isActive': isActive,
    'modifiedBy': modifiedBy,
  };
}

/// The role badge for an API row — from the linked role when there is one,
/// otherwise just the stored label (a role since deleted).
RoleBadge _roleOf(Map<String, dynamic> json) {
  final ref = json['roleRef'];
  if (ref is Map) {
    return RoleBadge(
      id: (ref['id'] as num?)?.toInt(),
      key: ref['key'] as String?,
      label: ref['name'] as String? ?? '',
      iconName: ref['icon'] as String? ?? 'custom',
      isSuperAdmin: ref['isSuperAdmin'] == true,
    );
  }
  return RoleBadge(label: json['role'] as String? ?? 'No role');
}

/// Reads the API's permissions blob. Anything unexpected (null, a list, a
/// malformed entry) degrades to "no access recorded" rather than throwing —
/// an employee row must never fail to parse over its permissions.
Map<String, ModuleAccess> _permissionsOf(Object? raw) {
  if (raw is! Map) return const {};
  final out = <String, ModuleAccess>{};
  raw.forEach((key, value) {
    if (value is Map) {
      out[key.toString()] = ModuleAccess.fromJson(
        Map<String, dynamic>.from(value),
      );
    }
  });
  return out;
}

// ── Display helpers ─────────────────────────────────────────────────────────

List<Color> get _badgeColors => [
  const Color(0xFFF47B20),
  appColors.accent,
  const Color(0xFF22C55E),
  const Color(0xFF0EA5E9),
  const Color(0xFFF59E0B),
  const Color(0xFFEF4444),
  const Color(0xFF8B5CF6),
  const Color(0xFF14B8A6),
  const Color(0xFFEC4899),
  const Color(0xFF6366F1),
];

Color _badgeColorOf(String name) =>
    _badgeColors[name.hashCode.abs() % _badgeColors.length];

String _initialsOf(String name) {
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

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime? d) {
  if (d == null) return '—';
  return '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';
}

String _formatDateTime(DateTime? d) {
  if (d == null) return 'Never';
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  return '${_formatDate(d)}, $hour12:${d.minute.toString().padLeft(2, '0')} $ampm';
}

/// One entry of the role breakdown from GET /api/stats/users.
class RoleCount {
  final String role;
  final int count;

  const RoleCount({required this.role, required this.count});

  factory RoleCount.fromJson(Map<String, dynamic> json) => RoleCount(
    role: json['role'] as String? ?? '',
    count: (json['count'] as num?)?.toInt() ?? 0,
  );
}

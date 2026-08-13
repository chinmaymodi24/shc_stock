import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Roles
// ─────────────────────────────────────────────────────────────────────────────
enum UserRole { admin, manager, salesman, stockManager, accountant }

/// Maps the API's role label back onto the enum. Unknown labels fall back to
/// salesman rather than throwing, so a role added server-side can't blank the
/// Employee list.
UserRole userRoleFromLabel(String label) => UserRole.values.firstWhere(
  (r) => r.label.toLowerCase() == label.trim().toLowerCase(),
  orElse: () => UserRole.salesman,
);

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.salesman:
        return 'Salesman';
      case UserRole.stockManager:
        return 'Stock Manager';
      case UserRole.accountant:
        return 'Accountant';
    }
  }

  Color get color {
    switch (this) {
      case UserRole.admin:
        return const Color(0xFFF47B20); // orange
      case UserRole.manager:
        return const Color(0xFF4A3AFF); // purple
      case UserRole.salesman:
        return const Color(0xFF22C55E); // green
      case UserRole.stockManager:
        return const Color(0xFF0EA5E9); // sky blue
      case UserRole.accountant:
        return const Color(0xFFF59E0B); // amber
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
      case UserRole.manager:
        return Icons.manage_accounts_outlined;
      case UserRole.salesman:
        return Icons.storefront_outlined;
      case UserRole.stockManager:
        return Icons.inventory_2_outlined;
      case UserRole.accountant:
        return Icons.account_balance_outlined;
    }
  }
}

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
  final UserRole role;
  final bool isActive;
  final String lastLogin; // formatted string
  final String createdAt; // formatted string
  final String department;
  final String modifiedBy;
  final DateTime? modifiedAt;

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
      role: userRoleFromLabel(json['role'] as String? ?? ''),
      isActive: json['isActive'] as bool? ?? true,
      lastLogin: _formatDateTime(date('lastLoginAt')),
      createdAt: _formatDate(date('createdAt')),
      department: json['department'] as String? ?? '',
      modifiedBy: json['modifiedBy'] as String? ?? 'Admin',
      modifiedAt: date('modifiedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role.label,
    'department': department,
    'isActive': isActive,
    'modifiedBy': modifiedBy,
  };
}

// ── Display helpers ─────────────────────────────────────────────────────────

const List<Color> _badgeColors = [
  Color(0xFFF47B20),
  Color(0xFF4A3AFF),
  Color(0xFF22C55E),
  Color(0xFF0EA5E9),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF8B5CF6),
  Color(0xFF14B8A6),
  Color(0xFFEC4899),
  Color(0xFF6366F1),
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

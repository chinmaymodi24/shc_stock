import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

/// Icon names a role can carry, as stored by the API.
const kRoleIconNames = [
  'stars',
  'admin',
  'manager',
  'sales',
  'store',
  'custom',
];

IconData roleIconFor(String name) {
  switch (name) {
    case 'stars':
      return Icons.stars_rounded;
    case 'admin':
      return Icons.admin_panel_settings_outlined;
    case 'manager':
      return Icons.manage_accounts_outlined;
    case 'sales':
      return Icons.point_of_sale_outlined;
    case 'store':
      return Icons.warehouse_outlined;
    default:
      return Icons.tune_rounded;
  }
}

/// Badge colour for a role. Ready-made roles keep a fixed colour each;
/// custom roles take one from a small palette by name, so the same role is
/// always the same colour.
Color roleColorFor({String? key, required String name}) {
  switch (key) {
    case 'super_admin':
      return const Color(0xFFF47B20);
    case 'admin':
      return const Color(0xFFEF4444);
    case 'manager':
      return appColors.accent;
    case 'sales':
      return const Color(0xFF22C55E);
    case 'store_staff':
      return const Color(0xFF0EA5E9);
  }
  const palette = [
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFFEC4899),
    Color(0xFF6366F1),
  ];
  return palette[name.hashCode.abs() % palette.length];
}

/// How an employee's role shows in the Employee list — a coloured label.
class RoleBadge {
  final int? id;

  /// Ready-made role id (super_admin, admin, …); null for a custom role.
  final String? key;
  final String label;
  final String iconName;
  final bool isSuperAdmin;

  const RoleBadge({
    this.id,
    this.key,
    required this.label,
    this.iconName = 'custom',
    this.isSuperAdmin = false,
  });

  Color get color => roleColorFor(key: key, name: label);
  IconData get icon => roleIconFor(iconName);
}

/// A role from GET /api/roles — a ready-made preset or a custom role.
class RoleModel {
  final int id;
  final String? key;
  final String name;
  final String description;
  final String iconName;
  final bool isSystem;
  final bool isSuperAdmin;
  final int userCount;
  final Map<String, ModuleAccess> permissions;

  const RoleModel({
    required this.id,
    this.key,
    required this.name,
    this.description = '',
    this.iconName = 'custom',
    this.isSystem = false,
    this.isSuperAdmin = false,
    this.userCount = 0,
    this.permissions = const {},
  });

  IconData get icon => roleIconFor(iconName);
  Color get color => roleColorFor(key: key, name: name);

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    final perms = <String, ModuleAccess>{};
    final raw = json['permissions'];
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is Map) {
          perms[k.toString()] = ModuleAccess.fromJson(
            Map<String, dynamic>.from(v),
          );
        }
      });
    }
    return RoleModel(
      id: (json['id'] as num).toInt(),
      key: json['key'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconName: json['icon'] as String? ?? 'custom',
      isSystem: json['isSystem'] == true,
      isSuperAdmin: json['isSuperAdmin'] == true,
      userCount: (json['userCount'] as num?)?.toInt() ?? 0,
      permissions: perms,
    );
  }
}

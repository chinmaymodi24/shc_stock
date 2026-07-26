import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Roles
// ─────────────────────────────────────────────────────────────────────────────
enum UserRole { admin, manager, salesman, stockManager, accountant }

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
}

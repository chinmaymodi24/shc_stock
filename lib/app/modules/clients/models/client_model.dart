import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Client Model
// ─────────────────────────────────────────────────────────────────────────────
class ClientModel {
  final String id;
  final String code;
  final String name;
  final String initials;
  final Color badgeColor;
  final String contactPerson;
  final String email;
  final String phone;
  final double outstanding;
  final double salesMTD;
  final bool isActive;

  const ClientModel({
    required this.id,
    required this.code,
    required this.name,
    required this.initials,
    required this.badgeColor,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.outstanding,
    required this.salesMTD,
    required this.isActive,
  });
}

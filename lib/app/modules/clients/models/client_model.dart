import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Client Model — backed by the company's universal client list.
// ─────────────────────────────────────────────────────────────────────────────
class ClientModel {
  final String id;
  final String code;
  final String name;
  final String address;
  final String state;
  final String country;
  final String registrationType;
  final String gstin;
  final String pan;
  final String modifiedBy;
  final DateTime? modifiedAt;

  const ClientModel({
    required this.id,
    required this.code,
    required this.name,
    required this.address,
    required this.state,
    required this.country,
    required this.registrationType,
    required this.gstin,
    required this.pan,
    this.modifiedBy = 'Admin',
    this.modifiedAt,
  });

  DateTime get effectiveModifiedAt => modifiedAt ?? DateTime.now();

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

  Color get badgeColor => _badgeColors[name.hashCode.abs() % _badgeColors.length];
}

const List<Color> _badgeColors = [
  Color(0xFF4A3AFF),
  Color(0xFFEF4444),
  Color(0xFF22C55E),
  Color(0xFFFF6B35),
  Color(0xFF0EA5E9),
  Color(0xFF14B8A6),
  Color(0xFF8B5CF6),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFF6366F1),
];

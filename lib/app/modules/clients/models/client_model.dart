import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Client Model — backed by the company's universal client list, served by
// GET /api/clients. Field names mirror the Prisma `Client` model.
// ─────────────────────────────────────────────────────────────────────────────
class ClientModel {
  final String id;
  final String code;
  final String name;
  final String clientType;
  final String registrationType;
  final String email;
  final String phone;
  final String altPhone;
  final String gstin;
  final String pan;
  final DateTime? clientSince;

  /// Free-text display address rendered in the clients list. Legacy rows from
  /// the accounting export only have this; rows added through the form get it
  /// composed server-side from the registered-address fields.
  final String address;
  final String regAddr1;
  final String regAddr2;
  final String regCity;
  final String regState;
  final String regPin;
  final String regCountry;

  final bool shipSameAsRegistered;
  final bool shipSameAsBilling;
  final String shipAddr1;
  final String shipAddr2;
  final String shipCity;
  final String shipState;
  final String shipPin;
  final String shipCountry;

  /// 'shipping' | 'registered' | 'custom'
  final String billingMode;
  final String billAddr1;
  final String billAddr2;
  final String billCity;
  final String billState;
  final String billPin;
  final String billCountry;

  final String paymentTerms;
  final String priceList;
  final double openingBalance;
  final double creditLimit;
  final int creditDays;

  final String contactPerson;
  final String contactDesignation;
  final String contactPhone;
  final String contactEmail;

  final String modifiedBy;
  final DateTime? modifiedAt;

  const ClientModel({
    required this.id,
    required this.code,
    required this.name,
    this.clientType = '',
    this.registrationType = 'Regular',
    this.email = '',
    this.phone = '',
    this.altPhone = '',
    this.gstin = '',
    this.pan = '',
    this.clientSince,
    this.address = '',
    this.regAddr1 = '',
    this.regAddr2 = '',
    this.regCity = '',
    this.regState = '',
    this.regPin = '',
    this.regCountry = 'India',
    this.shipSameAsRegistered = true,
    this.shipSameAsBilling = false,
    this.shipAddr1 = '',
    this.shipAddr2 = '',
    this.shipCity = '',
    this.shipState = '',
    this.shipPin = '',
    this.shipCountry = 'India',
    this.billingMode = 'shipping',
    this.billAddr1 = '',
    this.billAddr2 = '',
    this.billCity = '',
    this.billState = '',
    this.billPin = '',
    this.billCountry = 'India',
    this.paymentTerms = '',
    this.priceList = '',
    this.openingBalance = 0,
    this.creditLimit = 0,
    this.creditDays = 0,
    this.contactPerson = '',
    this.contactDesignation = '',
    this.contactPhone = '',
    this.contactEmail = '',
    this.modifiedBy = 'Admin',
    this.modifiedAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    String s(String key, [String fallback = '']) =>
        json[key] as String? ?? fallback;
    DateTime? date(String key) {
      final v = json[key];
      return v == null ? null : DateTime.tryParse(v as String);
    }

    return ClientModel(
      id: json['id'].toString(),
      code: s('code'),
      name: s('name'),
      clientType: s('clientType'),
      registrationType: s('registrationType', 'Regular'),
      email: s('email'),
      phone: s('phone'),
      altPhone: s('altPhone'),
      gstin: s('gstin'),
      pan: s('pan'),
      clientSince: date('clientSince'),
      address: s('address'),
      regAddr1: s('regAddr1'),
      regAddr2: s('regAddr2'),
      regCity: s('regCity'),
      regState: s('regState'),
      regPin: s('regPin'),
      regCountry: s('regCountry', 'India'),
      shipSameAsRegistered: json['shipSameAsRegistered'] as bool? ?? true,
      shipSameAsBilling: json['shipSameAsBilling'] as bool? ?? false,
      shipAddr1: s('shipAddr1'),
      shipAddr2: s('shipAddr2'),
      shipCity: s('shipCity'),
      shipState: s('shipState'),
      shipPin: s('shipPin'),
      shipCountry: s('shipCountry', 'India'),
      billingMode: s('billingMode', 'shipping'),
      billAddr1: s('billAddr1'),
      billAddr2: s('billAddr2'),
      billCity: s('billCity'),
      billState: s('billState'),
      billPin: s('billPin'),
      billCountry: s('billCountry', 'India'),
      paymentTerms: s('paymentTerms'),
      priceList: s('priceList'),
      openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0,
      creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
      creditDays: (json['creditDays'] as num?)?.toInt() ?? 0,
      contactPerson: s('contactPerson'),
      contactDesignation: s('contactDesignation'),
      contactPhone: s('contactPhone'),
      contactEmail: s('contactEmail'),
      modifiedBy: s('modifiedBy', 'Admin'),
      modifiedAt: date('modifiedAt'),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'clientType': clientType,
    'registrationType': registrationType,
    'email': email,
    'phone': phone,
    'altPhone': altPhone,
    'gstin': gstin,
    'pan': pan,
    'clientSince': clientSince?.toIso8601String(),
    'address': address,
    'regAddr1': regAddr1,
    'regAddr2': regAddr2,
    'regCity': regCity,
    'regState': regState,
    'regPin': regPin,
    'regCountry': regCountry,
    'shipSameAsRegistered': shipSameAsRegistered,
    'shipSameAsBilling': shipSameAsBilling,
    'shipAddr1': shipAddr1,
    'shipAddr2': shipAddr2,
    'shipCity': shipCity,
    'shipState': shipState,
    'shipPin': shipPin,
    'shipCountry': shipCountry,
    'billingMode': billingMode,
    'billAddr1': billAddr1,
    'billAddr2': billAddr2,
    'billCity': billCity,
    'billState': billState,
    'billPin': billPin,
    'billCountry': billCountry,
    'paymentTerms': paymentTerms,
    'priceList': priceList,
    'openingBalance': openingBalance,
    'creditLimit': creditLimit,
    'creditDays': creditDays,
    'contactPerson': contactPerson,
    'contactDesignation': contactDesignation,
    'contactPhone': contactPhone,
    'contactEmail': contactEmail,
    'modifiedBy': modifiedBy,
  };

  /// Top-level state used by the State filter and the Top States card.
  String get state => regState;

  String get country => regCountry;

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

  Color get badgeColor =>
      _badgeColors[name.hashCode.abs() % _badgeColors.length];

  /// Structured city when the client was added through the form; otherwise a
  /// best-effort parse out of the free-text [address] — legacy accounting rows
  /// follow a "…, City - PIN code, …" pattern and have no city column.
  /// Returns '' when nothing matches.
  String get city {
    if (regCity.trim().isNotEmpty) return regCity.trim();
    final match = RegExp(
      r'([A-Za-z][A-Za-z .]{1,30}?)\s*[-,]\s*(\d{6}|\d{3}\s?\d{3})',
    ).firstMatch(address);
    if (match == null) return '';
    var name = match.group(1)!.trim();
    name = name.replaceFirst(
      RegExp(r'^(Dist\.?|Tal\.?|Ta\.?|Nr\.?|Vill\.?)\s+', caseSensitive: false),
      '',
    );
    final parts = name.split(',');
    return parts.last.trim();
  }

  String get contactInitials {
    final parts = contactPerson
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length < 2 ? 1 : 2).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
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

/// A row of the "Top States" panel — served by GET /api/stats/clients.
class TopStateEntry {
  final String state;
  final int count;

  const TopStateEntry({required this.state, required this.count});

  factory TopStateEntry.fromJson(Map<String, dynamic> json) => TopStateEntry(
    state: json['state'] as String? ?? '',
    count: (json['count'] as num?)?.toInt() ?? 0,
  );
}

/// A row of the "New This Month" panel — clients whose `createdAt` falls in
/// the current calendar month, newest first. Previously this was just the
/// first four clients in the list, which had nothing to do with the month.
class NewClientEntry {
  final String id;
  final String code;
  final String name;
  final String state;

  const NewClientEntry({
    required this.id,
    required this.code,
    required this.name,
    this.state = '',
  });

  factory NewClientEntry.fromJson(Map<String, dynamic> json) => NewClientEntry(
    id: json['id'].toString(),
    code: json['code'] as String? ?? '',
    name: json['name'] as String? ?? '',
    state: json['state'] as String? ?? '',
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

  Color get badgeColor =>
      _badgeColors[name.hashCode.abs() % _badgeColors.length];
}

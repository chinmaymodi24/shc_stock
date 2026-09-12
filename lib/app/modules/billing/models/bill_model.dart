import 'package:flutter/material.dart';
import 'package:shc_stock/app/modules/billing/models/billing_profile.dart';

/// One entry of a bill's audit trail.
class BillEvent {
  final int id;

  /// generated | irn_received | sent_whatsapp | sent_email | payment_received
  /// | printed | downloaded
  final String type;
  final String note;
  final String actor;
  final DateTime at;

  const BillEvent({
    required this.id,
    required this.type,
    required this.actor,
    required this.at,
    this.note = '',
  });

  factory BillEvent.fromJson(Map<String, dynamic> json) => BillEvent(
    id: (json['id'] as num?)?.toInt() ?? 0,
    type: json['type'] as String? ?? '',
    note: json['note'] as String? ?? '',
    actor: json['actor'] as String? ?? 'Admin',
    at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
  );

  String get label => switch (type) {
    'generated' => 'Invoice generated',
    'irn_received' => 'IRN received from IRP',
    'sent_whatsapp' => 'Sent on WhatsApp',
    'sent_email' => 'Emailed to client',
    'payment_received' => 'Payment received',
    'printed' => 'Printed',
    'downloaded' => 'PDF downloaded',
    _ => type,
  };

  /// The dot beside the event. Reads from the theme's status colours rather
  /// than a per-event hex, so a rebrand moves them too.
  Color color(
    ColorScheme _, {
    required Color success,
    required Color info,
    required Color warning,
    required Color neutral,
  }) => switch (type) {
    'generated' => success,
    'irn_received' => info,
    'sent_whatsapp' || 'sent_email' => warning,
    'payment_received' => success,
    _ => neutral,
  };
}

/// The e-Invoice registration, when there is one.
///
/// There is no Invoice Registration Portal integration in this system, so in
/// practice [irn] is null and the invoice prints "Not registered". The fields
/// exist so that the day an IRP is wired up, nothing about the document has to
/// change — and so that nothing here ever invents a registration number.
class EInvoiceInfo {
  final String? irn;
  final String? ackNo;
  final DateTime? ackDate;

  const EInvoiceInfo({this.irn, this.ackNo, this.ackDate});

  bool get isRegistered => (irn ?? '').trim().isNotEmpty;

  factory EInvoiceInfo.fromJson(Map<String, dynamic> json) => EInvoiceInfo(
    irn: json['irn'] as String?,
    ackNo: json['ackNo'] as String?,
    ackDate: json['ackDate'] == null
        ? null
        : DateTime.tryParse(json['ackDate'] as String),
  );
}

/// The bill raised against a sale.
class BillModel {
  final int id;
  final int salesOrderId;
  final String invoiceNo;
  final DateTime issuedOn;
  final BillOptions options;
  final EInvoiceInfo eInvoice;
  final String generatedBy;
  final List<BillEvent> events;

  const BillModel({
    required this.id,
    required this.salesOrderId,
    required this.invoiceNo,
    required this.issuedOn,
    required this.options,
    required this.eInvoice,
    this.generatedBy = 'Admin',
    this.events = const [],
  });

  factory BillModel.fromJson(Map<String, dynamic> json) => BillModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    salesOrderId: (json['salesOrderId'] as num?)?.toInt() ?? 0,
    invoiceNo: json['invoiceNo'] as String? ?? '',
    issuedOn:
        DateTime.tryParse(json['issuedOn'] as String? ?? '') ?? DateTime.now(),
    options: json['options'] is Map<String, dynamic>
        ? BillOptions.fromJson(json['options'] as Map<String, dynamic>)
        : const BillOptions(),
    eInvoice: json['eInvoice'] is Map<String, dynamic>
        ? EInvoiceInfo.fromJson(json['eInvoice'] as Map<String, dynamic>)
        : const EInvoiceInfo(),
    generatedBy: json['generatedBy'] as String? ?? 'Admin',
    events: [
      for (final e in (json['events'] as List<dynamic>? ?? []))
        BillEvent.fromJson(e as Map<String, dynamic>),
    ],
  );

  BillModel copyWith({BillOptions? options}) => BillModel(
    id: id,
    salesOrderId: salesOrderId,
    invoiceNo: invoiceNo,
    issuedOn: issuedOn,
    options: options ?? this.options,
    eInvoice: eInvoice,
    generatedBy: generatedBy,
    events: events,
  );
}

/// The Billing card on the Sale page.
class BillingSummary {
  final int generated;
  final int pending;
  final int irnRegistered;
  final int irnTotal;
  final int? latestSalesOrderId;
  final String latestInvoiceNo;

  const BillingSummary({
    this.generated = 0,
    this.pending = 0,
    this.irnRegistered = 0,
    this.irnTotal = 0,
    this.latestSalesOrderId,
    this.latestInvoiceNo = '',
  });

  static const empty = BillingSummary();

  factory BillingSummary.fromJson(Map<String, dynamic> json) {
    final latest = json['latest'] as Map<String, dynamic>?;
    int n(String key) => (json[key] as num?)?.toInt() ?? 0;
    return BillingSummary(
      generated: n('generated'),
      pending: n('pending'),
      irnRegistered: n('irnRegistered'),
      irnTotal: n('irnTotal'),
      latestSalesOrderId: (latest?['salesOrderId'] as num?)?.toInt(),
      latestInvoiceNo: latest?['invoiceNo'] as String? ?? '',
    );
  }
}

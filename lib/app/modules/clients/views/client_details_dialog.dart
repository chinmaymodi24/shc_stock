import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/purchase/controllers/purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/models/purchase_model.dart';
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/routes/app_routes.dart';

PurchaseController _purchaseController() {
  if (Get.isRegistered<PurchaseController>()) {
    return Get.find<PurchaseController>();
  }
  return Get.put(PurchaseController(), permanent: true);
}

SalesController _salesController() {
  if (Get.isRegistered<SalesController>()) {
    return Get.find<SalesController>();
  }
  return Get.put(SalesController(), permanent: true);
}

String _fmtQty(double q) =>
    q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toStringAsFixed(2);

/// One line item of a purchase/sales order where the counterparty (supplier
/// or client) matched this client's name — the same person/company can be
/// both a supplier we bought from and a client we sold to.
class _ClientHistoryEntry {
  final bool isPurchase;
  final String product;
  final double qty;
  final String unit;
  final String reference;
  final double amount;
  final DateTime date;
  const _ClientHistoryEntry({
    required this.isPurchase,
    required this.product,
    required this.qty,
    required this.unit,
    required this.reference,
    required this.amount,
    required this.date,
  });
}

List<_ClientHistoryEntry> _buildClientHistory(
  String clientName,
  List<PurchaseOrder> purchaseOrders,
  List<SalesOrder> salesOrders,
) {
  final name = clientName.trim().toLowerCase();
  if (name.isEmpty) return const [];
  final entries = <_ClientHistoryEntry>[];

  for (final po in purchaseOrders) {
    if (po.supplier.trim().toLowerCase() != name) continue;
    for (final item in po.items) {
      if (item.qty <= 0) continue;
      entries.add(
        _ClientHistoryEntry(
          isPurchase: true,
          product: item.product.isEmpty ? '—' : item.product,
          qty: item.qty,
          unit: item.unit,
          reference: po.poNumber,
          amount: item.amount,
          date: po.date,
        ),
      );
    }
  }
  for (final so in salesOrders) {
    if (so.client.trim().toLowerCase() != name) continue;
    for (final item in so.items) {
      if (item.qty <= 0) continue;
      entries.add(
        _ClientHistoryEntry(
          isPurchase: false,
          product: item.product.isEmpty ? '—' : item.product,
          qty: item.qty,
          unit: item.unit,
          reference: so.soNumber,
          amount: item.amount,
          date: so.date,
        ),
      );
    }
  }
  entries.sort((a, b) => b.date.compareTo(a.date));
  return entries;
}

/// Composes a display address out of structured fields, skipping blanks.
String _composeAddr({
  required String addr1,
  required String addr2,
  required String city,
  required String state,
  required String pin,
  required String country,
}) {
  final cityPin = [
    city,
    pin,
  ].where((s) => s.trim().isNotEmpty).join(' - ');
  final parts = [
    addr1,
    addr2,
    cityPin,
    state,
    if (country.trim().isNotEmpty && country.trim() != 'India') country,
  ].where((s) => s.trim().isNotEmpty).toList();
  return parts.join(', ');
}

/// Read-only "Client Details" side panel — opened from the list page's View
/// icon. Every field is read straight off [ClientModel] / the live
/// Purchase & Sales order lists; nothing here is hardcoded — a client with no
/// email, no structured address, etc. (true of most of the 1037 imported
/// legacy rows) correctly falls back to "—" because that data was never
/// captured, not because the panel doesn't know how to show it.
class ClientDetailsDialog extends StatelessWidget {
  final ClientModel client;
  final VoidCallback? onDelete;

  const ClientDetailsDialog({super.key, required this.client, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isRegistered = client.registrationType == 'Regular';
    final purchase = _purchaseController();
    final sales = _salesController();

    final regAddr = client.regAddr1.isNotEmpty
        ? _composeAddr(
            addr1: client.regAddr1,
            addr2: client.regAddr2,
            city: client.regCity,
            state: client.regState,
            pin: client.regPin,
            country: client.regCountry,
          )
        : client.address;
    final shipAddr = client.shipSameAsRegistered
        ? regAddr
        : (client.shipAddr1.isNotEmpty
              ? _composeAddr(
                  addr1: client.shipAddr1,
                  addr2: client.shipAddr2,
                  city: client.shipCity,
                  state: client.shipState,
                  pin: client.shipPin,
                  country: client.shipCountry,
                )
              : client.address);
    final billAddr = switch (client.billingMode) {
      'registered' => regAddr,
      'custom' => client.billAddr1.isNotEmpty
          ? _composeAddr(
              addr1: client.billAddr1,
              addr2: client.billAddr2,
              city: client.billCity,
              state: client.billState,
              pin: client.billPin,
              country: client.billCountry,
            )
          : client.address,
      _ => shipAddr,
    };
    final paymentTermsAndPriceList = [
      client.paymentTerms,
      client.priceList,
    ].where((s) => s.trim().isNotEmpty).join(' · ');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      alignment: Alignment.centerRight,
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: 400,
          height: double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 24,
                offset: const Offset(-6, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Client Details',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: Get.back,
                      borderRadius: BorderRadius.circular(8),
                      child: Icon(
                        Icons.close_rounded,
                        color: colors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.divider),

              // ── Body ──────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: client.badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                client.initials,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: client.badgeColor,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  client.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  client.code,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryOrange,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _field(
                        'Client Type',
                        client.clientType.isEmpty ? '—' : client.clientType,
                        colors,
                      ),
                      const SizedBox(height: 14),
                      _pairField(
                        'Email',
                        client.email.isEmpty ? '—' : client.email,
                        'Phone',
                        client.phone.isEmpty ? '—' : client.phone,
                        colors,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Registration Address',
                        regAddr.isEmpty ? '—' : regAddr,
                        colors,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Shipping Address',
                        shipAddr.isEmpty ? '—' : shipAddr,
                        colors,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Billing Address',
                        billAddr.isEmpty ? '—' : billAddr,
                        colors,
                      ),
                      const SizedBox(height: 14),
                      _pairField(
                        'GSTIN/UIN',
                        client.gstin.isEmpty ? '—' : client.gstin,
                        'PAN',
                        client.pan.isEmpty ? '—' : client.pan,
                        colors,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel('Reg. Type', colors),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isRegistered
                                        ? const Color(
                                            0xFF22C55E,
                                          ).withValues(alpha: 0.10)
                                        : colors.comingSoonBadge,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    client.registrationType,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isRegistered
                                          ? const Color(0xFF22C55E)
                                          : colors.textSecondary,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _field(
                              'Client Since',
                              client.clientSince == null
                                  ? '—'
                                  : DateFormat(
                                      'MMM d, yyyy',
                                    ).format(client.clientSince!),
                              colors,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Contact Person',
                        client.contactPerson.isEmpty
                            ? '—'
                            : '${client.contactPerson}${client.contactPhone.isEmpty ? '' : ' · ${client.contactPhone}'}',
                        colors,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Payment Terms & Price List',
                        paymentTermsAndPriceList.isEmpty
                            ? '—'
                            : paymentTermsAndPriceList,
                        colors,
                      ),
                      const SizedBox(height: 14),
                      _pairField(
                        'Opening Balance (₹)',
                        client.openingBalance.toStringAsFixed(2),
                        'Credit Limit (₹)',
                        client.creditLimit.toStringAsFixed(2),
                        colors,
                      ),
                      const SizedBox(height: 18),
                      Divider(height: 1, color: colors.divider),
                      const SizedBox(height: 14),

                      // ── Purchase & Sale History — every order where this
                      // client's name matches an order's supplier (we bought
                      // from them) or client (we sold to them). The same
                      // company can show up on both sides.
                      _sectionLabel('Purchase & Sale History', colors),
                      const SizedBox(height: 10),
                      Obx(() {
                        final loading =
                            purchase.isLoading.value && purchase.orders.isEmpty ||
                            sales.isLoading.value && sales.orders.isEmpty;
                        final entries = _buildClientHistory(
                          client.name,
                          purchase.orders,
                          sales.orders,
                        );
                        if (loading) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        }
                        if (entries.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'No purchases or sales recorded for this client yet.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colors.textHint,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: entries
                              .map((e) => _historyRow(e, colors))
                              .toList(),
                        );
                      }),
                      const SizedBox(height: 8),
                      Divider(height: 1, color: colors.divider),
                      const SizedBox(height: 12),
                      _quickLink(
                        Icons.history_rounded,
                        AppColors.primaryPurple,
                        'All Transactions History',
                        colors,
                        onTap: () => Get.toNamed(AppRoutes.transactions),
                      ),
                      _quickLink(
                        Icons.receipt_long_rounded,
                        const Color(0xFF6B5CBF),
                        'Ledger Statement',
                        colors,
                      ),
                      _quickLink(
                        Icons.warning_amber_rounded,
                        const Color(0xFFA05A00),
                        'Outstanding Statement',
                        colors,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Footer: Edit / Delete ──────────────────────────────
              Divider(height: 1, color: colors.divider),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.inputFill,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, AppThemeColors colors) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: colors.textHint,
      fontFamily: 'Poppins',
      letterSpacing: 0.5,
    ),
  );

  Widget _field(
    String label,
    String value,
    AppThemeColors colors, {
    String? sub,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(label, colors),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '—' : value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        if (sub != null && sub.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ],
    );
  }

  Widget _pairField(
    String label1,
    String value1,
    String label2,
    String value2,
    AppThemeColors colors,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _field(label1, value1, colors)),
        Expanded(child: _field(label2, value2, colors)),
      ],
    );
  }

  Widget _historyRow(_ClientHistoryEntry e, AppThemeColors colors) {
    final color = e.isPurchase ? colors.accent : colors.success;
    final dateFmt = DateFormat('MMM d, yyyy');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        e.isPurchase ? 'Purchase' : 'Sale',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.product,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${_fmtQty(e.qty)}${e.unit.isEmpty ? '' : ' ${e.unit}'} · ${e.reference}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: colors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRupees(e.amount),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateFmt.format(e.date),
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textHint,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickLink(
    IconData icon,
    Color iconColor,
    String label,
    AppThemeColors colors, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 17, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: colors.textHint),
          ],
        ),
      ),
    );
  }
}

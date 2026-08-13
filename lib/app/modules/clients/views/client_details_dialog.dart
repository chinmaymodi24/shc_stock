import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/routes/app_routes.dart';

/// Read-only "Client Details" side panel — opened from the list page's View
/// icon. Falls back to "—" for anything the static client list doesn't
/// carry (email, client-since, credit terms, etc. aren't in the seed data).
class ClientDetailsDialog extends StatelessWidget {
  final ClientModel client;
  final VoidCallback? onDelete;

  const ClientDetailsDialog({super.key, required this.client, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isRegistered = client.registrationType == 'Regular';

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
                      // Not carried by the static client list — shown as
                      // "—" like the approved design does for anything the
                      // source data doesn't have.
                      _field('Client Type', '—', colors),
                      const SizedBox(height: 14),
                      _pairField('Email', '—', 'Phone', '—', colors),
                      const SizedBox(height: 14),
                      _field(
                        'Registration Address',
                        client.address,
                        colors,
                        sub: client.state,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Shipping Address',
                        client.address,
                        colors,
                        sub: client.state,
                      ),
                      const SizedBox(height: 14),
                      _field('Billing Address', client.address, colors),
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
                          Expanded(child: _field('Client Since', '—', colors)),
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
                      _field('Payment Terms & Price List', '—', colors),
                      const SizedBox(height: 14),
                      _pairField(
                        'Opening Balance (₹)',
                        '0.00',
                        'Credit Limit (₹)',
                        '0.00',
                        colors,
                      ),
                      const SizedBox(height: 16),
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

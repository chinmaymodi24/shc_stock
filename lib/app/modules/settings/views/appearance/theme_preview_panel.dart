import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/brand_controller.dart';
import 'package:shc_stock/app/core/theme/brand_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// A miniature of the real app, painted from the DRAFT.
//
// This is the whole reason the draft exists: the buyer sees the palette on
// something shaped like the product — a sidebar, KPI cards, a table with
// status pills, action chips, a pair of buttons — before committing it. Every
// configurable colour appears at least once here, so nothing can be changed
// without showing up in the preview.
//
// Nothing in here reads the ambient theme; every colour comes off the draft.
// ─────────────────────────────────────────────────────────────────────────────
class ThemePreviewPanel extends StatelessWidget {
  const ThemePreviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final bc = Get.find<BrandController>();
    final ambient = context.appColors;

    return Obx(() {
      final d = bc.draft.value;
      // Read `applied` too, not just the draft: Apply moves `applied` and
      // leaves the draft untouched, so watching the draft alone left the badge
      // stuck on "Not applied yet" after a successful Apply.
      bc.applied.value;
      final dirty = bc.isDirty;
      return Container(
        decoration: BoxDecoration(
          color: ambient.surface,
          borderRadius: BorderRadius.circular(ambient.radius + 2),
          border: Border.all(color: ambient.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ambient.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    dirty ? 'Not applied yet' : 'Applied',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: dirty ? ambient.warning : ambient.success,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: ambient.divider),

            // ── The miniature ─────────────────────────────────────────
            Container(
              color: d.bg,
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MiniSidebar(d: d),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MiniKpiRow(d: d),
                        const SizedBox(height: 8),
                        _MiniTable(d: d),
                        const SizedBox(height: 8),
                        _MiniChips(d: d),
                        const SizedBox(height: 10),
                        _MiniButtons(d: d),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _MiniSidebar extends StatelessWidget {
  final BrandTheme d;
  const _MiniSidebar({required this.d});

  @override
  Widget build(BuildContext context) {
    Widget mark() {
      if (d.logoBase64 != null) {
        try {
          return ClipRRect(
            borderRadius: BorderRadius.circular(d.radiusSm),
            child: Image.memory(
              base64Decode(d.logoBase64!),
              width: 22,
              height: 22,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _shortCodeMark(),
            ),
          );
        } catch (_) {
          return _shortCodeMark();
        }
      }
      return _shortCodeMark();
    }

    return Container(
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: d.sidebarBg,
        borderRadius: BorderRadius.circular(d.radiusSm),
        border: Border.all(color: d.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          mark(),
          const SizedBox(height: 12),
          _navItem('Products', active: false),
          _navItem('Purchase', active: true),
          _navItem('Reports', active: false),
        ],
      ),
    );
  }

  Widget _shortCodeMark() => Container(
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: d.secondary,
      borderRadius: BorderRadius.circular(d.radiusSm),
    ),
    child: Text(
      d.shortCode.isEmpty ? '·' : d.shortCode,
      style: TextStyle(
        fontFamily: d.font,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );

  Widget _navItem(String label, {required bool active}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    decoration: BoxDecoration(
      color: active ? d.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(d.radiusSm),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: TextStyle(
        fontFamily: d.font,
        fontSize: 7.5,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        color: active ? Colors.white : d.textSecondary,
      ),
    ),
  );
}

class _MiniKpiRow extends StatelessWidget {
  final BrandTheme d;
  const _MiniKpiRow({required this.d});

  @override
  Widget build(BuildContext context) {
    Widget card(String label, String value, Color bg, Color fg) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(d.radiusSm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontFamily: d.font,
                fontSize: 6.5,
                color: d.textTertiary,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontFamily: d.font,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            card('Orders', '4', d.tintAccent, d.accent),
            const SizedBox(width: 6),
            card('Purchase', '₹1.5L', d.tintInfo, d.info),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            card('Paid', '₹1.2L', d.tintSuccess, d.success),
            const SizedBox(width: 6),
            card('Due', '₹31K', d.tintWarning, d.warning),
          ],
        ),
      ],
    );
  }
}

class _MiniTable extends StatelessWidget {
  final BrandTheme d;
  const _MiniTable({required this.d});

  @override
  Widget build(BuildContext context) {
    Widget pill(String text, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: d.font,
          fontSize: 6.5,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );

    Widget row(String po, Widget status, {required bool hovered}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      color: hovered ? d.rowHover : d.cardBg,
      child: Row(
        children: [
          Expanded(
            child: Text(
              po,
              style: TextStyle(
                fontFamily: d.font,
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: d.primary,
              ),
            ),
          ),
          status,
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: d.cardBg,
        borderRadius: BorderRadius.circular(d.radiusSm),
        border: Border.all(color: d.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: d.tableHeaderBg,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'PO Number',
                    style: TextStyle(
                      fontFamily: d.font,
                      fontSize: 6.5,
                      fontWeight: FontWeight.w600,
                      color: d.textTertiary,
                    ),
                  ),
                ),
                Text(
                  'Status',
                  style: TextStyle(
                    fontFamily: d.font,
                    fontSize: 6.5,
                    fontWeight: FontWeight.w600,
                    color: d.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          row(
            'PO-2201',
            pill('Received', d.tintSuccess, d.success),
            hovered: false,
          ),
          row(
            'PO-1187',
            pill('Partial', d.tintWarning, d.warning),
            hovered: true,
          ),
          row(
            'PO-5502',
            pill('Pending', d.tintAccent, d.accent),
            hovered: false,
          ),
        ],
      ),
    );
  }
}

class _MiniChips extends StatelessWidget {
  final BrandTheme d;
  const _MiniChips({required this.d});

  @override
  Widget build(BuildContext context) {
    Widget chip(IconData icon, Color bg, Color fg) => Container(
      width: 18,
      height: 18,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(d.radiusSm * 0.8),
      ),
      child: Icon(icon, size: 10, color: fg),
    );

    return Row(
      children: [
        chip(Icons.visibility_outlined, d.tintSuccess, d.success),
        chip(Icons.edit_outlined, d.tintPrimary, d.primary),
        chip(Icons.delete_outline, d.tintDanger, d.danger),
        const Spacer(),
        Text(
          'Body text',
          style: TextStyle(
            fontFamily: d.font,
            fontSize: 8,
            color: d.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MiniButtons extends StatelessWidget {
  final BrandTheme d;
  const _MiniButtons({required this.d});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: d.primary,
              borderRadius: BorderRadius.circular(d.radiusSm),
            ),
            child: Text(
              'Add Purchase',
              style: TextStyle(
                fontFamily: d.font,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: d.rowHover,
              borderRadius: BorderRadius.circular(d.radiusSm),
              border: Border.all(color: d.border),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: d.font,
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: d.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

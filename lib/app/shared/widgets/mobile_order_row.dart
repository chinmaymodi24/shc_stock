import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The dense list row the Purchase and Sale mobile pages are built from, plus
// the kebab menu Products uses too.
//
// One row = a colored settlement bar down the left, an initials badge, the
// item and who it was with, and the money on the right — amount over its
// settlement state. The four/five row actions collapse behind the kebab so a
// row stays one line tall per field instead of growing an action strip.
// ─────────────────────────────────────────────────────────────────────────────

/// Two-letter badge from a name — "Copper Pipe 15mm" → "CP", "Ashoka" → "AS".
/// Digits and punctuation are skipped so `3/4"` valves don't badge as `34`.
String mobileRowInitials(String source) {
  final words = source
      .split(RegExp(r'[\s/\-_]+'))
      .where((w) => w.isNotEmpty && RegExp(r'^[A-Za-z]').hasMatch(w))
      .toList();
  if (words.isEmpty) {
    final letters = source.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.isEmpty) return '—';
    return letters.substring(0, letters.length < 2 ? 1 : 2).toUpperCase();
  }
  if (words.length == 1) {
    final w = words.first;
    return w.substring(0, w.length < 2 ? 1 : 2).toUpperCase();
  }
  return (words[0][0] + words[1][0]).toUpperCase();
}

/// One entry in a [MobileRowMenu].
class MobileRowMenuItem {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onSelected;

  const MobileRowMenuItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.onSelected,
  });
}

/// The ⋮ menu on a mobile list row — the same actions the web table spreads
/// across its Actions column, collapsed behind one icon.
class MobileRowMenu extends StatelessWidget {
  final List<MobileRowMenuItem> items;

  const MobileRowMenu({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PopupMenuButton<VoidCallback>(
      icon: Icon(Icons.more_vert_rounded, color: colors.textHint, size: 20),
      padding: EdgeInsets.zero,
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (action) => action(),
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem<VoidCallback>(
            value: item.onSelected,
            height: 40,
            child: Row(
              children: [
                Icon(item.icon, size: 17, color: item.color),
                const SizedBox(width: 10),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class MobileOrderRow extends StatelessWidget {
  /// Two/three letters in the leading badge.
  final String badge;

  /// The item the order is about.
  final String title;

  /// Who it was with, and one identifying detail — "Ashoka Metals · INV-2201",
  /// "Suresh Patel · Qty 120".
  final String subtitle;

  /// Formatted order total.
  final String amount;

  /// "Paid" / "Received" / "₹6,800 due" — what's left to settle. Its color
  /// drives the accent bar down the left of the row, so the state is readable
  /// while scrolling without reading the text at all.
  final String statusLabel;
  final Color statusColor;

  final VoidCallback onTap;
  final List<MobileRowMenuItem> menuItems;

  const MobileOrderRow({
    super.key,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.statusLabel,
    required this.statusColor,
    required this.onTap,
    required this.menuItems,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: statusColor),
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 2, 10),
                    child: Row(
                      children: [
                        _badge(colors),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: colors.textHint,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              amount,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                        MobileRowMenu(items: menuItems),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(AppThemeColors colors) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: colors.tagBg,
      borderRadius: BorderRadius.circular(8),
    ),
    alignment: Alignment.center,
    child: Text(
      badge,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: colors.textSecondary,
        fontFamily: 'Poppins',
      ),
    ),
  );
}

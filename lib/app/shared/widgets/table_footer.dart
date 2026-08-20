import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared table footer: optional "Showing X to Y of Z <thing>" summary, rows-
// per-page dropdown, and page-number pagination with first/prev/next/last.
//
// Replaces the per-file _Footer / _PBtn / _PageBtn copies (Clients, Sales,
// Stock, Transactions, Employee/Users).
//
// Two page-number algorithms exist in the app (both preserved exactly, not
// silently unified):
//   - "smart" (default) — 1,2,3 … currentPage … last, current page always
//     visible. Used by Clients / Stock / Transactions / Employee.
//   - "legacy" (`legacyPageNumbers: true`) — always 1,2,3 … last; doesn't
//     surface the current page once it's past position 3. Used by Sales.
// ─────────────────────────────────────────────────────────────────────────────
class AppTableFooter extends StatelessWidget {
  /// e.g. "Showing 1 to 10 of 26 clients". Omit to skip the summary line
  /// (Stock / Transactions start the row straight from "Rows per page:").
  final String? summaryText;

  final int currentPage;
  final int totalPages;
  final int rowsPerPage;
  final AppThemeColors colors;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onRowsChanged;
  final List<int> rowsPerPageOptions;
  final bool legacyPageNumbers;

  const AppTableFooter({
    super.key,
    this.summaryText,
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
    required this.colors,
    required this.onPageChanged,
    required this.onRowsChanged,
    this.rowsPerPageOptions = const [5, 10, 20, 50],
    this.legacyPageNumbers = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: summaryText != null ? 12 : 11,
      ),
      child: Row(
        children: [
          if (summaryText != null) ...[
            Flexible(
              child: Text(
                summaryText!,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: colors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const Spacer(),
          ],
          Text(
            'Rows per page:',
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(6),
              color: colors.surface,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: rowsPerPage,
                isDense: true,
                style: TextStyle(
                  fontSize: 12.5,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
                dropdownColor: colors.surface,
                items: rowsPerPageOptions
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onRowsChanged(v);
                },
              ),
            ),
          ),
          if (summaryText != null) const SizedBox(width: 16),
          // Expanded (not Flexible) so this claims all remaining row width by
          // itself — with no sibling Spacer competing for the same flex
          // space, the pager is guaranteed to sit flush against the card's
          // right edge instead of drifting toward the middle. Align then
          // pins the fixed-width button cluster to that edge; the
          // SingleChildScrollView only kicks in if a narrow table ever makes
          // the cluster wider than the space left for it.
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: [
                    _PageBtn(
                      icon: Icons.first_page_rounded,
                      enabled: currentPage > 1,
                      colors: colors,
                      onTap: () => onPageChanged(1),
                    ),
                    const SizedBox(width: 4),
                    _PageBtn(
                      icon: Icons.chevron_left_rounded,
                      enabled: currentPage > 1,
                      colors: colors,
                      onTap: () => onPageChanged(currentPage - 1),
                    ),
                    const SizedBox(width: 6),
                    ..._pageNumbers(),
                    const SizedBox(width: 6),
                    _PageBtn(
                      icon: Icons.chevron_right_rounded,
                      enabled: currentPage < totalPages,
                      colors: colors,
                      onTap: () => onPageChanged(currentPage + 1),
                    ),
                    const SizedBox(width: 4),
                    _PageBtn(
                      icon: Icons.last_page_rounded,
                      enabled: currentPage < totalPages,
                      colors: colors,
                      onTap: () => onPageChanged(totalPages),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _pageNumbers() =>
      legacyPageNumbers ? _legacyPageNumbers() : _smartPageNumbers();

  // "1 2 3 … current … last" — current page always represented.
  List<Widget> _smartPageNumbers() {
    final items = <Widget>[];
    final pages = <int>[];
    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        pages.add(i);
      }
    } else {
      pages.addAll([1, 2, 3]);
      if (currentPage > 4) pages.add(-1); // ellipsis
      if (currentPage > 3 && currentPage < totalPages - 1) {
        pages.add(currentPage);
      }
      pages.add(totalPages);
    }

    for (int i = 0; i < pages.length; i++) {
      final p = pages[i];
      if (i > 0) items.add(const SizedBox(width: 4));
      if (p == -1) {
        items.add(
          Text(
            '...',
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        );
      } else {
        items.add(_pageNumberChip(p, size: 30));
      }
    }
    return items;
  }

  // "1 2 3 … last" — first 3 always shown, last page appended after an
  // ellipsis once there are more than 3 pages.
  List<Widget> _legacyPageNumbers() {
    final items = <Widget>[];
    final visible = totalPages < 3 ? totalPages : 3;
    for (int i = 0; i < visible; i++) {
      final page = i + 1;
      items.add(
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: _pageNumberChip(page, size: 32, weight: FontWeight.w700),
        ),
      );
    }
    if (totalPages > 3) {
      items.add(
        Text(
          '...',
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
      );
      items.add(const SizedBox(width: 4));
      items.add(_pageNumberChip(totalPages, size: 32, weight: FontWeight.w700));
      items.add(const SizedBox(width: 4));
    }
    return items;
  }

  Widget _pageNumberChip(
    int page, {
    required double size,
    FontWeight weight = FontWeight.w600,
  }) {
    final isActive = page == currentPage;
    return InkWell(
      onTap: () => onPageChanged(page),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryOrange : colors.surface,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isActive ? AppColors.primaryOrange : colors.border,
          ),
        ),
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: 13,
              fontWeight: weight,
              color: isActive ? Colors.white : colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final AppThemeColors colors;
  final VoidCallback onTap;
  const _PageBtn({
    required this.icon,
    required this.enabled,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(6),
          color: colors.surface,
        ),
        child: Icon(
          icon,
          size: 17,
          color: enabled ? colors.textPrimary : colors.textHint,
        ),
      ),
    );
  }
}

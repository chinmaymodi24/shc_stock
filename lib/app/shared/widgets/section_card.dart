import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared chrome for the add/edit form pages (web + mobile).
//
// Web and mobile differ only in sizing, so each widget takes a `mobile` flag
// rather than being copy-pasted per platform. Defaults are the web metrics.
//
// Replaces the per-file _NumberedSectionCard / _BackButton /
// _AddRowPillButton / _AddPillButton copies.
// ─────────────────────────────────────────────────────────────────────────────

/// Numbered ("1 Client & Invoice Details") card wrapping a form section.
class AppNumberedSectionCard extends StatelessWidget {
  final AppThemeColors colors;
  final int number;
  final String title;
  final Widget child;
  final Widget? trailing;
  final bool mobile;

  const AppNumberedSectionCard({
    super.key,
    required this.colors,
    required this.number,
    required this.title,
    required this.child,
    this.trailing,
    this.mobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final pad = mobile ? 14.0 : 20.0;
    final badge = mobile ? 20.0 : 22.0;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
        boxShadow: mobile
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(pad, mobile ? 12 : 16, pad, mobile ? 12 : 16),
            child: Row(
              children: [
                Container(
                  width: badge,
                  height: badge,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: TextStyle(
                        fontSize: mobile ? 11 : 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                SizedBox(width: mobile ? 8 : 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: mobile ? 13.5 : 14.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Padding(padding: EdgeInsets.all(pad), child: child),
        ],
      ),
    );
  }
}

/// Rounded-square back button used in form page headers.
class AppBackButton extends StatelessWidget {
  final AppThemeColors colors;
  final VoidCallback onTap;
  final bool mobile;

  const AppBackButton({
    super.key,
    required this.colors,
    required this.onTap,
    this.mobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = mobile ? 36.0 : 38.0;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.inputFill,
          borderRadius: BorderRadius.circular(mobile ? 9 : 10),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          color: colors.textPrimary,
          size: mobile ? 18 : 19,
        ),
      ),
    );
  }
}

/// Orange-tinted "+ Add Row" pill used in section card headers.
class AppAddRowPill extends StatelessWidget {
  final AppThemeColors colors;
  final String label;
  final VoidCallback onTap;
  final bool mobile;

  const AppAddRowPill({
    super.key,
    required this.colors,
    required this.label,
    required this.onTap,
    this.mobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 12 : 14,
            vertical: mobile ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: mobile ? 15 : 16,
                color: AppColors.primaryOrange,
              ),
              SizedBox(width: mobile ? 3 : 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: mobile ? 12.5 : 13,
                  color: AppColors.primaryOrange,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

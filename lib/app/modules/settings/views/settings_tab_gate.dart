import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/session/app_modules.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

/// Wraps one Settings tab in its permission.
///
/// * No read access — the tab's content is replaced by a short explanation.
///   The nav already hides the tab; this covers reaching it another way.
/// * Read but no write — the settings are shown as they are, with a notice,
///   and every control inside is inert. The backend refuses the save anyway;
///   this stops someone from changing values that would silently not stick.
/// * Profile and Security are the person's own account and always pass.
class SettingsTabGate extends StatelessWidget {
  final String tab;
  final Widget child;
  const SettingsTabGate({super.key, required this.tab, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    if (!canOpenSettingsTab(tab)) {
      return _Notice(
        icon: Icons.lock_outline_rounded,
        text: "You don't have permission to view $tab settings.",
        colors: c,
      );
    }
    if (canSaveSettingsTab(tab)) return child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Notice(
          icon: Icons.visibility_outlined,
          text: 'View only — you can see $tab settings but not change them.',
          colors: c,
        ),
        const SizedBox(height: 16),
        // Scrolling still works: the scroll view sits above this widget.
        AbsorbPointer(child: Opacity(opacity: 0.75, child: child)),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  final AppThemeColors colors;
  const _Notice({required this.icon, required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(colors.radiusSm),
        border: Border.all(
          color: AppColors.primaryOrange.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: colors.textPrimary,
                fontFamily: brandFontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

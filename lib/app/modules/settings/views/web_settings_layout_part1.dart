part of 'web_settings_layout.dart';

// Left-nav tab item
class _NavTab extends StatelessWidget {
  final String label;
  final bool selected;
  final AppThemeColors colors;
  final VoidCallback onTap;
  const _NavTab({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? colors.purple.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? colors.purple : colors.textSecondary,
              fontFamily: brandFontFamily,
            ),
          ),
        ),
      ),
    );
  }
}

/// The signed-in user, for the avatar initials and the read-only Role field.
SessionUser? get _sessionUser => Get.isRegistered<SessionController>()
    ? Get.find<SessionController>().user.value
    : null;

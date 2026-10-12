part of 'web_add_client_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar card — matches `.section-card` with a titled, divider-underlined
// header (no numbered badge, unlike the main form's section cards).
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarCard extends StatelessWidget {
  final AppThemeColors colors;
  final String title;
  final Widget child;

  const _SidebarCard({
    required this.colors,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              fontFamily: brandFontFamily,
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

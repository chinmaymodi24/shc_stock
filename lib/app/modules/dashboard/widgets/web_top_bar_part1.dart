part of 'web_top_bar.dart';

// Current-user avatar — filled navy circle with initials. Tap opens the
// profile card (name/role, My Settings, Appearance, Sign Out).
class _HeaderAvatar extends StatelessWidget {
  final String? initials;
  const _HeaderAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return ProfileAvatarMenu(
      trigger: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primaryPurple,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initials ?? _sessionInitials(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: brandFontFamily,
            ),
          ),
        ),
      ),
    );
  }
}

// Reusable profile dropdown — wrap any avatar widget with `trigger` and tap
// opens the same card (name/role, My Settings, Appearance, Sign Out). Used
// by the shared WebTopBar and by pages with their own custom top bar
// (e.g. Dashboard) so the profile menu behaves identically everywhere.
class ProfileAvatarMenu extends StatefulWidget {
  final Widget trigger;
  final String? initials;
  const ProfileAvatarMenu({super.key, required this.trigger, this.initials});

  @override
  State<ProfileAvatarMenu> createState() => _ProfileAvatarMenuState();
}

class _ProfileAvatarMenuState extends State<ProfileAvatarMenu> {
  final _overlayController = OverlayPortalController();
  final _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) => Positioned(
          width: 220,
          child: CompositedTransformFollower(
            link: _link,
            offset: const Offset(-178, 52),
            child: TapRegion(
              onTapOutside: (_) => _overlayController.hide(),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.primaryPurple,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  widget.initials ?? _sessionInitials(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    fontFamily: brandFontFamily,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              Get.find<SessionController>().user.value?.name ??
                                  'Signed out',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                                fontFamily: brandFontFamily,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Get.find<SessionController>().user.value?.role ??
                                  '',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryOrange,
                                fontFamily: brandFontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: colors.divider),
                      _ProfileMenuItem(
                        label: 'My Settings',
                        colors: colors,
                        onTap: () {
                          _overlayController.hide();
                          Get.toNamed(AppRoutes.settings);
                        },
                      ),
                      Divider(height: 1, color: colors.divider),
                      _ProfileMenuItem(
                        label: 'Preferences',
                        colors: colors,
                        onTap: () {
                          _overlayController.hide();
                          Get.toNamed(AppRoutes.settings);
                          // SettingsBinding runs a frame later than this line,
                          // so on a first visit Get.find() would throw
                          // "SettingsController not found" — register it here
                          // if it isn't already (same guard the mobile hub
                          // uses).
                          if (!Get.isRegistered<SettingsController>()) {
                            Get.put(SettingsController());
                          }
                          Get.find<SettingsController>().tab.value = 3;
                        },
                      ),
                      Divider(height: 1, color: colors.divider),
                      InkWell(
                        onTap: () {
                          _overlayController.hide();
                          Get.dialog(const _SignOutDialog());
                        },
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryOrange,
                                fontFamily: brandFontFamily,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        child: InkWell(
          onTap: _overlayController.toggle,
          borderRadius: BorderRadius.circular(21),
          child: widget.trigger,
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final String label;
  final AppThemeColors colors;
  final VoidCallback onTap;
  const _ProfileMenuItem({
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            color: colors.textPrimary,
            fontFamily: brandFontFamily,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign Out Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _SignOutDialog extends StatelessWidget {
  const _SignOutDialog();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, minWidth: 320),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: AppColors.primaryOrange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                                fontFamily: brandFontFamily,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Are you sure you want to sign out?',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colors.textSecondary,
                                fontFamily: brandFontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: Get.back,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors.comingSoonBadge,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Divider(height: 1, color: colors.divider),
                ),
                // Body
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      // Orange tint derived from the accent instead of a fixed
                      // cream — a hardcoded light hex stayed white in dark mode.
                      color: AppColors.primaryOrange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryOrange.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primaryOrange.withValues(alpha: 0.8),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You will be returned to the login screen. Any unsaved changes will be lost.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: colors.textSecondary,
                              fontFamily: brandFontFamily,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: Get.back,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: brandFontFamily,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Get.back();
                            await Get.find<SessionController>().signOut();
                            Get.offAllNamed(AppRoutes.login);
                          },
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          label: Text(
                            'Yes, Sign Out',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: brandFontFamily,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
}

/// Initials of the signed-in user, or '—' when signed out. Used as the default
/// for the header avatar so it always reflects the real account.
String _sessionInitials() {
  if (!Get.isRegistered<SessionController>()) return '—';
  return Get.find<SessionController>().user.value?.initials ?? '—';
}

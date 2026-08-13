import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_switch_helper.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/settings/controllers/settings_controller.dart';

// Pages (+ quick-add actions) offered as search suggestions in the header.
// `enabled: false` entries match WebSidebar's "Coming Soon" modules.
class _SearchSuggestion {
  final IconData icon;
  final String label;
  final String route;
  final bool enabled;
  const _SearchSuggestion({
    required this.icon,
    required this.label,
    required this.route,
    this.enabled = true,
  });
}

const _searchSuggestions = <_SearchSuggestion>[
  _SearchSuggestion(
    icon: Icons.dashboard_rounded,
    label: 'Dashboard',
    route: AppRoutes.dashboard,
  ),
  _SearchSuggestion(
    icon: Icons.inventory_2_outlined,
    label: 'Products',
    route: AppRoutes.products,
  ),
  _SearchSuggestion(
    icon: Icons.add_circle_outline_rounded,
    label: 'Add Product',
    route: AppRoutes.addProduct,
  ),
  _SearchSuggestion(
    icon: Icons.category_outlined,
    label: 'Categories',
    route: AppRoutes.categories,
  ),
  _SearchSuggestion(
    icon: Icons.warehouse_outlined,
    label: 'Inventory',
    route: AppRoutes.stock,
  ),
  _SearchSuggestion(
    icon: Icons.swap_horiz_rounded,
    label: 'Transactions',
    route: AppRoutes.transactions,
  ),
  _SearchSuggestion(
    icon: Icons.shopping_bag_outlined,
    label: 'Purchase',
    route: AppRoutes.purchase,
  ),
  _SearchSuggestion(
    icon: Icons.add_circle_outline_rounded,
    label: 'Add Purchase',
    route: AppRoutes.addPurchase,
  ),
  _SearchSuggestion(
    icon: Icons.point_of_sale_outlined,
    label: 'Sales',
    route: AppRoutes.sales,
  ),
  _SearchSuggestion(
    icon: Icons.add_circle_outline_rounded,
    label: 'Add Sale',
    route: AppRoutes.addSale,
  ),
  _SearchSuggestion(
    icon: Icons.people_outline_rounded,
    label: 'Clients',
    route: AppRoutes.clients,
  ),
  _SearchSuggestion(
    icon: Icons.add_circle_outline_rounded,
    label: 'Add Client',
    route: AppRoutes.addClient,
  ),
  _SearchSuggestion(
    icon: Icons.bar_chart_rounded,
    label: 'Reports',
    route: AppRoutes.reports,
    enabled: false,
  ),
  _SearchSuggestion(
    icon: Icons.manage_accounts_outlined,
    label: 'Employee',
    route: AppRoutes.users,
  ),
  _SearchSuggestion(
    icon: Icons.person_add_alt_1_rounded,
    label: 'Add Employee',
    route: AppRoutes.addEmployee,
  ),
  _SearchSuggestion(
    icon: Icons.settings_outlined,
    label: 'Settings',
    route: AppRoutes.settings,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Shared web top bar — used across all module pages so the header stays common.
// Layout:  [ 🔍 Search anything... ] ............ [ 🔔 ] [ theme toggle ] [ CM ]
// ─────────────────────────────────────────────────────────────────────────────
class WebTopBar extends StatelessWidget {
  /// Initials shown in the avatar (defaults to the current user's).
  final String? initials;

  /// Defaults to the signed-in user's initials; pass a value to override.
  const WebTopBar({super.key, this.initials});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: colors.topBarBg,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          const HeaderSearchBox(),
          const Spacer(),
          HeaderActionsCluster(initials: initials),
        ],
      ),
    );
  }
}

// Bell + theme toggle + avatar, in that exact order — the right-hand cluster
// shared by every page's header (including pages with their own custom top
// bar layout, e.g. Dashboard) so it's pixel-identical everywhere.
class HeaderActionsCluster extends StatelessWidget {
  final String? initials;
  const HeaderActionsCluster({super.key, this.initials});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderBellBtn(colors: colors),
        const SizedBox(width: 12),
        const _HeaderThemeToggle(),
        const SizedBox(width: 12),
        _HeaderAvatar(initials: initials),
      ],
    );
  }
}

// Global "Search anything..." field — the same bordered search box (with the
// shortcut badge) used by every page's header, including pages with their
// own custom top bar layout (e.g. Dashboard).
//
// The inner TextField is fully chrome-less: every border state is cleared so
// the global inputDecorationTheme's orange focusedBorder can't paint a second
// ring inside the box. Focus is shown on the OUTER container instead.
class HeaderSearchBox extends StatefulWidget {
  const HeaderSearchBox({super.key});

  @override
  State<HeaderSearchBox> createState() => _HeaderSearchBoxState();
}

class _HeaderSearchBoxState extends State<HeaderSearchBox> {
  // Field FocusNode owned by RawAutocomplete — captured on first build so the
  // double-Shift shortcut can request focus on it directly.
  FocusNode? _fieldFocusNode;
  TextEditingController? _fieldController;
  DateTime? _lastShiftPressTime;

  @override
  void initState() {
    super.initState();
    // Double-tap Shift focuses the search box — web only.
    if (kIsWeb) {
      HardwareKeyboard.instance.addHandler(_handleDoubleShift);
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      HardwareKeyboard.instance.removeHandler(_handleDoubleShift);
    }
    super.dispose();
  }

  void _selectSuggestion(
    _SearchSuggestion suggestion,
    TextEditingController controller,
  ) {
    controller.clear();
    _fieldFocusNode?.unfocus();
    if (suggestion.enabled) {
      Get.offNamed(suggestion.route);
    } else {
      showAppToast(
        '🚧 Coming Soon',
        '${suggestion.label} module is under development.',
        backgroundColor: AppColors.primaryPurple,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  bool _handleDoubleShift(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final isShift =
        event.logicalKey == LogicalKeyboardKey.shiftLeft ||
        event.logicalKey == LogicalKeyboardKey.shiftRight;
    if (!isShift) {
      _lastShiftPressTime = null;
      return false;
    }

    final now = DateTime.now();
    if (_lastShiftPressTime != null &&
        now.difference(_lastShiftPressTime!) <
            const Duration(milliseconds: 400)) {
      _fieldFocusNode?.requestFocus();
      _lastShiftPressTime = null;
    } else {
      _lastShiftPressTime = now;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Autocomplete<_SearchSuggestion>(
      displayStringForOption: (s) => s.label,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return const Iterable<_SearchSuggestion>.empty();
        return _searchSuggestions.where(
          (s) => s.label.toLowerCase().contains(query),
        );
      },
      onSelected: (suggestion) {
        // The field's controller isn't exposed here, but fieldViewBuilder
        // hands us the same instance each build — clear it via the node.
        final controller = _fieldController;
        if (controller != null) _selectSuggestion(suggestion, controller);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _fieldFocusNode = focusNode;
        _fieldController = controller;
        return AnimatedBuilder(
          animation: focusNode,
          builder: (context, _) => Container(
            width: 320,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: colors.inputFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: focusNode.hasFocus
                    ? AppColors.primaryOrange
                    : colors.border,
                width: focusNode.hasFocus ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: colors.textHint, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    cursorColor: AppColors.primaryOrange,
                    cursorWidth: 1.5,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                    onSubmitted: (_) => onFieldSubmitted(),
                    decoration: InputDecoration(
                      isDense: true,
                      isCollapsed: true,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      hintText: 'Search anything...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: colors.textHint,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'Double Shift',
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelect, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: colors.surface,
            child: Container(
              width: 320,
              constraints: const BoxConstraints(maxHeight: 320),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final suggestion = options.elementAt(index);
                  final highlighted =
                      AutocompleteHighlightedOption.of(context) == index;
                  if (highlighted) {
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        Scrollable.ensureVisible(context, alignment: 0.5);
                      }
                    });
                  }
                  return Container(
                    color: highlighted
                        ? AppColors.primaryOrange.withValues(alpha: 0.1)
                        : null,
                    child: InkWell(
                      onTap: () => onSelect(suggestion),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              suggestion.icon,
                              size: 17,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                suggestion.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textPrimary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            if (!suggestion.enabled)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.comingSoonBadge,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  'Soon',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: colors.textSecondary,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// Notification bell — light grey rounded-square button with an orange dot.
class _HeaderBellBtn extends StatelessWidget {
  final AppThemeColors colors;
  const _HeaderBellBtn({required this.colors});

  @override
  Widget build(BuildContext context) {
    final bg = colors.background.computeLuminance() > 0.5
        ? const Color(0xFFF1F2F4)
        : colors.inputFill;
    return InkWell(
      onTap: () {},
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: colors.textSecondary,
              size: 21,
            ),
          ),
          Positioned(
            top: 9,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                shape: BoxShape.circle,
                border: Border.all(color: bg, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Compact light/dark theme toggle pill (sun ↔ moon knob).
// Sun icon — plain switch — moon icon, laid out side by side (icons are
// flanking the track rather than riding inside the knob).
class _HeaderThemeToggle extends StatelessWidget {
  const _HeaderThemeToggle();

  // Exact values from the approved design (Secure Heat Care Dashboard.dc.html):
  // switchTrackBg, sunColor/sunOpacity, moonColor/moonOpacity.
  static const _trackDark = Color(0xFF2D1B8C);
  static const _trackLight = Color(0xFFE4E2EE);
  static const _sunColorDark = Color(0xFFF0B45C);
  static const _sunColorLight = Color(0xFFA05A00);
  static const _moonColorDark = Color(0xFFA78BFA);
  static const _moonColorLight = Color(0xFF2D1B8C);

  @override
  Widget build(BuildContext context) {
    final tc = Get.find<ThemeController>();
    return Obx(() {
      final isDark = tc.isDark;
      final track = isDark ? _trackDark : _trackLight;
      final sunColor = isDark ? _sunColorDark : _sunColorLight;
      final sunOpacity = isDark ? 0.85 : 1.0;
      final moonColor = isDark ? _moonColorDark : _moonColorLight;
      final moonOpacity = isDark ? 1.0 : 0.35;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => switchThemeWithRipple(context, ThemeMode.light),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Opacity(
                opacity: sunOpacity,
                child: Icon(Icons.wb_sunny_rounded, size: 17, color: sunColor),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => switchThemeWithRipple(
              context,
              isDark ? ThemeMode.light : ThemeMode.dark,
            ),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 26,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: track,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: isDark
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => switchThemeWithRipple(context, ThemeMode.dark),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Opacity(
                opacity: moonOpacity,
                child: Icon(Icons.nightlight_round, size: 17, color: moonColor),
              ),
            ),
          ),
        ],
      );
    });
  }
}

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
        decoration: const BoxDecoration(
          color: AppColors.primaryPurple,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initials ?? _sessionInitials(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Poppins',
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
                              decoration: const BoxDecoration(
                                color: AppColors.primaryPurple,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  widget.initials ?? _sessionInitials(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
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
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Get.find<SessionController>().user.value?.role ??
                                  '',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryOrange,
                                fontFamily: 'Poppins',
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
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryOrange,
                                fontFamily: 'Poppins',
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
            fontFamily: 'Poppins',
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
                        child: const Icon(
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
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Are you sure you want to sign out?',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: colors.textSecondary,
                                fontFamily: 'Poppins',
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
                              fontFamily: 'Poppins',
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
                              fontFamily: 'Poppins',
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.back();
                            Get.offAllNamed(AppRoutes.login);
                          },
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          label: const Text(
                            'Yes, Sign Out',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
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

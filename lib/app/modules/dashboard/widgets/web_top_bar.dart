import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/brand_theme.dart';
import 'package:shc_stock/app/core/theme/brand_controller.dart';
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
import 'package:shc_stock/app/shared/widgets/export/export_overlay_host.dart';

part 'web_top_bar_part1.dart';

// Pages (+ quick-add actions) offered as search suggestions in the header.
// `enabled: false` entries match WebSidebar's "Coming Soon" modules. Every
// module is live as of the Reports catalog landing, so nothing passes it right
// now — the flag, its "Soon" badge and its toast stay for the next one.
class _SearchSuggestion {
  final IconData icon;
  final String label;
  final String route;
  final bool enabled;
  const _SearchSuggestion({
    required this.icon,
    required this.label,
    required this.route,
    // ignore: unused_element_parameter — see the note above.
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
        const DownloadsHeaderButton(),
        const SizedBox(width: 12),
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
                      fontFamily: brandFontFamily,
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
                        fontFamily: brandFontFamily,
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
                      fontFamily: brandFontFamily,
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
                                  fontFamily: brandFontFamily,
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
                                    fontFamily: brandFontFamily,
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

  // Shapes and opacities are from the approved design; the colours now come
  // from the brand, so the toggle stops being the one control still wearing
  // Secure Heat Care's navy on a rebranded deployment.
  static Color get _trackDark => brand.secondary;
  static Color get _trackLight => tint(brand.secondary, 0.86);
  static Color get _sunColorDark => tint(brand.warning, 0.35);
  static Color get _sunColorLight => brand.warning;
  static Color get _moonColorDark => tint(brand.accent, 0.45);
  static Color get _moonColorLight => brand.secondary;

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

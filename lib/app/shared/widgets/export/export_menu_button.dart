import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/export/export_format.dart';
import 'package:shc_stock/app/core/export/export_job.dart';
import 'package:shc_stock/app/core/export/export_service.dart';
import 'package:shc_stock/app/core/export/export_source.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/shared/widgets/export/export_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The Export control every list page carries.
//
// Format first, because picking one is the only decision most people make:
// the three formats download immediately using the default columns, and
// "More options…" is there for the rest. The label and the menu's section
// header are driven by the live row counts, so what the button promises is
// exactly what the list is showing.
// ─────────────────────────────────────────────────────────────────────────────
class ExportMenuButton extends StatefulWidget {
  final ExportSource source;

  /// Filled orange instead of bordered — used on the Reports toolbar, where
  /// Export is the page's primary action.
  final bool filled;

  /// Off for sources whose shape is fixed — a statement has two columns and
  /// one scope, so the dialog would have nothing to offer.
  final bool showMoreOptions;

  const ExportMenuButton({
    super.key,
    required this.source,
    this.filled = false,
    this.showMoreOptions = true,
  });

  @override
  State<ExportMenuButton> createState() => _ExportMenuButtonState();
}

class _ExportMenuButtonState extends State<ExportMenuButton> {
  final _overlay = OverlayPortalController();
  final _link = LayerLink();
  final _open = false.obs;

  static const double _height = 32;
  static const double _menuWidth = 212;

  @override
  void dispose() {
    _open.close();
    super.dispose();
  }

  void _toggle() {
    _open.value = !_open.value;
    _overlay.toggle();
  }

  void _close() {
    if (!_open.value) return;
    _open.value = false;
    _overlay.hide();
  }

  ExportScope get _scope =>
      widget.source.hasSelection ? ExportScope.selected : ExportScope.filtered;

  Future<void> _download(ExportFormat format) async {
    _close();
    await ExportService.to.start(
      widget.source,
      ExportRequest(
        scope: _scope,
        format: format,
        columnKeys: widget.source.defaultColumnKeys,
      ),
    );
  }

  void _openDialog() {
    _close();
    Get.dialog(ExportDialog(source: widget.source));
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlay,
        overlayChildBuilder: (_) => Positioned(
          width: _menuWidth,
          child: CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 6),
            child: TapRegion(
              onTapOutside: (_) => _close(),
              child: _ExportMenu(
                source: widget.source,
                scope: _scope,
                onPick: _download,
                onMoreOptions: widget.showMoreOptions ? _openDialog : null,
                onDismiss: _close,
              ),
            ),
          ),
        ),
        child: Obx(() => _button(context)),
      ),
    );
  }

  Widget _button(BuildContext context) {
    final colors = context.appColors;
    final selected = widget.source.countOf(ExportScope.selected);
    final label = selected > 0 ? 'Export $selected selected' : 'Export';
    final isOpen = _open.value;

    if (widget.filled) {
      return _Shell(
        height: _height,
        onTap: _toggle,
        background: AppColors.primaryOrange,
        border: AppColors.primaryOrange,
        children: [
          const Icon(Icons.download_rounded, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: _labelStyle(Colors.white)),
        ],
      );
    }

    // Open state: orange border on the orange tint, so it reads as the
    // anchor of the panel below it.
    final tint = AppColors.primaryOrange.withValues(alpha: 0.10);
    return _Shell(
      height: _height,
      onTap: _toggle,
      background: isOpen ? tint : colors.surface,
      border: isOpen ? AppColors.primaryOrange : colors.border,
      children: [
        Icon(
          Icons.download_rounded,
          size: 15,
          color: isOpen ? AppColors.primaryOrange : colors.textPrimary,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: _labelStyle(
            isOpen ? AppColors.primaryOrange : colors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          isOpen
              ? Icons.keyboard_arrow_up_rounded
              : Icons.keyboard_arrow_down_rounded,
          size: 16,
          color: isOpen ? AppColors.primaryOrange : colors.textPrimary,
        ),
      ],
    );
  }

  static TextStyle _labelStyle(Color color) => TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: color,
    fontFamily: 'Poppins',
  );
}

class _Shell extends StatelessWidget {
  final double height;
  final VoidCallback onTap;
  final Color background;
  final Color border;
  final List<Widget> children;

  const _Shell({
    required this.height,
    required this.onTap,
    required this.background,
    required this.border,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _ExportMenu extends StatelessWidget {
  final ExportSource source;
  final ExportScope scope;
  final ValueChanged<ExportFormat> onPick;
  final VoidCallback? onMoreOptions;
  final VoidCallback onDismiss;

  const _ExportMenu({
    required this.source,
    required this.scope,
    required this.onPick,
    required this.onMoreOptions,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): onDismiss},
      child: Focus(
        autofocus: true,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Read once, not via Obx: the menu is built fresh each time
                // it opens and nothing behind it can change while it is up.
                _sectionLabel(colors),
                for (final format in ExportFormat.values)
                  _MenuRow(
                    icon: format.icon,
                    iconColor: format.color(Theme.of(context).brightness),
                    label: format.menuLabel,
                    onTap: () => onPick(format),
                  ),
                if (onMoreOptions != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Divider(height: 1, color: colors.divider),
                  ),
                  _MenuRow(
                    icon: Icons.tune_rounded,
                    iconColor: colors.textSecondary,
                    label: 'More options…',
                    onTap: onMoreOptions!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// "DOWNLOAD 248 FILTERED" — or "DOWNLOAD 12 SELECTED" / "DOWNLOAD 611"
  /// when there is a selection / nothing is narrowing the list. Live: it
  /// tracks the same lists the table renders.
  Widget _sectionLabel(AppThemeColors colors) {
    final count = source.countOf(scope);
    final suffix = switch (scope) {
      ExportScope.selected => ' SELECTED',
      ExportScope.filtered => source.isFiltered ? ' FILTERED' : '',
      ExportScope.all => '',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: Text(
        'DOWNLOAD $count$suffix',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.05 * 9.5,
          color: colors.textHint,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

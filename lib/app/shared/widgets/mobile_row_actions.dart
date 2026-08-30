import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

/// Mobile counterpart of the web table's [RowActionButton]. Every mobile list
/// card used to hand-roll its own private `_ActBtn` / `_MobileActionBtn`, so
/// the same action ended up a different size and color from page to page —
/// and pages quietly shipped fewer actions than their web table offered.
/// One widget, one set of named constructors, so View / Edit / Duplicate /
/// Delete look and behave identically everywhere.
class MobileActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const MobileActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  /// Green eye — opens the record's details.
  factory MobileActionButton.view({
    required BuildContext context,
    required VoidCallback onTap,
  }) => MobileActionButton(
    icon: Icons.remove_red_eye_outlined,
    color: context.appColors.success,
    tooltip: 'View',
    onTap: onTap,
  );

  /// Purple pencil — opens the record's form pre-filled, saving in place.
  factory MobileActionButton.edit({
    required BuildContext context,
    required VoidCallback onTap,
  }) => MobileActionButton(
    icon: Icons.edit_outlined,
    color: context.appColors.purple,
    tooltip: 'Edit',
    onTap: onTap,
  );

  /// Blue copy — opens the form pre-filled but saves as a NEW record.
  factory MobileActionButton.duplicate({required VoidCallback onTap}) =>
      MobileActionButton(
        icon: Icons.copy_outlined,
        color: const Color(0xFF3B82F6),
        tooltip: 'Duplicate',
        onTap: onTap,
      );

  factory MobileActionButton.delete({required VoidCallback onTap}) =>
      MobileActionButton(
        icon: Icons.delete_outline_rounded,
        color: const Color(0xFFEF4444),
        tooltip: 'Delete',
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
      ),
    );
  }
}

/// Right-aligned action row for a mobile list card — same 6px gap the web
/// table uses between its row actions.
class MobileActionRow extends StatelessWidget {
  final List<MobileActionButton> actions;

  /// Anything that belongs on the left of the row (a stock chip, an item
  /// count); the actions stay pinned to the right of it.
  final Widget? leading;

  const MobileActionRow({super.key, required this.actions, this.leading});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) leading!,
        const Spacer(),
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          actions[i],
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';

/// Common small square icon button used in every list page's table row
/// "Actions" column (view / edit / duplicate / delete, etc).
///
/// Previously each list page (Categories, Products, Sales, Transactions,
/// Users, Purchase, Stock, Clients) duplicated its own copy of this widget
/// (`_ActionBtn` / `_ActBtn` / `_TxnActBtn`). Centralizing it here means a
/// single UI tweak (size, radius, hover) applies everywhere at once, and new
/// list pages don't need to redefine it.
class RowActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;

  /// Background tint behind the icon. Defaults to [color] at 10% opacity,
  /// matching every existing call site that doesn't need a custom bg.
  final Color? bg;

  /// Tooltip shown on hover. Pass null to skip the [Tooltip] wrapper.
  final String? tooltip;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final double borderRadius;

  const RowActionButton({
    super.key,
    required this.icon,
    required this.color,
    this.bg,
    this.tooltip,
    this.onTap,
    this.size = 28,
    this.iconSize = 16,
    this.borderRadius = 7,
  });

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg ?? color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) return button;
    return Tooltip(message: tooltip, child: button);
  }
}

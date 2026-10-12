part of 'web_purchase_layout.dart';

// One row of the purchase table (hover, actions, status) — part of web_purchase_layout.dart.

// ─────────────────────────────────────────────────────────────────────────────
// Purchase Row
// ─────────────────────────────────────────────────────────────────────────────
class _PurchaseRow extends StatefulWidget {
  final PurchaseOrder order;
  final int index;
  final AppThemeColors colors;
  final bool isLast;
  final VoidCallback onDelete;

  const _PurchaseRow({
    required this.order,
    required this.index,
    required this.colors,
    required this.isLast,
    required this.onDelete,
  });

  @override
  State<_PurchaseRow> createState() => _PurchaseRowState();
}

class _PurchaseRowState extends State<_PurchaseRow> {
  final _hovered = false.obs;

  @override
  void dispose() {
    _hovered.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final colors = widget.colors;
    final dateStr = fmtDate(o.date);

    // Resolve modified by
    final mod = resolveModifiedBy(
      storedName: o.modifiedBy,
      storedDate: o.modifiedAt,
    );

    return MouseRegion(
      onEnter: (_) => _hovered.value = true,
      onExit: (_) => _hovered.value = false,
      child: Obx(
        () => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _hovered.value ? colors.rowEven : colors.surface,
            border: widget.isLast
                ? null
                : Border(bottom: BorderSide(color: colors.divider, width: 0.8)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // # badge
                Container(
                  width: _kIdxW,
                  height: _kIdxW,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOrange,
                        fontFamily: brandFontFamily,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: _kGap),

                // PO Number
                Expanded(
                  flex: _kPoFlex,
                  child: Text(
                    o.poNumber,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.accent,
                      fontFamily: brandFontFamily,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Supplier
                Expanded(
                  flex: _kSupFlex,
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: context.appColors.accent.withValues(
                            alpha: 0.09,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.business_outlined,
                          color: context.appColors.accent,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          o.supplier,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                            fontFamily: brandFontFamily,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Date
                Expanded(
                  flex: _kDateFlex,
                  child: Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                      fontFamily: brandFontFamily,
                    ),
                  ),
                ),

                // Expected Delivery — a dash when the order has none.
                Expanded(
                  flex: _kExpFlex,
                  child: Text(
                    fmtDate(o.expectedDelivery),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                      fontFamily: brandFontFamily,
                    ),
                  ),
                ),

                // Items
                Expanded(
                  flex: _kItemFlex,
                  child: Center(
                    // Units, not lines — a single 5-unit line used to read "1"
                    // here while the form showed 5. The line count is still a
                    // hover away.
                    child: Tooltip(
                      message: o.items.isEmpty
                          ? '${o.itemCount} line items'
                          : o.qtyBreakdown,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          o.totalQtyLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                            fontFamily: brandFontFamily,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Amount
                Expanded(
                  flex: _kAmtFlex,
                  child: Text(
                    _formatAmount(o.amount),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      fontFamily: brandFontFamily,
                    ),
                  ),
                ),

                // Status badge — tap to change just the status, without
                // opening the whole record for editing.
                Expanded(
                  flex: _kStsFlex,
                  child: Center(
                    child: Tooltip(
                      message: 'Update status',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Get.dialog(
                          UpdatePurchaseStatusDialog(order: widget.order),
                        ),
                        child: _StatusBadge(status: o.status),
                      ),
                    ),
                  ),
                ),

                // Modified By
                Expanded(
                  flex: _kModFlex,
                  child: mod == null
                      ? ModifiedByEmpty(textHint: colors.textHint)
                      : ModifiedByCell(
                          name: mod.name,
                          date: mod.date,
                          textPrimary: colors.textPrimary,
                          textHint: colors.textHint,
                        ),
                ),

                // Actions: View, Edit, Delete
                Expanded(
                  flex: _kActFlex,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RowActionButton(
                        icon: Icons.remove_red_eye_outlined,
                        color: context.appColors.success,
                        bg: context.appColors.success.withValues(alpha: 0.10),
                        tooltip: 'View',
                        onTap: () =>
                            PurchaseActions.view(context, widget.order),
                      ),
                      if (canWriteModule('Purchase')) ...[
                        const SizedBox(width: 5),
                        RowActionButton(
                          icon: Icons.edit_outlined,
                          color: AppColors.primaryOrange,
                          bg: AppColors.primaryOrange.withValues(alpha: 0.10),
                          tooltip: 'Edit',
                          onTap: () => PurchaseActions.edit(widget.order),
                        ),
                        const SizedBox(width: 5),
                        RowActionButton(
                          icon: Icons.copy_outlined,
                          color: AppColors.info,
                          bg: AppColors.info.withValues(alpha: 0.10),
                          tooltip: 'Duplicate',
                          onTap: () => PurchaseActions.duplicate(widget.order),
                        ),
                        const SizedBox(width: 5),
                        RowActionButton(
                          icon: Icons.delete_outline_rounded,
                          iconSize: 18,
                          color: context.appColors.error,
                          // Neutral, not red-tinted — only the icon carries
                          // the warning color.
                          bg: context.appColors.tagBg,
                          tooltip: 'Delete',
                          onTap: widget.onDelete,
                        ),
                      ],
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

  String _formatAmount(double v) => formatRupees(v);
}

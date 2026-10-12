part of 'web_sales_layout.dart';

// One row of the sales table (hover, actions, status) — part of web_sales_layout.dart.

// ─────────────────────────────────────────────────────────────────────────────
// Sales Row — uses the SAME constants as _TableHeader
// ─────────────────────────────────────────────────────────────────────────────
class _SalesRow extends StatefulWidget {
  final SalesOrder order;
  final int displayIndex;
  final AppThemeColors colors;
  final bool isLast;

  const _SalesRow({
    required this.order,
    required this.displayIndex,
    required this.colors,
    required this.isLast,
  });

  @override
  State<_SalesRow> createState() => _SalesRowState();
}

class _SalesRowState extends State<_SalesRow> {
  // Local, widget-scoped hover flag — kept as an Rx on the persistent State
  // object (not setState) so only the row's background repaints on hover.
  final _hovered = false.obs;

  @override
  void dispose() {
    _hovered.close();
    super.dispose();
  }

  String _fmtDate(DateTime d) => fmtDate(d);

  String _fmtAmount(double v) => formatRupees(v);

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final c = widget.colors;

    return MouseRegion(
      onEnter: (_) => _hovered.value = true,
      onExit: (_) => _hovered.value = false,
      child: Obx(
        () => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _hovered.value ? c.rowEven : c.surface,
            border: widget.isLast
                ? null
                : Border(bottom: BorderSide(color: c.divider, width: 0.8)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // # badge
                SizedBox(
                  width: _kIdxWidth,
                  child: Container(
                    width: _kIdxWidth,
                    height: _kIdxWidth,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.displayIndex}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryOrange,
                          fontFamily: brandFontFamily,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: _kColGap),

                // SO Number
                Expanded(
                  flex: _kSoFlex,
                  child: Text(
                    o.soNumber,
                    // The design paints the order number in the brand orange.
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                      fontFamily: brandFontFamily,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Client
                Expanded(
                  flex: _kClientFlex,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: o.clientColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            o.clientBadge,
                            style: TextStyle(
                              fontSize: o.clientBadge.length > 2 ? 9.5 : 11,
                              fontWeight: FontWeight.w700,
                              color: o.clientColor,
                              fontFamily: brandFontFamily,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          o.client,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: c.textPrimary,
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
                    _fmtDate(o.date),
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textSecondary,
                      fontFamily: brandFontFamily,
                    ),
                  ),
                ),

                // Items
                Expanded(
                  flex: _kItemsFlex,
                  child: Center(
                    // Units, not lines — see the purchase list for why.
                    child: Tooltip(
                      message: o.items.isEmpty
                          ? '${o.itemCount} line items'
                          : o.qtyBreakdown,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          o.totalQtyLabel,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
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
                    _fmtAmount(o.amount),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                      fontFamily: brandFontFamily,
                    ),
                  ),
                ),

                // Status badge — tap to change just the status, now that the
                // row's third action is Delete.
                Expanded(
                  flex: _kStatusFlex,
                  child: Center(
                    child: Tooltip(
                      message: 'Update status',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Get.dialog(
                          UpdateSalesStatusDialog(order: widget.order),
                        ),
                        child: _Badge(
                          label: o.status.label,
                          color: o.status.color,
                        ),
                      ),
                    ),
                  ),
                ),

                // Payment Status badge
                Expanded(
                  flex: _kPayFlex,
                  child: Center(
                    child: _Badge(
                      label: o.paymentStatus.label,
                      color: o.paymentStatus.color,
                    ),
                  ),
                ),

                // Modified By — same cell the Purchase table uses.
                Expanded(
                  flex: _kModFlex,
                  child: Builder(
                    builder: (context) {
                      final mod = resolveModifiedBy(
                        storedName: o.modifiedBy,
                        storedDate: o.modifiedAt,
                      );
                      return mod == null
                          ? ModifiedByEmpty(textHint: c.textHint)
                          : ModifiedByCell(
                              name: mod.name,
                              date: mod.date,
                              textPrimary: c.textPrimary,
                              textHint: c.textHint,
                            );
                    },
                  ),
                ),

                // Actions
                Expanded(
                  flex: _kActFlex,
                  // Scales down instead of overflowing when the window is narrow
                  // (a 1366px laptop with the summary rail still lost 27px).
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RowActionButton(
                            icon: Icons.receipt_long_outlined,
                            color: AppColors.primaryOrange,
                            bg: AppColors.primaryOrange.withValues(alpha: 0.10),
                            tooltip: 'Bill',
                            onTap: () => SalesActions.bill(widget.order),
                          ),
                          const SizedBox(width: 6),
                          RowActionButton(
                            icon: Icons.remove_red_eye_outlined,
                            color: context.appColors.success,
                            bg: context.appColors.success.withValues(
                              alpha: 0.10,
                            ),
                            tooltip: 'View',
                            onTap: () =>
                                SalesActions.view(context, widget.order),
                          ),
                          if (canWriteModule('Sales')) ...[
                            const SizedBox(width: 6),
                            RowActionButton(
                              icon: Icons.edit_outlined,
                              color: AppColors.primaryOrange,
                              bg: AppColors.primaryOrange.withValues(
                                alpha: 0.10,
                              ),
                              tooltip: 'Edit',
                              onTap: () => SalesActions.edit(widget.order),
                            ),
                            const SizedBox(width: 6),
                            RowActionButton(
                              icon: Icons.copy_outlined,
                              color: AppColors.info,
                              bg: const Color(
                                0xFF3B82F6,
                              ).withValues(alpha: 0.10),
                              tooltip: 'Duplicate',
                              onTap: () => SalesActions.duplicate(widget.order),
                            ),
                            const SizedBox(width: 6),
                            RowActionButton(
                              icon: Icons.delete_outline_rounded,
                              iconSize: 18,
                              color: context.appColors.error,
                              // Neutral, not red-tinted — only the icon carries
                              // the warning color.
                              bg: context.appColors.tagBg,
                              tooltip: 'Delete',
                              onTap: () =>
                                  SalesActions.delete(context, widget.order),
                            ),
                          ],
                        ],
                      ),
                    ),
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

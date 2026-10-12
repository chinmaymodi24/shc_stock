part of 'web_products_layout.dart';

// ── Product Table Row ─────────────────────────────────────────────────────────
class _ProductRow extends StatefulWidget {
  final ProductModel product;
  final bool isLast;
  final ProductsController controller;

  const _ProductRow({
    required this.product,
    required this.isLast,
    required this.controller,
  });

  @override
  State<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<_ProductRow> {
  // Same row surface as every other list table (Inventory, Sales, ...): plain
  // rows, no zebra stripes, and rowEven only while hovered. Kept as an Rx on
  // the persistent State (not setState) so only the background repaints.
  final _hovered = false.obs;

  @override
  void dispose() {
    _hovered.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final controller = widget.controller;
    final fmt = NumberFormat('#,##,##0', 'en_IN');
    final colors = context.appColors;

    Color stockColor;
    if (product.currentStock == 0) {
      stockColor = colors.error;
    } else if (product.currentStock <= product.minimumStock) {
      stockColor = colors.warning;
    } else {
      stockColor = colors.success;
    }

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 34,
                  child: Obx(
                    () => _SelectBox(
                      checked: controller.selectedIds.contains(product.id),
                      onTap: () => controller.toggleSelected(product.id),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      ProductThumbnail(
                        imageUrl: product.imageUrl,
                        fallbackLabel: product.name,
                        size: 38,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                                fontFamily: brandFontFamily,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.sku,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: colors.textHint,
                                fontFamily: brandFontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    product.categoryName.replaceFirst(RegExp(r'^\d+\.\s'), ''),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                      fontFamily: brandFontFamily,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    product.subCategory,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                      fontFamily: brandFontFamily,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '₹${fmt.format(product.sellingPrice)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                      fontFamily: brandFontFamily,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 52),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: stockColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        fmtStockQty(product.currentStock),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: stockColor,
                          fontFamily: brandFontFamily,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Builder(
                    builder: (_) {
                      final mod = resolveModifiedBy(
                        storedName: product.modifiedBy,
                        storedDate: product.modifiedAt,
                      );
                      if (mod == null) {
                        return ModifiedByEmpty(textHint: colors.textHint);
                      }
                      return ModifiedByCell(
                        name: mod.name,
                        date: mod.date,
                        textPrimary: colors.textPrimary,
                        textHint: colors.textHint,
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RowActionButton(
                        icon: Icons.remove_red_eye_outlined,
                        color: colors.success,
                        bg: colors.success.withValues(alpha: 0.10),
                        tooltip: 'View',
                        onTap: () => ProductActions.view(product),
                      ),
                      if (canWriteModule('Products')) ...[
                        const SizedBox(width: 6),
                        RowActionButton(
                          icon: Icons.edit_outlined,
                          color: AppColors.primaryOrange,
                          bg: AppColors.primaryOrange.withValues(alpha: 0.10),
                          tooltip: 'Edit',
                          onTap: () => ProductActions.edit(product),
                        ),
                        const SizedBox(width: 6),
                        RowActionButton(
                          icon: Icons.copy_outlined,
                          color: AppColors.info,
                          bg: AppColors.info.withValues(alpha: 0.10),
                          tooltip: 'Duplicate',
                          onTap: () => ProductActions.duplicate(product),
                        ),
                        const SizedBox(width: 6),
                        RowActionButton(
                          icon: Icons.delete_outline_rounded,
                          iconSize: 18,
                          color: colors.error,
                          // Neutral, not red-tinted — only the icon carries the
                          // warning color.
                          bg: colors.tagBg,
                          tooltip: 'Delete',
                          onTap: () => ProductActions.delete(context, product),
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
}

/// The row / select-all checkbox. Ticking rows is what turns the toolbar
/// button into "Export 12 selected".
class _SelectBox extends StatelessWidget {
  final bool checked;
  final VoidCallback onTap;
  const _SelectBox({required this.checked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Icon(
          checked
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank_rounded,
          size: 18,
          color: checked ? AppColors.primaryOrange : colors.textHint,
        ),
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _PageButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _PageButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.border),
          color: enabled ? colors.surface : colors.background,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? colors.textPrimary : colors.textHint,
        ),
      ),
    );
  }
}

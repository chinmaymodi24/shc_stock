part of 'web_categories_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Empty state — no categories yet
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final AppThemeColors colors;
  final VoidCallback onAdd;
  const _EmptyState({required this.colors, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_outlined, size: 40, color: colors.textHint),
          const SizedBox(height: 12),
          Text(
            'No categories yet',
            style: TextStyle(
              fontSize: 14,
              color: colors.textHint,
              fontFamily: brandFontFamily,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
            label: Text(
              'Add Category',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: brandFontFamily,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Left sidebar category item
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarCategoryItem extends StatelessWidget {
  final String name;
  final int count;
  final bool selected;
  final AppThemeColors colors;
  final VoidCallback onTap;

  const _SidebarCategoryItem({
    required this.name,
    required this.count,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryOrange.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: selected ? AppColors.primaryOrange : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.primaryOrange
                      : colors.textPrimary,
                  fontFamily: brandFontFamily,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12.5,
                color: selected ? AppColors.primaryOrange : colors.textHint,
                fontFamily: brandFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right detail panel — selected category's subcategories table
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryDetailPanel extends StatelessWidget {
  final CategoryModel cat;
  final int globalIndex;
  final int skuCount;
  final int Function(String categoryName, String subCategory) subSkuCount;
  final AppThemeColors colors;
  final VoidCallback onEditCategory, onDeleteCategory, onAddSub;
  final ValueChanged<int> onEditSub, onDeleteSub;

  const _CategoryDetailPanel({
    required this.cat,
    required this.globalIndex,
    required this.skuCount,
    required this.subSkuCount,
    required this.colors,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onAddSub,
    required this.onEditSub,
    required this.onDeleteSub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          fontFamily: brandFontFamily,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${cat.subProducts.length} subcategories · $skuCount SKUs',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.textSecondary,
                          fontFamily: brandFontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canWriteModule('Categories')) ...[
                  _HeaderActionBtn(
                    icon: Icons.edit_rounded,
                    label: 'Edit',
                    bgColor: colors.background.computeLuminance() > 0.5
                        ? const Color(0xFFF3F1EC)
                        : colors.inputFill,
                    fgColor: colors.textPrimary,
                    onTap: onEditCategory,
                  ),
                  const SizedBox(width: 8),
                  _HeaderActionBtn(
                    icon: Icons.delete_rounded,
                    label: 'Delete',
                    bgColor: colors.error.withValues(alpha: 0.12),
                    fgColor: colors.error,
                    onTap: onDeleteCategory,
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),

          // Sub-categories label
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Text(
              'SUBCATEGORIES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.textHint,
                fontFamily: brandFontFamily,
                letterSpacing: 0.6,
              ),
            ),
          ),

          if (cat.subProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No subcategories yet',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textHint,
                    fontFamily: brandFontFamily,
                  ),
                ),
              ),
            )
          else ...[
            // Table header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Subcategory',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                        fontFamily: brandFontFamily,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                        fontFamily: brandFontFamily,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 76,
                    child: Text(
                      'Actions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                        fontFamily: brandFontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.divider),
            ...cat.subProducts.asMap().entries.map(
              (e) => _SubCategoryTableRow(
                name: e.value,
                itemCount: subSkuCount(cat.name, e.value),
                colors: colors,
                onEdit: () => onEditSub(e.key),
                onDelete: () => onDeleteSub(e.key),
              ),
            ),
          ],

          // Add subcategory
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: InkWell(
              onTap: onAddSub,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: AppColors.primaryOrange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Add subcategory',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                      fontFamily: brandFontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubCategoryTableRow extends StatefulWidget {
  final String name;
  final int itemCount;
  final AppThemeColors colors;
  final VoidCallback onEdit, onDelete;

  const _SubCategoryTableRow({
    required this.name,
    required this.itemCount,
    required this.colors,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SubCategoryTableRow> createState() => _SubCategoryTableRowState();
}

class _SubCategoryTableRowState extends State<_SubCategoryTableRow> {
  // Local, widget-scoped hover flag — kept as an Rx on the persistent State
  // object (not setState) so only the row's background repaints on hover.
  final _hovered = false.obs;

  @override
  void dispose() {
    _hovered.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return MouseRegion(
      onEnter: (_) => _hovered.value = true,
      onExit: (_) => _hovered.value = false,
      child: Obx(
        () => Container(
          color: _hovered.value ? c.rowEven : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  widget.name,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                    fontFamily: brandFontFamily,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '${widget.itemCount}',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: c.textPrimary,
                    fontFamily: brandFontFamily,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Row(
                  children: [
                    if (canWriteModule('Categories')) ...[
                      RowActionButton(
                        icon: Icons.edit_outlined,
                        color: AppColors.primaryOrange,
                        bg: AppColors.primaryOrange.withValues(alpha: 0.10),
                        tooltip: 'Edit',
                        onTap: widget.onEdit,
                      ),
                      const SizedBox(width: 6),
                      RowActionButton(
                        icon: Icons.delete_outline_rounded,
                        iconSize: 18,
                        color: c.error,
                        // Neutral, not red-tinted — only the icon carries the
                        // warning color.
                        bg: c.tagBg,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header Action Button (filled Edit/Delete pill, matches target UI)
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor, fgColor;
  final VoidCallback onTap;
  const _HeaderActionBtn({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.fgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(appColors.radius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(appColors.radius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fgColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: brandFontFamily,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simple Name-only Form Dialog — used for Add/Edit Category and
// Add/Edit Sub-Category, matching the approved design (single "Name" field,
// Cancel/Save row).
// ─────────────────────────────────────────────────────────────────────────────
class _SimpleFormDialog extends StatefulWidget {
  final String title;
  final String initialName;

  /// Awaited, so the Save button can show its own spinner.
  final Future<void> Function(String) onSave;

  const _SimpleFormDialog({
    required this.title,
    this.initialName = '',
    required this.onSave,
  });

  @override
  State<_SimpleFormDialog> createState() => _SimpleFormDialogState();
}

class _SimpleFormDialogState extends State<_SimpleFormDialog> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) await widget.onSave(name);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: brandFontFamily,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                autofocus: true,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textPrimary,
                  fontFamily: brandFontFamily,
                ),
                decoration: InputDecoration(
                  hintText: 'Name…',
                  hintStyle: TextStyle(
                    color: colors.textHint,
                    fontFamily: brandFontFamily,
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.border, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.border, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.primaryOrange,
                      width: 1.5,
                    ),
                  ),
                ),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 20),
              // IntrinsicHeight + stretch rather than matching padding by eye:
              // "Cancel" is a plain Container, "Save" an ElevatedButton inside
              // AppAsyncButton, and Material's button metrics don't always
              // agree with a hand-set padding down to the pixel — stretching
              // both to the row's own tallest content guarantees they match
              // regardless.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: Get.back,
                        borderRadius: BorderRadius.circular(appColors.radius),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: colors.background.computeLuminance() > 0.5
                                ? const Color(0xFFF3F1EC)
                                : colors.inputFill,
                            borderRadius: BorderRadius.circular(
                              appColors.radius,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              fontFamily: brandFontFamily,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppAsyncButton(
                        label: 'Save',
                        onPressed: _save,
                        expand: true,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        radius: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

part of 'mobile_categories_layout.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Subcategory row — name + item count stacked on the left, tinted edit/delete
// chips on the right. Plain (no card/border) so a stack of them reads as one
// list inside the expanded category.
// ─────────────────────────────────────────────────────────────────────────────
class _SubCategoryInlineRow extends StatelessWidget {
  final String name;
  final int itemCount;
  final AppThemeColors colors;
  final VoidCallback onEdit, onDelete;

  const _SubCategoryInlineRow({
    required this.name,
    required this.itemCount,
    required this.colors,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Indented from the category name so the sub-category list reads as a
      // level below it.
      padding: const EdgeInsets.fromLTRB(30, 11, 12, 11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    fontFamily: brandFontFamily,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$itemCount items',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.accent,
                    fontFamily: brandFontFamily,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _SubChipBtn(
            icon: Icons.edit_outlined,
            color: AppColors.primaryOrange,
            onTap: onEdit,
          ),
          const SizedBox(width: 8),
          _SubChipBtn(
            icon: Icons.delete_outline_rounded,
            color: AppColors.danger,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Helpers
// ─────────────────────────────────────────────────────────────────────────────
/// Small square tinted-background icon button — used for both a subcategory
/// row and the category's own Edit / Delete actions in an expanded card.
class _SubChipBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SubChipBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _MobileFormDialog extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController controller;

  /// Awaited, so the Save button can show its own spinner.
  final Future<void> Function() onSave;

  const _MobileFormDialog({
    required this.title,
    required this.hint,
    required this.controller,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.primaryOrange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: brandFontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: TextStyle(
                fontSize: 14,
                color: colors.textPrimary,
                fontFamily: brandFontFamily,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: colors.textHint,
                  fontFamily: brandFontFamily,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                filled: true,
                fillColor: colors.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(appColors.radius),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(appColors.radius),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(appColors.radius),
                  borderSide: BorderSide(
                    color: AppColors.primaryOrange,
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: (_) => onSave(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: Get.back,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: brandFontFamily,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AppAsyncButton(
                  label: 'Save',
                  onPressed: onSave,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  radius: 8,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

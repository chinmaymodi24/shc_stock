part of 'export_dialog.dart';

class _RecordCard extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _RecordCard({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryOrange.withValues(alpha: 0.10)
              : colors.surface,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: active ? AppColors.primaryOrange : colors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              active
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 17,
              color: active ? AppColors.primaryOrange : colors.textHint,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: colors.textPrimary,
                  fontFamily: brandFontFamily,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.primaryOrange : colors.textSecondary,
                fontFamily: brandFontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColumnChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ColumnChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryOrange.withValues(alpha: 0.10)
              : colors.tagBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(
                Icons.check_rounded,
                size: 13,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryOrange.withValues(alpha: 0.10)
              : colors.surface,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: active ? AppColors.primaryOrange : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.primaryOrange : colors.textSecondary,
            fontFamily: brandFontFamily,
          ),
        ),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final Widget Function(T)? leadingOf;
  final ValueChanged<T> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.leadingOf,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        isDense: true,
        underline: const SizedBox(),
        dropdownColor: colors.surface,
        borderRadius: BorderRadius.circular(8),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18,
          color: colors.textSecondary,
        ),
        items: [
          for (final item in items)
            DropdownMenuItem<T>(
              value: item,
              child: Row(
                children: [
                  if (leadingOf != null) ...[
                    leadingOf!(item),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      labelOf(item),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                        fontFamily: brandFontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

/// Names a column set. Deliberately tiny — the only decision is the name.
class _SavePresetDialog extends StatelessWidget {
  final TextEditingController controller;
  final int columnCount;

  const _SavePresetDialog({
    required this.controller,
    required this.columnCount,
  });

  void _submit() {
    final name = controller.text.trim();
    if (name.isEmpty) return;
    Get.back<String>(result: name);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Save column preset',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: brandFontFamily,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$columnCount ${columnCount == 1 ? 'column' : 'columns'} '
                'will be saved under this name.',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textHint,
                  fontFamily: brandFontFamily,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                onSubmitted: (_) => _submit(),
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textPrimary,
                  fontFamily: brandFontFamily,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Monthly review',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: Get.back,
                    borderRadius: BorderRadius.circular(7),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                          fontFamily: brandFontFamily,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _submit,
                    borderRadius: BorderRadius.circular(7),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: brandFontFamily,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

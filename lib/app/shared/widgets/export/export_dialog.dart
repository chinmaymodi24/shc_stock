import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/export/export_format.dart';
import 'package:shc_stock/app/core/export/export_presets.dart';
import 'package:shc_stock/app/core/export/export_job.dart';
import 'package:shc_stock/app/core/export/export_service.dart';
import 'package:shc_stock/app/core/export/export_source.dart';
import 'package:shc_stock/app/core/export/writers/pdf_table_writer.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// "More options…" — the full export dialog.
//
// RECORDS states the scope as a fact rather than asking a question: the list
// is already filtered, so the filtered view is what is selected, with the
// alternatives (and their counts) right there. Nothing in here re-queries;
// every count comes from the same [ExportSource] the list page renders from.
// ─────────────────────────────────────────────────────────────────────────────
class ExportDialog extends StatefulWidget {
  final ExportSource source;

  const ExportDialog({super.key, required this.source});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  late final Rx<ExportScope> _scope;
  final _format = ExportFormat.excel.obs;
  late final RxList<String> _columns;
  final _layout = PdfPageLayout.landscape.obs;
  final _email = false.obs;
  final _preset = 'Default'.obs;
  final _busy = false.obs;

  ExportSource get _source => widget.source;

  @override
  void initState() {
    super.initState();
    // A selection is the most specific thing the user has told us, so it wins
    // as the default when one exists.
    _scope =
        (_source.hasSelection ? ExportScope.selected : ExportScope.filtered)
            .obs;
    _columns = _source.defaultColumnKeys.toList().obs;
  }

  @override
  void dispose() {
    _scope.close();
    _format.close();
    _columns.close();
    _layout.close();
    _email.close();
    _preset.close();
    _busy.close();
    super.dispose();
  }

  int get _rowCount => _source.countOf(_scope.value);

  /// Rows × selected columns × a per-format cell cost, plus file overhead.
  /// Deliberately rough — it is there to warn about a 40 MB download, not to
  /// predict a byte count.
  int get _estimatedBytes {
    final cells = _rowCount * _columns.length;
    final overhead = switch (_format.value) {
      ExportFormat.excel => 6 * 1024,
      ExportFormat.pdf => 3 * 1024,
      ExportFormat.csv => 256,
    };
    return overhead + cells * _format.value.bytesPerCell;
  }

  /// The entity's built-in presets plus whatever the user has saved.
  List<ExportColumnPreset> get _presets => [
    ..._source.presets,
    if (Get.isRegistered<ExportPresetStore>())
      ...ExportPresetStore.to.forEntity(_source.entityKey),
  ];

  static const _saveAsOption = 'Save current as…';

  void _applyPreset(String name) {
    if (name == _saveAsOption) {
      _promptSavePreset();
      return;
    }
    _preset.value = name;
    if (name == 'Default') {
      _columns.assignAll(_source.defaultColumnKeys);
      return;
    }
    if (name == 'All columns') {
      _columns.assignAll(_source.columns.map((c) => c.key));
      return;
    }
    final preset = _presets.firstWhereOrNull((p) => p.name == name);
    if (preset != null) _columns.assignAll(preset.columnKeys);
  }

  Future<void> _promptSavePreset() async {
    if (!Get.isRegistered<ExportPresetStore>()) return;
    final controller = TextEditingController();
    final name = await Get.dialog<String>(
      _SavePresetDialog(controller: controller, columnCount: _columns.length),
    );
    controller.dispose();
    if (name == null) return;
    final saved = await ExportPresetStore.to.save(
      _source.entityKey,
      name,
      _columns.toList(),
    );
    if (saved) _preset.value = name.trim();
  }

  Future<void> _export() async {
    if (_columns.isEmpty || _busy.value) return;
    _busy.value = true;
    final request = ExportRequest(
      scope: _scope.value,
      format: _format.value,
      columnKeys: _columns.toList(),
      pageLayout: _layout.value,
      emailWhenReady: _email.value,
    );
    Get.back();
    await ExportService.to.start(_source, request);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: 456,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(colors),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _sectionLabel(colors, 'RECORDS'),
                      const SizedBox(height: 8),
                      Obx(() => _recordCards(colors)),
                      const SizedBox(height: 18),
                      _formatAndPreset(colors),
                      const SizedBox(height: 18),
                      _columnsPicker(colors),
                      Obx(
                        () => _format.value == ExportFormat.pdf
                            ? Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: _pageLayout(colors),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),
                      _emailCheckbox(colors),
                    ],
                  ),
                ),
              ),
              _footer(colors),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _header(AppThemeColors colors) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
    child: Row(
      children: [
        Expanded(
          child: Text(
            'Export ${_source.entityLabel}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              fontFamily: brandFontFamily,
            ),
          ),
        ),
        IconButton(
          onPressed: Get.back,
          icon: Icon(Icons.close_rounded, size: 18, color: colors.textHint),
          splashRadius: 18,
          tooltip: 'Close',
        ),
      ],
    ),
  );

  Widget _sectionLabel(AppThemeColors colors, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.05 * 9.5,
      color: colors.textHint,
      fontFamily: brandFontFamily,
    ),
  );

  // ── Records ───────────────────────────────────────────────────────────────
  Widget _recordCards(AppThemeColors colors) {
    final selected = _source.countOf(ExportScope.selected);
    return Column(
      children: [
        if (selected > 0) ...[
          _RecordCard(
            label: '$selected selected ${selected == 1 ? 'row' : 'rows'}',
            count: selected,
            active: _scope.value == ExportScope.selected,
            onTap: () => _scope.value = ExportScope.selected,
          ),
          const SizedBox(height: 8),
        ],
        _RecordCard(
          label: 'Current filtered view',
          count: _source.countOf(ExportScope.filtered),
          active: _scope.value == ExportScope.filtered,
          onTap: () => _scope.value = ExportScope.filtered,
        ),
        const SizedBox(height: 8),
        _RecordCard(
          label: 'All ${_source.rowNoun}',
          count: _source.countOf(ExportScope.all),
          active: _scope.value == ExportScope.all,
          onTap: () => _scope.value = ExportScope.all,
        ),
      ],
    );
  }

  // ── Format + preset ───────────────────────────────────────────────────────
  Widget _formatAndPreset(AppThemeColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(colors, 'FORMAT'),
              const SizedBox(height: 8),
              Obx(
                () => _Dropdown<ExportFormat>(
                  value: _format.value,
                  items: ExportFormat.values,
                  labelOf: (f) => f.label,
                  leadingOf: (f) => Icon(
                    f.icon,
                    size: 15,
                    color: f.color(Theme.of(context).brightness),
                  ),
                  onChanged: (f) => _format.value = f,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(colors, 'COLUMN PRESET'),
              const SizedBox(height: 8),
              // Inside the Obx: saving a preset has to make it appear in
              // this list without reopening the dialog.
              Obx(() {
                final presetNames = [
                  'Default',
                  ..._presets.map((p) => p.name),
                  'All columns',
                  _saveAsOption,
                ];
                return _Dropdown<String>(
                  value: presetNames.contains(_preset.value)
                      ? _preset.value
                      : 'Default',
                  items: presetNames,
                  labelOf: (name) => name == 'Default'
                      ? 'Default (${_source.defaultColumnKeys.length})'
                      : name,
                  onChanged: _applyPreset,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ── Columns ───────────────────────────────────────────────────────────────
  Widget _columnsPicker(AppThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel(colors, 'COLUMNS'),
            const Spacer(),
            Obx(() {
              final all = _columns.length == _source.columns.length;
              return InkWell(
                onTap: () {
                  _preset.value = all ? 'Default' : 'All columns';
                  _columns.assignAll(
                    all
                        ? _source.defaultColumnKeys
                        : _source.columns.map((c) => c.key),
                  );
                },
                child: Text(
                  all ? 'Reset' : 'Select all',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryOrange,
                    fontFamily: brandFontFamily,
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 10),
        Obx(
          () => Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final column in _source.columns)
                _ColumnChip(
                  label: column.label,
                  selected: _columns.contains(column.key),
                  onTap: () {
                    _preset.value = 'Custom';
                    if (_columns.contains(column.key)) {
                      // Never let the user export a file with no columns.
                      if (_columns.length > 1) _columns.remove(column.key);
                    } else {
                      _columns.add(column.key);
                    }
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── PDF page layout ───────────────────────────────────────────────────────
  Widget _pageLayout(AppThemeColors colors) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel(colors, 'PAGE LAYOUT'),
      const SizedBox(height: 8),
      Obx(
        () => Row(
          children: [
            for (final layout in PdfPageLayout.values) ...[
              Expanded(
                child: _SegmentButton(
                  label: layout.label,
                  active: _layout.value == layout,
                  onTap: () => _layout.value = layout,
                ),
              ),
              if (layout != PdfPageLayout.values.last)
                const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    ],
  );

  Widget _emailCheckbox(AppThemeColors colors) => InkWell(
    onTap: () => _email.value = !_email.value,
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Obx(
            () => Icon(
              _email.value
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 18,
              color: _email.value ? AppColors.primaryOrange : colors.textHint,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Email me the file when it is ready',
              style: TextStyle(
                fontSize: 12.5,
                color: colors.textPrimary,
                fontFamily: brandFontFamily,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _footer(AppThemeColors colors) {
    final footerBg = colors.tableHeaderBg;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: footerBg,
        border: Border(top: BorderSide(color: colors.divider)),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => Text(
                'Estimated size ~${formatFileSize(_estimatedBytes)}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: colors.textHint,
                  fontFamily: brandFontFamily,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: Get.back,
            borderRadius: BorderRadius.circular(7),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          Obx(
            () => InkWell(
              onTap: _busy.value ? null : _export,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_rounded, size: 15, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Export',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: brandFontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pieces ──────────────────────────────────────────────────────────────────

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

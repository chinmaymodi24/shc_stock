import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/brand_controller.dart';
import 'package:shc_stock/app/core/theme/brand_theme.dart';
import 'package:shc_stock/app/modules/settings/views/appearance/appearance_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Card 2 — Color palette, in three modes.
//
//   Presets     start from an industry palette
//   Custom hex  all 16 colours as hex rows, grouped and captioned
//   Advanced    the same 16 as swatch-picker cards
//
// Presets is deliberately first: most buyers want "make it look like our
// brand" and never open the other two. Touching any single colour in either
// of the other modes drops the preset badge, because the palette stops being
// the thing that preset describes.
// ─────────────────────────────────────────────────────────────────────────────

enum PaletteMode { presets, customHex, advanced }

class ColorPaletteCard extends StatefulWidget {
  const ColorPaletteCard({super.key});

  @override
  State<ColorPaletteCard> createState() => _ColorPaletteCardState();
}

class _ColorPaletteCardState extends State<ColorPaletteCard> {
  PaletteMode _mode = PaletteMode.presets;

  @override
  Widget build(BuildContext context) {
    final bc = Get.find<BrandController>();
    return AppearanceCard(
      title: 'Color palette',
      subtitle: 'Start from a preset, then fine-tune any individual color',
      trailing: _ModeSwitch(
        mode: _mode,
        onChanged: (m) => setState(() => _mode = m),
      ),
      child: Obx(() {
        final draft = bc.draft.value;
        switch (_mode) {
          case PaletteMode.presets:
            return _PresetGrid(draft: draft, onPick: bc.selectPreset);
          case PaletteMode.customHex:
            return _ColorGroups(
              draft: draft,
              rowBuilder: (field) => _HexRow(field: field, draft: draft),
            );
          case PaletteMode.advanced:
            return _ColorGroups(
              draft: draft,
              rowBuilder: null,
              gridBuilder: (fields) =>
                  _AdvancedGrid(fields: fields, draft: draft),
            );
        }
      }),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  final PaletteMode mode;
  final ValueChanged<PaletteMode> onChanged;
  const _ModeSwitch({required this.mode, required this.onChanged});

  static const _labels = {
    PaletteMode.presets: 'Presets',
    PaletteMode.customHex: 'Custom hex',
    PaletteMode.advanced: 'Advanced',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.rowEven,
        borderRadius: BorderRadius.circular(c.radiusSm + 2),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in _labels.entries)
            InkWell(
              onTap: () => onChanged(entry.key),
              borderRadius: BorderRadius.circular(c.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: mode == entry.key ? c.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(c.radiusSm),
                  border: Border.all(
                    color: mode == entry.key
                        ? AppColors.primaryOrange
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: mode == entry.key
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: mode == entry.key
                        ? AppColors.primaryOrange
                        : c.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Presets ────────────────────────────────────────────────────────────────
class _PresetGrid extends StatelessWidget {
  final BrandTheme draft;
  final ValueChanged<BrandPreset> onPick;
  const _PresetGrid({required this.draft, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth > 720
            ? 4
            : box.maxWidth > 480
            ? 3
            : 2;
        const gap = 12.0;
        final width = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final preset in kBrandPresets)
              SizedBox(
                width: width,
                child: _PresetCard(
                  preset: preset,
                  selected: draft.presetName == preset.name,
                  onTap: () => onPick(preset),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PresetCard extends StatelessWidget {
  final BrandPreset preset;
  final bool selected;
  final VoidCallback onTap;

  const _PresetCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final primary = AppColors.primaryOrange;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(c.radius),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? c.tintPrimary : c.surface,
          borderRadius: BorderRadius.circular(c.radius),
          border: Border.all(
            color: selected ? primary : c.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final swatch in [
                  preset.primary,
                  preset.secondary,
                  preset.success,
                  preset.danger,
                ]) ...[
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: swatch,
                      borderRadius: BorderRadius.circular(c.radiusSm),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              preset.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            Text(
              preset.industry,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: c.textHint),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared grouping for the two per-colour modes ───────────────────────────
class _ColorGroups extends StatelessWidget {
  final BrandTheme draft;
  final Widget Function(BrandColorField)? rowBuilder;
  final Widget Function(List<BrandColorField>)? gridBuilder;

  const _ColorGroups({required this.draft, this.rowBuilder, this.gridBuilder});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final groups = <String, List<BrandColorField>>{};
    for (final f in kBrandColorFields) {
      groups.putIfAbsent(f.group, () => []).add(f);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groups.entries) ...[
          Text(
            entry.key.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: c.textHint,
            ),
          ),
          const SizedBox(height: 8),
          if (gridBuilder != null)
            gridBuilder!(entry.value)
          else
            for (final f in entry.value) rowBuilder!(f),
          if (entry.key != groups.keys.last) const SizedBox(height: 18),
        ],
      ],
    );
  }
}

// ── Custom hex mode ────────────────────────────────────────────────────────
class _HexRow extends StatelessWidget {
  final BrandColorField field;
  final BrandTheme draft;
  const _HexRow({required this.field, required this.draft});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bc = Get.find<BrandController>();
    final value = field.read(draft);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ColorSwatchButton(
            color: value,
            onPicked: (picked) => bc.editColor((b) => field.write(b, picked)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  field.usage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: c.textHint),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          HexField(
            value: value,
            onChanged: (picked) => bc.editColor((b) => field.write(b, picked)),
          ),
        ],
      ),
    );
  }
}

// ── Advanced mode ──────────────────────────────────────────────────────────
class _AdvancedGrid extends StatelessWidget {
  final List<BrandColorField> fields;
  final BrandTheme draft;
  const _AdvancedGrid({required this.fields, required this.draft});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bc = Get.find<BrandController>();

    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth > 640
            ? 3
            : box.maxWidth > 400
            ? 2
            : 1;
        const gap = 12.0;
        final width = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final f in fields)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(c.radius),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        f.usage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.3,
                          color: c.textHint,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // The picker square is the `<input type="color">` the
                      // spec asks for; Flutter has no native one.
                      ColorSwatchButton(
                        color: f.read(draft),
                        size: 44,
                        onPicked: (picked) =>
                            bc.editColor((b) => f.write(b, picked)),
                      ),
                      const SizedBox(height: 8),
                      HexField(
                        value: f.read(draft),
                        width: double.infinity,
                        onChanged: (picked) =>
                            bc.editColor((b) => f.write(b, picked)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

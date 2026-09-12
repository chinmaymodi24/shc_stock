import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/brand_controller.dart';
import 'package:shc_stock/app/shared/widgets/image_dropzone.dart';
import 'package:shc_stock/app/core/theme/brand_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The editors behind Settings › Appearance.
//
// Everything here mutates the CONTROLLER'S DRAFT, never the applied theme, so
// the app behind the settings page keeps its current brand until the buyer
// presses Apply. Each card renders from `draft` and reads its own colours from
// the ambient (applied) theme, which is why a half-picked palette can't make
// the settings page itself unreadable.
// ─────────────────────────────────────────────────────────────────────────────

/// One row of the "where is this colour used" table, shared by the Custom hex
/// and Advanced modes so a colour's meaning is stated once.
class BrandColorField {
  final String group;
  final String label;

  /// What this colour paints, in the buyer's terms.
  final String usage;
  final Color Function(BrandTheme) read;
  final BrandTheme Function(BrandTheme, Color) write;

  const BrandColorField({
    required this.group,
    required this.label,
    required this.usage,
    required this.read,
    required this.write,
  });
}

const kBrandColorFields = <BrandColorField>[
  // ── Brand ────────────────────────────────────────────────────────────
  BrandColorField(
    group: 'Brand',
    label: 'Primary',
    usage: 'Primary buttons, active nav item, table links, step badges, FAB',
    read: _rPrimary,
    write: _wPrimary,
  ),
  BrandColorField(
    group: 'Brand',
    label: 'Secondary',
    usage: 'Logo mark background, user avatar circles',
    read: _rSecondary,
    write: _wSecondary,
  ),
  BrandColorField(
    group: 'Brand',
    label: 'Info',
    usage: 'Blue KPI cards — Total Products, Purchase (MTD)',
    read: _rInfo,
    write: _wInfo,
  ),
  BrandColorField(
    group: 'Brand',
    label: 'Accent',
    usage: 'Purple KPI card — Orders; Pending status pill',
    read: _rAccent,
    write: _wAccent,
  ),
  // ── Status ───────────────────────────────────────────────────────────
  BrandColorField(
    group: 'Status',
    label: 'Success',
    usage: 'In stock / Received pills, Amount Paid card, positive trends',
    read: _rSuccess,
    write: _wSuccess,
  ),
  BrandColorField(
    group: 'Status',
    label: 'Warning',
    usage: 'Low Stock card, Partial pill, Amount Due card',
    read: _rWarning,
    write: _wWarning,
  ),
  BrandColorField(
    group: 'Status',
    label: 'Danger',
    usage: 'Out of Stock card, delete action, overdue amounts',
    read: _rDanger,
    write: _wDanger,
  ),
  // ── Surfaces ─────────────────────────────────────────────────────────
  BrandColorField(
    group: 'Surfaces',
    label: 'Background',
    usage: 'Page background behind all cards and tables',
    read: _rBg,
    write: _wBg,
  ),
  BrandColorField(
    group: 'Surfaces',
    label: 'Card',
    usage: 'Cards, dialogs, table body rows, side panels',
    read: _rCardBg,
    write: _wCardBg,
  ),
  BrandColorField(
    group: 'Surfaces',
    label: 'Sidebar',
    usage: 'Left navigation panel',
    read: _rSidebarBg,
    write: _wSidebarBg,
  ),
  BrandColorField(
    group: 'Surfaces',
    label: 'Table header',
    usage: 'Table column-header strip',
    read: _rTableHeaderBg,
    write: _wTableHeaderBg,
  ),
  BrandColorField(
    group: 'Surfaces',
    label: 'Row hover',
    usage: 'Hovered rows, readonly inputs, secondary buttons',
    read: _rRowHover,
    write: _wRowHover,
  ),
  BrandColorField(
    group: 'Surfaces',
    label: 'Border',
    usage: 'Card borders, dividers, input outlines',
    read: _rBorder,
    write: _wBorder,
  ),
  // ── Text ─────────────────────────────────────────────────────────────
  BrandColorField(
    group: 'Text',
    label: 'Text primary',
    usage: 'Headings, KPI values, product names, amounts',
    read: _rTextPrimary,
    write: _wTextPrimary,
  ),
  BrandColorField(
    group: 'Text',
    label: 'Text secondary',
    usage: 'Nav items, table cell text, field labels',
    read: _rTextSecondary,
    write: _wTextSecondary,
  ),
  BrandColorField(
    group: 'Text',
    label: 'Text tertiary',
    usage: 'Sub-labels, SKU lines, hints, timestamps',
    read: _rTextTertiary,
    write: _wTextTertiary,
  ),
];

// Top-level accessors — a const list can only hold const closures, so these
// cannot be inline lambdas.
Color _rPrimary(BrandTheme b) => b.primary;
BrandTheme _wPrimary(BrandTheme b, Color c) => b.copyWith(primary: c);
Color _rSecondary(BrandTheme b) => b.secondary;
BrandTheme _wSecondary(BrandTheme b, Color c) => b.copyWith(secondary: c);
Color _rInfo(BrandTheme b) => b.info;
BrandTheme _wInfo(BrandTheme b, Color c) => b.copyWith(info: c);
Color _rAccent(BrandTheme b) => b.accent;
BrandTheme _wAccent(BrandTheme b, Color c) => b.copyWith(accent: c);
Color _rSuccess(BrandTheme b) => b.success;
BrandTheme _wSuccess(BrandTheme b, Color c) => b.copyWith(success: c);
Color _rWarning(BrandTheme b) => b.warning;
BrandTheme _wWarning(BrandTheme b, Color c) => b.copyWith(warning: c);
Color _rDanger(BrandTheme b) => b.danger;
BrandTheme _wDanger(BrandTheme b, Color c) => b.copyWith(danger: c);
Color _rBg(BrandTheme b) => b.bg;
BrandTheme _wBg(BrandTheme b, Color c) => b.copyWith(bg: c);
Color _rCardBg(BrandTheme b) => b.cardBg;
BrandTheme _wCardBg(BrandTheme b, Color c) => b.copyWith(cardBg: c);
Color _rSidebarBg(BrandTheme b) => b.sidebarBg;
BrandTheme _wSidebarBg(BrandTheme b, Color c) => b.copyWith(sidebarBg: c);
Color _rTableHeaderBg(BrandTheme b) => b.tableHeaderBg;
BrandTheme _wTableHeaderBg(BrandTheme b, Color c) =>
    b.copyWith(tableHeaderBg: c);
Color _rRowHover(BrandTheme b) => b.rowHover;
BrandTheme _wRowHover(BrandTheme b, Color c) => b.copyWith(rowHover: c);
Color _rBorder(BrandTheme b) => b.border;
BrandTheme _wBorder(BrandTheme b, Color c) => b.copyWith(border: c);
Color _rTextPrimary(BrandTheme b) => b.textPrimary;
BrandTheme _wTextPrimary(BrandTheme b, Color c) => b.copyWith(textPrimary: c);
Color _rTextSecondary(BrandTheme b) => b.textSecondary;
BrandTheme _wTextSecondary(BrandTheme b, Color c) =>
    b.copyWith(textSecondary: c);
Color _rTextTertiary(BrandTheme b) => b.textTertiary;
BrandTheme _wTextTertiary(BrandTheme b, Color c) => b.copyWith(textTertiary: c);

/// The card chrome every Appearance section shares.
class AppearanceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget child;

  const AppearanceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(c.radius + 2),
        border: Border.all(color: c.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card 1 — Brand identity
// ─────────────────────────────────────────────────────────────────────────────
class BrandIdentityCard extends StatelessWidget {
  const BrandIdentityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final bc = Get.find<BrandController>();

    return AppearanceCard(
      title: 'Brand identity',
      subtitle: 'Shown in the sidebar, invoices and exported reports',
      child: Obx(() {
        final d = bc.draft.value;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImageDropzone(
              base64Image: d.logoBase64,
              emptyLabel: 'Upload logo',
              onPicked: (encoded) =>
                  bc.updateDraft((b) => b.copyWith(logoBase64: encoded)),
              onRemove: () =>
                  bc.updateDraft((b) => b.copyWith(clearLogo: true)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LabelledField(
                    label: 'Company name',
                    child: _DraftTextField(
                      value: d.companyName,
                      hint: 'Your company name',
                      onChanged: (v) =>
                          bc.updateDraft((b) => b.copyWith(companyName: v)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LabelledField(
                    label: 'Short code',
                    hint: 'used when no logo is set',
                    child: SizedBox(
                      width: 110,
                      child: _DraftTextField(
                        value: d.shortCode,
                        hint: 'S',
                        maxLength: 3,
                        onChanged: (v) => bc.updateDraft(
                          (b) => b.copyWith(shortCode: v.toUpperCase()),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _LabelledField extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;
  const _LabelledField({required this.label, required this.child, this.hint});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            if (hint != null)
              Text(
                ' — $hint',
                style: TextStyle(fontSize: 11.5, color: c.textHint),
              ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// A text field that stays in step with the draft without stealing the caret
/// on every keystroke — the controller is only reset when the draft changes
/// from somewhere else (Discard, Restore default).
class _DraftTextField extends StatefulWidget {
  final String value;
  final String hint;
  final int? maxLength;
  final ValueChanged<String> onChanged;

  const _DraftTextField({
    required this.value,
    required this.hint,
    required this.onChanged,
    this.maxLength,
  });

  @override
  State<_DraftTextField> createState() => _DraftTextFieldState();
}

class _DraftTextFieldState extends State<_DraftTextField> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(_DraftTextField old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text) _ctrl.text = widget.value;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      maxLength: widget.maxLength,
      style: TextStyle(fontSize: 13, color: c.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hint,
        counterText: '',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card 3 — Typography & shape
// ─────────────────────────────────────────────────────────────────────────────
class TypographyShapeCard extends StatelessWidget {
  const TypographyShapeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bc = Get.find<BrandController>();

    return AppearanceCard(
      title: 'Typography & shape',
      subtitle: 'Applies across every screen, dialog and exported document',
      child: Obx(() {
        final d = bc.draft.value;
        return LayoutBuilder(
          builder: (context, box) {
            final stacked = box.maxWidth < 520;
            final font = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LabelledField(
                  label: 'Font family',
                  child: DropdownButtonFormField<String>(
                    value: d.font,
                    isDense: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                    ),
                    items: [
                      for (final f in kBrandFonts)
                        DropdownMenuItem(
                          value: f,
                          child: Text(
                            f,
                            style: TextStyle(fontFamily: f, fontSize: 13),
                          ),
                        ),
                    ],
                    onChanged: (v) => v == null
                        ? null
                        : bc.updateDraft((b) => b.copyWith(font: v)),
                  ),
                ),
                const SizedBox(height: 14),
                // A specimen in the chosen face, so the buyer judges the font
                // on the numbers they actually look at all day.
                Text(
                  '₹1,42,00,000',
                  style: TextStyle(
                    fontFamily: d.font,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  'Ceramic Fiber Blanket · 84 units in stock',
                  style: TextStyle(
                    fontFamily: d.font,
                    fontSize: 12,
                    color: c.textSecondary,
                  ),
                ),
              ],
            );

            final radii = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LabelledField(
                  label: 'Corner radius',
                  child: Row(
                    children: [
                      for (final r in kBrandRadii) ...[
                        Expanded(
                          child: _RadiusCard(
                            option: r,
                            selected: d.radius == r.value,
                            onTap: () => bc.updateDraft(
                              (b) => b.copyWith(radius: r.value),
                            ),
                          ),
                        ),
                        if (r != kBrandRadii.last) const SizedBox(width: 10),
                      ],
                    ],
                  ),
                ),
              ],
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [font, const SizedBox(height: 18), radii],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: font),
                const SizedBox(width: 24),
                Expanded(child: radii),
              ],
            );
          },
        );
      }),
    );
  }
}

class _RadiusCard extends StatelessWidget {
  final BrandRadius option;
  final bool selected;
  final VoidCallback onTap;

  const _RadiusCard({
    required this.option,
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? c.tintPrimary : c.surface,
          borderRadius: BorderRadius.circular(c.radius),
          border: Border.all(
            color: selected ? primary : c.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // The preview box is drawn at the radius it sells.
            Container(
              height: 26,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: c.rowEven,
                borderRadius: BorderRadius.circular(option.value),
                border: Border.all(color: c.border),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              option.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? primary : c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared bits for the colour editors
// ─────────────────────────────────────────────────────────────────────────────

/// A monospace hex box that validates as you type. Rejecting bad input by
/// refusing to commit it — rather than clearing the field — is what lets
/// someone type "#1f6" on the way to "#1f6feb" without losing their place.
class HexField extends StatefulWidget {
  final Color value;
  final ValueChanged<Color> onChanged;
  final double width;

  const HexField({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 108,
  });

  @override
  State<HexField> createState() => _HexFieldState();
}

class _HexFieldState extends State<HexField> {
  late final TextEditingController _ctrl = TextEditingController(
    text: hexOf(widget.value),
  );
  bool _invalid = false;

  @override
  void didUpdateWidget(HexField old) {
    super.didUpdateWidget(old);
    // Only pull the field back in step when the change came from elsewhere
    // (a preset, Discard) — never mid-typing.
    if (widget.value != old.value && hexOf(widget.value) != _ctrl.text.trim()) {
      _ctrl.text = hexOf(widget.value);
      _invalid = false;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SizedBox(
      width: widget.width,
      child: TextField(
        controller: _ctrl,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12.5,
          color: c.textPrimary,
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(7),
          FilteringTextInputFormatter.allow(RegExp(r'[#0-9a-fA-F]')),
        ],
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 9,
          ),
          errorText: _invalid ? '' : null,
          errorStyle: const TextStyle(height: 0, fontSize: 0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(c.radiusSm),
            borderSide: BorderSide(color: _invalid ? c.error : c.border),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(c.radiusSm),
            borderSide: BorderSide(color: _invalid ? c.error : c.border),
          ),
        ),
        onChanged: (raw) {
          // Only a COMPLETE hex commits. Anything shorter is someone still
          // typing, not an error — and committing a 3-char hex mid-way used
          // to expand "#1f6" to "#11FF66" under the caret, which made typing
          // a real six-digit brand colour almost impossible.
          final digits = raw.trim().replaceFirst('#', '');
          if (digits.length < 6) {
            if (_invalid) setState(() => _invalid = false);
            return;
          }
          final parsed = colorFromHex(raw);
          setState(() => _invalid = parsed == null);
          if (parsed != null) widget.onChanged(parsed);
        },
      ),
    );
  }
}

/// A colour swatch that opens a picker on tap — the Advanced mode's
/// equivalent of `<input type="color">`.
class ColorSwatchButton extends StatelessWidget {
  final Color color;
  final double size;
  final ValueChanged<Color>? onPicked;

  const ColorSwatchButton({
    super.key,
    required this.color,
    this.size = 30,
    this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final swatch = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(c.radiusSm),
        border: Border.all(color: c.border),
      ),
    );
    if (onPicked == null) return swatch;
    return InkWell(
      onTap: () async {
        final picked = await showColorPickerDialog(context, color);
        if (picked != null) onPicked!(picked);
      },
      borderRadius: BorderRadius.circular(c.radiusSm),
      child: swatch,
    );
  }
}

/// Flutter has no native colour input, so this is the stand-in: a grid of
/// shades plus the hex box, which together cover both "pick something near
/// this" and "paste our exact brand hex".
Future<Color?> showColorPickerDialog(BuildContext context, Color initial) {
  return showDialog<Color>(
    context: context,
    builder: (context) => _ColorPickerDialog(initial: initial),
  );
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initial;
  const _ColorPickerDialog({required this.initial});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _color = widget.initial;

  static const _hues = <Color>[
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFF59E0B),
    Color(0xFFEAB308),
    Color(0xFF84CC16),
    Color(0xFF22C55E),
    Color(0xFF10B981),
    Color(0xFF14B8A6),
    Color(0xFF06B6D4),
    Color(0xFF0EA5E9),
    Color(0xFF3B82F6),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFA855F7),
    Color(0xFFD946EF),
    Color(0xFFEC4899),
    Color(0xFF1A1A2E),
    Color(0xFF5A5770),
    Color(0xFF8A8797),
    Color(0xFFFFFFFF),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return AlertDialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(c.radius + 2),
      ),
      title: Text(
        'Pick a colour',
        style: TextStyle(fontSize: 16, color: c.textPrimary),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(c.radiusSm),
                border: Border.all(color: c.border),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hue in _hues)
                  for (final shade in const [0.0, 0.35])
                    _Shade(
                      color: shade == 0 ? hue : tint(hue, shade),
                      selected: _color == (shade == 0 ? hue : tint(hue, shade)),
                      onTap: () => setState(
                        () => _color = shade == 0 ? hue : tint(hue, shade),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 14),
            HexField(
              value: _color,
              width: 130,
              onChanged: (v) => setState(() => _color = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_color),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Use colour'),
        ),
      ],
    );
  }
}

class _Shade extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _Shade({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? c.textPrimary : c.border,
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

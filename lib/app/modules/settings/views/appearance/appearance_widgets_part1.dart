part of 'appearance_widgets.dart';

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

  /// Reactive (no setState): the field turns red while a complete hex is
  /// not a valid colour.
  final RxBool _invalid = false.obs;

  @override
  void didUpdateWidget(HexField old) {
    super.didUpdateWidget(old);
    // Only pull the field back in step when the change came from elsewhere
    // (a preset, Discard) — never mid-typing.
    if (widget.value != old.value && hexOf(widget.value) != _ctrl.text.trim()) {
      _ctrl.text = hexOf(widget.value);
      _invalid.value = false;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _invalid.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SizedBox(
      width: widget.width,
      child: Obx(
        () => TextField(
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
            errorText: _invalid.value ? '' : null,
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(c.radiusSm),
              borderSide: BorderSide(
                color: _invalid.value ? c.error : c.border,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(c.radiusSm),
              borderSide: BorderSide(
                color: _invalid.value ? c.error : c.border,
              ),
            ),
          ),
          onChanged: (raw) {
            // Only a COMPLETE hex commits. Anything shorter is someone still
            // typing, not an error — and committing a 3-char hex mid-way used
            // to expand "#1f6" to "#11FF66" under the caret, which made typing
            // a real six-digit brand colour almost impossible.
            final digits = raw.trim().replaceFirst('#', '');
            if (digits.length < 6) {
              if (_invalid.value) _invalid.value = false;
              return;
            }
            final parsed = colorFromHex(raw);
            _invalid.value = parsed == null;
            if (parsed != null) widget.onChanged(parsed);
          },
        ),
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
  late final Rx<Color> _color = widget.initial.obs;

  @override
  void dispose() {
    _color.close();
    super.dispose();
  }

  static final _hues = <Color>[
    AppColors.danger,
    Color(0xFFF97316),
    AppColors.warning,
    Color(0xFFEAB308),
    Color(0xFF84CC16),
    AppColors.success,
    Color(0xFF10B981),
    Color(0xFF14B8A6),
    Color(0xFF06B6D4),
    Color(0xFF0EA5E9),
    AppColors.info,
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
            Obx(
              () => Container(
                height: 52,
                decoration: BoxDecoration(
                  color: _color.value,
                  borderRadius: BorderRadius.circular(c.radiusSm),
                  border: Border.all(color: c.border),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Obx(
              () => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final hue in _hues)
                    for (final shade in const [0.0, 0.35])
                      _Shade(
                        color: shade == 0 ? hue : tint(hue, shade),
                        selected:
                            _color.value ==
                            (shade == 0 ? hue : tint(hue, shade)),
                        onTap: () =>
                            _color.value = shade == 0 ? hue : tint(hue, shade),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Obx(
              () => HexField(
                value: _color.value,
                width: 130,
                onChanged: (v) => _color.value = v,
              ),
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
          onPressed: () => Navigator.of(context).pop(_color.value),
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

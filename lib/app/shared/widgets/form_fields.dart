import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared form-field widgets used by every add/edit form (web + mobile).
//
// Web and mobile differ only in a few metrics (control height, label size,
// inner padding), so each widget takes a `mobile` flag instead of being
// copy-pasted per platform. Defaults are the web metrics.
//
// Replaces the per-file _Field / _TextBox / _DropBox / _DateBox / _TotalRow /
// _SmallInput / _SmallNumber / _SmallDrop copies that previously lived in
// web_new_purchase, web_new_sales, mobile_add_purchase and mobile_add_sales.
// ─────────────────────────────────────────────────────────────────────────────

/// Labelled form field wrapper. Pass `required: true` for the orange asterisk.
class AppField extends StatelessWidget {
  final String label;
  final AppThemeColors colors;
  final Widget child;
  final bool required;
  final bool mobile;

  const AppField({
    super.key,
    required this.label,
    required this.colors,
    required this.child,
    this.required = false,
    this.mobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: mobile ? 12 : 12.5,
      fontWeight: FontWeight.w500,
      color: colors.textPrimary,
      fontFamily: 'Poppins',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (required)
          RichText(
            text: TextSpan(
              text: label,
              style: labelStyle,
              children: const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.primaryOrange),
                ),
              ],
            ),
          )
        else
          Text(label, style: labelStyle),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Standard bordered text input.
class AppTextBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final AppThemeColors colors;

  const AppTextBox({
    super.key,
    required this.controller,
    required this.hint,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(
        fontSize: 13,
        color: colors.textPrimary,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: colors.textHint,
          fontFamily: 'Poppins',
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        filled: true,
        fillColor: colors.surface,
        border: _outline(colors.border, 8),
        enabledBorder: _outline(colors.border, 8),
        focusedBorder: _outline(AppColors.primaryOrange, 8, width: 1.5),
      ),
    );
  }
}

/// Standard bordered dropdown.
class AppDropBox extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final AppThemeColors colors;
  final ValueChanged<String?> onChanged;
  final bool mobile;

  const AppDropBox({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.colors,
    required this.onChanged,
    this.mobile = false,
  });

  @override
  Widget build(BuildContext context) {
    // Guard against a value that isn't in `items` — DropdownButton asserts.
    final safeVal = (value != null && items.contains(value)) ? value : null;
    return Container(
      height: mobile ? 42 : 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeVal,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 13,
              color: colors.textHint,
              fontFamily: 'Poppins',
            ),
          ),
          isDense: true,
          isExpanded: true,
          dropdownColor: colors.surface,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: colors.textSecondary,
          ),
          style: TextStyle(
            fontSize: 13,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
          items: items
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Tap-to-pick date field. Focusable/Tab-reachable like a real input.
class AppDateBox extends StatefulWidget {
  final DateTime? date;
  final AppThemeColors colors;
  final VoidCallback onTap;
  final bool mobile;

  const AppDateBox({
    super.key,
    required this.date,
    required this.colors,
    required this.onTap,
    this.mobile = false,
  });

  @override
  State<AppDateBox> createState() => _AppDateBoxState();
}

class _AppDateBoxState extends State<AppDateBox> {
  // Widget-scoped focus flag kept as an Rx on the persistent State object
  // (not setState) so only the border repaints on focus change.
  final _focused = false.obs;

  @override
  void dispose() {
    _focused.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.date;
    final colors = widget.colors;
    final label = d == null
        ? 'dd-mm-yyyy'
        : '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
    return Focus(
      onFocusChange: (f) => _focused.value = f,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: InkWell(
        onTap: widget.onTap,
        child: Obx(
          () => Container(
            height: widget.mobile ? 42 : 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused.value ? AppColors.primaryOrange : colors.border,
                width: _focused.value ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: d == null ? colors.textHint : colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_month_outlined,
                  size: widget.mobile ? 15 : 16,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `Label ................ value` row used in the GST / totals panel.
class AppTotalRow extends StatelessWidget {
  final String label;
  final String value;
  final AppThemeColors colors;

  const AppTotalRow({
    super.key,
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    // The label flexes (and ellipsises) so long labels like "Outstanding
    // Amount (₹)" don't overflow the narrow sidebar cards; the value keeps
    // its natural width, hard right.
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

/// Compact text cell used inside the item-details table.
class AppSmallInput extends StatelessWidget {
  final String hint;
  final String value;
  final AppThemeColors colors;
  final bool center;
  final ValueChanged<String> onChanged;
  final bool mobile;

  const AppSmallInput({
    super.key,
    required this.hint,
    required this.value,
    required this.colors,
    required this.onChanged,
    this.center = false,
    this.mobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        fontSize: 12,
        color: colors.textPrimary,
        fontFamily: 'Poppins',
      ),
      decoration: _smallDecoration(
        colors: colors,
        hint: hint,
        mobile: mobile,
        horizontalPadding: 8,
      ),
    );
  }
}

/// Compact numeric cell used inside the item-details table.
class AppSmallNumber extends StatelessWidget {
  final double value;
  final AppThemeColors colors;
  final bool decimal;
  final ValueChanged<double> onChanged;

  /// Mobile shows a hint and leaves the box empty at 0; web pre-fills 0/0.00.
  final String hint;
  final bool mobile;

  const AppSmallNumber({
    super.key,
    required this.value,
    required this.colors,
    required this.onChanged,
    this.decimal = false,
    this.hint = '',
    this.mobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final String initial;
    if (value != 0) {
      initial = decimal ? value.toStringAsFixed(2) : value.toStringAsFixed(0);
    } else {
      initial = mobile ? '' : (decimal ? '0.00' : '0');
    }
    return TextFormField(
      initialValue: initial,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: colors.textPrimary,
        fontFamily: 'Poppins',
      ),
      decoration: _smallDecoration(
        colors: colors,
        hint: hint,
        mobile: mobile,
        horizontalPadding: 6,
      ),
    );
  }
}

/// Compact dropdown cell (UoM) used inside the item-details table.
class AppSmallDrop extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final AppThemeColors colors;
  final ValueChanged<String?> onChanged;

  const AppSmallDrop({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safe = (value != null && items.contains(value)) ? value : null;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safe,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 11,
              color: colors.textHint,
              fontFamily: 'Poppins',
            ),
            overflow: TextOverflow.ellipsis,
          ),
          isDense: true,
          isExpanded: true,
          dropdownColor: colors.surface,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 14,
            color: colors.textSecondary,
          ),
          style: TextStyle(
            fontSize: 11.5,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
          items: items
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Internal helpers ────────────────────────────────────────────────────────

OutlineInputBorder _outline(Color color, double radius, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );

InputDecoration _smallDecoration({
  required AppThemeColors colors,
  required String hint,
  required bool mobile,
  required double horizontalPadding,
}) => InputDecoration(
  hintText: hint.isEmpty ? null : hint,
  hintStyle: TextStyle(
    fontSize: mobile ? 11.5 : 12,
    color: colors.textHint,
    fontFamily: 'Poppins',
  ),
  isDense: true,
  contentPadding: EdgeInsets.symmetric(
    horizontal: horizontalPadding,
    vertical: mobile ? 10 : 8,
  ),
  filled: true,
  fillColor: colors.surface,
  border: _outline(colors.border, 6),
  enabledBorder: _outline(colors.border, 6),
  focusedBorder: _outline(AppColors.primaryOrange, 6, width: 1.2),
);

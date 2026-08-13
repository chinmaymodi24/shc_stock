import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/users/controllers/add_employee_wizard_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared layout helpers for the Add Employee wizard's 4 step widgets
// (EmployeeDetailsStep / AssignRoleStep / PermissionsStep / ReviewCreateStep).
// Extracted from add_employee_wizard.dart so no single file carries the whole
// wizard — each step now owns its own build() instead of sharing one huge
// _buildStepContent dispatcher.
// ─────────────────────────────────────────────────────────────────────────────

Widget wizCard(AppThemeColors c, {required Widget child}) => Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: c.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: c.divider),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: child,
);

Widget wizSecHeader(
  AppThemeColors c, {
  required IconData icon,
  required String title,
  required String sub,
}) => Row(
  children: [
    Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.primaryOrange, size: 20),
    ),
    const SizedBox(width: 12),
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
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              fontSize: 12,
              color: c.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    ),
  ],
);

// 2-column on wide, single column on mobile
Widget wizRow2(bool wide, List<Widget> children) {
  if (!wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
  final rows = <Widget>[];
  for (int i = 0; i < children.length; i += 2) {
    if (i > 0) rows.add(const SizedBox(height: 14));
    rows.add(
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: children[i]),
          const SizedBox(width: 14),
          Expanded(
            child: i + 1 < children.length ? children[i + 1] : const SizedBox(),
          ),
        ],
      ),
    );
  }
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
}

Widget wizVGap(bool wide) => SizedBox(height: wide ? 14.0 : 14.0);

// Responsive N-up row: 4 columns wide, 2 columns tablet, 1 column mobile.
Widget wizRowN(bool wide, bool tablet, List<Widget> children) {
  final cols = wide ? 4 : (tablet ? 2 : 1);
  if (cols == 1) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
  final rows = <Widget>[];
  for (int i = 0; i < children.length; i += cols) {
    if (i > 0) rows.add(const SizedBox(height: 14));
    final rowChildren = <Widget>[];
    for (int j = 0; j < cols; j++) {
      if (j > 0) rowChildren.add(const SizedBox(width: 14));
      final idx = i + j;
      rowChildren.add(
        Expanded(
          child: idx < children.length ? children[idx] : const SizedBox(),
        ),
      );
    }
    rows.add(
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowChildren),
    );
  }
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
}

Widget wizTextField(
  AppThemeColors c, {
  required TextEditingController ctrl,
  required String label,
  required String hint,
  bool req = false,
  IconData? icon,
  String? error,
  ValueChanged<String>? onChange,
  bool readOnly = false,
  VoidCallback? onTap,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: c.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        if (req)
          const Text(
            ' *',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    ),
    const SizedBox(height: 6),
    TextField(
      controller: ctrl,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChange,
      style: TextStyle(
        fontSize: 13,
        color: c.textPrimary,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: c.textHint,
          fontFamily: 'Poppins',
          fontSize: 13,
        ),
        prefixIcon: icon != null
            ? Icon(icon, size: 17, color: c.textHint)
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        filled: true,
        fillColor: c.inputFill,
        errorText: error,
        errorStyle: const TextStyle(fontSize: 11, fontFamily: 'Poppins'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: error != null ? const Color(0xFFEF4444) : c.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: error != null ? const Color(0xFFEF4444) : c.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primaryOrange,
            width: 1.5,
          ),
        ),
      ),
    ),
  ],
);

Widget wizPwdField(
  AppThemeColors c, {
  required String label,
  required TextEditingController ctrl,
  required bool show,
  bool req = false,
  String? error,
  String? hint,
  required VoidCallback onToggle,
  ValueChanged<String>? onChange,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: c.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        if (req)
          const Text(
            ' *',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    ),
    const SizedBox(height: 6),
    TextField(
      controller: ctrl,
      obscureText: !show,
      onChanged: onChange,
      style: TextStyle(
        fontSize: 13,
        color: c.textPrimary,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        // No dot-string placeholder — an empty field showing "●●●●●●●●" reads
        // as a saved password. Plain wording, whether or not it's masked.
        hintText: hint ?? 'Enter password',
        hintStyle: TextStyle(color: c.textHint, fontFamily: 'Poppins'),
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          size: 17,
          color: c.textHint,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            show ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 17,
            color: c.textHint,
          ),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        filled: true,
        fillColor: c.inputFill,
        errorText: error,
        errorStyle: const TextStyle(fontSize: 11, fontFamily: 'Poppins'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: error != null ? const Color(0xFFEF4444) : c.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: error != null ? const Color(0xFFEF4444) : c.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primaryOrange,
            width: 1.5,
          ),
        ),
      ),
    ),
  ],
);

Widget wizDeptDropdown(
  AddEmployeeWizardController controller,
  AppThemeColors c,
) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      'Department',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: c.textPrimary,
        fontFamily: 'Poppins',
      ),
    ),
    const SizedBox(height: 6),
    Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.dept.value.isEmpty ? null : controller.dept.value,
          hint: Row(
            children: [
              Icon(Icons.business_outlined, size: 17, color: c.textHint),
              const SizedBox(width: 8),
              Text(
                'Select department',
                style: TextStyle(
                  color: c.textHint,
                  fontFamily: 'Poppins',
                  fontSize: 13,
                ),
              ),
            ],
          ),
          isExpanded: true,
          dropdownColor: c.surface,
          style: TextStyle(
            fontSize: 13,
            color: c.textPrimary,
            fontFamily: 'Poppins',
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.textHint),
          items: kDepts
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: (v) {
            if (v != null) controller.dept.value = v;
          },
        ),
      ),
    ),
  ],
);

Widget wizDatePickerField(
  AppThemeColors c, {
  required String label,
  required Rx<DateTime?> value,
  required String fmt,
  required ValueChanged<DateTime> onPick,
  required BuildContext context,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: c.textPrimary,
        fontFamily: 'Poppins',
      ),
    ),
    const SizedBox(height: 6),
    Obx(
      () => _DojField(
        colors: c,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value.value ?? DateTime.now(),
            firstDate: DateTime(1950),
            lastDate: DateTime(2100),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primaryOrange,
                  onPrimary: Colors.white,
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) onPick(picked);
        },
        label: value.value == null ? 'Select date' : fmt,
        isEmpty: value.value == null,
      ),
    ),
  ],
);

Widget wizStatusDropdown(
  AddEmployeeWizardController controller,
  AppThemeColors c,
) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      'Status',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: c.textPrimary,
        fontFamily: 'Poppins',
      ),
    ),
    const SizedBox(height: 6),
    Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.status.value,
          isExpanded: true,
          dropdownColor: c.surface,
          style: TextStyle(
            fontSize: 13,
            color: c.textPrimary,
            fontFamily: 'Poppins',
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.textHint),
          items: ['Active', 'Inactive']
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: s == 'Active'
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(s),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) controller.status.value = v;
          },
        ),
      ),
    ),
  ],
);

Widget wizSimpleDropdown(
  AppThemeColors c, {
  required String label,
  required IconData icon,
  required String value,
  required List<String> items,
  required ValueChanged<String> onChanged,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: c.textPrimary,
        fontFamily: 'Poppins',
      ),
    ),
    const SizedBox(height: 6),
    Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.inputFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: c.surface,
          style: TextStyle(
            fontSize: 13,
            color: c.textPrimary,
            fontFamily: 'Poppins',
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.textHint),
          items: items
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Row(
                    children: [
                      Icon(icon, size: 15, color: c.textHint),
                      const SizedBox(width: 8),
                      Text(v),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    ),
  ],
);

Widget wizRoleTab(
  AppThemeColors c, {
  required String label,
  required IconData icon,
  required bool active,
  required VoidCallback onTap,
}) => InkWell(
  onTap: onTap,
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      border: Border.all(
        color: active ? AppColors.primaryOrange : c.border,
        width: active ? 1.5 : 1,
      ),
      borderRadius: BorderRadius.circular(10),
      color: active
          ? AppColors.primaryOrange.withValues(alpha: 0.04)
          : c.inputFill,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 17,
          color: active ? AppColors.primaryOrange : c.textSecondary,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? AppColors.primaryOrange : c.textPrimary,
              fontFamily: 'Poppins',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  ),
);

Widget wizInfoBox(
  AppThemeColors c, {
  required String text,
  bool isError = false,
}) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  decoration: BoxDecoration(
    color: isError
        ? const Color(0xFFFEF2F2)
        : AppColors.primaryOrange.withValues(alpha: 0.06),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      Icon(
        Icons.info_outline_rounded,
        color: isError
            ? const Color(0xFFEF4444)
            : AppColors.primaryOrange.withValues(alpha: 0.8),
        size: 15,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isError ? const Color(0xFFEF4444) : c.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    ],
  ),
);

Widget wizRevSection(
  AppThemeColors c, {
  required IconData icon,
  required String title,
  required VoidCallback onEdit,
  required Widget child,
}) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 14),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryOrange, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onEdit,
            icon: Icon(Icons.edit_outlined, size: 13, color: c.textSecondary),
            label: Text(
              'Edit',
              style: TextStyle(
                fontSize: 12.5,
                color: c.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      child,
    ],
  ),
);

Widget wizRevRow(String label, String value, AppThemeColors c) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 110,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: c.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      const Text(' :  ', style: TextStyle(fontSize: 12, color: Colors.grey)),
      Expanded(
        child: Text(
          value.isEmpty ? '-' : value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: c.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    ],
  ),
);

Widget wizPermStat(
  AppThemeColors c, {
  required IconData icon,
  required String label,
  required String value,
  required Color color,
}) => Container(
  padding: const EdgeInsets.all(12),
  margin: const EdgeInsets.only(bottom: 10),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.06),
    borderRadius: BorderRadius.circular(10),
  ),
  child: Row(
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: c.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: color,
          fontFamily: 'Poppins',
        ),
      ),
    ],
  ),
);

// ── Right panel data ──────────────────────────────────────────────────────

class _DojField extends StatefulWidget {
  final AppThemeColors colors;
  final VoidCallback onTap;
  final String label;
  final bool isEmpty;
  const _DojField({
    required this.colors,
    required this.onTap,
    required this.label,
    required this.isEmpty,
  });

  @override
  State<_DojField> createState() => _DojFieldState();
}

class _DojFieldState extends State<_DojField> {
  // Local, widget-scoped focus flag — kept as an Rx on the persistent State
  // object (not setState) so only the border repaints on focus change.
  final _focused = false.obs;

  @override
  void dispose() {
    _focused.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
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
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: c.inputFill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused.value ? AppColors.primaryOrange : c.border,
                width: _focused.value ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 17,
                  color: c.textHint,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.isEmpty ? c.textHint : c.textPrimary,
                      fontFamily: 'Poppins',
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

import 'package:shc_stock/app/core/session/app_modules.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/users/controllers/users_controller.dart';
import 'package:shc_stock/app/modules/users/models/permission_editor.dart';
import 'package:shc_stock/app/modules/users/models/role_model.dart';
import 'permission_table.dart';
import 'wizard_step_widgets.dart';

/// Opens the Define Custom Role dialog. Pass [role] to edit an existing custom
/// role. Completes with the saved role, or null when cancelled.
Future<RoleModel?> showCustomRoleDialog({RoleModel? role}) =>
    Get.dialog<RoleModel>(CustomRoleDialog(role: role));

/// Name, description, icon and the full permissions table for a reusable
/// custom role. Saved to the database, so it appears in the role list for
/// every employee created after it.
class CustomRoleDialog extends StatefulWidget {
  final RoleModel? role;
  const CustomRoleDialog({super.key, this.role});

  @override
  State<CustomRoleDialog> createState() => _CustomRoleDialogState();
}

class _CustomRoleDialogState extends State<CustomRoleDialog> {
  // Form state lives on the persistent State as controllers and Rx values —
  // never setState — and is disposed with the dialog.
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _editor = PermissionEditor();
  final _icon = 'custom'.obs;
  final _nameErr = RxnString();
  final _saving = false.obs;

  /// Role whose permissions the form was last filled from ("Start from").
  final _startFrom = RxnInt();

  bool get _isEdit => widget.role != null;

  @override
  void initState() {
    super.initState();
    final role = widget.role;
    if (role != null) {
      _nameCtrl.text = role.name;
      _descCtrl.text = role.description;
      _icon.value = role.iconName;
      _editor.load(role.permissions);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _icon.close();
    _nameErr.close();
    _saving.close();
    _startFrom.close();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _nameErr.value = 'Role name is required';
      return;
    }
    if (_editor.perms.every((p) => p.noAccess)) {
      _nameErr.value = null;
      showAppToast(
        'No permissions',
        'Give this role access to at least one module or setting.',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }
    _nameErr.value = null;
    _saving.value = true;
    final users = Get.find<UsersController>();
    final body = {
      'name': name,
      'description': _descCtrl.text.trim(),
      'icon': _icon.value,
      'permissions': _editor.toJson(),
    };
    final saved = _isEdit
        ? await users.updateRole(widget.role!.id, body)
        : await users.createRole(body);
    _saving.value = false;
    if (saved != null) Get.back(result: saved);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final size = MediaQuery.of(context).size;
    final wide = size.width >= 700;

    return Dialog(
      backgroundColor: c.surface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: wide ? 40 : 12,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
          maxHeight: size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: wizSecHeader(
                      c,
                      icon: Icons.tune_rounded,
                      title: _isEdit
                          ? 'Edit Custom Role'
                          : 'Define Custom Role',
                      sub:
                          'Saved roles appear in the role list for every new employee.',
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close_rounded, color: c.textSecondary),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: c.divider),

            // ── Body ───────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => wizRow2(wide, [
                        wizTextField(
                          c,
                          ctrl: _nameCtrl,
                          label: 'Role Name',
                          hint: 'e.g. Accountant',
                          req: true,
                          icon: Icons.badge_outlined,
                          error: _nameErr.value,
                          onChange: (_) => _nameErr.value = null,
                        ),
                        wizTextField(
                          c,
                          ctrl: _descCtrl,
                          label: 'Description',
                          hint: 'What this role is for',
                          icon: Icons.notes_rounded,
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    _IconPicker(icon: _icon),
                    const SizedBox(height: 14),
                    _StartFrom(editor: _editor, selected: _startFrom),
                    const SizedBox(height: 16),
                    PermissionBulkActions(editor: _editor),
                    const SizedBox(height: 14),
                    PermissionTable(editor: _editor, wide: wide),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: c.divider),

            // ── Footer ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: c.textSecondary,
                        fontFamily: brandFontFamily,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(
                    () => ElevatedButton.icon(
                      onPressed: _saving.value ? null : _save,
                      icon: _saving.value
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                      label: Text(
                        _isEdit ? 'Save Changes' : 'Save Role',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: brandFontFamily,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        disabledBackgroundColor: AppColors.primaryOrange
                            .withValues(alpha: 0.6),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon choice for the role badge.
class _IconPicker extends StatelessWidget {
  final RxString icon;
  const _IconPicker({required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icon',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: c.textPrimary,
            fontFamily: brandFontFamily,
          ),
        ),
        const SizedBox(height: 6),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in kRoleIconNames)
                InkWell(
                  onTap: () => icon.value = name,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: icon.value == name
                          ? AppColors.primaryOrange.withValues(alpha: 0.12)
                          : c.inputFill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: icon.value == name
                            ? AppColors.primaryOrange
                            : c.border,
                      ),
                    ),
                    child: Icon(
                      roleIconFor(name),
                      size: 18,
                      color: icon.value == name
                          ? AppColors.primaryOrange
                          : c.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Start from" chips — fill the table from an existing role, then adjust.
class _StartFrom extends StatelessWidget {
  final PermissionEditor editor;
  final RxnInt selected;
  const _StartFrom({required this.editor, required this.selected});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final users = Get.find<UsersController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start from an existing role (optional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: c.textPrimary,
            fontFamily: brandFontFamily,
          ),
        ),
        const SizedBox(height: 6),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Only a Super Admin may start from Super Admin — anyone else
              // would have it clipped to their own access on save anyway.
              for (final role in users.roles.where(
                (r) => !r.isSuperAdmin || isSuperAdminSession,
              ))
                ChoiceChip(
                  label: Text(
                    role.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: brandFontFamily,
                      color: selected.value == role.id
                          ? AppColors.primaryOrange
                          : c.textSecondary,
                    ),
                  ),
                  avatar: Icon(role.icon, size: 14, color: role.color),
                  selected: selected.value == role.id,
                  selectedColor: AppColors.primaryOrange.withValues(
                    alpha: 0.12,
                  ),
                  backgroundColor: c.inputFill,
                  side: BorderSide(
                    color: selected.value == role.id
                        ? AppColors.primaryOrange
                        : c.border,
                  ),
                  showCheckmark: false,
                  onSelected: (_) {
                    selected.value = role.id;
                    editor.load(
                      role.permissions,
                      everything: role.isSuperAdmin,
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

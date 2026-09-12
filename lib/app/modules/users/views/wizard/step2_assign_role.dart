import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/users/controllers/add_employee_wizard_controller.dart';
import 'package:shc_stock/app/modules/users/controllers/users_controller.dart';
import 'package:shc_stock/app/modules/users/models/role_model.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';
import 'package:shc_stock/app/shared/widgets/row_action_button.dart';
import 'custom_role_dialog.dart';
import 'wizard_step_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Assign Role: pick a ready-made or saved custom role, or define a
// new custom role. Picking a role fills Step 3 with its permissions.
// ─────────────────────────────────────────────────────────────────────────────
class AssignRoleStep extends GetView<AddEmployeeWizardController> {
  final bool wide;
  final bool tablet;
  const AssignRoleStep({super.key, required this.wide, required this.tablet});

  Future<void> _defineCustomRole() async {
    final created = await showCustomRoleDialog();
    if (created == null) return;
    controller.customTab.value = false;
    controller.selectRole(created);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final users = Get.find<UsersController>();
    return Obx(() {
      final q = controller.roleSearchQuery.value.toLowerCase();
      final all = controller.assignableRoles;
      final roles = q.isEmpty
          ? all
          : all
                .where(
                  (r) =>
                      r.name.toLowerCase().contains(q) ||
                      r.description.toLowerCase().contains(q),
                )
                .toList();
      final roleId = controller.roleId.value;
      final customTab = controller.customTab.value;

      return wizCard(
        c,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            wizSecHeader(
              c,
              icon: Icons.group_outlined,
              title: 'Assign Role',
              sub:
                  'Select an existing role or create a new custom role for this employee.',
            ),
            const SizedBox(height: 20),

            // Tabs
            Row(
              children: [
                Expanded(
                  child: wizRoleTab(
                    c,
                    label: 'Select Existing Role',
                    icon: Icons.radio_button_checked_rounded,
                    active: !customTab,
                    onTap: () => controller.customTab.value = false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: wizRoleTab(
                    c,
                    label: 'Create Custom Role',
                    icon: Icons.add_circle_outline_rounded,
                    active: customTab,
                    onTap: () => controller.customTab.value = true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (!customTab) ...[
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Roles',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                            fontFamily: brandFontFamily,
                          ),
                        ),
                        Text(
                          'Ready-made and custom roles',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: c.textSecondary,
                            fontFamily: brandFontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: wide ? 180 : 140,
                    height: 34,
                    child: TextField(
                      controller: controller.roleSearchCtrl,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: c.textPrimary,
                        fontFamily: brandFontFamily,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search role...',
                        hintStyle: TextStyle(
                          color: c.textHint,
                          fontFamily: brandFontFamily,
                          fontSize: 12.5,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 7),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: c.textHint,
                          size: 15,
                        ),
                        filled: true,
                        fillColor: c.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: c.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: c.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.primaryOrange,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _RolesHeader(wide: wide),

              if (users.isLoadingRoles.value && all.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryOrange,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (roles.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      all.isEmpty
                          ? 'Could not load roles. Is the backend running?'
                          : 'No role matches "$q"',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: c.textSecondary,
                        fontFamily: brandFontFamily,
                      ),
                    ),
                  ),
                ),

              ...roles.asMap().entries.map(
                (e) => Column(
                  children: [
                    _RoleRow(
                      role: e.value,
                      selected: e.value.id == roleId,
                      wide: wide,
                      onSelect: () => controller.selectRole(e.value),
                    ),
                    if (e.key < roles.length - 1)
                      Divider(height: 1, color: c.divider),
                  ],
                ),
              ),

              if (controller.roleErr.value) ...[
                const SizedBox(height: 10),
                wizInfoBox(
                  c,
                  text: 'Please select a role to continue.',
                  isError: true,
                ),
              ],
              const SizedBox(height: 12),
              wizInfoBox(
                c,
                text:
                    'You can fine-tune permissions for the selected role in the next step.',
              ),
            ] else ...[
              // Custom role
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  border: Border.all(color: c.divider),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: AppColors.primaryOrange,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Custom Role',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                        fontFamily: brandFontFamily,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Name a new role and choose exactly what it can read, change\n'
                      'and which summaries it can see. It is saved for future employees too.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: c.textSecondary,
                        fontFamily: brandFontFamily,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _defineCustomRole,
                      icon: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: Text(
                        'Define Custom Role',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: brandFontFamily,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.roleErr.value)
                wizInfoBox(
                  c,
                  text:
                      'Define a custom role, or pick an existing one, to continue.',
                  isError: true,
                ),
            ],
          ],
        ),
      );
    });
  }
}

class _RolesHeader extends StatelessWidget {
  final bool wide;
  const _RolesHeader({required this.wide});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    TextStyle s() => TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: c.textSecondary,
      fontFamily: brandFontFamily,
    );
    return Container(
      decoration: BoxDecoration(
        color: c.rowEven,
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Role Name', style: s())),
          if (wide) Expanded(flex: 5, child: Text('Description', style: s())),
          SizedBox(
            width: wide ? 80 : 52,
            child: Center(child: Text('Users', style: s())),
          ),
          SizedBox(
            width: wide ? 130 : 84,
            child: Center(child: Text('Actions', style: s())),
          ),
        ],
      ),
    );
  }
}

class _RoleRow extends GetView<AddEmployeeWizardController> {
  final RoleModel role;
  final bool selected;
  final bool wide;
  final VoidCallback onSelect;
  const _RoleRow({
    required this.role,
    required this.selected,
    required this.wide,
    required this.onSelect,
  });

  Future<void> _edit() async {
    final updated = await showCustomRoleDialog(role: role);
    // Re-apply the edited defaults when this is the role being assigned.
    if (updated != null && selected) controller.selectRole(updated);
  }

  Future<void> _delete(BuildContext context) => confirmDelete(
    context,
    itemName: role.name,
    itemLabel: 'Role',
    onConfirm: () async {
      final ok = await Get.find<UsersController>().deleteRole(role.id);
      if (ok && selected) controller.roleId.value = null;
    },
  );

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return InkWell(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: selected
            ? AppColors.primaryOrange.withValues(alpha: 0.05)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: role.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(role.icon, color: role.color, size: 15),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                            fontFamily: brandFontFamily,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          role.isSystem ? 'Ready-made' : 'Custom',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: c.textHint,
                            fontFamily: brandFontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (wide)
              Expanded(
                flex: 5,
                child: Text(
                  role.description.isEmpty ? '—' : role.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textSecondary,
                    fontFamily: brandFontFamily,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            SizedBox(
              width: wide ? 80 : 52,
              child: Center(
                child: Text(
                  '${role.userCount}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                    fontFamily: brandFontFamily,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: wide ? 130 : 84,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ready-made roles are rebuilt from the catalog, so only
                  // custom roles can be edited or removed.
                  if (wide && !role.isSystem) ...[
                    RowActionButton(
                      icon: Icons.edit_outlined,
                      color: AppColors.primaryOrange,
                      tooltip: 'Edit role',
                      onTap: _edit,
                    ),
                    const SizedBox(width: 6),
                    RowActionButton(
                      icon: Icons.delete_outline_rounded,
                      color: const Color(0xFFEF4444),
                      bg: c.tagBg,
                      tooltip: role.userCount > 0
                          ? 'In use by ${role.userCount} employee(s)'
                          : 'Delete role',
                      onTap: () => _delete(context),
                    ),
                  ],
                  // Same edit / delete on a phone, tucked into a menu.
                  if (!wide && !role.isSystem)
                    PopupMenuButton<String>(
                      tooltip: 'Role actions',
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: c.textSecondary,
                      ),
                      onSelected: (v) =>
                          v == 'edit' ? _edit() : _delete(context),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit role')),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete role'),
                        ),
                      ],
                    ),
                  Radio<int>(
                    value: role.id,
                    groupValue: selected ? role.id : null,
                    onChanged: (_) => onSelect(),
                    activeColor: AppColors.primaryOrange,
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

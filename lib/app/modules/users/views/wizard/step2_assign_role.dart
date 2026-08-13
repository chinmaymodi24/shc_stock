import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/users/controllers/add_employee_wizard_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'wizard_step_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Assign Role (pick an existing role or start a custom one).
// Extracted from add_employee_wizard.dart's _step2 method.
// ─────────────────────────────────────────────────────────────────────────────
class AssignRoleStep extends GetView<AddEmployeeWizardController> {
  final bool wide;
  final bool tablet;
  const AssignRoleStep({super.key, required this.wide, required this.tablet});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final q = controller.roleSearchQuery.value.toLowerCase();
    final roles = q.isEmpty
        ? kRoles
        : kRoles
              .where(
                (r) =>
                    r.name.toLowerCase().contains(q) ||
                    r.desc.toLowerCase().contains(q),
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
                  onTap: () {
                    controller.customTab.value = true;
                    controller.roleId.value = null;
                  },
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Roles',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      'Choose from pre-defined roles',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: c.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 180,
                  height: 34,
                  child: TextField(
                    controller: controller.roleSearchCtrl,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: c.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search role...',
                      hintStyle: TextStyle(
                        color: c.textHint,
                        fontFamily: 'Poppins',
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
                        borderSide: const BorderSide(
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

            // Table header
            Container(
              decoration: BoxDecoration(
                color: c.rowEven,
                border: Border(bottom: BorderSide(color: c.divider)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Role Name',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: wide ? 80 : 52,
                    child: Center(
                      child: Text(
                        'Users',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: wide ? 70 : 52,
                    child: Center(
                      child: Text(
                        'Actions',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            ...roles.asMap().entries.map((e) {
              final r = e.value;
              final sel = r.id == roleId;
              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      controller.roleId.value = r.id;
                      controller.roleErr.value = false;
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      color: sel
                          ? AppColors.primaryOrange.withValues(alpha: 0.05)
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
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
                                    color: AppColors.primaryOrange.withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    r.icon,
                                    color: AppColors.primaryOrange,
                                    size: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    r.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: c.textPrimary,
                                      fontFamily: 'Poppins',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: Text(
                              r.desc,
                              style: TextStyle(
                                fontSize: 12,
                                color: c.textSecondary,
                                fontFamily: 'Poppins',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: wide ? 80 : 52,
                            child: Center(
                              child: Text(
                                '${roleOptUserCount(r.id)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: wide ? 70 : 52,
                            child: Center(
                              child: Radio<String>(
                                value: r.id,
                                groupValue: roleId,
                                onChanged: (v) {
                                  controller.roleId.value = v;
                                  controller.roleErr.value = false;
                                },
                                activeColor: AppColors.primaryOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (e.key < roles.length - 1)
                    Divider(height: 1, color: c.divider),
                ],
              );
            }),

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
            // Custom role UI
            Container(
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
                    child: const Icon(
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
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Define a custom role with specific permissions.\nYou will configure the permissions in the next step.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: c.textSecondary,
                      fontFamily: 'Poppins',
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    label: const Text(
                      'Define Custom Role',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
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
          ],
        ],
      ),
    );
  }
}

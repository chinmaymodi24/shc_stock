import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/users/controllers/add_employee_wizard_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'wizard_step_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Permissions (per-module read/write access toggles).
// Extracted from add_employee_wizard.dart's _step3 method.
// ─────────────────────────────────────────────────────────────────────────────
class PermissionsStep extends GetView<AddEmployeeWizardController> {
  final bool wide;
  final bool tablet;
  const PermissionsStep({super.key, required this.wide, required this.tablet});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return wizCard(
      c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Select All buttons
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.primaryOrange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Permissions',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        'Manage read and write access for modules',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      for (final p in controller.perms) {
                        p.read = true;
                      }
                      controller.perms.refresh();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryOrange),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Select All Read',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.primaryOrange,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      for (final p in controller.perms) {
                        p.write = true;
                      }
                      controller.perms.refresh();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryOrange),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Select All Write',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.primaryOrange,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Column headers
          Container(
            decoration: BoxDecoration(
              color: c.rowEven,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Module',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                SizedBox(
                  width: wide ? 130 : 100,
                  child: Center(
                    child: Text(
                      'Read Access',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: wide ? 130 : 100,
                  child: Center(
                    child: Text(
                      'Write Access',
                      style: TextStyle(
                        fontSize: 12.5,
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
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: c.divider),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
            ),
            child: Column(
              children: controller.perms.asMap().entries.map((e) {
                final p = e.value;
                final isLast = e.key == controller.perms.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryOrange.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    p.icon,
                                    color: AppColors.primaryOrange,
                                    size: 15,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  p.module,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: c.textPrimary,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: wide ? 130 : 100,
                            child: Center(
                              child: Switch(
                                value: p.read,
                                onChanged: (v) {
                                  p.read = v;
                                  controller.perms.refresh();
                                },
                                activeColor: AppColors.primaryOrange,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: wide ? 130 : 100,
                            child: Center(
                              child: Switch(
                                value: p.write,
                                onChanged: (v) {
                                  p.write = v;
                                  controller.perms.refresh();
                                },
                                activeColor: AppColors.primaryOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast) Divider(height: 1, color: c.divider),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          wizInfoBox(
            c,
            text:
                'Read access allows viewing data. Write access allows creating, editing and deleting data.',
          ),
        ],
      ),
    );
  }
}

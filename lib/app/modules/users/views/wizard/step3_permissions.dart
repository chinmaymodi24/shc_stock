import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/users/controllers/add_employee_wizard_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'permission_table.dart';
import 'wizard_step_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Permissions: read / write / summary per module, read / write per
// Settings tab. Pre-filled from the role picked in Step 2.
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(appColors.radius),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set Permissions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                        fontFamily: brandFontFamily,
                      ),
                    ),
                    Obx(
                      () => Text(
                        controller.selRole == null
                            ? 'Manage read, write and summary access for modules'
                            : 'Starting from the ${controller.selRole!.name} role — change anything for this employee',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.textSecondary,
                          fontFamily: brandFontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PermissionBulkActions(editor: controller.editor),
          const SizedBox(height: 16),
          PermissionTable(editor: controller.editor, wide: wide),
          const SizedBox(height: 12),
          wizInfoBox(
            c,
            text:
                'Read opens the page. Write allows creating, editing and deleting. '
                'Summary shows the figures at the top of the page (stat cards, dashboard totals and charts).',
          ),
        ],
      ),
    );
  }
}

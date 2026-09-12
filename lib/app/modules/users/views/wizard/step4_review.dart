import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/users/controllers/add_employee_wizard_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'wizard_step_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — Review & Create (final summary before submit).
// Extracted from add_employee_wizard.dart's _step4 method.
// ─────────────────────────────────────────────────────────────────────────────
class ReviewCreateStep extends GetView<AddEmployeeWizardController> {
  final bool wide;
  final bool tablet;
  const ReviewCreateStep({super.key, required this.wide, required this.tablet});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Obx(() {
      final status = controller.status.value;
      final welcome = controller.welcome.value;
      final selRole = controller.selRole;
      final editor = controller.editor;

      return wizCard(
        c,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            wizSecHeader(
              c,
              icon: Icons.checklist_rounded,
              title: 'Review & Confirm',
              sub:
                  'Review all information before creating the employee account.',
            ),
            const SizedBox(height: 20),

            // ── Employee Information ──────────────────────────────────────────────
            wizRevSection(
              c,
              icon: Icons.person_outline_rounded,
              title: 'Employee Information',
              onEdit: () => controller.step.value = 0,
              child: wizRow2(wide, [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    wizRevRow(
                      'Full Name',
                      controller.nameCtrl.text.isEmpty
                          ? '-'
                          : controller.nameCtrl.text,
                      c,
                    ),
                    wizRevRow(
                      'Email',
                      controller.emailCtrl.text.isEmpty
                          ? '-'
                          : controller.emailCtrl.text,
                      c,
                    ),
                    wizRevRow(
                      'Phone',
                      controller.phoneCtrl.text.isEmpty
                          ? '-'
                          : controller.phoneCtrl.text,
                      c,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    wizRevRow(
                      'Department',
                      controller.dept.value.isEmpty
                          ? '-'
                          : controller.dept.value,
                      c,
                    ),
                    wizRevRow('Date of Joining', controller.fmtDOJ, c),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 12,
                                color: c.textSecondary,
                                fontFamily: brandFontFamily,
                              ),
                            ),
                          ),
                          const Text(
                            ' :  ',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: status == 'Active'
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              fontFamily: brandFontFamily,
                              color: status == 'Active'
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ]),
            ),
            Divider(height: 1, color: c.divider),

            // ── Account Settings ──────────────────────────────────────────────────
            wizRevSection(
              c,
              icon: Icons.lock_outline_rounded,
              title: 'Account Settings',
              onEdit: () => controller.step.value = 0,
              child: wizRow2(wide, [
                Column(
                  children: [
                    wizRevRow(
                      'Username',
                      controller.userCtrl.text.isEmpty
                          ? '-'
                          : controller.userCtrl.text,
                      c,
                    ),
                    _PasswordReviewRow(
                      password: controller.passCtrl.text,
                      // On an edit a blank field keeps the current password.
                      emptyLabel: controller.isEdit ? 'Unchanged' : '-',
                      show: controller.showReviewPass.value,
                      onToggle: () => controller.showReviewPass.toggle(),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 130,
                            child: Text(
                              'Send Welcome Email',
                              style: TextStyle(
                                fontSize: 12,
                                color: c.textSecondary,
                                fontFamily: brandFontFamily,
                              ),
                            ),
                          ),
                          const Text(
                            ' :  ',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: welcome
                                  ? const Color(0xFF22C55E)
                                  : c.textHint,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            welcome ? 'Yes' : 'No',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              fontFamily: brandFontFamily,
                              color: welcome
                                  ? const Color(0xFF22C55E)
                                  : c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ]),
            ),
            Divider(height: 1, color: c.divider),

            // ── Role Information ──────────────────────────────────────────────────
            wizRevSection(
              c,
              icon: Icons.manage_accounts_outlined,
              title: 'Role Information',
              onEdit: () => controller.step.value = 1,
              child: wizRow2(wide, [
                Column(
                  children: [
                    wizRevRow('Role Name', selRole?.name ?? '-', c),
                    wizRevRow(
                      'Role Description',
                      selRole == null || selRole.description.isEmpty
                          ? '-'
                          : selRole.description,
                      c,
                    ),
                  ],
                ),
                Column(
                  children: [
                    wizRevRow(
                      'Role Type',
                      selRole == null
                          ? '-'
                          : selRole.isSystem
                          ? 'Ready-made'
                          : 'Custom',
                      c,
                    ),
                    wizRevRow(
                      'Users with this role',
                      '${selRole?.userCount ?? 0}',
                      c,
                    ),
                  ],
                ),
              ]),
            ),
            Divider(height: 1, color: c.divider),

            // ── Permissions Summary ───────────────────────────────────────────────
            wizRevSection(
              c,
              icon: Icons.shield_outlined,
              title: 'Permissions Summary',
              onEdit: () => controller.step.value = 2,
              child: wizRow2(wide, [
                wizPermStat(
                  c,
                  icon: Icons.visibility_outlined,
                  label: 'Modules with Read Access',
                  value: '${editor.readCnt}',
                  color: const Color(0xFF0EA5E9),
                ),
                wizPermStat(
                  c,
                  icon: Icons.edit_outlined,
                  label: 'Modules with Write Access',
                  value: '${editor.writeCnt}',
                  color: AppColors.primaryOrange,
                ),
                wizPermStat(
                  c,
                  icon: Icons.insights_outlined,
                  label: 'Modules with Summary Access',
                  value: '${editor.summaryCnt}',
                  color: const Color(0xFF22C55E),
                ),
                wizPermStat(
                  c,
                  icon: Icons.visibility_off_outlined,
                  label: 'Modules with No Access',
                  value: '${editor.noCnt}',
                  color: const Color(0xFFEF4444),
                ),
                wizPermStat(
                  c,
                  icon: Icons.settings_outlined,
                  label:
                      'Settings Tabs Allowed (${editor.settingsWriteCnt} can save)',
                  value: '${editor.settingsReadCnt} / ${editor.settingsCnt}',
                  color: const Color(0xFF8B5CF6),
                ),
                wizPermStat(
                  c,
                  icon: Icons.apps_rounded,
                  label: 'Total Modules',
                  value: '${editor.moduleCnt}',
                  color: context.appColors.accent,
                ),
              ]),
            ),

            const SizedBox(height: 12),
            wizInfoBox(
              c,
              text:
                  'Please review all the details carefully. After creating the account, you can edit the information anytime.',
            ),
          ],
        ),
      );
    });
  }
}

/// Review row for the password: masked with `*` (one per character) by
/// default, with an eye icon beside it that reveals the typed password.
class _PasswordReviewRow extends StatelessWidget {
  final String password;
  final String emptyLabel;
  final bool show;
  final VoidCallback onToggle;

  const _PasswordReviewRow({
    required this.password,
    required this.emptyLabel,
    required this.show,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final hasPassword = password.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              'Password',
              style: TextStyle(
                fontSize: 12,
                color: c.textSecondary,
                fontFamily: brandFontFamily,
              ),
            ),
          ),
          const Text(
            ' :  ',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Flexible(
            child: Text(
              !hasPassword
                  ? emptyLabel
                  : show
                  ? password
                  : '*' * password.length,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
                fontFamily: brandFontFamily,
              ),
            ),
          ),
          if (hasPassword) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: show ? 'Hide password' : 'Show password',
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    show
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 16,
                    color: c.textHint,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/users/controllers/add_employee_wizard_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'wizard/step1_employee_details.dart';
import 'wizard/step2_assign_role.dart';
import 'wizard/step3_permissions.dart';
import 'wizard/step4_review.dart';

const _kStepTitles = [
  'Employee Details',
  'Assign Role',
  'Permissions',
  'Review & Create',
];
const _kStepSubs = [
  'Enter basic information',
  'Select or create a role',
  'Set access permissions',
  'Review and confirm',
];

// ─────────────────────────────────────────────────────────────────────────────
// Wizard Widget — all state lives in AddEmployeeWizardController (registered
// by UsersBinding) — no setState anywhere in this file.
// ─────────────────────────────────────────────────────────────────────────────
class AddEmployeeWizard extends GetView<AddEmployeeWizardController> {
  const AddEmployeeWizard({super.key});

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: Row(
        children: [
          const WebSidebar(),
          Expanded(
            child: Column(
              children: [
                const WebTopBar(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (ctx, cons) {
                      final wide = cons.maxWidth >= 1000;
                      final tablet = cons.maxWidth >= 600;
                      return Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(
                                wide
                                    ? 24.0
                                    : tablet
                                    ? 16.0
                                    : 12.0,
                              ),
                              child: Obx(
                                () => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ── Header: title ─────────────────────
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Create Employee Account',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: colors.textPrimary,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Add a new employee and assign role with permissions',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: colors.textSecondary,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: wide ? 20.0 : 16.0),
                                    _buildStepper(wide, tablet, colors),
                                    SizedBox(height: wide ? 24.0 : 16.0),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildStepContent(
                                            context,
                                            wide,
                                            tablet,
                                            colors,
                                          ),
                                        ),
                                        if (wide) ...[
                                          const SizedBox(width: 16),
                                          SizedBox(
                                            width: 272,
                                            child: _buildRightPanel(colors),
                                          ),
                                        ],
                                      ],
                                    ),
                                    // Tablet: right panel below
                                    if (tablet && !wide) ...[
                                      const SizedBox(height: 16),
                                      _buildRightPanel(colors),
                                    ],
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Obx(() => _buildBottomBar(wide, tablet, colors)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stepper ───────────────────────────────────────────────────────────────
  Widget _buildStepper(bool wide, bool tablet, AppThemeColors c) {
    final step = controller.step.value;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: wide ? 24 : 16,
        vertical: wide ? 20 : 14,
      ),
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
      child: Row(
        children: List.generate(_kStepTitles.length, (i) {
          final done = i < step;
          final active = i == step;
          final isLast = i == _kStepTitles.length - 1;
          final circleSz = wide ? 36.0 : 28.0;

          final borderColor = (active || done)
              ? AppColors.primaryOrange
              : c.divider;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Left connector — transparent (not omitted) on the
                          // first step so its circle still centers under its
                          // label instead of hugging the container edge.
                          Expanded(
                            child: Container(
                              height: 2,
                              color: i == 0
                                  ? Colors.transparent
                                  : (done || active
                                        ? AppColors.primaryOrange
                                        : c.divider),
                            ),
                          ),
                          // Step circle
                          Container(
                            width: circleSz,
                            height: circleSz,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active
                                  ? AppColors.primaryOrange
                                  : Colors.transparent,
                              border: Border.all(
                                color: borderColor,
                                width: active || done ? 2 : 1.5,
                              ),
                            ),
                            child: Center(
                              child: done
                                  ? Icon(
                                      Icons.check_rounded,
                                      color: AppColors.primaryOrange,
                                      size: wide ? 16 : 13,
                                    )
                                  : Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontSize: wide ? 14 : 12,
                                        fontWeight: FontWeight.w700,
                                        color: active
                                            ? Colors.white
                                            : (done
                                                  ? AppColors.primaryOrange
                                                  : c.textHint),
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                            ),
                          ),
                          // Right connector — transparent (not omitted) on
                          // the last step for the same reason as above.
                          Expanded(
                            child: Container(
                              height: 2,
                              color: isLast
                                  ? Colors.transparent
                                  : (done
                                        ? AppColors.primaryOrange
                                        : c.divider),
                            ),
                          ),
                        ],
                      ),
                      if (tablet) ...[
                        const SizedBox(height: 8),
                        Text(
                          _kStepTitles[i],
                          style: TextStyle(
                            fontSize: wide ? 13 : 11,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: active
                                ? AppColors.primaryOrange
                                : (done ? c.textSecondary : c.textHint),
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (wide)
                          Text(
                            _kStepSubs[i],
                            style: TextStyle(
                              fontSize: 11,
                              color: c.textHint,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Step content dispatcher ───────────────────────────────────────────────
  Widget _buildStepContent(
    BuildContext context,
    bool wide,
    bool tablet,
    AppThemeColors c,
  ) {
    switch (controller.step.value) {
      case 0:
        return EmployeeDetailsStep(wide: wide, tablet: tablet);
      case 1:
        return AssignRoleStep(wide: wide, tablet: tablet);
      case 2:
        return PermissionsStep(wide: wide, tablet: tablet);
      case 3:
        return ReviewCreateStep(wide: wide, tablet: tablet);
      default:
        return const SizedBox();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1 — Employee Details
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRightPanel(AppThemeColors c) {
    final step = controller.step.value;
    final items = _panelItems(c);
    final tips = _stepTips();

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step X of 4
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step ${step + 1} of 4',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: c.textHint,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _kStepTitles[step],
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _stepDesc(),
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textSecondary,
                    fontFamily: 'Poppins',
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: c.divider),
          ...items,
          const SizedBox(height: 4),
          Divider(height: 1, color: c.divider),
          // Tips
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.primaryOrange,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tips',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryOrange,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...tips.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 5, right: 8),
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              t,
                              style: TextStyle(
                                fontSize: 12,
                                color: c.textSecondary,
                                fontFamily: 'Poppins',
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar(bool wide, bool tablet, AppThemeColors c) {
    final isLast = controller.step.value == 3;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: controller.back,
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 16,
              color: c.textSecondary,
            ),
            label: Text(
              'Back',
              style: TextStyle(
                fontSize: 13.5,
                fontFamily: 'Poppins',
                color: c.textSecondary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: c.border),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Get.offNamed(AppRoutes.users),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 13.5,
                fontFamily: 'Poppins',
                color: c.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: controller.next,
            icon: Icon(
              isLast ? Icons.person_add_outlined : Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 16,
            ),
            label: Text(
              isLast ? 'Create Employee' : 'Continue',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: tablet ? 22 : 14,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED BUILDER HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  // ── Right panel data ──────────────────────────────────────────────────────
  String _stepDesc() => [
    'Provide basic information and login credentials for the new employee.',
    'Roles help you define access levels for employees. You can choose an existing role or create a custom one.',
    'Define what this employee can view and edit in the system.',
    'You are about to create a new employee account with the following details.',
  ][controller.step.value];

  List<Widget> _panelItems(AppThemeColors c) {
    final items = [
      [
        (
          'Secure Access',
          Icons.lock_outline_rounded,
          'Employee will receive secure login credentials',
        ),
        (
          'Role Based Access',
          Icons.group_outlined,
          'Access will be based on selected role',
        ),
        (
          'Custom Permissions',
          Icons.shield_outlined,
          'Fine-grained permissions in next step',
        ),
      ],
      [
        (
          'Pre-defined Roles',
          Icons.group_outlined,
          'Use existing roles to quickly assign access permissions',
        ),
        (
          'Custom Roles',
          Icons.shield_outlined,
          'Create a new role with specific permissions as per your need',
        ),
        (
          'Flexible Permissions',
          Icons.tune_rounded,
          'You can modify permissions in the next step',
        ),
      ],
      [
        (
          'Read Access',
          Icons.visibility_outlined,
          'Employee can view and access module information',
        ),
        (
          'Write Access',
          Icons.edit_outlined,
          'Employee can create, edit and delete information',
        ),
        (
          'Granular Control',
          Icons.tune_rounded,
          'You can customize permissions module by module',
        ),
      ],
      [
        (
          'Employee Information',
          Icons.person_outline_rounded,
          '${controller.nameCtrl.text.isEmpty ? 'Name' : controller.nameCtrl.text}\n${controller.emailCtrl.text.isEmpty ? 'Email' : controller.emailCtrl.text}',
        ),
        (
          'Account Settings',
          Icons.lock_outline_rounded,
          'Username: ${controller.userCtrl.text.isEmpty ? '-' : controller.userCtrl.text}\n${controller.welcome.value ? 'Welcome email will be sent' : 'No welcome email'}',
        ),
        (
          'Role',
          Icons.manage_accounts_outlined,
          '${controller.customTab.value ? 'Custom Role' : (controller.selRole?.name ?? 'Not selected')}\n${controller.selRole != null ? '${roleOptUserCount(controller.selRole!.id)} users with this role' : ''}',
        ),
        (
          'Permissions',
          Icons.shield_outlined,
          'Read: ${controller.readCnt} modules\nWrite: ${controller.writeCnt} modules',
        ),
      ],
    ][controller.step.value];

    return items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.$2, size: 17, color: AppColors.primaryOrange),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.$3,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: c.textSecondary,
                          fontFamily: 'Poppins',
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  List<String> _stepTips() => [
    [
      'Use a valid email address',
      'Username must be unique',
      'Employee can reset password later',
    ],
    [
      'Choose the role that best fits the employee\'s responsibilities',
      'You can always update role or permissions later',
    ],
    [
      'Grant only necessary permissions for security',
      'You can change permissions anytime',
      'Use custom role if predefined roles don\'t fit your needs',
    ],
    [
      'Please review all details carefully',
      'After creating, you can edit information anytime',
      'Employee will receive login credentials if welcome email is enabled',
    ],
  ][controller.step.value];
}

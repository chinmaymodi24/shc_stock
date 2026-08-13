import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/users/controllers/add_employee_wizard_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'wizard_step_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Employee Details (employee info + account settings).
// Extracted from add_employee_wizard.dart's _step1 method.
// ─────────────────────────────────────────────────────────────────────────────
class EmployeeDetailsStep extends GetView<AddEmployeeWizardController> {
  final bool wide;
  final bool tablet;
  const EmployeeDetailsStep({
    super.key,
    required this.wide,
    required this.tablet,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      children: [
        // ── Employee Information ──────────────────────────────────────────────
        wizCard(
          c,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              wizSecHeader(
                c,
                icon: Icons.person_outline_rounded,
                title: 'Employee Information',
                sub: 'Enter basic details of the employee',
              ),
              const SizedBox(height: 20),
              wizRowN(wide, tablet, [
                wizTextField(
                  c,
                  ctrl: controller.nameCtrl,
                  label: 'Full Name',
                  hint: 'Enter full name',
                  icon: Icons.person_outline_rounded,
                  req: true,
                  error: controller.eName.value,
                  onChange: (_) => controller.eName.value = null,
                ),
                wizTextField(
                  c,
                  ctrl: controller.emailCtrl,
                  label: 'Email Address',
                  hint: 'Enter email address',
                  icon: Icons.email_outlined,
                  req: true,
                  error: controller.eEmail.value,
                  onChange: (_) => controller.eEmail.value = null,
                ),
                wizTextField(
                  c,
                  ctrl: controller.phoneCtrl,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  icon: Icons.phone_outlined,
                ),
                wizTextField(
                  c,
                  ctrl: controller.altPhoneCtrl,
                  label: 'Alternate Phone',
                  hint: 'Enter phone number',
                  icon: Icons.phone_outlined,
                ),
              ]),
              wizVGap(wide),
              wizRowN(wide, tablet, [
                wizDeptDropdown(controller, c),
                wizTextField(
                  c,
                  ctrl: controller.designationCtrl,
                  label: 'Designation',
                  hint: 'e.g. Warehouse Executive',
                  icon: Icons.badge_outlined,
                ),
                wizTextField(
                  c,
                  ctrl: controller.employeeCodeCtrl,
                  label: 'Employee Code',
                  hint: 'Auto generated',
                  icon: Icons.tag_rounded,
                  readOnly: true,
                ),
                wizDatePickerField(
                  c,
                  label: 'Date of Joining',
                  value: controller.doj,
                  fmt: controller.fmtDOJ,
                  onPick: (d) => controller.doj.value = d,
                  context: context,
                ),
              ]),
              wizVGap(wide),
              wizRowN(wide, tablet, [
                wizDatePickerField(
                  c,
                  label: 'Date of Birth',
                  value: controller.dob,
                  fmt: controller.fmtDOB,
                  onPick: (d) => controller.dob.value = d,
                  context: context,
                ),
                wizSimpleDropdown(
                  c,
                  label: 'Employment Type',
                  icon: Icons.work_outline_rounded,
                  value: controller.employmentType.value,
                  items: kEmploymentTypes,
                  onChanged: (v) => controller.employmentType.value = v,
                ),
                wizTextField(
                  c,
                  ctrl: controller.reportingManagerCtrl,
                  label: 'Reporting Manager',
                  hint: 'e.g. Riya Patel',
                  icon: Icons.supervisor_account_outlined,
                ),
                wizStatusDropdown(controller, c),
              ]),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Account Settings ──────────────────────────────────────────────────
        wizCard(
          c,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              wizSecHeader(
                c,
                icon: Icons.lock_outline_rounded,
                title: 'Account Settings',
                sub: 'Set login credentials for the employee',
              ),
              const SizedBox(height: 20),
              wizTextField(
                c,
                ctrl: controller.userCtrl,
                label: 'Username',
                hint: 'Enter username',
                icon: Icons.person_outline_rounded,
                req: true,
                error: controller.eUser.value,
                onChange: (_) => controller.eUser.value = null,
              ),
              wizVGap(wide),
              wizRow2(wide, [
                wizPwdField(
                  c,
                  label: 'Password',
                  ctrl: controller.passCtrl,
                  show: controller.showPass.value,
                  req: true,
                  error: controller.ePass.value,
                  onToggle: () =>
                      controller.showPass.value = !controller.showPass.value,
                  onChange: (_) => controller.ePass.value = null,
                ),
                wizPwdField(
                  c,
                  label: 'Confirm Password',
                  ctrl: controller.confCtrl,
                  show: controller.showConf.value,
                  req: true,
                  hint: 'Re-enter password',
                  error: controller.eConf.value,
                  onToggle: () =>
                      controller.showConf.value = !controller.showConf.value,
                  onChange: (_) => controller.eConf.value = null,
                ),
              ]),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Send welcome email to employee',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: c.textPrimary,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Switch(
                    value: controller.welcome.value,
                    onChanged: (v) => controller.welcome.value = v,
                    activeColor: AppColors.primaryOrange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

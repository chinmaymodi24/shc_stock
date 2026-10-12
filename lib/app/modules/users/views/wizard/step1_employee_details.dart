import 'package:flutter/material.dart';
import 'package:shc_stock/app/core/utils/phone_input.dart';
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
    // Obx lives HERE, not just around the step in the parent wizard: a parent
    // Obx only tracks the observables read while its own builder runs, and
    // this step's build happens later, in its own element. Without this the
    // show/hide password eyes and every validation message were dead — the
    // .obs flipped, nothing repainted.
    return Obx(
      () => Column(
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
                  // Digits only, hard-stopped at 10 — the field used to take
                  // any text at all, so "asdfasdkfjha" sailed through to the
                  // backend as a phone number.
                  wizTextField(
                    c,
                    ctrl: controller.phoneCtrl,
                    label: 'Phone Number',
                    hint: kPhoneHint,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: kPhoneInputFormatters,
                    error: controller.ePhone.value,
                    onChange: (_) => controller.ePhone.value = null,
                  ),
                  wizTextField(
                    c,
                    ctrl: controller.altPhoneCtrl,
                    label: 'Alternate Phone',
                    hint: kPhoneHint,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: kPhoneInputFormatters,
                    error: controller.eAltPhone.value,
                    onChange: (_) => controller.eAltPhone.value = null,
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
                  sub: controller.isEdit
                      ? 'Sign-in is by email address — set a new password only '
                            'to change it'
                      : 'The employee signs in with the email address above '
                            'and this password',
                ),
                const SizedBox(height: 20),
                wizRow2(wide, [
                  wizPwdField(
                    c,
                    label: 'Password',
                    ctrl: controller.passCtrl,
                    show: controller.showPass.value,
                    // On an edit the stored password is never sent back to
                    // the app, so the box starts blank and blank means "leave
                    // it as it is" - it is not a field the admin has to fill.
                    req: !controller.isEdit,
                    hint: controller.isEdit
                        ? 'Leave blank to keep current'
                        : null,
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
                    req: !controller.isEdit,
                    hint: controller.isEdit
                        ? 'Leave blank to keep current'
                        : 'Re-enter password',
                    error: controller.eConf.value,
                    onToggle: () =>
                        controller.showConf.value = !controller.showConf.value,
                    onChange: (_) => controller.eConf.value = null,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

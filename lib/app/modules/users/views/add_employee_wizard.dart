import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/add_employee_wizard_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';

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
      body: LayoutBuilder(
        builder: (ctx, cons) {
          final wide = cons.maxWidth >= 1000;
          final tablet = cons.maxWidth >= 600;
          return Column(
            children: [
              _buildTopBar(colors, tablet),
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
                        _buildStepper(wide, tablet, colors),
                        SizedBox(height: wide ? 24.0 : 16.0),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(AppThemeColors c, bool tablet) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          // Back button
          InkWell(
            onTap: Get.back,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: c.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Create Employee Account',
                  style: TextStyle(
                    fontSize: tablet ? 16 : 14,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (tablet)
                  Text(
                    'Add a new employee and assign role with permissions',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: c.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
              ],
            ),
          ),
          if (tablet) ...[
            Container(
              width: 200,
              height: 34,
              decoration: BoxDecoration(
                color: c.inputFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.border),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(Icons.search_rounded, color: c.textHint, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    'Search anything...',
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textHint,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
          Stack(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: c.inputFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.border),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: c.textSecondary,
                  size: 17,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '3',
                      style: TextStyle(
                        fontSize: 7,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primaryOrange,
              size: 17,
            ),
          ),
          const SizedBox(width: 6),
          if (tablet)
            Text(
              'Admin',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: c.textSecondary,
            size: 16,
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
                          // Left connector
                          if (i > 0)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: done || active
                                    ? AppColors.primaryOrange
                                    : c.divider,
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
                          // Right connector
                          if (!isLast)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: done
                                    ? AppColors.primaryOrange
                                    : c.divider,
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
        return _step1(wide, tablet, c, context);
      case 1:
        return _step2(wide, tablet, c);
      case 2:
        return _step3(wide, tablet, c);
      case 3:
        return _step4(wide, tablet, c);
      default:
        return const SizedBox();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1 — Employee Details
  // ─────────────────────────────────────────────────────────────────────────
  Widget _step1(
    bool wide,
    bool tablet,
    AppThemeColors c,
    BuildContext context,
  ) {
    return Column(
      children: [
        // ── Employee Information ──────────────────────────────────────────────
        _card(
          c,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _secHeader(
                c,
                icon: Icons.person_outline_rounded,
                title: 'Employee Information',
                sub: 'Enter basic details of the employee',
              ),
              const SizedBox(height: 20),
              _row2(wide, [
                _textField(
                  c,
                  ctrl: controller.nameCtrl,
                  label: 'Full Name',
                  hint: 'Enter full name',
                  icon: Icons.person_outline_rounded,
                  req: true,
                  error: controller.eName.value,
                  onChange: (_) => controller.eName.value = null,
                ),
                _textField(
                  c,
                  ctrl: controller.emailCtrl,
                  label: 'Email Address',
                  hint: 'Enter email address',
                  icon: Icons.email_outlined,
                  req: true,
                  error: controller.eEmail.value,
                  onChange: (_) => controller.eEmail.value = null,
                ),
              ]),
              _vGap(wide),
              _row2(wide, [
                _textField(
                  c,
                  ctrl: controller.phoneCtrl,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  icon: Icons.phone_outlined,
                ),
                _deptDropdown(c),
              ]),
              _vGap(wide),
              _row2(wide, [_datePickerField(c, context), _statusDropdown(c)]),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Account Settings ──────────────────────────────────────────────────
        _card(
          c,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _secHeader(
                c,
                icon: Icons.lock_outline_rounded,
                title: 'Account Settings',
                sub: 'Set login credentials for the employee',
              ),
              const SizedBox(height: 20),
              _textField(
                c,
                ctrl: controller.userCtrl,
                label: 'Username',
                hint: 'Enter username',
                icon: Icons.person_outline_rounded,
                req: true,
                error: controller.eUser.value,
                onChange: (_) => controller.eUser.value = null,
              ),
              _vGap(wide),
              _row2(wide, [
                _pwdField(
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
                _pwdField(
                  c,
                  label: 'Confirm Password',
                  ctrl: controller.confCtrl,
                  show: controller.showConf.value,
                  req: true,
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

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2 — Assign Role
  // ─────────────────────────────────────────────────────────────────────────
  Widget _step2(bool wide, bool tablet, AppThemeColors c) {
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

    return _card(
      c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secHeader(
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
                child: _roleTab(
                  c,
                  label: 'Select Existing Role',
                  icon: Icons.radio_button_checked_rounded,
                  active: !customTab,
                  onTap: () => controller.customTab.value = false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _roleTab(
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
                                '${r.count}',
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
              _infoBox(
                c,
                text: 'Please select a role to continue.',
                isError: true,
              ),
            ],
            const SizedBox(height: 12),
            _infoBox(
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

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3 — Permissions
  // ─────────────────────────────────────────────────────────────────────────
  Widget _step3(bool wide, bool tablet, AppThemeColors c) {
    return _card(
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
          _infoBox(
            c,
            text:
                'Read access allows viewing data. Write access allows creating, editing and deleting data.',
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 4 — Review & Create
  // ─────────────────────────────────────────────────────────────────────────
  Widget _step4(bool wide, bool tablet, AppThemeColors c) {
    final status = controller.status.value;
    final welcome = controller.welcome.value;
    final customTab = controller.customTab.value;
    final selRole = controller.selRole;

    return _card(
      c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secHeader(
            c,
            icon: Icons.checklist_rounded,
            title: 'Review & Confirm',
            sub: 'Review all information before creating the employee account.',
          ),
          const SizedBox(height: 20),

          // ── Employee Information ──────────────────────────────────────────────
          _revSection(
            c,
            icon: Icons.person_outline_rounded,
            title: 'Employee Information',
            onEdit: () => controller.step.value = 0,
            child: _row2(wide, [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _revRow(
                    'Full Name',
                    controller.nameCtrl.text.isEmpty
                        ? '-'
                        : controller.nameCtrl.text,
                    c,
                  ),
                  _revRow(
                    'Email',
                    controller.emailCtrl.text.isEmpty
                        ? '-'
                        : controller.emailCtrl.text,
                    c,
                  ),
                  _revRow(
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
                  _revRow(
                    'Department',
                    controller.dept.value.isEmpty ? '-' : controller.dept.value,
                    c,
                  ),
                  _revRow('Date of Joining', controller.fmtDOJ, c),
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
                              fontFamily: 'Poppins',
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
                            fontFamily: 'Poppins',
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
          _revSection(
            c,
            icon: Icons.lock_outline_rounded,
            title: 'Account Settings',
            onEdit: () => controller.step.value = 0,
            child: _row2(wide, [
              Column(
                children: [
                  _revRow(
                    'Username',
                    controller.userCtrl.text.isEmpty
                        ? '-'
                        : controller.userCtrl.text,
                    c,
                  ),
                  _revRow('Password', '●' * 12, c),
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
                              fontFamily: 'Poppins',
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
                            fontFamily: 'Poppins',
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
          _revSection(
            c,
            icon: Icons.manage_accounts_outlined,
            title: 'Role Information',
            onEdit: () => controller.step.value = 1,
            child: _row2(wide, [
              Column(
                children: [
                  _revRow(
                    'Role Name',
                    customTab ? 'Custom Role' : (selRole?.name ?? '-'),
                    c,
                  ),
                  _revRow(
                    'Role Description',
                    customTab
                        ? 'Custom role with specific permissions'
                        : (selRole?.desc ?? '-'),
                    c,
                  ),
                ],
              ),
              Column(
                children: [
                  _revRow('Users with this role', '${selRole?.count ?? 0}', c),
                ],
              ),
            ]),
          ),
          Divider(height: 1, color: c.divider),

          // ── Permissions Summary ───────────────────────────────────────────────
          _revSection(
            c,
            icon: Icons.shield_outlined,
            title: 'Permissions Summary',
            onEdit: () => controller.step.value = 2,
            child: _row2(wide, [
              _permStat(
                c,
                icon: Icons.visibility_outlined,
                label: 'Modules with Read Access',
                value: '${controller.readCnt}',
                color: const Color(0xFF0EA5E9),
              ),
              _permStat(
                c,
                icon: Icons.edit_outlined,
                label: 'Modules with Write Access',
                value: '${controller.writeCnt}',
                color: AppColors.primaryOrange,
              ),
              _permStat(
                c,
                icon: Icons.visibility_off_outlined,
                label: 'Modules with No Access',
                value: '${controller.noCnt}',
                color: const Color(0xFFEF4444),
              ),
              _permStat(
                c,
                icon: Icons.apps_rounded,
                label: 'Total Modules',
                value: '${controller.perms.length}',
                color: const Color(0xFF4A3AFF),
              ),
            ]),
          ),

          const SizedBox(height: 12),
          _infoBox(
            c,
            text:
                'Please review all the details carefully. After creating the account, you can edit the information anytime.',
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RIGHT PANEL
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

  Widget _card(AppThemeColors c, {required Widget child}) => Container(
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

  Widget _secHeader(
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
  Widget _row2(bool wide, List<Widget> children) {
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
              child: i + 1 < children.length
                  ? children[i + 1]
                  : const SizedBox(),
            ),
          ],
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _vGap(bool wide) => SizedBox(height: wide ? 14.0 : 14.0);

  Widget _textField(
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

  Widget _pwdField(
    AppThemeColors c, {
    required String label,
    required TextEditingController ctrl,
    required bool show,
    bool req = false,
    String? error,
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
          hintText: show ? 'Enter password' : '●●●●●●●●',
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

  Widget _deptDropdown(AppThemeColors c) => Column(
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

  Widget _datePickerField(AppThemeColors c, BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Date of Joining',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: c.textPrimary,
          fontFamily: 'Poppins',
        ),
      ),
      const SizedBox(height: 6),
      _DojField(
        colors: c,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: controller.doj.value ?? DateTime.now(),
            firstDate: DateTime(2000),
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
          if (picked != null) controller.doj.value = picked;
        },
        label: controller.doj.value == null ? 'Select date' : controller.fmtDOJ,
        isEmpty: controller.doj.value == null,
      ),
    ],
  );

  Widget _statusDropdown(AppThemeColors c) => Column(
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

  Widget _roleTab(
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

  Widget _infoBox(
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

  Widget _revSection(
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

  Widget _revRow(String label, String value, AppThemeColors c) => Padding(
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

  Widget _permStat(
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
          '${controller.customTab.value ? 'Custom Role' : (controller.selRole?.name ?? 'Not selected')}\n${controller.selRole != null ? '${controller.selRole!.count} users with this role' : ''}',
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

// ─────────────────────────────────────────────────────────────────────────────
// Date of Joining field — a real Focus-wrapped widget (not an inline method)
// so it can hold persistent focus state and is reachable via Tab.
// ─────────────────────────────────────────────────────────────────────────────
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

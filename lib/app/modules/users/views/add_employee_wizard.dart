import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/users_controller.dart';
import '../models/user_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data types
// ─────────────────────────────────────────────────────────────────────────────
class _RoleOpt {
  final String id, name, desc;
  final IconData icon;
  final int count;
  const _RoleOpt(this.id, this.name, this.desc, this.icon, this.count);
}

const _kRoles = <_RoleOpt>[
  _RoleOpt('super_admin', 'Super Admin',  'Full access to all modules and settings',      Icons.stars_rounded,                   1),
  _RoleOpt('admin',       'Admin',        'Manage most modules and system settings',       Icons.admin_panel_settings_outlined,   3),
  _RoleOpt('manager',     'Manager',      'Manage stock, purchases, sales and reports',    Icons.manage_accounts_outlined,        5),
  _RoleOpt('sales',       'Sales',        'Access to sales, customers and invoices',       Icons.point_of_sale_outlined,          8),
  _RoleOpt('store_staff', 'Store Staff',  'Access to stock and warehouse operations',      Icons.warehouse_outlined,              7),
  _RoleOpt('custom',      'Custom Role',  'Custom role with specific permissions',         Icons.tune_rounded,                    2),
];

class _Mod {
  final String name;
  final IconData icon;
  const _Mod(this.name, this.icon);
}

const _kMods = <_Mod>[
  _Mod('Dashboard', Icons.dashboard_rounded),
  _Mod('Products',  Icons.inventory_2_outlined),
  _Mod('Stock',     Icons.warehouse_outlined),
  _Mod('Purchase',  Icons.shopping_bag_outlined),
  _Mod('Sales',     Icons.point_of_sale_outlined),
  _Mod('Clients',   Icons.people_outline_rounded),
  _Mod('Reports',   Icons.bar_chart_rounded),
  _Mod('Users',     Icons.manage_accounts_outlined),
  _Mod('Settings',  Icons.settings_outlined),
];

const _kDepts = <String>[
  'Sales', 'Marketing', 'IT', 'Finance', 'Operations', 'HR', 'Warehouse',
];

const _kStepTitles = ['Employee Details', 'Assign Role', 'Permissions', 'Review & Create'];
const _kStepSubs   = ['Enter basic information', 'Select or create a role', 'Set access permissions', 'Review and confirm'];

class _Perm {
  final String  module;
  final IconData icon;
  bool read;
  bool write;
  _Perm({required this.module, required this.icon, this.read = true, this.write = true});
}

// ─────────────────────────────────────────────────────────────────────────────
// Wizard Widget
// ─────────────────────────────────────────────────────────────────────────────
class AddEmployeeWizard extends StatefulWidget {
  const AddEmployeeWizard({super.key});
  @override
  State<AddEmployeeWizard> createState() => _WizardState();
}

class _WizardState extends State<AddEmployeeWizard> {
  int _step = 0;

  // ── Step 1 state ──────────────────────────────────────────────────────────
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _userCtrl  = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confCtrl  = TextEditingController();
  String    _dept     = '';
  String    _status   = 'Active';
  bool      _welcome  = true;
  bool      _showPass = false;
  bool      _showConf = false;
  DateTime? _doj;
  // Step 1 validation errors
  String? _eName, _eEmail, _eUser, _ePass, _eConf;

  // ── Step 2 state ──────────────────────────────────────────────────────────
  String? _roleId;
  bool    _customTab = false;
  bool    _roleErr   = false;
  final   _roleSearchCtrl = TextEditingController();

  // ── Step 3 state ──────────────────────────────────────────────────────────
  late List<_Perm> _perms;

  @override
  void initState() {
    super.initState();
    _perms = _kMods.map((m) => _Perm(
      module: m.name, icon: m.icon,
      read: true,
      write: m.name != 'Reports' && m.name != 'Users',
    )).toList();
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _phoneCtrl, _userCtrl, _passCtrl, _confCtrl, _roleSearchCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Computed ─────────────────────────────────────────────────────────────
  int get _readCnt  => _perms.where((p) => p.read).length;
  int get _writeCnt => _perms.where((p) => p.write).length;
  int get _noCnt    => _perms.where((p) => !p.read && !p.write).length;

  _RoleOpt? get _selRole => _roleId == null
      ? null
      : _kRoles.where((r) => r.id == _roleId).firstOrNull;

  String get _fmtDOJ {
    if (_doj == null) return '-';
    const M = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${_doj!.day} ${M[_doj!.month - 1]} ${_doj!.year}';
  }

  // ── Validation ────────────────────────────────────────────────────────────
  bool _v1() {
    bool ok = true;
    setState(() {
      _eName  = _nameCtrl.text.trim().isEmpty ? 'Full name is required' : null;
      _eEmail = _emailCtrl.text.trim().isEmpty
          ? 'Email is required'
          : !RegExp(r'^[\w\-.]+@[\w\-]+\.[\w\-.]+$').hasMatch(_emailCtrl.text.trim())
              ? 'Enter a valid email'
              : null;
      _eUser  = _userCtrl.text.trim().isEmpty ? 'Username is required' : null;
      _ePass  = _passCtrl.text.isEmpty
          ? 'Password is required'
          : _passCtrl.text.length < 6 ? 'Minimum 6 characters' : null;
      _eConf  = _confCtrl.text.isEmpty
          ? 'Confirm your password'
          : _confCtrl.text != _passCtrl.text ? 'Passwords do not match' : null;
      if ([_eName, _eEmail, _eUser, _ePass, _eConf].any((e) => e != null)) { ok = false; }
    });
    return ok;
  }

  bool _v2() {
    if (_customTab) return true;
    setState(() => _roleErr = _roleId == null);
    return _roleId != null;
  }

  void _next() {
    if (_step == 0 && !_v1()) return;
    if (_step == 1 && !_v2()) return;
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Get.back();
    }
  }

  void _submit() {
    final c  = Get.find<UsersController>();
    final nm = _nameCtrl.text.trim();
    final pts = nm.split(' ');
    final ini = pts.length >= 2
        ? '${pts.first[0]}${pts.last[0]}'.toUpperCase()
        : nm.substring(0, nm.length >= 2 ? 2 : 1).toUpperCase();

    UserRole ur = UserRole.salesman;
    switch (_roleId) {
      case 'super_admin':
      case 'admin':       ur = UserRole.admin;        break;
      case 'manager':     ur = UserRole.manager;      break;
      case 'sales':       ur = UserRole.salesman;     break;
      case 'store_staff': ur = UserRole.stockManager; break;
      case 'custom':      ur = UserRole.manager;      break;
    }

    c.users.add(UserModel(
      id: '${c.users.length + 1}',
      code: 'EMP-${(c.users.length + 1).toString().padLeft(4, '0')}',
      name: nm, initials: ini, badgeColor: ur.color,
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? '-' : _phoneCtrl.text.trim(),
      role: ur, isActive: _status == 'Active',
      lastLogin: 'Never',
      createdAt: _fmtDOJ == '-' ? '${DateTime.now().day} Jul ${DateTime.now().year}' : _fmtDOJ,
      department: _dept.isEmpty ? 'General' : _dept,
    ));

    Get.offNamed(AppRoutes.users);
    Get.snackbar(
      'Employee Created',
      '$nm has been added successfully.',
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    );
  }

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
          final wide   = cons.maxWidth >= 1000;
          final tablet = cons.maxWidth >= 600;
          return Column(children: [
            _buildTopBar(colors, tablet),
            Expanded(child: SingleChildScrollView(
              padding: EdgeInsets.all(wide ? 24.0 : tablet ? 16.0 : 12.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildStepper(wide, tablet, colors),
                SizedBox(height: wide ? 24.0 : 16.0),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _buildStepContent(wide, tablet, colors)),
                  if (wide) ...[
                    const SizedBox(width: 16),
                    SizedBox(width: 272, child: _buildRightPanel(colors)),
                  ],
                ]),
                // Tablet: right panel below
                if (tablet && !wide) ...[
                  const SizedBox(height: 16),
                  _buildRightPanel(colors),
                ],
                const SizedBox(height: 16),
              ]),
            )),
            _buildBottomBar(wide, tablet, colors),
          ]);
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
      child: Row(children: [
        // Back button
        InkWell(
          onTap: Get.back,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.arrow_back_rounded, color: c.textPrimary, size: 18),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Create Employee Account', style: TextStyle(fontSize: tablet ? 16 : 14, fontWeight: FontWeight.w700, color: c.textPrimary, fontFamily: 'Poppins')),
          if (tablet) Text('Add a new employee and assign role with permissions', style: TextStyle(fontSize: 11.5, color: c.textSecondary, fontFamily: 'Poppins')),
        ])),
        if (tablet) ...[
          Container(width: 200, height: 34,
            decoration: BoxDecoration(color: c.inputFill, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
            child: Row(children: [
              const SizedBox(width: 10),
              Icon(Icons.search_rounded, color: c.textHint, size: 15),
              const SizedBox(width: 6),
              Text('Search anything...', style: TextStyle(fontSize: 12, color: c.textHint, fontFamily: 'Poppins')),
            ]),
          ),
          const SizedBox(width: 10),
        ],
        Stack(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: c.inputFill, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
            child: Icon(Icons.notifications_outlined, color: c.textSecondary, size: 17)),
          Positioned(top: 0, right: 0, child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: AppColors.primaryOrange, shape: BoxShape.circle),
            child: const Center(child: Text('3', style: TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.w700))))),
        ]),
        const SizedBox(width: 10),
        CircleAvatar(radius: 15, backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15), child: const Icon(Icons.person_rounded, color: AppColors.primaryOrange, size: 17)),
        const SizedBox(width: 6),
        if (tablet) Text('Admin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary, fontFamily: 'Poppins')),
        Icon(Icons.keyboard_arrow_down_rounded, color: c.textSecondary, size: 16),
      ]),
    );
  }

  // ── Stepper ───────────────────────────────────────────────────────────────
  Widget _buildStepper(bool wide, bool tablet, AppThemeColors c) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 16, vertical: wide ? 20 : 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: List.generate(_kStepTitles.length, (i) {
        final done    = i < _step;
        final active  = i == _step;
        final isLast  = i == _kStepTitles.length - 1;
        final circleSz = wide ? 36.0 : 28.0;

        final borderColor = (active || done) ? AppColors.primaryOrange : c.divider;

        return Expanded(child: Row(children: [
          Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              // Left connector
              if (i > 0) Expanded(child: Container(height: 2, color: done || active ? AppColors.primaryOrange : c.divider)),
              // Step circle
              Container(
                width: circleSz, height: circleSz,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? AppColors.primaryOrange : Colors.transparent,
                  border: Border.all(color: borderColor, width: active || done ? 2 : 1.5),
                ),
                child: Center(child: done
                    ? Icon(Icons.check_rounded, color: AppColors.primaryOrange, size: wide ? 16 : 13)
                    : Text('${i + 1}', style: TextStyle(
                        fontSize: wide ? 14 : 12, fontWeight: FontWeight.w700,
                        color: active ? Colors.white : (done ? AppColors.primaryOrange : c.textHint),
                        fontFamily: 'Poppins'))),
              ),
              // Right connector
              if (!isLast) Expanded(child: Container(height: 2, color: done ? AppColors.primaryOrange : c.divider)),
            ]),
            if (tablet) ...[
              const SizedBox(height: 8),
              Text(_kStepTitles[i],
                style: TextStyle(fontSize: wide ? 13 : 11, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? AppColors.primaryOrange : (done ? c.textSecondary : c.textHint), fontFamily: 'Poppins'),
                textAlign: TextAlign.center),
              if (wide) Text(_kStepSubs[i],
                style: TextStyle(fontSize: 11, color: c.textHint, fontFamily: 'Poppins'),
                textAlign: TextAlign.center),
            ],
          ])),
        ]));
      })),
    );
  }

  // ── Step content dispatcher ───────────────────────────────────────────────
  Widget _buildStepContent(bool wide, bool tablet, AppThemeColors c) {
    switch (_step) {
      case 0: return _step1(wide, tablet, c);
      case 1: return _step2(wide, tablet, c);
      case 2: return _step3(wide, tablet, c);
      case 3: return _step4(wide, tablet, c);
      default: return const SizedBox();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1 — Employee Details
  // ─────────────────────────────────────────────────────────────────────────
  Widget _step1(bool wide, bool tablet, AppThemeColors c) {
    return Column(children: [
      // ── Employee Information ──────────────────────────────────────────────
      _card(c, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _secHeader(c, icon: Icons.person_outline_rounded, title: 'Employee Information', sub: 'Enter basic details of the employee'),
        const SizedBox(height: 20),
        _row2(wide, [
          _textField(c, ctrl: _nameCtrl, label: 'Full Name', hint: 'Enter full name', icon: Icons.person_outline_rounded, req: true, error: _eName,
            onChange: (_) => setState(() => _eName = null)),
          _textField(c, ctrl: _emailCtrl, label: 'Email Address', hint: 'Enter email address', icon: Icons.email_outlined, req: true, error: _eEmail,
            onChange: (_) => setState(() => _eEmail = null)),
        ]),
        _vGap(wide),
        _row2(wide, [
          _textField(c, ctrl: _phoneCtrl, label: 'Phone Number', hint: 'Enter phone number', icon: Icons.phone_outlined),
          _deptDropdown(c),
        ]),
        _vGap(wide),
        _row2(wide, [
          _datePickerField(c),
          _statusDropdown(c),
        ]),
      ])),

      const SizedBox(height: 16),

      // ── Account Settings ──────────────────────────────────────────────────
      _card(c, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _secHeader(c, icon: Icons.lock_outline_rounded, title: 'Account Settings', sub: 'Set login credentials for the employee'),
        const SizedBox(height: 20),
        _textField(c, ctrl: _userCtrl, label: 'Username', hint: 'Enter username', icon: Icons.person_outline_rounded, req: true, error: _eUser,
          onChange: (_) => setState(() => _eUser = null)),
        _vGap(wide),
        _row2(wide, [
          _pwdField(c, label: 'Password', ctrl: _passCtrl, show: _showPass, req: true, error: _ePass,
            onToggle: () => setState(() => _showPass = !_showPass),
            onChange: (_) => setState(() => _ePass = null)),
          _pwdField(c, label: 'Confirm Password', ctrl: _confCtrl, show: _showConf, req: true, error: _eConf,
            onToggle: () => setState(() => _showConf = !_showConf),
            onChange: (_) => setState(() => _eConf = null)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Text('Send welcome email to employee', style: TextStyle(fontSize: 13.5, color: c.textPrimary, fontFamily: 'Poppins', fontWeight: FontWeight.w500))),
          Switch(value: _welcome, onChanged: (v) => setState(() => _welcome = v), activeColor: AppColors.primaryOrange),
        ]),
      ])),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2 — Assign Role
  // ─────────────────────────────────────────────────────────────────────────
  Widget _step2(bool wide, bool tablet, AppThemeColors c) {
    final q     = _roleSearchCtrl.text.toLowerCase();
    final roles = q.isEmpty
        ? _kRoles
        : _kRoles.where((r) => r.name.toLowerCase().contains(q) || r.desc.toLowerCase().contains(q)).toList();

    return _card(c, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _secHeader(c, icon: Icons.group_outlined, title: 'Assign Role', sub: 'Select an existing role or create a new custom role for this employee.'),
      const SizedBox(height: 20),

      // Tabs
      Row(children: [
        Expanded(child: _roleTab(c, label: 'Select Existing Role', icon: Icons.radio_button_checked_rounded, active: !_customTab,
          onTap: () => setState(() => _customTab = false))),
        const SizedBox(width: 12),
        Expanded(child: _roleTab(c, label: 'Create Custom Role', icon: Icons.add_circle_outline_rounded, active: _customTab,
          onTap: () => setState(() { _customTab = true; _roleId = null; }))),
      ]),
      const SizedBox(height: 20),

      if (!_customTab) ...[
        // Header row
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Available Roles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary, fontFamily: 'Poppins')),
            Text('Choose from pre-defined roles', style: TextStyle(fontSize: 11.5, color: c.textSecondary, fontFamily: 'Poppins')),
          ]),
          SizedBox(width: 180, height: 34, child: TextField(
            controller: _roleSearchCtrl,
            onChanged: (_) => setState(() {}),
            style: TextStyle(fontSize: 12.5, color: c.textPrimary, fontFamily: 'Poppins'),
            decoration: InputDecoration(
              hintText: 'Search role...', hintStyle: TextStyle(color: c.textHint, fontFamily: 'Poppins', fontSize: 12.5),
              isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 7),
              prefixIcon: Icon(Icons.search_rounded, color: c.textHint, size: 15),
              filled: true, fillColor: c.inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5)),
            ),
          )),
        ]),
        const SizedBox(height: 12),

        // Table header
        Container(
          decoration: BoxDecoration(color: c.rowEven, border: Border(bottom: BorderSide(color: c.divider))),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(children: [
            Expanded(flex: 3, child: Text('Role Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textSecondary, fontFamily: 'Poppins'))),
            Expanded(flex: 5, child: Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textSecondary, fontFamily: 'Poppins'))),
            SizedBox(width: wide ? 80 : 52, child: Center(child: Text('Users', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textSecondary, fontFamily: 'Poppins')))),
            SizedBox(width: wide ? 70 : 52, child: Center(child: Text('Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textSecondary, fontFamily: 'Poppins')))),
          ]),
        ),

        ...roles.asMap().entries.map((e) {
          final r   = e.value;
          final sel = r.id == _roleId;
          return Column(children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() { _roleId = r.id; _roleErr = false; }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  color: sel ? AppColors.primaryOrange.withValues(alpha: 0.05) : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  child: Row(children: [
                    Expanded(flex: 3, child: Row(children: [
                      Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.primaryOrange.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
                        child: Icon(r.icon, color: AppColors.primaryOrange, size: 15)),
                      const SizedBox(width: 8),
                      Flexible(child: Text(r.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary, fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis)),
                    ])),
                    Expanded(flex: 5, child: Text(r.desc, style: TextStyle(fontSize: 12, color: c.textSecondary, fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis)),
                    SizedBox(width: wide ? 80 : 52, child: Center(child: Text('${r.count}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary, fontFamily: 'Poppins')))),
                    SizedBox(width: wide ? 70 : 52, child: Center(child: Radio<String>(
                      value: r.id, groupValue: _roleId,
                      onChanged: (v) => setState(() { _roleId = v; _roleErr = false; }),
                      activeColor: AppColors.primaryOrange,
                    ))),
                  ]),
                ),
              ),
            ),
            if (e.key < roles.length - 1) Divider(height: 1, color: c.divider),
          ]);
        }),

        if (_roleErr) ...[
          const SizedBox(height: 10),
          _infoBox(c, text: 'Please select a role to continue.', isError: true),
        ],
        const SizedBox(height: 12),
        _infoBox(c, text: 'You can fine-tune permissions for the selected role in the next step.'),
      ] else ...[
        // Custom role UI
        Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            border: Border.all(color: c.divider),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.primaryOrange.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.tune_rounded, color: AppColors.primaryOrange, size: 28)),
            const SizedBox(height: 14),
            Text('Custom Role', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary, fontFamily: 'Poppins')),
            const SizedBox(height: 6),
            Text('Define a custom role with specific permissions.\nYou will configure the permissions in the next step.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: c.textSecondary, fontFamily: 'Poppins', height: 1.6)),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
              label: const Text('Define Custom Role', style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ]),
        ),
      ],
    ]));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3 — Permissions
  // ─────────────────────────────────────────────────────────────────────────
  Widget _step3(bool wide, bool tablet, AppThemeColors c) {
    return _card(c, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header + Select All buttons
      Wrap(
        spacing: 12, runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primaryOrange.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.shield_outlined, color: AppColors.primaryOrange, size: 20)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Set Permissions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary, fontFamily: 'Poppins')),
              Text('Manage read and write access for modules', style: TextStyle(fontSize: 12, color: c.textSecondary, fontFamily: 'Poppins')),
            ]),
          ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            OutlinedButton(
              onPressed: () => setState(() { for (final p in _perms) { p.read = true; } }),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primaryOrange), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Select All Read', style: TextStyle(fontSize: 12.5, color: AppColors.primaryOrange, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => setState(() { for (final p in _perms) { p.write = true; } }),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primaryOrange), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Select All Write', style: TextStyle(fontSize: 12.5, color: AppColors.primaryOrange, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ),
          ]),
        ],
      ),
      const SizedBox(height: 16),

      // Column headers
      Container(
        decoration: BoxDecoration(color: c.rowEven, borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(children: [
          Expanded(child: Text('Module', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.textSecondary, fontFamily: 'Poppins'))),
          SizedBox(width: wide ? 130 : 100, child: Center(child: Text('Read Access', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.textSecondary, fontFamily: 'Poppins')))),
          SizedBox(width: wide ? 130 : 100, child: Center(child: Text('Write Access', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.textSecondary, fontFamily: 'Poppins')))),
        ]),
      ),
      Container(decoration: BoxDecoration(border: Border.all(color: c.divider), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8))),
        child: Column(children: _perms.asMap().entries.map((e) {
          final p      = e.value;
          final isLast = e.key == _perms.length - 1;
          return Column(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                Expanded(child: Row(children: [
                  Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.primaryOrange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                    child: Icon(p.icon, color: AppColors.primaryOrange, size: 15)),
                  const SizedBox(width: 10),
                  Text(p.module, style: TextStyle(fontSize: 13.5, color: c.textPrimary, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                ])),
                SizedBox(width: wide ? 130 : 100, child: Center(child: Switch(value: p.read, onChanged: (v) => setState(() => p.read = v), activeColor: AppColors.primaryOrange))),
                SizedBox(width: wide ? 130 : 100, child: Center(child: Switch(value: p.write, onChanged: (v) => setState(() => p.write = v), activeColor: AppColors.primaryOrange))),
              ]),
            ),
            if (!isLast) Divider(height: 1, color: c.divider),
          ]);
        }).toList()),
      ),
      const SizedBox(height: 12),
      _infoBox(c, text: 'Read access allows viewing data. Write access allows creating, editing and deleting data.'),
    ]));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 4 — Review & Create
  // ─────────────────────────────────────────────────────────────────────────
  Widget _step4(bool wide, bool tablet, AppThemeColors c) {
    return _card(c, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _secHeader(c, icon: Icons.checklist_rounded, title: 'Review & Confirm', sub: 'Review all information before creating the employee account.'),
      const SizedBox(height: 20),

      // ── Employee Information ──────────────────────────────────────────────
      _revSection(c, icon: Icons.person_outline_rounded, title: 'Employee Information', onEdit: () => setState(() => _step = 0),
        child: _row2(wide, [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _revRow('Full Name',    _nameCtrl.text.isEmpty ? '-' : _nameCtrl.text, c),
            _revRow('Email',        _emailCtrl.text.isEmpty ? '-' : _emailCtrl.text, c),
            _revRow('Phone',        _phoneCtrl.text.isEmpty ? '-' : _phoneCtrl.text, c),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _revRow('Department',   _dept.isEmpty ? '-' : _dept, c),
            _revRow('Date of Joining', _fmtDOJ, c),
            Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
              SizedBox(width: 110, child: Text('Status', style: TextStyle(fontSize: 12, color: c.textSecondary, fontFamily: 'Poppins'))),
              const Text(' :  ', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _status == 'Active' ? const Color(0xFF22C55E) : const Color(0xFFEF4444))),
              const SizedBox(width: 5),
              Text(_status, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: _status == 'Active' ? const Color(0xFF22C55E) : const Color(0xFFEF4444))),
            ])),
          ]),
        ]),
      ),
      Divider(height: 1, color: c.divider),

      // ── Account Settings ──────────────────────────────────────────────────
      _revSection(c, icon: Icons.lock_outline_rounded, title: 'Account Settings', onEdit: () => setState(() => _step = 0),
        child: _row2(wide, [
          Column(children: [
            _revRow('Username', _userCtrl.text.isEmpty ? '-' : _userCtrl.text, c),
            _revRow('Password', '●' * 12, c),
          ]),
          Column(children: [
            Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
              SizedBox(width: 130, child: Text('Send Welcome Email', style: TextStyle(fontSize: 12, color: c.textSecondary, fontFamily: 'Poppins'))),
              const Text(' :  ', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _welcome ? const Color(0xFF22C55E) : c.textHint)),
              const SizedBox(width: 5),
              Text(_welcome ? 'Yes' : 'No', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: _welcome ? const Color(0xFF22C55E) : c.textSecondary)),
            ])),
          ]),
        ]),
      ),
      Divider(height: 1, color: c.divider),

      // ── Role Information ──────────────────────────────────────────────────
      _revSection(c, icon: Icons.manage_accounts_outlined, title: 'Role Information', onEdit: () => setState(() => _step = 1),
        child: _row2(wide, [
          Column(children: [
            _revRow('Role Name',        _customTab ? 'Custom Role' : (_selRole?.name ?? '-'), c),
            _revRow('Role Description', _customTab ? 'Custom role with specific permissions' : (_selRole?.desc ?? '-'), c),
          ]),
          Column(children: [
            _revRow('Users with this role', '${_selRole?.count ?? 0}', c),
          ]),
        ]),
      ),
      Divider(height: 1, color: c.divider),

      // ── Permissions Summary ───────────────────────────────────────────────
      _revSection(c, icon: Icons.shield_outlined, title: 'Permissions Summary', onEdit: () => setState(() => _step = 2),
        child: _row2(wide, [
          _permStat(c, icon: Icons.visibility_outlined, label: 'Modules with Read Access', value: '$_readCnt', color: const Color(0xFF0EA5E9)),
          _permStat(c, icon: Icons.edit_outlined, label: 'Modules with Write Access', value: '$_writeCnt', color: AppColors.primaryOrange),
          _permStat(c, icon: Icons.visibility_off_outlined, label: 'Modules with No Access', value: '$_noCnt', color: const Color(0xFFEF4444)),
          _permStat(c, icon: Icons.apps_rounded, label: 'Total Modules', value: '${_perms.length}', color: const Color(0xFF4A3AFF)),
        ]),
      ),

      const SizedBox(height: 12),
      _infoBox(c, text: 'Please review all the details carefully. After creating the account, you can edit the information anytime.'),
    ]));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RIGHT PANEL
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRightPanel(AppThemeColors c) {
    final items = _panelItems(c);
    final tips  = _stepTips();

    return Container(
      decoration: BoxDecoration(
        color: c.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Step X of 4
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Step ${_step + 1} of 4', style: TextStyle(fontSize: 11.5, color: c.textHint, fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          Text(_kStepTitles[_step], style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.textPrimary, fontFamily: 'Poppins')),
          const SizedBox(height: 6),
          Text(_stepDesc(), style: TextStyle(fontSize: 12, color: c.textSecondary, fontFamily: 'Poppins', height: 1.55)),
        ])),
        Divider(height: 1, color: c.divider),
        ...items,
        const SizedBox(height: 4),
        Divider(height: 1, color: c.divider),
        // Tips
        Padding(padding: const EdgeInsets.all(14), child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primaryOrange.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primaryOrange, size: 15),
              const SizedBox(width: 6),
              Text('Tips', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryOrange, fontFamily: 'Poppins')),
            ]),
            const SizedBox(height: 8),
            ...tips.map((t) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(margin: const EdgeInsets.only(top: 5, right: 8), width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryOrange)),
              Expanded(child: Text(t, style: TextStyle(fontSize: 12, color: c.textSecondary, fontFamily: 'Poppins', height: 1.45))),
            ]))),
          ]),
        )),
      ]),
    );
  }

  // ── Bottom Bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar(bool wide, bool tablet, AppThemeColors c) {
    final isLast = _step == 3;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.divider))),
      child: Row(children: [
        OutlinedButton.icon(
          onPressed: _back,
          icon: Icon(Icons.arrow_back_rounded, size: 16, color: c.textSecondary),
          label: Text('Back', style: TextStyle(fontSize: 13.5, fontFamily: 'Poppins', color: c.textSecondary)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: c.border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Get.offNamed(AppRoutes.users),
          child: Text('Cancel', style: TextStyle(fontSize: 13.5, fontFamily: 'Poppins', color: c.textSecondary)),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _next,
          icon: Icon(isLast ? Icons.person_add_outlined : Icons.arrow_forward_rounded, color: Colors.white, size: 16),
          label: Text(isLast ? 'Create Employee' : 'Continue', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins')),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange, elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: tablet ? 22 : 14, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED BUILDER HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _card(AppThemeColors c, {required Widget child}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: c.surface, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: c.divider),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: child,
  );

  Widget _secHeader(AppThemeColors c, {required IconData icon, required String title, required String sub}) => Row(children: [
    Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primaryOrange.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: AppColors.primaryOrange, size: 20)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary, fontFamily: 'Poppins')),
      Text(sub, style: TextStyle(fontSize: 12, color: c.textSecondary, fontFamily: 'Poppins')),
    ])),
  ]);

  // 2-column on wide, single column on mobile
  Widget _row2(bool wide, List<Widget> children) {
    if (!wide) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i], if (i < children.length - 1) const SizedBox(height: 14),
        ],
      ]);
    }
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 14));
      rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: children[i]),
        const SizedBox(width: 14),
        Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
      ]));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _vGap(bool wide) => SizedBox(height: wide ? 14.0 : 14.0);

  Widget _textField(AppThemeColors c, {
    required TextEditingController ctrl,
    required String label,
    required String hint,
    bool req = false,
    IconData? icon,
    String? error,
    ValueChanged<String>? onChange,
    bool readOnly = false,
    VoidCallback? onTap,
  }) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.textPrimary, fontFamily: 'Poppins')),
      if (req) const Text(' *', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
    ]),
    const SizedBox(height: 6),
    TextField(
      controller: ctrl, readOnly: readOnly, onTap: onTap, onChanged: onChange,
      style: TextStyle(fontSize: 13, color: c.textPrimary, fontFamily: 'Poppins'),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: c.textHint, fontFamily: 'Poppins', fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, size: 17, color: c.textHint) : null,
        isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true, fillColor: c.inputFill,
        errorText: error, errorStyle: const TextStyle(fontSize: 11, fontFamily: 'Poppins'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: error != null ? const Color(0xFFEF4444) : c.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: error != null ? const Color(0xFFEF4444) : c.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5)),
      ),
    ),
  ]);

  Widget _pwdField(AppThemeColors c, {
    required String label,
    required TextEditingController ctrl,
    required bool show,
    bool req = false,
    String? error,
    required VoidCallback onToggle,
    ValueChanged<String>? onChange,
  }) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.textPrimary, fontFamily: 'Poppins')),
      if (req) const Text(' *', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
    ]),
    const SizedBox(height: 6),
    TextField(
      controller: ctrl, obscureText: !show, onChanged: onChange,
      style: TextStyle(fontSize: 13, color: c.textPrimary, fontFamily: 'Poppins'),
      decoration: InputDecoration(
        hintText: show ? 'Enter password' : '●●●●●●●●',
        hintStyle: TextStyle(color: c.textHint, fontFamily: 'Poppins'),
        prefixIcon: Icon(Icons.lock_outline_rounded, size: 17, color: c.textHint),
        suffixIcon: IconButton(onPressed: onToggle, icon: Icon(show ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 17, color: c.textHint)),
        isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true, fillColor: c.inputFill,
        errorText: error, errorStyle: const TextStyle(fontSize: 11, fontFamily: 'Poppins'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: error != null ? const Color(0xFFEF4444) : c.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: error != null ? const Color(0xFFEF4444) : c.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5)),
      ),
    ),
  ]);

  Widget _deptDropdown(AppThemeColors c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Department', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.textPrimary, fontFamily: 'Poppins')),
    const SizedBox(height: 6),
    Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: c.inputFill, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: _dept.isEmpty ? null : _dept,
        hint: Row(children: [Icon(Icons.business_outlined, size: 17, color: c.textHint), const SizedBox(width: 8), Text('Select department', style: TextStyle(color: c.textHint, fontFamily: 'Poppins', fontSize: 13))]),
        isExpanded: true, dropdownColor: c.surface,
        style: TextStyle(fontSize: 13, color: c.textPrimary, fontFamily: 'Poppins'),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.textHint),
        items: _kDepts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
        onChanged: (v) { if (v != null) setState(() => _dept = v); },
      )),
    ),
  ]);

  Widget _datePickerField(AppThemeColors c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Date of Joining', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.textPrimary, fontFamily: 'Poppins')),
    const SizedBox(height: 6),
    GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _doj ?? DateTime.now(),
          firstDate: DateTime(2000), lastDate: DateTime(2100),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primaryOrange, onPrimary: Colors.white)),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _doj = picked);
      },
      child: Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: c.inputFill, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined, size: 17, color: c.textHint),
          const SizedBox(width: 8),
          Expanded(child: Text(_doj == null ? 'Select date' : _fmtDOJ, style: TextStyle(fontSize: 13, color: _doj == null ? c.textHint : c.textPrimary, fontFamily: 'Poppins'))),
        ]),
      ),
    ),
  ]);

  Widget _statusDropdown(AppThemeColors c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.textPrimary, fontFamily: 'Poppins')),
    const SizedBox(height: 6),
    Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: c.inputFill, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: _status, isExpanded: true, dropdownColor: c.surface,
        style: TextStyle(fontSize: 13, color: c.textPrimary, fontFamily: 'Poppins'),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.textHint),
        items: ['Active', 'Inactive'].map((s) => DropdownMenuItem(value: s, child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: s == 'Active' ? const Color(0xFF22C55E) : const Color(0xFFEF4444))),
          const SizedBox(width: 8), Text(s),
        ]))).toList(),
        onChanged: (v) { if (v != null) setState(() => _status = v); },
      )),
    ),
  ]);

  Widget _roleTab(AppThemeColors c, {required String label, required IconData icon, required bool active, required VoidCallback onTap}) =>
    MouseRegion(cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap,
        child: AnimatedContainer(duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            border: Border.all(color: active ? AppColors.primaryOrange : c.border, width: active ? 1.5 : 1),
            borderRadius: BorderRadius.circular(10),
            color: active ? AppColors.primaryOrange.withValues(alpha: 0.04) : c.inputFill),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 17, color: active ? AppColors.primaryOrange : c.textSecondary),
            const SizedBox(width: 8),
            Flexible(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? AppColors.primaryOrange : c.textPrimary, fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ),
    );

  Widget _infoBox(AppThemeColors c, {required String text, bool isError = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: isError ? const Color(0xFFFEF2F2) : AppColors.primaryOrange.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Icon(Icons.info_outline_rounded, color: isError ? const Color(0xFFEF4444) : AppColors.primaryOrange.withValues(alpha: 0.8), size: 15),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: isError ? const Color(0xFFEF4444) : c.textSecondary, fontFamily: 'Poppins'))),
    ]),
  );

  Widget _revSection(AppThemeColors c, {required IconData icon, required String title, required VoidCallback onEdit, required Widget child}) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.primaryOrange.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.primaryOrange, size: 15)),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary, fontFamily: 'Poppins'))),
        TextButton.icon(onPressed: onEdit, icon: Icon(Icons.edit_outlined, size: 13, color: c.textSecondary), label: Text('Edit', style: TextStyle(fontSize: 12.5, color: c.textSecondary, fontFamily: 'Poppins')), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4))),
      ]),
      const SizedBox(height: 12),
      child,
    ]));

  Widget _revRow(String label, String value, AppThemeColors c) =>
    Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary, fontFamily: 'Poppins'))),
      const Text(' :  ', style: TextStyle(fontSize: 12, color: Colors.grey)),
      Expanded(child: Text(value.isEmpty ? '-' : value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: c.textPrimary, fontFamily: 'Poppins'))),
    ]));

  Widget _permStat(AppThemeColors c, {required IconData icon, required String label, required String value, required Color color}) =>
    Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary, fontFamily: 'Poppins'))),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color, fontFamily: 'Poppins')),
      ]),
    );

  // ── Right panel data ──────────────────────────────────────────────────────
  String _stepDesc() => [
    'Provide basic information and login credentials for the new employee.',
    'Roles help you define access levels for employees. You can choose an existing role or create a custom one.',
    'Define what this employee can view and edit in the system.',
    'You are about to create a new employee account with the following details.',
  ][_step];

  List<Widget> _panelItems(AppThemeColors c) {
    final items = [
      [
        ('Secure Access',       Icons.lock_outline_rounded,    'Employee will receive secure login credentials'),
        ('Role Based Access',   Icons.group_outlined,          'Access will be based on selected role'),
        ('Custom Permissions',  Icons.shield_outlined,         'Fine-grained permissions in next step'),
      ],
      [
        ('Pre-defined Roles',   Icons.group_outlined,          'Use existing roles to quickly assign access permissions'),
        ('Custom Roles',        Icons.shield_outlined,         'Create a new role with specific permissions as per your need'),
        ('Flexible Permissions',Icons.tune_rounded,            'You can modify permissions in the next step'),
      ],
      [
        ('Read Access',         Icons.visibility_outlined,     'Employee can view and access module information'),
        ('Write Access',        Icons.edit_outlined,           'Employee can create, edit and delete information'),
        ('Granular Control',    Icons.tune_rounded,            'You can customize permissions module by module'),
      ],
      [
        ('Employee Information',Icons.person_outline_rounded,  '${_nameCtrl.text.isEmpty ? 'Name' : _nameCtrl.text}\n${_emailCtrl.text.isEmpty ? 'Email' : _emailCtrl.text}'),
        ('Account Settings',   Icons.lock_outline_rounded,    'Username: ${_userCtrl.text.isEmpty ? '-' : _userCtrl.text}\n${_welcome ? 'Welcome email will be sent' : 'No welcome email'}'),
        ('Role',               Icons.manage_accounts_outlined, '${_customTab ? 'Custom Role' : (_selRole?.name ?? 'Not selected')}\n${_selRole != null ? '${_selRole!.count} users with this role' : ''}'),
        ('Permissions',        Icons.shield_outlined,          'Read: $_readCnt modules\nWrite: $_writeCnt modules'),
      ],
    ][_step];

    return items.map((item) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(item.$2, size: 17, color: AppColors.primaryOrange),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.$1, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary, fontFamily: 'Poppins')),
          const SizedBox(height: 2),
          Text(item.$3, style: TextStyle(fontSize: 11.5, color: c.textSecondary, fontFamily: 'Poppins', height: 1.45)),
          const SizedBox(height: 4),
        ])),
      ]),
    )).toList();
  }

  List<String> _stepTips() => [
    ['Use a valid email address', 'Username must be unique', 'Employee can reset password later'],
    ['Choose the role that best fits the employee\'s responsibilities', 'You can always update role or permissions later'],
    ['Grant only necessary permissions for security', 'You can change permissions anytime', 'Use custom role if predefined roles don\'t fit your needs'],
    ['Please review all details carefully', 'After creating, you can edit information anytime', 'Employee will receive login credentials if welcome email is enabled'],
  ][_step];
}

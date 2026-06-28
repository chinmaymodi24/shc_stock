import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../dashboard/widgets/web_sidebar.dart';

// ── Select options ─────────────────────────────────────────────────────────
const _kClientTypes   = ['Regular', 'VIP', 'Walk-in', 'Government', 'Dealer', 'Distributor'];
const _kCurrencies    = ['INR - Indian Rupee (₹)', 'USD - US Dollar (\$)', 'EUR - Euro (€)', 'GBP - British Pound (£)', 'AED - UAE Dirham'];
const _kPaymentTerms  = ['Immediate', 'Net 7', 'Net 15', 'Net 30', 'Net 45', 'Net 60', 'Net 90'];
const _kPriceLists    = ['Standard Price', 'Wholesale Price', 'Retail Price', 'Special Price'];
const _kStates        = [
  'Select state', 'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar',
  'Chhattisgarh', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
  'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
  'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
  'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
  'Delhi', 'Jammu & Kashmir', 'Ladakh', 'Puducherry',
];
const _kCountries = ['India', 'USA', 'UK', 'UAE', 'Singapore', 'Germany', 'Australia'];

// ─────────────────────────────────────────────────────────────────────────────
// Main Widget
// ─────────────────────────────────────────────────────────────────────────────
class WebAddClientLayout extends StatefulWidget {
  const WebAddClientLayout({super.key});
  @override
  State<WebAddClientLayout> createState() => _WebAddClientLayoutState();
}

class _WebAddClientLayoutState extends State<WebAddClientLayout> {
  // ── Client Info ────────────────────────────────────────────────────────
  String    _clientType = '';
  final     _nameCtrl   = TextEditingController();
  final     _emailCtrl  = TextEditingController();
  final     _phoneCtrl  = TextEditingController();
  final     _altPhCtrl  = TextEditingController();
  final     _gstinCtrl  = TextEditingController();
  final     _panCtrl    = TextEditingController();
  String    _currency   = 'INR - Indian Rupee (₹)';
  String    _pyTerms    = '';
  String    _priceList  = '';
  DateTime? _since;
  final     _opBalCtrl  = TextEditingController(text: '0.00');
  final     _crLimCtrl  = TextEditingController(text: '0.00');
  final     _crDaysCtrl = TextEditingController(text: '0');

  // ── Primary Address (Right Panel) ─────────────────────────────────────
  final  _pAddr1Ctrl = TextEditingController();
  final  _pAddr2Ctrl = TextEditingController();
  final  _pCityCtrl  = TextEditingController();
  String _pState     = 'Select state';
  final  _pPinCtrl   = TextEditingController();
  String _pCountry   = 'India';

  // ── Billing Address ───────────────────────────────────────────────────
  bool   _sameAsPrim = true;
  final  _bAddr1Ctrl = TextEditingController();
  final  _bAddr2Ctrl = TextEditingController();
  final  _bCityCtrl  = TextEditingController();
  String _bState     = 'Select state';
  final  _bPinCtrl   = TextEditingController();
  String _bCountry   = 'India';

  // ── Additional Info ───────────────────────────────────────────────────
  final _noteCtrl  = TextEditingController();
  final _termsCtrl = TextEditingController();

  // ── Contact Person ────────────────────────────────────────────────────
  final _cpNameCtrl  = TextEditingController();
  final _cpDesigCtrl = TextEditingController();
  final _cpPhCtrl    = TextEditingController();
  final _cpEmailCtrl = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _emailCtrl, _phoneCtrl, _altPhCtrl, _gstinCtrl, _panCtrl,
      _opBalCtrl, _crLimCtrl, _crDaysCtrl, _pAddr1Ctrl, _pAddr2Ctrl,
      _pCityCtrl, _pPinCtrl, _bAddr1Ctrl, _bAddr2Ctrl, _bCityCtrl, _bPinCtrl,
      _noteCtrl, _termsCtrl, _cpNameCtrl, _cpDesigCtrl, _cpPhCtrl, _cpEmailCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Row(children: [
        const WebSidebar(),
        Expanded(child: Column(children: [
          _TopBar(colors: colors),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── Breadcrumb ──────────────────────────────────────────────
              Row(children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Get.back(),
                    child: Text('Clients', style: TextStyle(
                      fontSize: 13, color: AppColors.primaryOrange,
                      fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.chevron_right_rounded, size: 16, color: colors.textHint)),
                Text('Add New Client', style: TextStyle(
                  fontSize: 13, color: colors.textSecondary, fontFamily: 'Poppins')),
              ]),
              const SizedBox(height: 16),

              // ── Page Header + Action Buttons ────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Add New Client', style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: colors.textPrimary, fontFamily: 'Poppins')),
                    const SizedBox(height: 3),
                    Text('Add a new client and manage their business information.',
                      style: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Poppins')),
                  ]),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: Text('Cancel', style: TextStyle(
                      fontSize: 14, color: colors.textSecondary, fontFamily: 'Poppins')),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: Text('Save as Draft', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: colors.textPrimary, fontFamily: 'Poppins')),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _saveClient,
                    icon: const Icon(Icons.save_rounded, color: Colors.white, size: 17),
                    label: const Text('Save Client', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: Colors.white, fontFamily: 'Poppins')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange, elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Body: Left form + Right panel ────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // LEFT: Form sections
                  Expanded(child: Column(children: [
                    _clientInfoSection(colors),
                    const SizedBox(height: 16),
                    _billingSection(colors),
                    const SizedBox(height: 16),
                    _additionalSection(colors),
                    const SizedBox(height: 16),
                  ])),

                  const SizedBox(width: 20),

                  // RIGHT: Panel
                  SizedBox(width: 284, child: Column(children: [
                    _creditSummaryCard(colors),
                    const SizedBox(height: 14),
                    _primaryAddressCard(colors),
                    const SizedBox(height: 14),
                    _contactPersonCard(colors),
                  ])),
                ],
              ),
            ]),
          )),
        ])),
      ]),
    );
  }

  void _saveClient() {
    // Validate name at minimum
    if (_nameCtrl.text.trim().isEmpty) {
      Get.snackbar('Validation Error', 'Client Name is required.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444), colorText: Colors.white,
        duration: const Duration(seconds: 2), margin: const EdgeInsets.all(16),
        borderRadius: 10);
      return;
    }
    Get.back();
  }

  // ── SECTION: Client Information ────────────────────────────────────────
  Widget _clientInfoSection(AppThemeColors colors) {
    return _SectionCard(
      title: 'Client Information',
      colors: colors,
      child: Column(children: [
        // Row 1: Client Type | Client Code | Client Name
        Row(children: [
          Expanded(child: _Dropdown(
            label: 'Client Type', required: true,
            value: _clientType.isEmpty ? null : _clientType,
            hint: 'Select client type',
            items: _kClientTypes, colors: colors,
            onChange: (v) => setState(() => _clientType = v ?? ''),
          )),
          const SizedBox(width: 16),
          Expanded(child: _Field(
            label: 'Client Code', required: true,
            ctrl: TextEditingController(text: 'Auto generated'),
            hint: 'Auto generated',
            readOnly: true, colors: colors,
          )),
          const SizedBox(width: 16),
          Expanded(child: _Field(
            label: 'Client Name', required: true,
            ctrl: _nameCtrl, hint: 'Enter client name', colors: colors,
          )),
        ]),
        const SizedBox(height: 14),

        // Row 2: Email | Phone | Alternate Phone
        Row(children: [
          Expanded(child: _Field(
            label: 'Email', ctrl: _emailCtrl,
            hint: 'Enter email address', colors: colors,
            keyboardType: TextInputType.emailAddress,
          )),
          const SizedBox(width: 16),
          Expanded(child: _PhoneField(
            label: 'Phone', required: true,
            ctrl: _phoneCtrl, colors: colors,
          )),
          const SizedBox(width: 16),
          Expanded(child: _PhoneField(
            label: 'Alternate Phone',
            ctrl: _altPhCtrl, colors: colors,
          )),
        ]),
        const SizedBox(height: 14),

        // Row 3: GSTIN | PAN | Currency
        Row(children: [
          Expanded(child: _Field(
            label: 'GSTIN', ctrl: _gstinCtrl,
            hint: 'Enter GSTIN', colors: colors,
          )),
          const SizedBox(width: 16),
          Expanded(child: _Field(
            label: 'PAN', ctrl: _panCtrl,
            hint: 'Enter PAN', colors: colors,
          )),
          const SizedBox(width: 16),
          Expanded(child: _Dropdown(
            label: 'Currency', required: true,
            value: _currency,
            hint: 'Select currency',
            items: _kCurrencies, colors: colors,
            onChange: (v) => setState(() => _currency = v ?? _currency),
          )),
        ]),
        const SizedBox(height: 14),

        // Row 4: Payment Terms | Price List | Client Since
        Row(children: [
          Expanded(child: _Dropdown(
            label: 'Payment Terms',
            value: _pyTerms.isEmpty ? null : _pyTerms,
            hint: 'Select payment terms',
            items: _kPaymentTerms, colors: colors,
            onChange: (v) => setState(() => _pyTerms = v ?? ''),
          )),
          const SizedBox(width: 16),
          Expanded(child: _Dropdown(
            label: 'Price List',
            value: _priceList.isEmpty ? null : _priceList,
            hint: 'Select price list',
            items: _kPriceLists, colors: colors,
            onChange: (v) => setState(() => _priceList = v ?? ''),
          )),
          const SizedBox(width: 16),
          Expanded(child: _DateField(
            label: 'Client Since',
            value: _since, colors: colors,
            onPick: (d) => setState(() => _since = d),
          )),
        ]),
        const SizedBox(height: 14),

        // Row 5: Opening Balance | Credit Limit | Credit Days
        Row(children: [
          Expanded(child: _Field(
            label: 'Opening Balance (₹)',
            ctrl: _opBalCtrl, hint: '0.00',
            keyboardType: TextInputType.number, colors: colors,
          )),
          const SizedBox(width: 16),
          Expanded(child: _Field(
            label: 'Credit Limit (₹)',
            ctrl: _crLimCtrl, hint: '0.00',
            keyboardType: TextInputType.number, colors: colors,
          )),
          const SizedBox(width: 16),
          Expanded(child: _Field(
            label: 'Credit Days',
            ctrl: _crDaysCtrl, hint: '0',
            keyboardType: TextInputType.number, colors: colors,
            suffix: 'days',
          )),
        ]),
      ]),
    );
  }

  // ── SECTION: Billing Address ────────────────────────────────────────────
  Widget _billingSection(AppThemeColors colors) {
    return _SectionCard(
      colors: colors,
      title: '',
      customHeader: Row(children: [
        Text('Billing Address', style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700,
          color: colors.textPrimary, fontFamily: 'Poppins')),
        const Spacer(),
        // Checkbox: Same as Primary Address
        Row(children: [
          SizedBox(
            width: 18, height: 18,
            child: Checkbox(
              value: _sameAsPrim,
              onChanged: (v) => setState(() => _sameAsPrim = v ?? false),
              activeColor: AppColors.primaryOrange,
              side: BorderSide(color: colors.border, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 6),
          Text('Same as Primary Address', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: colors.textPrimary, fontFamily: 'Poppins')),
        ]),
      ]),
      child: Column(children: [
        // Row 1: Address Line 1 | Address Line 2
        Row(children: [
          Expanded(child: _Field(
            label: 'Address Line 1', required: true,
            ctrl: _bAddr1Ctrl, hint: 'Enter address line 1',
            readOnly: _sameAsPrim, colors: colors,
          )),
          const SizedBox(width: 16),
          Expanded(child: _Field(
            label: 'Address Line 2',
            ctrl: _bAddr2Ctrl, hint: 'Enter address line 2',
            readOnly: _sameAsPrim, colors: colors,
          )),
        ]),
        const SizedBox(height: 14),

        // Row 2: City | State | PIN Code | Country
        Row(children: [
          Expanded(child: _Field(
            label: 'City', required: true,
            ctrl: _bCityCtrl, hint: 'Enter city',
            readOnly: _sameAsPrim, colors: colors,
          )),
          const SizedBox(width: 12),
          Expanded(child: _Dropdown(
            label: 'State', required: true,
            value: _bState,
            hint: 'Select state',
            items: _kStates, colors: colors,
            enabled: !_sameAsPrim,
            onChange: (v) { if (!_sameAsPrim) setState(() => _bState = v ?? _bState); },
          )),
          const SizedBox(width: 12),
          Expanded(child: _Field(
            label: 'PIN Code', required: true,
            ctrl: _bPinCtrl, hint: 'Enter PIN code',
            readOnly: _sameAsPrim,
            keyboardType: TextInputType.number, colors: colors,
          )),
          const SizedBox(width: 12),
          Expanded(child: _Dropdown(
            label: 'Country', required: true,
            value: _bCountry,
            hint: 'Select country',
            items: _kCountries, colors: colors,
            enabled: !_sameAsPrim,
            onChange: (v) { if (!_sameAsPrim) setState(() => _bCountry = v ?? _bCountry); },
          )),
        ]),
      ]),
    );
  }

  // ── SECTION: Additional Information ────────────────────────────────────
  Widget _additionalSection(AppThemeColors colors) {
    return _SectionCard(
      title: 'Additional Information',
      colors: colors,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client Note
          Expanded(child: _TextAreaField(
            label: 'Client Note',
            ctrl: _noteCtrl,
            hint: 'Enter any notes about the client...',
            maxLength: 500, colors: colors,
          )),
          const SizedBox(width: 16),
          // Terms & Conditions
          Expanded(child: _TextAreaField(
            label: 'Terms & Conditions',
            ctrl: _termsCtrl,
            hint: 'Enter terms and conditions...',
            maxLength: 500, colors: colors,
          )),
        ],
      ),
    );
  }

  // ── RIGHT PANEL: Credit & Summary ─────────────────────────────────────
  Widget _creditSummaryCard(AppThemeColors colors) {
    return _RightCard(
      title: 'Credit & Summary',
      colors: colors,
      child: Column(children: [
        _CreditRow(label: 'Opening Balance (₹)', value: _opBalCtrl.text.isEmpty ? '0.00' : _opBalCtrl.text, colors: colors),
        _CreditRow(label: 'Credit Limit (₹)',    value: _crLimCtrl.text.isEmpty ? '0.00' : _crLimCtrl.text, colors: colors),
        _CreditRow(label: 'Credit Days',         value: '${_crDaysCtrl.text.isEmpty ? "0" : _crDaysCtrl.text} days', colors: colors),
        _CreditRow(label: 'Outstanding Amount (₹)', value: '0.00', colors: colors),
        _CreditRow(label: 'Total Sales (MTD):', value: '0.00', colors: colors, isLast: true),
      ]),
    );
  }

  // ── RIGHT PANEL: Primary Address ──────────────────────────────────────
  Widget _primaryAddressCard(AppThemeColors colors) {
    return _RightCard(
      title: 'Primary Address',
      colors: colors,
      child: Column(children: [
        _Field(label: 'Address Line 1', required: true, ctrl: _pAddr1Ctrl, hint: 'Enter address line 1', colors: colors),
        const SizedBox(height: 12),
        _Field(label: 'Address Line 2', ctrl: _pAddr2Ctrl, hint: 'Enter address line 2', colors: colors),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Field(label: 'City', required: true, ctrl: _pCityCtrl, hint: 'Enter city', colors: colors)),
          const SizedBox(width: 10),
          Expanded(child: _Dropdown(
            label: 'State', required: true,
            value: _pState, hint: 'Select state',
            items: _kStates, colors: colors,
            onChange: (v) => setState(() => _pState = v ?? _pState),
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Field(
            label: 'PIN Code', required: true, ctrl: _pPinCtrl,
            hint: 'Enter PIN code', keyboardType: TextInputType.number, colors: colors)),
          const SizedBox(width: 10),
          Expanded(child: _Dropdown(
            label: 'Country', required: true,
            value: _pCountry, hint: 'Select country',
            items: _kCountries, colors: colors,
            onChange: (v) => setState(() => _pCountry = v ?? _pCountry),
          )),
        ]),
      ]),
    );
  }

  // ── RIGHT PANEL: Contact Person ───────────────────────────────────────
  Widget _contactPersonCard(AppThemeColors colors) {
    return _RightCard(
      title: 'Contact Person',
      titleTrailing: Row(children: [
        Icon(Icons.add_rounded, color: AppColors.primaryOrange, size: 15),
        const SizedBox(width: 4),
        const Text('Add More', style: TextStyle(
          fontSize: 12.5, fontWeight: FontWeight.w600,
          color: AppColors.primaryOrange, fontFamily: 'Poppins')),
      ]),
      colors: colors,
      child: Column(children: [
        // Contact Person Name | Designation (2 col)
        Row(children: [
          Expanded(child: _Field(label: 'Contact Person Name', ctrl: _cpNameCtrl, hint: 'Enter contact person name', colors: colors)),
          const SizedBox(width: 10),
          Expanded(child: _Field(label: 'Designation', ctrl: _cpDesigCtrl, hint: 'Enter designation', colors: colors)),
        ]),
        const SizedBox(height: 12),
        _PhoneField(label: 'Phone', ctrl: _cpPhCtrl, colors: colors),
        const SizedBox(height: 12),
        _Field(
          label: 'Email', ctrl: _cpEmailCtrl,
          hint: 'Enter email address',
          keyboardType: TextInputType.emailAddress, colors: colors),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final AppThemeColors colors;
  const _TopBar({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colors.topBarBg,
        border: Border(bottom: BorderSide(color: colors.divider))),
      child: Row(children: [
        Container(
          width: 320, height: 38,
          decoration: BoxDecoration(
            color: colors.inputFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border)),
          child: Row(children: [
            const SizedBox(width: 10),
            Icon(Icons.search_rounded, color: colors.textHint, size: 17),
            const SizedBox(width: 8),
            Expanded(child: Text('Search anything...', style: TextStyle(
              fontSize: 13, color: colors.textHint, fontFamily: 'Poppins'))),
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: colors.divider, borderRadius: BorderRadius.circular(5)),
              child: Text('Ctrl + K', style: TextStyle(
                fontSize: 10, color: colors.textSecondary, fontFamily: 'Poppins')),
            ),
          ]),
        ),
        const Spacer(),
        _IBtn(icon: Icons.notifications_outlined, badge: '3', colors: colors),
        const SizedBox(width: 8),
        _IBtn(icon: Icons.chat_bubble_outline_rounded, badge: '2', colors: colors),
        const SizedBox(width: 8),
        _IBtn(icon: Icons.calendar_today_outlined, colors: colors),
        const SizedBox(width: 14),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
          label: Row(children: const [
            Text('Quick Action', style: TextStyle(fontSize: 13, color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
          ]),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange, elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
        const SizedBox(width: 14),
        Container(width: 1, height: 30, color: colors.divider),
        const SizedBox(width: 14),
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15),
          child: const Icon(Icons.person_rounded, color: AppColors.primaryOrange, size: 18),
        ),
        const SizedBox(width: 8),
        Text('Admin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary, fontFamily: 'Poppins')),
        Icon(Icons.keyboard_arrow_down_rounded, color: colors.textSecondary, size: 18),
      ]),
    );
  }
}

class _IBtn extends StatelessWidget {
  final IconData icon; final String? badge; final AppThemeColors colors;
  const _IBtn({required this.icon, this.badge, required this.colors});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(width: 38, height: 38,
        decoration: BoxDecoration(color: colors.inputFill, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.border)),
        child: Icon(icon, color: colors.textSecondary, size: 19)),
      if (badge != null)
        Positioned(top: 0, right: 0, child: Container(
          width: 17, height: 17,
          decoration: const BoxDecoration(color: AppColors.primaryOrange, shape: BoxShape.circle),
          child: Center(child: Text(badge!, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Poppins'))))),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Card (main left form sections)
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? customHeader;
  final Widget child;
  final AppThemeColors colors;

  const _SectionCard({required this.title, required this.child, required this.colors, this.customHeader});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        customHeader ?? Text(title, style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700,
          color: colors.textPrimary, fontFamily: 'Poppins')),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right Panel Card
// ─────────────────────────────────────────────────────────────────────────────
class _RightCard extends StatelessWidget {
  final String title;
  final Widget? titleTrailing;
  final Widget child;
  final AppThemeColors colors;

  const _RightCard({required this.title, required this.child, required this.colors, this.titleTrailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Expanded(child: Text(title, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: colors.textPrimary, fontFamily: 'Poppins'))),
            if (titleTrailing != null) ...[
              MouseRegion(cursor: SystemMouseCursors.click, child: titleTrailing!),
            ],
          ]),
        ),
        Divider(height: 1, color: colors.divider),
        Padding(padding: const EdgeInsets.all(14), child: child),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Credit & Summary Row
// ─────────────────────────────────────────────────────────────────────────────
class _CreditRow extends StatelessWidget {
  final String label, value;
  final AppThemeColors colors;
  final bool isLast;
  const _CreditRow({required this.label, required this.value, required this.colors, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isLast ? null : BoxDecoration(border: Border(bottom: BorderSide(color: colors.divider, width: 0.5))),
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(
          fontSize: 12.5, color: colors.textSecondary, fontFamily: 'Poppins'))),
        Text(value, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: colors.textPrimary, fontFamily: 'Poppins')),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Labeled Text Field
// ─────────────────────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final bool required, readOnly;
  final TextInputType keyboardType;
  final AppThemeColors colors;
  final String? suffix;

  const _Field({
    required this.label, required this.ctrl, this.hint = '',
    this.required = false, this.readOnly = false,
    this.keyboardType = TextInputType.text,
    required this.colors, this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _LabelText(label, required: required, colors: colors),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 13, color: readOnly ? colors.textHint : colors.textPrimary, fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: colors.textHint, fontFamily: 'Poppins'),
          filled: true,
          fillColor: readOnly ? colors.background.withValues(alpha: 0.6) : colors.inputFill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          suffixText: suffix,
          suffixStyle: TextStyle(fontSize: 13, color: colors.textSecondary, fontFamily: 'Poppins'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5)),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.divider)),
          isDense: true,
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Labeled Dropdown Field
// ─────────────────────────────────────────────────────────────────────────────
class _Dropdown extends StatelessWidget {
  final String label;
  final String? value, hint;
  final List<String> items;
  final ValueChanged<String?> onChange;
  final bool required, enabled;
  final AppThemeColors colors;

  const _Dropdown({
    required this.label, this.value, this.hint,
    required this.items, required this.onChange,
    this.required = false, this.enabled = true,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _LabelText(label, required: required, colors: colors),
      const SizedBox(height: 6),
      Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: enabled ? colors.inputFill : colors.background.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: enabled ? colors.border : colors.divider)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            hint: Text(hint ?? 'Select', style: TextStyle(fontSize: 13, color: colors.textHint, fontFamily: 'Poppins')),
            style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Poppins'),
            dropdownColor: colors.surface,
            icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: enabled ? colors.textSecondary : colors.textHint),
            items: items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: enabled ? onChange : null,
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone Field with Country Code
// ─────────────────────────────────────────────────────────────────────────────
class _PhoneField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final bool required;
  final AppThemeColors colors;

  const _PhoneField({required this.label, required this.ctrl, this.required = false, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _LabelText(label, required: required, colors: colors),
      const SizedBox(height: 6),
      Container(
        height: 42,
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(8),
          color: colors.inputFill),
        child: Row(children: [
          // Flag + country code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: colors.comingSoonBadge,
              border: Border(right: BorderSide(color: colors.border)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7), bottomLeft: Radius.circular(7))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🇮🇳', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text('+91', style: TextStyle(
                fontSize: 12.5, fontFamily: 'Poppins',
                color: colors.textPrimary, fontWeight: FontWeight.w500)),
            ]),
          ),
          // Phone number input
          Expanded(child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.phone,
            style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Poppins'),
            decoration: InputDecoration(
              hintText: 'Enter phone number',
              hintStyle: TextStyle(fontSize: 13, color: colors.textHint, fontFamily: 'Poppins'),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              isDense: true,
            ),
          )),
        ]),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date Picker Field
// ─────────────────────────────────────────────────────────────────────────────
class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final AppThemeColors colors;
  final ValueChanged<DateTime?> onPick;

  const _DateField({required this.label, this.value, required this.colors, required this.onPick});

  String get _display => value == null
      ? 'Select date'
      : '${value!.day.toString().padLeft(2,'0')} / ${value!.month.toString().padLeft(2,'0')} / ${value!.year}';

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _LabelText(label, colors: colors),
      const SizedBox(height: 6),
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.light(primary: AppColors.primaryOrange)),
              child: child!),
          );
          onPick(picked);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colors.inputFill,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon(Icons.calendar_month_outlined, size: 17, color: colors.textSecondary),
            const SizedBox(width: 8),
            Text(_display, style: TextStyle(
              fontSize: 13, color: value == null ? colors.textHint : colors.textPrimary,
              fontFamily: 'Poppins')),
          ]),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Multiline Text Area
// ─────────────────────────────────────────────────────────────────────────────
class _TextAreaField extends StatefulWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final int maxLength;
  final AppThemeColors colors;
  const _TextAreaField({required this.label, required this.ctrl, required this.hint, required this.maxLength, required this.colors});
  @override State<_TextAreaField> createState() => _TextAreaFieldState();
}

class _TextAreaFieldState extends State<_TextAreaField> {
  int _count = 0;
  @override void initState() { super.initState(); widget.ctrl.addListener(() => setState(() => _count = widget.ctrl.text.length)); }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _LabelText(widget.label, colors: colors),
      const SizedBox(height: 6),
      TextField(
        controller: widget.ctrl,
        maxLines: 5,
        maxLength: widget.maxLength,
        style: TextStyle(fontSize: 13, color: colors.textPrimary, fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(fontSize: 13, color: colors.textHint, fontFamily: 'Poppins'),
          filled: true, fillColor: colors.inputFill,
          counterText: '${_count}/${widget.maxLength}',
          counterStyle: TextStyle(fontSize: 11, color: colors.textHint, fontFamily: 'Poppins'),
          contentPadding: const EdgeInsets.all(12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5)),
          isDense: true,
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Label Text (with optional required asterisk)
// ─────────────────────────────────────────────────────────────────────────────
class _LabelText extends StatelessWidget {
  final String label;
  final bool required;
  final AppThemeColors colors;
  const _LabelText(this.label, {this.required = false, required this.colors});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(children: [
        TextSpan(
          text: label,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500,
            color: colors.textPrimary, fontFamily: 'Poppins')),
        if (required)
          const TextSpan(
            text: ' *',
            style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/billing/controllers/billing_profile_controller.dart';
import 'package:shc_stock/app/modules/billing/models/billing_profile.dart';
import 'package:shc_stock/app/shared/widgets/async_button.dart';
import 'package:shc_stock/app/shared/widgets/image_dropzone.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Settings › Billing.
//
// Everything a tax invoice prints that is not part of the sale: who is
// selling, where the money goes, what the declaration says, and which blocks
// a new bill starts with. Nothing here is hardcoded into the invoice layout,
// which is what makes the document work for any buyer of the app.
// ─────────────────────────────────────────────────────────────────────────────
class BillingTab extends StatefulWidget {
  const BillingTab({super.key});

  @override
  State<BillingTab> createState() => _BillingTabState();
}

class _BillingTabState extends State<BillingTab> {
  BillingProfileController get _controller => BillingProfileController.to;

  final _fields = <String, TextEditingController>{};
  late final Rx<BillOptions> _defaults;
  final _gstPercent = 18.0.obs;
  final _signature = RxnString();

  /// Seeded once from the loaded profile; re-seeded if the fetch lands after
  /// this tab is already on screen.
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _defaults = const BillOptions().obs;
    for (final key in _keys) {
      _fields[key] = TextEditingController();
    }
    _seed(_controller.profile.value);
    // The profile is fetched once at startup; if it has not landed yet, fill
    // the form the moment it does rather than leaving the user typing into
    // fields that are about to be overwritten.
    ever<BillingProfile>(_controller.profile, (p) {
      if (!_seeded) _seed(p);
    });
  }

  static const _keys = [
    'legalName',
    'addressLine1',
    'addressLine2',
    'gstin',
    'pan',
    'stateName',
    'stateCode',
    'phone',
    'email',
    'bankName',
    'accountNo',
    'branchAndIfsc',
    'upiId',
    'invoicePrefix',
    'declaration',
    'footerNote',
  ];

  void _seed(BillingProfile p) {
    final values = <String, String>{
      'legalName': p.legalName,
      'addressLine1': p.addressLine1,
      'addressLine2': p.addressLine2,
      'gstin': p.gstin,
      'pan': p.pan,
      'stateName': p.stateName,
      'stateCode': p.stateCode,
      'phone': p.phone,
      'email': p.email,
      'bankName': p.bankName,
      'accountNo': p.accountNo,
      'branchAndIfsc': p.branchAndIfsc,
      'upiId': p.upiId,
      'invoicePrefix': p.invoicePrefix,
      'declaration': p.declaration,
      'footerNote': p.footerNote,
    };
    values.forEach((key, value) => _fields[key]!.text = value);
    _defaults.value = p.defaults;
    _gstPercent.value = p.gstPercent;
    _signature.value = p.signatureBase64;
    if (_controller.isLoaded.value) _seeded = true;
  }

  @override
  void dispose() {
    for (final ctrl in _fields.values) {
      ctrl.dispose();
    }
    _defaults.close();
    _gstPercent.close();
    _signature.close();
    super.dispose();
  }

  String _text(String key) => _fields[key]!.text.trim();

  Future<void> _save() async {
    final next = BillingProfile(
      legalName: _text('legalName'),
      addressLine1: _text('addressLine1'),
      addressLine2: _text('addressLine2'),
      gstin: _text('gstin').toUpperCase(),
      pan: _text('pan').toUpperCase(),
      stateName: _text('stateName'),
      stateCode: _text('stateCode'),
      phone: _text('phone'),
      email: _text('email'),
      bankName: _text('bankName'),
      accountNo: _text('accountNo'),
      branchAndIfsc: _text('branchAndIfsc'),
      upiId: _text('upiId'),
      invoicePrefix: _text('invoicePrefix').isEmpty
          ? 'INV'
          : _text('invoicePrefix').toUpperCase(),
      gstPercent: _gstPercent.value,
      declaration: _text('declaration'),
      footerNote: _text('footerNote'),
      signatureBase64: _signature.value,
      defaults: _defaults.value,
    );
    final saved = await _controller.save(next);
    showAppToast(
      saved ? 'Saved' : 'Error',
      saved
          ? 'Billing details updated. New invoices will use them.'
          : 'Could not save. Check the backend and try again.',
      backgroundColor: saved ? appColors.success : appColors.error,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Billing', colors),
          const SizedBox(height: 4),
          Text(
            'What every tax invoice prints besides the sale itself.',
            style: TextStyle(
              fontSize: 13,
              color: colors.textSecondary,
              fontFamily: brandFontFamily,
            ),
          ),
          const SizedBox(height: 24),

          _group('Seller', colors, [
            _field(
              'legalName',
              'Legal name',
              colors,
              hint: 'Leave blank to use the company name from Appearance',
            ),
            _pair(
              _field('addressLine1', 'Address line 1', colors),
              _field('addressLine2', 'Address line 2', colors),
            ),
            _pair(
              _field(
                'gstin',
                'GSTIN / UIN',
                colors,
                hint: '24AAACS9876P1ZK',
                caps: true,
              ),
              _field('pan', 'PAN', colors, hint: 'AABCS1234F', caps: true),
            ),
            _pair(
              _field('stateName', 'State name', colors, hint: 'Gujarat'),
              _field('stateCode', 'State code', colors, hint: '24'),
            ),
            _pair(
              _field('phone', 'Phone', colors),
              _field('email', 'Email', colors),
            ),
          ]),

          _group('Bank & payment', colors, [
            _pair(
              _field('bankName', 'Bank name', colors),
              _field('accountNo', 'Account number', colors),
            ),
            _pair(
              _field('branchAndIfsc', 'Branch & IFSC', colors),
              _field(
                'upiId',
                'UPI id',
                colors,
                hint: 'Used for the payment link and the QR block',
              ),
            ),
          ]),

          _group('Document', colors, [
            _pair(
              _field(
                'invoicePrefix',
                'Invoice series prefix',
                colors,
                hint: 'ST produces ST/0248/26-27',
                caps: true,
              ),
              _gstField(colors),
            ),
            _field('declaration', 'Declaration', colors, lines: 4),
            _field('footerNote', 'Footer note', colors),
          ]),

          _group('Authorised signature', colors, [
            Text(
              'Printed above the signatory line at the bottom right of every '
              'invoice, on screen and in the PDF. Leave it empty to keep the '
              'space blank for a pen.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: colors.textHint,
                fontFamily: brandFontFamily,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => ImageDropzone(
                    base64Image: _signature.value,
                    emptyLabel: 'Upload signature',
                    width: 200,
                    height: 84,
                    onPicked: (encoded) => _signature.value = encoded,
                    onRemove: () => _signature.value = null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'PNG or JPG, under 1.5 MB. A transparent PNG sits best on '
                    'the paper — the invoice composites it onto white, so a '
                    'white background works too. It is scaled to fit the '
                    'signature line, so a large scan is safe.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: colors.textHint,
                      fontFamily: brandFontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ]),

          _group('Default blocks on a new bill', colors, [
            Text(
              'A bill starts with these; each invoice can still be changed on '
              'its own screen.',
              style: TextStyle(
                fontSize: 12.5,
                color: colors.textHint,
                fontFamily: brandFontFamily,
              ),
            ),
            const SizedBox(height: 6),
            Obx(() {
              final o = _defaults.value;
              return Column(
                children: [
                  _switch(
                    'HSN-wise tax summary',
                    o.showHsnSummary,
                    colors,
                    (v) => _defaults.value = o.copyWith(showHsnSummary: v),
                  ),
                  _switch(
                    "Company's bank details",
                    o.showBankDetails,
                    colors,
                    (v) => _defaults.value = o.copyWith(showBankDetails: v),
                  ),
                  _switch(
                    'UPI QR code',
                    o.showUpiQr,
                    colors,
                    (v) => _defaults.value = o.copyWith(showUpiQr: v),
                  ),
                  _switch(
                    'e-Invoice IRN block',
                    o.showEInvoice,
                    colors,
                    (v) => _defaults.value = o.copyWith(showEInvoice: v),
                  ),
                  _switch(
                    'Declaration & terms',
                    o.showDeclaration,
                    colors,
                    (v) => _defaults.value = o.copyWith(showDeclaration: v),
                  ),
                ],
              );
            }),
          ]),

          const SizedBox(height: 8),
          AppAsyncButton(label: 'Save billing details', onPressed: _save),
          const SizedBox(height: 12),
          Text(
            'e-Invoice registration is not connected. Until an IRP '
            'integration exists, invoices print "Not registered" rather than '
            'an IRN.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: colors.textHint,
              fontFamily: brandFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  // ── Pieces ────────────────────────────────────────────────────────────────
  Widget _title(String text, AppThemeColors colors) => Text(
    text,
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: colors.textPrimary,
      fontFamily: brandFontFamily,
    ),
  );

  Widget _group(String title, AppThemeColors colors, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: colors.textHint,
              fontFamily: brandFontFamily,
            ),
          ),
          const SizedBox(height: 12),
          for (final child in children)
            Padding(padding: const EdgeInsets.only(bottom: 12), child: child),
        ],
      ),
    );
  }

  Widget _pair(Widget left, Widget right) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: left),
      const SizedBox(width: 14),
      Expanded(child: right),
    ],
  );

  Widget _field(
    String key,
    String label,
    AppThemeColors colors, {
    String? hint,
    int lines = 1,
    bool caps = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFamily: brandFontFamily,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: _fields[key],
          maxLines: lines,
          textCapitalization: caps
              ? TextCapitalization.characters
              : TextCapitalization.none,
          inputFormatters: caps
              ? [UpperCaseFormatter()]
              : const <TextInputFormatter>[],
          style: TextStyle(
            fontSize: 13.5,
            color: colors.textPrimary,
            fontFamily: brandFontFamily,
          ),
          decoration: _decoration(colors, hint),
        ),
      ],
    );
  }

  Widget _gstField(AppThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GST rate',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
            fontFamily: brandFontFamily,
          ),
        ),
        const SizedBox(height: 7),
        Obx(
          () => Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: DropdownButton<double>(
              value: _gstPercent.value,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: colors.surface,
              items: const [0.0, 5.0, 12.0, 18.0, 28.0]
                  .map(
                    (rate) => DropdownMenuItem(
                      value: rate,
                      child: Text(
                        // Split evenly on the invoice, which is what the
                        // CGST/SGST columns show.
                        '${rate.toStringAsFixed(0)}%  '
                        '(${(rate / 2).toStringAsFixed(rate % 2 == 0 ? 0 : 1)}%'
                        ' CGST + SGST)',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textPrimary,
                          fontFamily: brandFontFamily,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) _gstPercent.value = v;
              },
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration(AppThemeColors colors, String? hint) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 12.5,
          color: colors.textHint,
          fontFamily: brandFontFamily,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          // Not const: the brand's primary is resolved at runtime, so the
          // focus ring follows a rebrand.
          borderSide: const BorderSide(
            width: 1.5,
          ).copyWith(color: AppColors.primaryOrange),
        ),
      );

  Widget _switch(
    String label,
    bool value,
    AppThemeColors colors,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colors.textPrimary,
              fontFamily: brandFontFamily,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primaryOrange,
          thumbColor: const WidgetStatePropertyAll(Colors.white),
          inactiveTrackColor: colors.border,
        ),
      ],
    );
  }
}

/// Upper-cases as the user types — GSTIN, PAN and the series prefix are always
/// written in capitals, and correcting them afterwards is fiddly.
class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => TextEditingValue(
    text: newValue.text.toUpperCase(),
    selection: newValue.selection,
  );
}

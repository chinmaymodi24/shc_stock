import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/clients/controllers/add_client_controller.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'package:shc_stock/app/shared/widgets/form_fields.dart';
import 'package:shc_stock/app/shared/widgets/section_card.dart';

const _kClientTypes = ['Business', 'Individual', 'Government'];
const _kPaymentTerms = ['Advance', 'Net 15', 'Net 30', 'Net 45'];
const _kPriceLists = ['Standard', 'Wholesale', 'Retail'];

/// Mobile counterpart of WebAddClientLayout — same 4 sections + contact
/// person, same AddClientController/toPayload(), stacked single-column
/// instead of the web's 3-column rows + side summary rail.
class MobileAddClientLayout extends GetView<AddClientController> {
  const MobileAddClientLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(context, colors),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _clientDetailsSection(colors),
            const SizedBox(height: 12),
            _shippingAddressSection(colors),
            const SizedBox(height: 12),
            _billingAddressSection(colors),
            const SizedBox(height: 12),
            _creditTermsSection(colors),
            const SizedBox(height: 12),
            _contactPersonSection(colors),
            const SizedBox(height: 20),
            _saveButton(colors),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, AppThemeColors colors) {
    return AppBar(
      backgroundColor: colors.topBarBg,
      elevation: 0,
      leading: AppBackButton(
        colors: colors,
        mobile: true,
        onTap: () => Get.offNamed(AppRoutes.clients),
      ).paddedIcon(),
      titleSpacing: 8,
      title: Text(
        'Add Client',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
          fontFamily: 'Poppins',
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: colors.divider),
      ),
    );
  }

  Future<void> _saveClient() async {
    if (controller.nameCtrl.text.trim().isEmpty) {
      showAppToast(
        'Validation Error',
        'Client Name is required.',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    controller.isSaving.value = true;
    final saved = await Get.find<ClientsController>().addClient(
      controller.toPayload(),
    );
    controller.isSaving.value = false;
    if (saved == null) return;
    Get.offNamed(AppRoutes.clients);
    showAppToast(
      '✅ Client Saved',
      '${saved.name} (${saved.code}) has been added.',
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
    );
  }

  Widget _saveButton(AppThemeColors colors) {
    return Obx(() {
      final saving = controller.isSaving.value;
      return SizedBox(
        width: double.infinity,
        child: InkWell(
          onTap: saving ? null : _saveClient,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: saving ? 0.6 : 1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (saving) ...[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  saving ? 'Saving…' : 'Save Client',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ── Section 1: Client Details ─────────────────────────────────────────────
  Widget _clientDetailsSection(AppThemeColors colors) {
    return AppNumberedSectionCard(
      colors: colors,
      number: 1,
      title: 'Client Details',
      mobile: true,
      child: Obx(
        () => Column(
          children: [
            AppField(
              label: 'Client Type',
              required: true,
              colors: colors,
              mobile: true,
              child: AppDropBox(
                hint: 'Select client type',
                value: controller.clientType.value.isEmpty
                    ? null
                    : controller.clientType.value,
                items: _kClientTypes,
                colors: colors,
                mobile: true,
                onChanged: (v) => controller.clientType.value = v ?? '',
              ),
            ),
            const SizedBox(height: 12),
            AppField(
              label: 'Client Code',
              required: true,
              colors: colors,
              mobile: true,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.6,
                  child: AppTextBox(
                    controller: controller.clientCodeCtrl,
                    hint: 'Auto generated',
                    colors: colors,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppField(
              label: 'Client Name',
              required: true,
              colors: colors,
              mobile: true,
              child: AppTextBox(
                controller: controller.nameCtrl,
                hint: 'Enter client name',
                colors: colors,
              ),
            ),
            const SizedBox(height: 12),
            AppField(
              label: 'Email',
              colors: colors,
              mobile: true,
              child: AppTextBox(
                controller: controller.emailCtrl,
                hint: 'Enter email address',
                colors: colors,
              ),
            ),
            const SizedBox(height: 12),
            AppField(
              label: 'Phone',
              required: true,
              colors: colors,
              mobile: true,
              child: AppTextBox(
                controller: controller.phoneCtrl,
                hint: 'Enter phone number',
                colors: colors,
              ),
            ),
            const SizedBox(height: 12),
            AppField(
              label: 'Alternate Phone',
              colors: colors,
              mobile: true,
              child: AppTextBox(
                controller: controller.altPhCtrl,
                hint: 'Enter phone number',
                colors: colors,
              ),
            ),
            const SizedBox(height: 12),
            AppField(
              label: 'GSTIN',
              colors: colors,
              mobile: true,
              child: AppTextBox(
                controller: controller.gstinCtrl,
                hint: 'Enter GSTIN',
                colors: colors,
              ),
            ),
            const SizedBox(height: 12),
            AppField(
              label: 'PAN',
              colors: colors,
              mobile: true,
              child: AppTextBox(
                controller: controller.panCtrl,
                hint: 'Enter PAN',
                colors: colors,
              ),
            ),
            const SizedBox(height: 12),
            AppField(
              label: 'Client Since',
              colors: colors,
              mobile: true,
              child: AppDateBox(
                date: controller.clientSince.value,
                colors: colors,
                mobile: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: Get.context!,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    controller.clientSince.value = picked;
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: colors.divider),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'REGISTERED ADDRESS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.textHint,
                  fontFamily: 'Poppins',
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _addressStack(
              colors: colors,
              addr1Ctrl: controller.regAddr1Ctrl,
              addr2Ctrl: controller.regAddr2Ctrl,
              cityCtrl: controller.regCityCtrl,
              stateCtrl: controller.regStateCtrl,
              pinCtrl: controller.regPinCtrl,
              countryCtrl: controller.regCountryCtrl,
              addr1Label: 'Address Line 1',
            ),
          ],
        ),
      ),
    );
  }

  // ── Section 2: Shipping Address ───────────────────────────────────────────
  Widget _shippingAddressSection(AppThemeColors colors) {
    return AppNumberedSectionCard(
      colors: colors,
      number: 2,
      title: 'Shipping Address',
      mobile: true,
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _checkRow(
              colors: colors,
              label: 'Same as Registered Address',
              value: controller.shippingSameAsRegistered.value,
              onChanged: controller.toggleShippingSameAsRegistered,
            ),
            const SizedBox(height: 8),
            _checkRow(
              colors: colors,
              label: 'Same as Billing Address',
              value: controller.shippingSameAsBilling.value,
              onChanged: controller.toggleShippingSameAsBilling,
            ),
            if (controller.showShippingFields) ...[
              const SizedBox(height: 12),
              _addressStack(
                colors: colors,
                addr1Ctrl: controller.shipAddr1Ctrl,
                addr2Ctrl: controller.shipAddr2Ctrl,
                cityCtrl: controller.shipCityCtrl,
                stateCtrl: controller.shipStateCtrl,
                pinCtrl: controller.shipPinCtrl,
                countryCtrl: controller.shipCountryCtrl,
                addr1Label: 'Address Line 1',
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Section 3: Billing Address ────────────────────────────────────────────
  Widget _billingAddressSection(AppThemeColors colors) {
    return AppNumberedSectionCard(
      colors: colors,
      number: 3,
      title: 'Billing Address',
      mobile: true,
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _checkRow(
              colors: colors,
              label: 'Same as Shipping Address',
              value:
                  controller.billingAddressMode.value ==
                  BillingAddressMode.shipping,
              onChanged: controller.toggleBillingSameAsShipping,
            ),
            const SizedBox(height: 8),
            _checkRow(
              colors: colors,
              label: 'Same as Registered Address',
              value:
                  controller.billingAddressMode.value ==
                  BillingAddressMode.registered,
              onChanged: controller.toggleBillingSameAsRegistered,
            ),
            if (controller.showBillingFields) ...[
              const SizedBox(height: 12),
              _addressStack(
                colors: colors,
                addr1Ctrl: controller.billAddr1Ctrl,
                addr2Ctrl: controller.billAddr2Ctrl,
                cityCtrl: controller.billCityCtrl,
                stateCtrl: controller.billStateCtrl,
                pinCtrl: controller.billPinCtrl,
                countryCtrl: controller.billCountryCtrl,
                addr1Label: 'Billing Address Line 1',
                addr2Label: 'Billing Address Line 2',
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Section 4: Credit & Payment Terms ─────────────────────────────────────
  Widget _creditTermsSection(AppThemeColors colors) {
    return AppNumberedSectionCard(
      colors: colors,
      number: 4,
      title: 'Credit & Payment Terms',
      mobile: true,
      child: Obx(
        () => Column(
          children: [
            AppField(
              label: 'Payment Terms',
              colors: colors,
              mobile: true,
              child: AppDropBox(
                hint: 'Select payment terms',
                value: controller.paymentTerms.value.isEmpty
                    ? null
                    : controller.paymentTerms.value,
                items: _kPaymentTerms,
                colors: colors,
                mobile: true,
                onChanged: (v) => controller.paymentTerms.value = v ?? '',
              ),
            ),
            const SizedBox(height: 12),
            AppField(
              label: 'Price List',
              colors: colors,
              mobile: true,
              child: AppDropBox(
                hint: 'Select price list',
                value: controller.priceList.value.isEmpty
                    ? null
                    : controller.priceList.value,
                items: _kPriceLists,
                colors: colors,
                mobile: true,
                onChanged: (v) => controller.priceList.value = v ?? '',
              ),
            ),
            const SizedBox(height: 12),
            AppField(
              label: 'Opening Balance (₹)',
              colors: colors,
              mobile: true,
              child: AppTextBox(
                controller: controller.opBalCtrl,
                hint: '0.00',
                colors: colors,
              ),
            ),
            const SizedBox(height: 12),
            AppField(
              label: 'Credit Limit (₹)',
              colors: colors,
              mobile: true,
              child: AppTextBox(
                controller: controller.crLimCtrl,
                hint: '0.00',
                colors: colors,
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: colors.divider),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: Listenable.merge([
                controller.opBalCtrl,
                controller.crLimCtrl,
                controller.crDaysCtrl,
              ]),
              builder: (context, _) => Column(
                children: [
                  AppTotalRow(
                    label: 'Opening Balance (₹)',
                    value: (double.tryParse(controller.opBalCtrl.text) ?? 0)
                        .toStringAsFixed(2),
                    colors: colors,
                  ),
                  const SizedBox(height: 10),
                  AppTotalRow(
                    label: 'Credit Limit (₹)',
                    value: (double.tryParse(controller.crLimCtrl.text) ?? 0)
                        .toStringAsFixed(2),
                    colors: colors,
                  ),
                  const SizedBox(height: 10),
                  AppTotalRow(
                    label: 'Credit Days',
                    value:
                        '${controller.crDaysCtrl.text.isEmpty ? '0' : controller.crDaysCtrl.text} days',
                    colors: colors,
                  ),
                  const SizedBox(height: 10),
                  AppTotalRow(
                    label: 'Outstanding Amount (₹)',
                    value: '0.00',
                    colors: colors,
                  ),
                  const SizedBox(height: 10),
                  AppTotalRow(
                    label: 'Total Sales (MTD)',
                    value: '0.00',
                    colors: colors,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section 5: Contact Person ─────────────────────────────────────────────
  Widget _contactPersonSection(AppThemeColors colors) {
    return AppNumberedSectionCard(
      colors: colors,
      number: 5,
      title: 'Contact Person',
      mobile: true,
      child: Column(
        children: [
          AppField(
            label: 'Contact Person Name',
            colors: colors,
            mobile: true,
            child: AppTextBox(
              controller: controller.cpNameCtrl,
              hint: 'Enter contact name',
              colors: colors,
            ),
          ),
          const SizedBox(height: 12),
          AppField(
            label: 'Designation',
            colors: colors,
            mobile: true,
            child: AppTextBox(
              controller: controller.cpDesigCtrl,
              hint: 'Enter designation',
              colors: colors,
            ),
          ),
          const SizedBox(height: 12),
          AppField(
            label: 'Phone',
            colors: colors,
            mobile: true,
            child: AppTextBox(
              controller: controller.cpPhCtrl,
              hint: 'Enter phone number',
              colors: colors,
            ),
          ),
          const SizedBox(height: 12),
          AppField(
            label: 'Email',
            colors: colors,
            mobile: true,
            child: AppTextBox(
              controller: controller.cpEmailCtrl,
              hint: 'Enter email address',
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared: single-column address field stack ─────────────────────────────
  Widget _addressStack({
    required AppThemeColors colors,
    required TextEditingController addr1Ctrl,
    required TextEditingController addr2Ctrl,
    required TextEditingController cityCtrl,
    required TextEditingController stateCtrl,
    required TextEditingController pinCtrl,
    required TextEditingController countryCtrl,
    String addr1Label = 'Address Line 1',
    String addr2Label = 'Address Line 2',
  }) {
    return Column(
      children: [
        AppField(
          label: addr1Label,
          required: true,
          colors: colors,
          mobile: true,
          child: AppTextBox(
            controller: addr1Ctrl,
            hint: 'Enter address line 1',
            colors: colors,
          ),
        ),
        const SizedBox(height: 12),
        AppField(
          label: addr2Label,
          colors: colors,
          mobile: true,
          child: AppTextBox(
            controller: addr2Ctrl,
            hint: 'Enter address line 2',
            colors: colors,
          ),
        ),
        const SizedBox(height: 12),
        AppField(
          label: 'City',
          required: true,
          colors: colors,
          mobile: true,
          child: AppTextBox(
            controller: cityCtrl,
            hint: 'Enter city',
            colors: colors,
          ),
        ),
        const SizedBox(height: 12),
        AppField(
          label: 'State',
          required: true,
          colors: colors,
          mobile: true,
          child: AppTextBox(
            controller: stateCtrl,
            hint: 'Select state',
            colors: colors,
          ),
        ),
        const SizedBox(height: 12),
        AppField(
          label: 'PIN Code',
          required: true,
          colors: colors,
          mobile: true,
          child: AppTextBox(
            controller: pinCtrl,
            hint: 'Enter PIN code',
            colors: colors,
          ),
        ),
        const SizedBox(height: 12),
        AppField(
          label: 'Country',
          required: true,
          colors: colors,
          mobile: true,
          child: AppTextBox(
            controller: countryCtrl,
            hint: 'India',
            colors: colors,
          ),
        ),
      ],
    );
  }

  // ── Shared: checkbox row for the "Same as…" toggles ───────────────────────
  Widget _checkRow({
    required AppThemeColors colors,
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primaryOrange,
              checkColor: Colors.white,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(color: colors.textSecondary, width: 1.3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: colors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

extension _PaddedIcon on Widget {
  /// AppBar `leading` centers a fixed 56px box; the back button reads better
  /// with a little breathing room inside that box.
  Widget paddedIcon() => Padding(
    padding: const EdgeInsets.only(left: 12),
    child: Align(alignment: Alignment.centerLeft, child: this),
  );
}

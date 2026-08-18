import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_sidebar.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/web_top_bar.dart';
import 'package:shc_stock/app/modules/clients/controllers/add_client_controller.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'package:shc_stock/app/shared/widgets/form_fields.dart';
import 'package:shc_stock/app/shared/widgets/section_card.dart';

// ── Select options — match the approved design exactly ─────────────────────
const _kClientTypes = ['Business', 'Individual', 'Government'];
const _kPaymentTerms = ['Advance', 'Net 15', 'Net 30', 'Net 45'];
const _kPriceLists = ['Standard', 'Wholesale', 'Retail'];

// ─────────────────────────────────────────────────────────────────────────────
// Main Widget — mirrors "Secure Heat Care Add Client.dc.html": a numbered
// 4-section form on the left, a live-summary sidebar on the right.
// ─────────────────────────────────────────────────────────────────────────────
class WebAddClientLayout extends GetView<AddClientController> {
  const WebAddClientLayout({super.key});

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
                _buildPageHeader(context, colors),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT: scrollable form sections
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              _clientDetailsSection(colors),
                              const SizedBox(height: 16),
                              _shippingAddressSection(colors),
                              const SizedBox(height: 16),
                              _billingAddressSection(colors),
                              const SizedBox(height: 16),
                              _creditTermsSection(colors),
                            ],
                          ),
                        ),
                      ),

                      // RIGHT: live-summary sidebar
                      SizedBox(
                        width: 280,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
                          child: Column(
                            children: [
                              _creditSummaryCard(colors),
                              const SizedBox(height: 16),
                              _registeredAddressPreviewCard(colors),
                              const SizedBox(height: 16),
                              _contactPersonCard(colors),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Page header: back + title/subtitle + Cancel/Save ─────────────────────
  Widget _buildPageHeader(BuildContext context, AppThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.divider)),
      ),
      child: Row(
        children: [
          AppBackButton(
            colors: colors,
            onTap: () => Get.offNamed(AppRoutes.clients),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Client',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Client details as per GST registration / KYC',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textHint,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => Get.offNamed(AppRoutes.clients),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: colors.inputFill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Obx(() {
            final saving = controller.isSaving.value;
            return InkWell(
              onTap: saving ? null : _saveClient,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withValues(
                    alpha: saving ? 0.6 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (saving) ...[
                      const SizedBox(
                        width: 13,
                        height: 13,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
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
    // ClientsBinding registers this permanently, so the new client lands in
    // the already-loaded list without a full refetch.
    final saved = await Get.find<ClientsController>().addClient(
      controller.toPayload(),
    );
    controller.isSaving.value = false;
    // addClient() already surfaced the API error toast on failure — keep the
    // form open so the entered data isn't lost.
    if (saved == null) return;
    Get.offNamed(AppRoutes.clients);
    showAppToast(
      '✅ Client Saved',
      '${saved.name} (${saved.code}) has been added.',
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
    );
  }

  // ── Section 1: Client Details ─────────────────────────────────────────────
  Widget _clientDetailsSection(AppThemeColors colors) {
    return AppNumberedSectionCard(
      colors: colors,
      number: 1,
      title: 'Client Details',
      child: Obx(
        () => Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppField(
                    label: 'Client Type',
                    required: true,
                    colors: colors,
                    child: AppDropBox(
                      hint: 'Select client type',
                      value: controller.clientType.value.isEmpty
                          ? null
                          : controller.clientType.value,
                      items: _kClientTypes,
                      colors: colors,
                      onChanged: (v) => controller.clientType.value = v ?? '',
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AppField(
                    label: 'Client Code',
                    required: true,
                    colors: colors,
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
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AppField(
                    label: 'Client Name',
                    required: true,
                    colors: colors,
                    child: AppTextBox(
                      controller: controller.nameCtrl,
                      hint: 'Enter client name',
                      colors: colors,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppField(
                    label: 'Email',
                    colors: colors,
                    child: AppTextBox(
                      controller: controller.emailCtrl,
                      hint: 'Enter email address',
                      colors: colors,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AppField(
                    label: 'Phone',
                    required: true,
                    colors: colors,
                    child: AppTextBox(
                      controller: controller.phoneCtrl,
                      hint: 'Enter phone number',
                      colors: colors,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AppField(
                    label: 'Alternate Phone',
                    colors: colors,
                    child: AppTextBox(
                      controller: controller.altPhCtrl,
                      hint: 'Enter phone number',
                      colors: colors,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppField(
                    label: 'GSTIN',
                    colors: colors,
                    child: AppTextBox(
                      controller: controller.gstinCtrl,
                      hint: 'Enter GSTIN',
                      colors: colors,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AppField(
                    label: 'PAN',
                    colors: colors,
                    child: AppTextBox(
                      controller: controller.panCtrl,
                      hint: 'Enter PAN',
                      colors: colors,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AppField(
                    label: 'Client Since',
                    colors: colors,
                    child: AppDateBox(
                      date: controller.clientSince.value,
                      colors: colors,
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: colors.divider),
            const SizedBox(height: 14),
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
            const SizedBox(height: 14),
            _addressGrid(
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
            const SizedBox(height: 6),
            _checkRow(
              colors: colors,
              label: 'Same as Billing Address',
              value: controller.shippingSameAsBilling.value,
              onChanged: controller.toggleShippingSameAsBilling,
            ),
            if (controller.showShippingFields) ...[
              const SizedBox(height: 14),
              _addressGrid(
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
            const SizedBox(height: 6),
            _checkRow(
              colors: colors,
              label: 'Same as Registered Address',
              value:
                  controller.billingAddressMode.value ==
                  BillingAddressMode.registered,
              onChanged: controller.toggleBillingSameAsRegistered,
            ),
            if (controller.showBillingFields) ...[
              const SizedBox(height: 14),
              _addressGrid(
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
      child: Obx(
        () => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppField(
                label: 'Payment Terms',
                colors: colors,
                child: AppDropBox(
                  hint: 'Select payment terms',
                  value: controller.paymentTerms.value.isEmpty
                      ? null
                      : controller.paymentTerms.value,
                  items: _kPaymentTerms,
                  colors: colors,
                  onChanged: (v) => controller.paymentTerms.value = v ?? '',
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AppField(
                label: 'Price List',
                colors: colors,
                child: AppDropBox(
                  hint: 'Select price list',
                  value: controller.priceList.value.isEmpty
                      ? null
                      : controller.priceList.value,
                  items: _kPriceLists,
                  colors: colors,
                  onChanged: (v) => controller.priceList.value = v ?? '',
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AppField(
                label: 'Opening Balance (₹)',
                colors: colors,
                child: AppTextBox(
                  controller: controller.opBalCtrl,
                  hint: '0.00',
                  colors: colors,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AppField(
                label: 'Credit Limit (₹)',
                colors: colors,
                child: AppTextBox(
                  controller: controller.crLimCtrl,
                  hint: '0.00',
                  colors: colors,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared: 2-column address field grid ───────────────────────────────────
  Widget _addressGrid({
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppField(
                label: addr1Label,
                required: true,
                colors: colors,
                child: AppTextBox(
                  controller: addr1Ctrl,
                  hint: 'Enter address line 1',
                  colors: colors,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AppField(
                label: addr2Label,
                colors: colors,
                child: AppTextBox(
                  controller: addr2Ctrl,
                  hint: 'Enter address line 2',
                  colors: colors,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppField(
                label: 'City',
                required: true,
                colors: colors,
                child: AppTextBox(
                  controller: cityCtrl,
                  hint: 'Enter city',
                  colors: colors,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AppField(
                label: 'State',
                required: true,
                colors: colors,
                child: AppTextBox(
                  controller: stateCtrl,
                  hint: 'Select state',
                  colors: colors,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppField(
                label: 'PIN Code',
                required: true,
                colors: colors,
                child: AppTextBox(
                  controller: pinCtrl,
                  hint: 'Enter PIN code',
                  colors: colors,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AppField(
                label: 'Country',
                required: true,
                colors: colors,
                child: AppTextBox(
                  controller: countryCtrl,
                  hint: 'India',
                  colors: colors,
                ),
              ),
            ),
          ],
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

  // ── Right sidebar: Credit & Summary ───────────────────────────────────────
  Widget _creditSummaryCard(AppThemeColors colors) {
    return _SidebarCard(
      colors: colors,
      title: 'Credit & Summary',
      // These three values come from TextEditingControllers, not Rx fields, so
      // an Obx here has nothing observable to subscribe to — GetX throws
      // "improper use of a GetX" and the values never refresh while typing.
      // Listen to the controllers directly, same as the address preview below.
      child: AnimatedBuilder(
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
            const SizedBox(height: 14),
            AppTotalRow(
              label: 'Credit Limit (₹)',
              value: (double.tryParse(controller.crLimCtrl.text) ?? 0)
                  .toStringAsFixed(2),
              colors: colors,
            ),
            const SizedBox(height: 14),
            AppTotalRow(
              label: 'Credit Days',
              value:
                  '${controller.crDaysCtrl.text.isEmpty ? '0' : controller.crDaysCtrl.text} days',
              colors: colors,
            ),
            const SizedBox(height: 14),
            AppTotalRow(
              label: 'Outstanding Amount (₹)',
              value: '0.00',
              colors: colors,
            ),
            const SizedBox(height: 14),
            AppTotalRow(
              label: 'Total Sales (MTD)',
              value: '0.00',
              colors: colors,
            ),
          ],
        ),
      ),
    );
  }

  // ── Right sidebar: live Registered Address preview ────────────────────────
  Widget _registeredAddressPreviewCard(AppThemeColors colors) {
    return _SidebarCard(
      colors: colors,
      title: 'Registered Address',
      child: AnimatedBuilder(
        animation: Listenable.merge([
          controller.regAddr1Ctrl,
          controller.regAddr2Ctrl,
          controller.regCityCtrl,
          controller.regStateCtrl,
          controller.regPinCtrl,
          controller.regCountryCtrl,
        ]),
        builder: (context, _) => Text(
          controller.registeredAddressPreview,
          style: TextStyle(
            fontSize: 12.5,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
            height: 1.6,
          ),
        ),
      ),
    );
  }

  // ── Right sidebar: Contact Person ─────────────────────────────────────────
  Widget _contactPersonCard(AppThemeColors colors) {
    return _SidebarCard(
      colors: colors,
      title: 'Contact Person',
      child: Column(
        children: [
          AppField(
            label: 'Contact Person Name',
            colors: colors,
            child: AppTextBox(
              controller: controller.cpNameCtrl,
              hint: 'Enter contact name',
              colors: colors,
            ),
          ),
          const SizedBox(height: 14),
          AppField(
            label: 'Designation',
            colors: colors,
            child: AppTextBox(
              controller: controller.cpDesigCtrl,
              hint: 'Enter designation',
              colors: colors,
            ),
          ),
          const SizedBox(height: 14),
          AppField(
            label: 'Phone',
            colors: colors,
            child: AppTextBox(
              controller: controller.cpPhCtrl,
              hint: 'Enter phone number',
              colors: colors,
            ),
          ),
          const SizedBox(height: 14),
          AppField(
            label: 'Email',
            colors: colors,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar card — matches `.section-card` with a titled, divider-underlined
// header (no numbered badge, unlike the main form's section cards).
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarCard extends StatelessWidget {
  final AppThemeColors colors;
  final String title;
  final Widget child;

  const _SidebarCard({
    required this.colors,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: colors.divider),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

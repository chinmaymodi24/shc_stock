import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';

/// How the Billing Address section behaves — mirrors the two "Same as…"
/// checkboxes: checking either sets this to the matching value; unchecking
/// either (regardless of which was active) drops to 'custom', which reveals
/// manual billing-address fields.
enum BillingAddressMode { shipping, registered, custom }

class AddClientController extends GetxController {
  // ── Client Details ────────────────────────────────────────────────────
  final clientType = ''.obs;
  final clientCodeCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final altPhCtrl = TextEditingController();
  final gstinCtrl = TextEditingController();
  final panCtrl = TextEditingController();
  final clientSince = Rx<DateTime?>(null);

  // ── Registered Address ────────────────────────────────────────────────
  final regAddr1Ctrl = TextEditingController();
  final regAddr2Ctrl = TextEditingController();
  final regCityCtrl = TextEditingController();
  final regStateCtrl = TextEditingController();
  final regPinCtrl = TextEditingController();
  final regCountryCtrl = TextEditingController(text: 'India');

  // ── Shipping Address ───────────────────────────────────────────────────
  final shippingSameAsRegistered = true.obs;
  final shippingSameAsBilling = false.obs;
  final shipAddr1Ctrl = TextEditingController();
  final shipAddr2Ctrl = TextEditingController();
  final shipCityCtrl = TextEditingController();
  final shipStateCtrl = TextEditingController();
  final shipPinCtrl = TextEditingController();
  final shipCountryCtrl = TextEditingController(text: 'India');

  bool get showShippingFields =>
      !shippingSameAsRegistered.value && !shippingSameAsBilling.value;

  void toggleShippingSameAsRegistered(bool? v) {
    shippingSameAsRegistered.value = v ?? false;
    if (shippingSameAsRegistered.value) shippingSameAsBilling.value = false;
  }

  void toggleShippingSameAsBilling(bool? v) {
    shippingSameAsBilling.value = v ?? false;
    if (shippingSameAsBilling.value) shippingSameAsRegistered.value = false;
  }

  // ── Billing Address ────────────────────────────────────────────────────
  final billingAddressMode = BillingAddressMode.shipping.obs;
  final billAddr1Ctrl = TextEditingController();
  final billAddr2Ctrl = TextEditingController();
  final billCityCtrl = TextEditingController();
  final billStateCtrl = TextEditingController();
  final billPinCtrl = TextEditingController();
  final billCountryCtrl = TextEditingController(text: 'India');

  bool get showBillingFields =>
      billingAddressMode.value == BillingAddressMode.custom;

  void toggleBillingSameAsShipping(bool? v) {
    billingAddressMode.value = (v ?? false)
        ? BillingAddressMode.shipping
        : BillingAddressMode.custom;
  }

  void toggleBillingSameAsRegistered(bool? v) {
    billingAddressMode.value = (v ?? false)
        ? BillingAddressMode.registered
        : BillingAddressMode.custom;
  }

  // ── Credit & Payment Terms ─────────────────────────────────────────────
  final paymentTerms = ''.obs;
  final priceList = ''.obs;
  final opBalCtrl = TextEditingController();
  final crLimCtrl = TextEditingController();
  final crDaysCtrl = TextEditingController(text: '0');

  // ── Contact Person ──────────────────────────────────────────────────────
  final cpNameCtrl = TextEditingController();
  final cpDesigCtrl = TextEditingController();
  final cpPhCtrl = TextEditingController();
  final cpEmailCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    clientCodeCtrl.text = 'CLT-${1000 + Random().nextInt(9000)}';
    final arg = Get.arguments;
    if (arg is ClientModel) loadFrom(arg);
  }

  /// Fills the form from an existing client — used by the clients list's
  /// "Duplicate" action. There is no edit/update path here: Client Code is
  /// left as the freshly-generated one above (so it stays unique) and Save
  /// always POSTs a new client, leaving the one duplicated from untouched.
  void loadFrom(ClientModel c) {
    clientType.value = c.clientType;
    nameCtrl.text = c.name;
    emailCtrl.text = c.email;
    phoneCtrl.text = c.phone;
    altPhCtrl.text = c.altPhone;
    gstinCtrl.text = c.gstin;
    panCtrl.text = c.pan;
    clientSince.value = c.clientSince;

    regAddr1Ctrl.text = c.regAddr1;
    regAddr2Ctrl.text = c.regAddr2;
    regCityCtrl.text = c.regCity;
    regStateCtrl.text = c.regState;
    regPinCtrl.text = c.regPin;
    regCountryCtrl.text = c.regCountry;

    shippingSameAsRegistered.value = c.shipSameAsRegistered;
    shippingSameAsBilling.value = c.shipSameAsBilling;
    shipAddr1Ctrl.text = c.shipAddr1;
    shipAddr2Ctrl.text = c.shipAddr2;
    shipCityCtrl.text = c.shipCity;
    shipStateCtrl.text = c.shipState;
    shipPinCtrl.text = c.shipPin;
    shipCountryCtrl.text = c.shipCountry;

    billingAddressMode.value = BillingAddressMode.values.firstWhere(
      (m) => m.name == c.billingMode,
      orElse: () => BillingAddressMode.shipping,
    );
    billAddr1Ctrl.text = c.billAddr1;
    billAddr2Ctrl.text = c.billAddr2;
    billCityCtrl.text = c.billCity;
    billStateCtrl.text = c.billState;
    billPinCtrl.text = c.billPin;
    billCountryCtrl.text = c.billCountry;

    paymentTerms.value = c.paymentTerms;
    priceList.value = c.priceList;
    opBalCtrl.text = c.openingBalance == 0 ? '' : c.openingBalance.toString();
    crLimCtrl.text = c.creditLimit == 0 ? '' : c.creditLimit.toString();
    crDaysCtrl.text = c.creditDays.toString();

    cpNameCtrl.text = c.contactPerson;
    cpDesigCtrl.text = c.contactDesignation;
    cpPhCtrl.text = c.contactPhone;
    cpEmailCtrl.text = c.contactEmail;
  }

  /// True while a save is in flight — disables the Save button.
  final isSaving = false.obs;

  /// The request body POSTed to /api/clients. Field names mirror the Prisma
  /// `Client` model; the backend composes the list's display address from the
  /// registered-address fields.
  Map<String, dynamic> toPayload() => {
    'code': clientCodeCtrl.text.trim(),
    'name': nameCtrl.text.trim(),
    'clientType': clientType.value,
    // GSTIN present ⇒ a GST-registered ("Regular") client; the clients list
    // and its GST Registered / Unregistered stat cards key off this.
    'registrationType': gstinCtrl.text.trim().isEmpty
        ? 'Unregistered/Consumer'
        : 'Regular',
    'email': emailCtrl.text.trim(),
    'phone': phoneCtrl.text.trim(),
    'altPhone': altPhCtrl.text.trim(),
    'gstin': gstinCtrl.text.trim(),
    'pan': panCtrl.text.trim(),
    'clientSince': clientSince.value?.toIso8601String(),

    'regAddr1': regAddr1Ctrl.text.trim(),
    'regAddr2': regAddr2Ctrl.text.trim(),
    'regCity': regCityCtrl.text.trim(),
    'regState': regStateCtrl.text.trim(),
    'regPin': regPinCtrl.text.trim(),
    'regCountry': regCountryCtrl.text.trim(),

    'shipSameAsRegistered': shippingSameAsRegistered.value,
    'shipSameAsBilling': shippingSameAsBilling.value,
    'shipAddr1': shipAddr1Ctrl.text.trim(),
    'shipAddr2': shipAddr2Ctrl.text.trim(),
    'shipCity': shipCityCtrl.text.trim(),
    'shipState': shipStateCtrl.text.trim(),
    'shipPin': shipPinCtrl.text.trim(),
    'shipCountry': shipCountryCtrl.text.trim(),

    'billingMode': billingAddressMode.value.name,
    'billAddr1': billAddr1Ctrl.text.trim(),
    'billAddr2': billAddr2Ctrl.text.trim(),
    'billCity': billCityCtrl.text.trim(),
    'billState': billStateCtrl.text.trim(),
    'billPin': billPinCtrl.text.trim(),
    'billCountry': billCountryCtrl.text.trim(),

    'paymentTerms': paymentTerms.value,
    'priceList': priceList.value,
    'openingBalance': double.tryParse(opBalCtrl.text.trim()) ?? 0,
    'creditLimit': double.tryParse(crLimCtrl.text.trim()) ?? 0,
    'creditDays': int.tryParse(crDaysCtrl.text.trim()) ?? 0,

    'contactPerson': cpNameCtrl.text.trim(),
    'contactDesignation': cpDesigCtrl.text.trim(),
    'contactPhone': cpPhCtrl.text.trim(),
    'contactEmail': cpEmailCtrl.text.trim(),
  };

  /// Live preview of the Registered Address, shown in the right sidebar.
  String get registeredAddressPreview {
    final parts = [
      regAddr1Ctrl.text,
      regAddr2Ctrl.text,
      regCityCtrl.text,
      regStateCtrl.text,
      regPinCtrl.text,
      regCountryCtrl.text,
    ].where((s) => s.trim().isNotEmpty).join(', ');
    return parts.isEmpty ? 'Not entered yet' : parts;
  }

  @override
  void onClose() {
    for (final c in [
      clientCodeCtrl,
      nameCtrl,
      emailCtrl,
      phoneCtrl,
      altPhCtrl,
      gstinCtrl,
      panCtrl,
      regAddr1Ctrl,
      regAddr2Ctrl,
      regCityCtrl,
      regStateCtrl,
      regPinCtrl,
      regCountryCtrl,
      shipAddr1Ctrl,
      shipAddr2Ctrl,
      shipCityCtrl,
      shipStateCtrl,
      shipPinCtrl,
      shipCountryCtrl,
      billAddr1Ctrl,
      billAddr2Ctrl,
      billCityCtrl,
      billStateCtrl,
      billPinCtrl,
      billCountryCtrl,
      opBalCtrl,
      crLimCtrl,
      crDaysCtrl,
      cpNameCtrl,
      cpDesigCtrl,
      cpPhCtrl,
      cpEmailCtrl,
    ]) {
      c.dispose();
    }
    super.onClose();
  }
}

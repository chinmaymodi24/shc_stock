import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddClientController extends GetxController {
  // ── Client Info ────────────────────────────────────────────────────────
  final clientType = ''.obs;
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final altPhCtrl = TextEditingController();
  final gstinCtrl = TextEditingController();
  final panCtrl = TextEditingController();
  final currency = 'INR - Indian Rupee (₹)'.obs;
  final pyTerms = ''.obs;
  final priceList = ''.obs;
  final since = Rx<DateTime?>(null);
  final opBalCtrl = TextEditingController(text: '0.00');
  final crLimCtrl = TextEditingController(text: '0.00');
  final crDaysCtrl = TextEditingController(text: '0');

  // ── Primary Address ───────────────────────────────────────────────────
  final pAddr1Ctrl = TextEditingController();
  final pAddr2Ctrl = TextEditingController();
  final pCityCtrl = TextEditingController();
  final pState = 'Select state'.obs;
  final pPinCtrl = TextEditingController();
  final pCountry = 'India'.obs;

  // ── Billing Address ───────────────────────────────────────────────────
  final sameAsPrim = true.obs;
  final bAddr1Ctrl = TextEditingController();
  final bAddr2Ctrl = TextEditingController();
  final bCityCtrl = TextEditingController();
  final bState = 'Select state'.obs;
  final bPinCtrl = TextEditingController();
  final bCountry = 'India'.obs;

  // ── Additional Info ───────────────────────────────────────────────────
  final noteCtrl = TextEditingController();
  final termsCtrl = TextEditingController();

  // ── Contact Person ─────────────────────────────────────────────────────
  final cpNameCtrl = TextEditingController();
  final cpDesigCtrl = TextEditingController();
  final cpPhCtrl = TextEditingController();
  final cpEmailCtrl = TextEditingController();

  @override
  void onClose() {
    for (final c in [
      nameCtrl,
      emailCtrl,
      phoneCtrl,
      altPhCtrl,
      gstinCtrl,
      panCtrl,
      opBalCtrl,
      crLimCtrl,
      crDaysCtrl,
      pAddr1Ctrl,
      pAddr2Ctrl,
      pCityCtrl,
      pPinCtrl,
      bAddr1Ctrl,
      bAddr2Ctrl,
      bCityCtrl,
      bPinCtrl,
      noteCtrl,
      termsCtrl,
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

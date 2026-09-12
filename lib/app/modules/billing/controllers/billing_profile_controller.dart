import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/export/writers/pdf_logo.dart';
import 'package:shc_stock/app/modules/billing/models/billing_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The portal-wide billing profile.
//
// Registered permanent and fetched once: the seller's GSTIN does not change
// between page visits, and every bill screen would otherwise re-request it.
// Settings › Billing writes through [save], which refreshes this in place.
// ─────────────────────────────────────────────────────────────────────────────
class BillingProfileController extends GetxService {
  static BillingProfileController get to =>
      Get.find<BillingProfileController>();

  final _api = ApiClient.instance;

  final Rx<BillingProfile> profile = BillingProfile.empty.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  /// True once the first fetch has completed, however it went — the bill
  /// screen waits for this before deciding the profile is unconfigured.
  final RxBool isLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    isLoading.value = true;
    try {
      final json = await _api.get('/settings/billing');
      profile.value = json is Map<String, dynamic>
          ? BillingProfile.fromJson(json)
          : BillingProfile.empty;
      // The PDF writer is synchronous; decode the signature now so it is ready
      // the first time someone presses Print.
      await warmPdfSignatureCache(profile.value.signatureBase64);
    } catch (e) {
      // Leave the defaults in place; the bill screen shows its "not
      // configured" notice rather than a blank seller block.
      profile.value = BillingProfile.empty;
    } finally {
      isLoading.value = false;
      isLoaded.value = true;
    }
  }

  /// Returns false on failure so the Settings tab can keep the user's edits
  /// on screen instead of silently discarding them.
  Future<bool> save(BillingProfile next) async {
    isSaving.value = true;
    try {
      final json = await _api.put('/settings/billing', next.toJson());
      profile.value = json is Map<String, dynamic>
          ? BillingProfile.fromJson(json)
          : next;
      await warmPdfSignatureCache(profile.value.signatureBase64);
      return true;
    } catch (e) {
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}

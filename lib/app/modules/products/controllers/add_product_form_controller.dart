import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddProductFormController extends GetxController {
  // ── Basic Info ─────────────────────────────────────────────────────────
  final nameCtrl = TextEditingController();
  final skuCtrl = TextEditingController();
  final barcodeCtrl = TextEditingController();
  final category = ''.obs;
  final subCat = ''.obs;
  final unit = ''.obs;
  final brand = ''.obs;
  final hsnCtrl = TextEditingController();
  final isStock = true.obs; // Stock Item vs Service Item
  final descCtrl = TextEditingController();

  // ── Pricing & Tax ──────────────────────────────────────────────────────
  final purPriceCtrl = TextEditingController();
  final selPriceCtrl = TextEditingController();
  final mrpCtrl = TextEditingController();
  final gstRate = 'Select GST rate'.obs;
  final cessCtrl = TextEditingController();
  final discCtrl = TextEditingController();

  // ── Inventory ──────────────────────────────────────────────────────────
  final openStockCtrl = TextEditingController();
  final reorderCtrl = TextEditingController();
  final location = 'Select location'.obs;
  final minQtyCtrl = TextEditingController();
  final maxQtyCtrl = TextEditingController();

  // ── Additional Info ────────────────────────────────────────────────────
  final shelfCtrl = TextEditingController();
  final warrantyCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final dimCtrl = TextEditingController();
  final isActive = true.obs;

  // ── Image ──────────────────────────────────────────────────────────────
  final images = <XFile>[].obs;
  final isDragging = false.obs;

  @override
  void onClose() {
    for (final c in [
      nameCtrl,
      skuCtrl,
      barcodeCtrl,
      hsnCtrl,
      descCtrl,
      purPriceCtrl,
      selPriceCtrl,
      mrpCtrl,
      cessCtrl,
      discCtrl,
      openStockCtrl,
      reorderCtrl,
      minQtyCtrl,
      maxQtyCtrl,
      shelfCtrl,
      warrantyCtrl,
      weightCtrl,
      dimCtrl,
    ]) {
      c.dispose();
    }
    super.onClose();
  }
}

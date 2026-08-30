import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/purchase/controllers/add_purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/controllers/purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/models/purchase_model.dart';
import 'package:shc_stock/app/modules/purchase/views/purchase_details_dialog.dart';
import 'package:shc_stock/app/modules/purchase/views/update_purchase_status_dialog.dart';
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';

/// The row actions a purchase order supports, defined once so the web table
/// and the mobile card can't drift apart on what a button does.
class PurchaseActions {
  const PurchaseActions._();

  static void view(BuildContext context, PurchaseOrder order) {
    Get.dialog(
      PurchaseDetailsDialog(
        order: order,
        onDelete: () {
          Get.back();
          delete(context, order);
        },
      ),
    );
  }

  /// Opens the same form Add Purchase uses, pre-filled from this order;
  /// saving updates it in place.
  static void edit(PurchaseOrder order) =>
      Get.toNamed(AppRoutes.addPurchase, arguments: order);

  /// Opens Add Purchase pre-filled from this order but as a new draft —
  /// saving creates a new record and never touches the one duplicated from.
  static void duplicate(PurchaseOrder order) => Get.toNamed(
    AppRoutes.addPurchase,
    arguments: DuplicatePurchaseOrder(order),
  );

  /// Mobile-only shortcut the web table has no room for — the status flow is
  /// otherwise reachable only through Edit.
  static void updateStatus(PurchaseOrder order) =>
      Get.dialog(UpdatePurchaseStatusDialog(order: order));

  static void delete(BuildContext context, PurchaseOrder order) =>
      confirmDelete(
        context,
        itemName: order.poNumber,
        itemLabel: 'Purchase Order',
        onConfirm: () => Get.find<PurchaseController>().deleteOrder(order.id),
      );
}

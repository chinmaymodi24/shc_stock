import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/sales/controllers/add_sale_controller.dart';
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/modules/sales/views/sale_details_dialog.dart';
import 'package:shc_stock/app/modules/sales/views/update_sales_status_dialog.dart';
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';

/// The row actions a sales order supports, defined once so the web table and
/// the mobile card can't drift apart on what a button does.
class SalesActions {
  const SalesActions._();

  static void view(BuildContext context, SalesOrder order) {
    Get.dialog(
      SaleDetailsDialog(
        order: order,
        onDelete: () {
          Get.back();
          delete(context, order);
        },
      ),
    );
  }

  /// Opens the same form Add Sale uses, pre-filled from this order; saving
  /// updates it in place.
  static void edit(SalesOrder order) =>
      Get.toNamed(AppRoutes.addSale, arguments: order);

  /// Opens Add Sale pre-filled from this order but as a new draft — saving
  /// creates a new record and never touches the one duplicated from.
  static void duplicate(SalesOrder order) =>
      Get.toNamed(AppRoutes.addSale, arguments: DuplicateSalesOrder(order));

  /// Mobile-only shortcut the web table has no room for.
  static void updateStatus(SalesOrder order) =>
      Get.dialog(UpdateSalesStatusDialog(order: order));

  static void delete(BuildContext context, SalesOrder order) => confirmDelete(
    context,
    itemName: order.soNumber,
    itemLabel: 'Sales Order',
    onConfirm: () => Get.find<SalesController>().deleteOrder(order.id),
  );
}

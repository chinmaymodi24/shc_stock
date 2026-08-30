import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/clients/controllers/add_client_controller.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/clients/views/client_details_dialog.dart';
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';

/// The four row actions a client supports, defined once so the web table and
/// the mobile card can't drift apart on what a button does.
class ClientActions {
  const ClientActions._();

  static void view(BuildContext context, ClientModel client) {
    Get.dialog(
      ClientDetailsDialog(
        client: client,
        onDelete: () {
          Get.back();
          delete(context, client);
        },
      ),
    );
  }

  /// Opens Add Client on this record; saving updates it in place.
  static void edit(ClientModel client) =>
      Get.toNamed(AppRoutes.addClient, arguments: EditClient(client));

  /// Opens Add Client pre-filled from this client but as a new draft — saving
  /// creates a new client and never touches the one duplicated from.
  static void duplicate(ClientModel client) =>
      Get.toNamed(AppRoutes.addClient, arguments: client);

  static void delete(BuildContext context, ClientModel client) => confirmDelete(
    context,
    itemName: client.name,
    itemLabel: 'Client',
    onConfirm: () => Get.find<ClientsController>().deleteClient(client.id),
  );
}

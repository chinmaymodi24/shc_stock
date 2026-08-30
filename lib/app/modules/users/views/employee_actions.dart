import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/routes/app_routes.dart';
import 'package:shc_stock/app/modules/users/controllers/add_employee_wizard_controller.dart';
import 'package:shc_stock/app/modules/users/controllers/users_controller.dart';
import 'package:shc_stock/app/modules/users/models/user_model.dart';
import 'package:shc_stock/app/modules/users/views/employee_details_dialog.dart';
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';

/// The four row actions an employee supports, defined once so the web table
/// and the mobile card can't drift apart on what a button does.
class EmployeeActions {
  const EmployeeActions._();

  static void view(BuildContext context, UserModel user) {
    Get.dialog(
      EmployeeDetailsDialog(
        user: user,
        onEdit: () {
          Get.back();
          edit(user);
        },
        onDelete: () {
          Get.back();
          delete(context, user);
        },
      ),
    );
  }

  /// Opens the Add Employee wizard on this record; finishing updates it in
  /// place.
  static void edit(UserModel user) =>
      Get.toNamed(AppRoutes.addEmployee, arguments: EditEmployee(user));

  /// Opens the wizard pre-filled from this employee but as a new draft — the
  /// email is cleared because it is the unique login.
  static void duplicate(UserModel user) =>
      Get.toNamed(AppRoutes.addEmployee, arguments: user);

  static void delete(BuildContext context, UserModel user) => confirmDelete(
    context,
    itemName: user.name,
    itemLabel: 'Employee',
    onConfirm: () => Get.find<UsersController>().deleteUser(user.id),
  );
}

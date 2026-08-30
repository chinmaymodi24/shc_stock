import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/transactions/controllers/transactions_controller.dart';
import 'package:shc_stock/app/modules/transactions/models/transaction_model.dart';
import 'package:shc_stock/app/modules/transactions/views/transaction_form_dialog.dart';
import 'package:shc_stock/app/shared/widgets/confirm_delete_dialog.dart';

/// The four row actions a transaction supports, defined once so the web table
/// and the mobile card can't drift apart on what a button does.
class TransactionActions {
  const TransactionActions._();

  /// The same form, rendered non-interactive — a transaction has no fields
  /// beyond what the form already shows, so a separate details screen would
  /// only be a second copy to keep in sync.
  static void view(TransactionModel txn) =>
      Get.dialog(TransactionFormDialog(existing: txn, readOnly: true));

  static void edit(TransactionModel txn) =>
      Get.dialog(TransactionFormDialog(existing: txn));

  /// Pre-fills the form from this transaction but saves as a new record.
  static void duplicate(TransactionModel txn) =>
      Get.dialog(TransactionFormDialog(existing: txn, duplicate: true));

  static void delete(BuildContext context, TransactionModel txn) =>
      confirmDelete(
        context,
        itemName: txn.item,
        itemLabel: 'Transaction',
        onConfirm: () =>
            Get.find<TransactionsController>().deleteTransaction(txn.id),
      );
}

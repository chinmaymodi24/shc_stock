import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/purchase/controllers/purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/models/purchase_model.dart';
import 'package:shc_stock/app/shared/widgets/status_update_dialog_shell.dart';

/// "Update Status" dialog for a purchase order, wired to
/// PurchaseController.updateStatus (PATCH /purchase-orders/:id/status).
///
/// Shared between web and mobile layouts — public (not per-file private) so
/// both can open the exact same dialog instead of two hand-rolled copies.
class UpdatePurchaseStatusDialog extends StatefulWidget {
  final PurchaseOrder order;
  const UpdatePurchaseStatusDialog({super.key, required this.order});

  @override
  State<UpdatePurchaseStatusDialog> createState() =>
      _UpdatePurchaseStatusDialogState();
}

class _UpdatePurchaseStatusDialogState
    extends State<UpdatePurchaseStatusDialog> {
  late final Rx<PurchaseStatus> _selected = widget.order.status.obs;

  @override
  void dispose() {
    _selected.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatusUpdateDialogShell(
      title: 'Update Status',
      subtitle: widget.order.poNumber,
      onSave: () => Get.find<PurchaseController>().updateStatus(
        widget.order.id,
        _selected.value,
      ),
      body: StatusRadioGroup<PurchaseStatus>(
        options: PurchaseStatus.values,
        selected: _selected,
        labelOf: (s) => s.label,
      ),
    );
  }
}

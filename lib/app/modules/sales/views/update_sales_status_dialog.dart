import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';
import 'package:shc_stock/app/shared/widgets/status_update_dialog_shell.dart';

/// "Update Status" dialog for a sales order (order status + payment
/// status), wired to SalesController.updateStatus (PATCH
/// /sales-orders/:id/status).
///
/// Shared between web and mobile layouts — public (not per-file private) so
/// both can open the exact same dialog instead of two hand-rolled copies.
class UpdateSalesStatusDialog extends StatefulWidget {
  final SalesOrder order;
  const UpdateSalesStatusDialog({super.key, required this.order});

  @override
  State<UpdateSalesStatusDialog> createState() =>
      _UpdateSalesStatusDialogState();
}

class _UpdateSalesStatusDialogState extends State<UpdateSalesStatusDialog> {
  late final Rx<SalesStatus> _status = widget.order.status.obs;
  late final Rx<PaymentStatus> _payment = widget.order.paymentStatus.obs;

  @override
  void dispose() {
    _status.close();
    _payment.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StatusUpdateDialogShell(
      title: 'Update Status',
      subtitle: widget.order.soNumber,
      width: 360,
      onSave: () => Get.find<SalesController>().updateStatus(
        widget.order.id,
        status: _status.value,
        paymentStatus: _payment.value,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusRadioGroup<SalesStatus>(
            label: 'Order Status',
            options: SalesStatus.values,
            selected: _status,
            labelOf: (s) => s.label,
          ),
          const SizedBox(height: 10),
          StatusRadioGroup<PaymentStatus>(
            label: 'Payment Status',
            options: PaymentStatus.values,
            selected: _payment,
            labelOf: (p) => p.label,
          ),
        ],
      ),
    );
  }
}

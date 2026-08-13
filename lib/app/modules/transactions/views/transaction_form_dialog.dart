import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/transactions/controllers/transactions_controller.dart';
import 'package:shc_stock/app/modules/transactions/models/transaction_model.dart';
import 'package:shc_stock/app/shared/widgets/form_fields.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit Transaction.
//
// One dialog serves both: pass [existing] to edit, omit it to create. Saving
// goes straight to the API through TransactionsController, which refreshes the
// list and the summary cards.
// ─────────────────────────────────────────────────────────────────────────────
class TransactionFormDialog extends StatefulWidget {
  final TransactionModel? existing;
  const TransactionFormDialog({super.key, this.existing});

  bool get isEdit => existing != null;

  @override
  State<TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<TransactionFormDialog> {
  static const _types = ['Inbound', 'Outbound'];
  static const _statuses = ['Pending', 'Received', 'Shipped', 'Delivered'];

  late final TextEditingController _item;
  late final TextEditingController _party;
  late final TextEditingController _po;
  late final TextEditingController _notes;

  late final RxString _type;
  late final RxString _status;
  late final Rx<DateTime> _date;
  final _saving = false.obs;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _item = TextEditingController(text: e?.item ?? '');
    _party = TextEditingController(text: e?.party ?? '');
    _po = TextEditingController(text: e?.poNumber ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _type = (e?.typeLabel ?? 'Inbound').obs;
    _status = (e?.statusLabel ?? 'Pending').obs;
    _date = (e?.date ?? DateTime.now()).obs;
  }

  @override
  void dispose() {
    for (final c in [_item, _party, _po, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) _date.value = picked;
  }

  Future<void> _save() async {
    if (_item.text.trim().isEmpty) {
      showAppToast(
        'Validation Error',
        'Item is required.',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final c = Get.find<TransactionsController>();
    final body = {
      'item': _item.text.trim(),
      'type': _type.value,
      'party': _party.text.trim(),
      'poNumber': _po.text.trim(),
      'date': _date.value.toIso8601String(),
      'status': _status.value,
      'notes': _notes.text.trim(),
    };

    _saving.value = true;
    final saved = widget.isEdit
        ? await c.updateTransaction(widget.existing!.id, body)
        : await c.addTransaction(body);
    _saving.value = false;

    // The controller already surfaced the API error — keep the dialog open so
    // the entered details aren't lost.
    if (saved == null) return;
    Get.back();
    showAppToast(
      widget.isEdit ? '✅ Transaction Updated' : '✅ Transaction Added',
      '${saved.item} has been saved.',
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEdit ? 'Edit Transaction' : 'New Transaction',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 18),

              AppField(
                label: 'Item',
                required: true,
                colors: colors,
                child: AppTextBox(
                  controller: _item,
                  hint: 'e.g. Copper Pipe 15mm',
                  colors: colors,
                ),
              ),
              const SizedBox(height: 14),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppField(
                      label: 'Type',
                      colors: colors,
                      child: Obx(
                        () => AppDropBox(
                          hint: 'Select type',
                          value: _type.value,
                          items: _types,
                          colors: colors,
                          onChanged: (v) => _type.value = v ?? 'Inbound',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AppField(
                      label: 'Status',
                      colors: colors,
                      child: Obx(
                        () => AppDropBox(
                          hint: 'Select status',
                          value: _status.value,
                          items: _statuses,
                          colors: colors,
                          onChanged: (v) => _status.value = v ?? 'Pending',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppField(
                      label: 'Party',
                      colors: colors,
                      child: AppTextBox(
                        controller: _party,
                        hint: 'Supplier or client',
                        colors: colors,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AppField(
                      label: 'PO #',
                      colors: colors,
                      child: AppTextBox(
                        controller: _po,
                        hint: 'e.g. #4421',
                        colors: colors,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              AppField(
                label: 'Date',
                required: true,
                colors: colors,
                child: Obx(
                  () => AppDateBox(
                    date: _date.value,
                    colors: colors,
                    onTap: _pickDate,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              AppField(
                label: 'Notes',
                colors: colors,
                child: AppTextBox(
                  controller: _notes,
                  hint: 'Optional',
                  colors: colors,
                ),
              ),
              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontFamily: 'Poppins',
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Obx(
                    () => ElevatedButton(
                      onPressed: _saving.value ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        disabledBackgroundColor: AppColors.primaryOrange
                            .withValues(alpha: 0.6),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_saving.value) ...[
                            const SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _saving.value
                                ? 'Saving…'
                                : (widget.isEdit ? 'Save Changes' : 'Add'),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

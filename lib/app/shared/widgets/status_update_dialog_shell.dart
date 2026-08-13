import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

/// Shared chrome for "update status"-style dialogs (title, subtitle,
/// scrollable body, Cancel/Update footer with a loading spinner).
///
/// Callers supply the actual fields (radio groups, etc.) as [body] and the
/// save logic as [onSave]; this widget owns the saving spinner state and
/// closes itself on success. Used by Purchase's and Sales' row-level
/// "update status" dialogs so the surrounding dialog shell isn't duplicated
/// between them — only the status options differ.
class StatusUpdateDialogShell extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget body;
  final Future<void> Function() onSave;
  final double width;

  const StatusUpdateDialogShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.onSave,
    this.width = 340,
  });

  @override
  State<StatusUpdateDialogShell> createState() =>
      _StatusUpdateDialogShellState();
}

class _StatusUpdateDialogShellState extends State<StatusUpdateDialogShell> {
  final _saving = false.obs;

  @override
  void dispose() {
    _saving.close();
    super.dispose();
  }

  Future<void> _save() async {
    _saving.value = true;
    await widget.onSave();
    _saving.value = false;
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 16),
                widget.body,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: Get.back,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: colors.background.computeLuminance() > 0.5
                                ? const Color(0xFFF3F1EC)
                                : colors.inputFill,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Cancel',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Obx(
                        () => InkWell(
                          onTap: _saving.value ? null : _save,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _saving.value
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Update',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single radio-button group used inside [StatusUpdateDialogShell.body]
/// (e.g. "Order Status", "Payment Status"). Reactive on its own via [Obx] —
/// pass an [Rx] and this rebuilds itself when it changes.
class StatusRadioGroup<T> extends StatelessWidget {
  final String? label;
  final List<T> options;
  final Rx<T> selected;
  final String Function(T) labelOf;

  const StatusRadioGroup({
    super.key,
    this.label,
    required this.options,
    required this.selected,
    required this.labelOf,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Text(
            label!,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
        Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map(
                  (o) => RadioListTile<T>(
                    value: o,
                    groupValue: selected.value,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primaryOrange,
                    title: Text(
                      labelOf(o),
                      style: TextStyle(
                        fontSize: 13.5,
                        color: colors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    onChanged: (v) => selected.value = v as T,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

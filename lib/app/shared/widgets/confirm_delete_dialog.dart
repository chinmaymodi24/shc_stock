import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

/// Shared "Are you sure?" dialog for every destructive delete in the app.
///
/// Every screen with a delete action must confirm before calling the
/// controller's delete method — never wire a delete icon/button straight to
/// `deleteX(...)`. Use this instead of hand-rolling another delete dialog.
///
/// Usage:
/// ```dart
/// onTap: () => confirmDelete(
///   context,
///   itemName: client.name,
///   itemLabel: 'Client',
///   onConfirm: () => controller.deleteClient(client.id),
/// ),
/// ```
Future<void> confirmDelete(
  BuildContext context, {
  required String itemName,
  required VoidCallback onConfirm,
  String itemLabel = 'item',
  String? message,
}) {
  return Get.dialog(
    _ConfirmDeleteDialog(
      itemName: itemName,
      itemLabel: itemLabel,
      message: message,
      onConfirm: onConfirm,
    ),
  );
}

class _ConfirmDeleteDialog extends StatelessWidget {
  final String itemName;
  final String itemLabel;
  final String? message;
  final VoidCallback onConfirm;

  const _ConfirmDeleteDialog({
    required this.itemName,
    required this.itemLabel,
    required this.message,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460, minWidth: 320),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 36,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: colors.error,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Delete $itemLabel?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: Get.back,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors.comingSoonBadge,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Divider(height: 1, color: colors.divider),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                            fontFamily: 'Poppins',
                            height: 1.55,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  message ??
                                  'Are you sure you want to permanently delete ',
                            ),
                            if (message == null) ...[
                              TextSpan(
                                text: '"$itemName"',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const TextSpan(
                                text: '? This action cannot be undone.',
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: Get.back,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colors.border),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Get.back();
                              onConfirm();
                            },
                            icon: const Icon(
                              Icons.delete_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            label: const Text(
                              'Yes, Delete',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/dashboard/models/dashboard_models.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'notes_todo.dart';

/// "View All" dialog for the Notes & To-dos card — shows every note in a
/// scrollable list, with the same checkbox/add-note controls as the card.
class NotesDialog extends StatelessWidget {
  final RxList<NoteItem> notes;
  final void Function(int index) onToggle;
  final void Function(String text) onAdd;

  const NotesDialog({
    super.key,
    required this.notes,
    required this.onToggle,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, minWidth: 320),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
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
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.checklist_rounded,
                          color: AppColors.primaryOrange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notes & To-dos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Obx(
                              () => Text(
                                '${notes.length} notes',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: colors.textSecondary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: Get.back,
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
                  padding: const EdgeInsets.only(top: 20),
                  child: Divider(height: 1, color: colors.divider),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5,
                    ),
                    child: SingleChildScrollView(
                      child: NotesTodo(
                        notes: notes,
                        onToggle: onToggle,
                        onAdd: onAdd,
                      ),
                    ),
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

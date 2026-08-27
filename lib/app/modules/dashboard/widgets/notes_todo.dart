import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/dashboard/models/dashboard_models.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

class NotesTodo extends StatefulWidget {
  final RxList<NoteItem> notes;
  final void Function(int index) onToggle;
  final void Function(String text) onAdd;
  final void Function(int index)? onDelete;

  const NotesTodo({
    super.key,
    required this.notes,
    required this.onToggle,
    required this.onAdd,
    this.onDelete,
  });

  @override
  State<NotesTodo> createState() => _NotesTodoState();
}

class _NotesTodoState extends State<NotesTodo> {
  final _controller = TextEditingController();
  final _hoveredIndex = RxInt(-1);

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(
          () => Column(
            children: widget.notes.asMap().entries.map((e) {
              final index = e.key;
              final note = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => _hoveredIndex.value = index,
                  onExit: (_) =>
                      _hoveredIndex.value == index
                          ? _hoveredIndex.value = -1
                          : null,
                  child: InkWell(
                    mouseCursor: SystemMouseCursors.click,
                    onTap: () => widget.onToggle(index),
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: Checkbox(
                            value: note.done,
                            onChanged: (_) => widget.onToggle(index),
                            activeColor: AppColors.primaryOrange,
                            checkColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: BorderSide(
                              color: colors.textSecondary,
                              width: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            note.text,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: note.done
                                  ? colors.textSecondary
                                  : colors.textPrimary,
                              decoration: note.done
                                  ? TextDecoration.lineThrough
                                  : null,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        if (widget.onDelete != null)
                          Obx(
                            () => _hoveredIndex.value == index
                                ? InkWell(
                                    mouseCursor: SystemMouseCursors.click,
                                    borderRadius: BorderRadius.circular(4),
                                    onTap: () => widget.onDelete!(index),
                                    child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  )
                                : const SizedBox(width: 20),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: colors.tagBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _controller,
            onSubmitted: (_) => _submit(),
            style: TextStyle(
              fontSize: 13,
              color: colors.textPrimary,
              fontFamily: 'Poppins',
            ),
            decoration: InputDecoration(
              hintText: '+ Add a note...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                fontFamily: 'Poppins',
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

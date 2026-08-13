import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/dashboard/models/dashboard_models.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

class NotesTodo extends StatefulWidget {
  final RxList<NoteItem> notes;
  final void Function(int index) onToggle;
  final void Function(String text) onAdd;

  const NotesTodo({
    super.key,
    required this.notes,
    required this.onToggle,
    required this.onAdd,
  });

  @override
  State<NotesTodo> createState() => _NotesTodoState();
}

class _NotesTodoState extends State<NotesTodo> {
  final _controller = TextEditingController();

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
                child: InkWell(
                  onTap: () => widget.onToggle(index),
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
                    ],
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

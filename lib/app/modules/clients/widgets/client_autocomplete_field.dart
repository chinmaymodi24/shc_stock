import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Client autocomplete — typing filters the universal client list by name;
// arrow keys + Enter navigate/select (native Autocomplete keyboard handling);
// selecting an option hands the full ClientModel back via onSelected so the
// caller can fill address/state/GSTIN/PAN fields from it.
// ─────────────────────────────────────────────────────────────────────────────
class ClientAutocompleteField extends StatelessWidget {
  final String initialValue;
  final AppThemeColors colors;
  final ValueChanged<ClientModel> onSelected;
  final String hint;
  final Widget? suffixIcon;

  const ClientAutocompleteField({
    super.key,
    required this.initialValue,
    required this.colors,
    required this.onSelected,
    this.hint = 'Type to search client...',
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final clients = Get.find<ClientsController>().clients;
    return Autocomplete<ClientModel>(
      displayStringForOption: (c) => c.name,
      optionsBuilder: (textEditingValue) {
        final q = textEditingValue.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<ClientModel>.empty();
        return clients.where((c) => c.name.toLowerCase().contains(q)).take(30);
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        if (controller.text.isEmpty && initialValue.isNotEmpty) {
          controller.text = initialValue;
        }
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: (_) => onSubmit(),
          style: TextStyle(
            fontSize: 13,
            color: colors.textPrimary,
            fontFamily: 'Poppins',
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: colors.textHint,
              fontFamily: 'Poppins',
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            filled: true,
            fillColor: colors.surface,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primaryOrange,
                width: 1.5,
              ),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelect, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            color: colors.surface,
            child: Container(
              width: 380,
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final c = options.elementAt(index);
                  final highlighted =
                      AutocompleteHighlightedOption.of(context) == index;
                  if (highlighted) {
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      Scrollable.ensureVisible(context, alignment: 0.5);
                    });
                  }
                  final subtitle = [
                    if (c.state.isNotEmpty) c.state,
                    c.gstin.isNotEmpty ? c.gstin : 'Unregistered',
                  ].join(' · ');
                  return Container(
                    color: highlighted
                        ? AppColors.primaryOrange.withValues(alpha: 0.1)
                        : null,
                    child: InkWell(
                      onTap: () => onSelect(c),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                                fontFamily: 'Poppins',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textHint,
                                fontFamily: 'Poppins',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

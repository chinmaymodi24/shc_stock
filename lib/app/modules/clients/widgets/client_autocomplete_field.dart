import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/shared/widgets/overlay_autocomplete_field.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Client typeahead — typing filters the universal client list by name;
// selecting an option hands the full ClientModel back via onSelected so the
// caller can fill address/state/GSTIN/PAN from it.
//
// Built on [OverlayAutocompleteField] rather than the framework's
// `Autocomplete`: that one always drops its list below the field, which put it
// behind the soft keyboard on the mobile Add Purchase / Add Sale forms — the
// suggestions were there but invisible. See that widget for the full story.
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
    return OverlayAutocompleteField<ClientModel>(
      initialValue: initialValue,
      colors: colors,
      maxDropdownHeight: 280,
      optionsFor: (query) {
        final q = query.toLowerCase();
        return clients
            .where((c) => c.name.toLowerCase().contains(q))
            .take(30)
            .toList();
      },
      displayStringFor: (c) => c.name,
      onSelected: onSelected,
      textStyle: TextStyle(
        fontSize: 13,
        color: colors.textPrimary,
        fontFamily: brandFontFamily,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: colors.textHint,
          fontFamily: brandFontFamily,
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
          borderSide: BorderSide(color: AppColors.primaryOrange, width: 1.5),
        ),
      ),
      optionBuilder: (context, c, highlighted) {
        final subtitle = [
          if (c.state.isNotEmpty) c.state,
          c.gstin.isNotEmpty ? c.gstin : 'Unregistered',
        ].join(' · ');
        return Container(
          color: highlighted
              ? AppColors.primaryOrange.withValues(alpha: 0.1)
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                  fontFamily: brandFontFamily,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textHint,
                  fontFamily: brandFontFamily,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

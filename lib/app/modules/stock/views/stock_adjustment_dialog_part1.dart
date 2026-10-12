part of 'stock_adjustment_dialog.dart';

/// Item search — typing filters the loaded inventory list by name or SKU;
/// selecting an option hands the full [StockItemModel] back. Mirrors
/// ClientAutocompleteField's pattern (Flutter's built-in Autocomplete, so
/// arrow keys + Enter just work).
class _ItemAutocomplete extends StatelessWidget {
  final AppThemeColors colors;
  final ValueChanged<StockItemModel> onSelected;
  final ValueChanged<String> onTextChanged;

  const _ItemAutocomplete({
    required this.colors,
    required this.onSelected,
    required this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = Get.find<StockController>().items;
    return Autocomplete<StockItemModel>(
      displayStringForOption: (i) => i.name,
      optionsBuilder: (textEditingValue) {
        final q = textEditingValue.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<StockItemModel>.empty();
        return items
            .where(
              (i) =>
                  i.name.toLowerCase().contains(q) ||
                  i.sku.toLowerCase().contains(q),
            )
            .take(30);
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, textCtrl, focusNode, onSubmit) {
        return TextField(
          controller: textCtrl,
          focusNode: focusNode,
          onSubmitted: (_) => onSubmit(),
          onChanged: onTextChanged,
          style: TextStyle(
            fontSize: 13,
            color: colors.textPrimary,
            fontFamily: brandFontFamily,
          ),
          decoration: InputDecoration(
            hintText: 'Type item name or SKU...',
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
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 18,
              color: colors.textHint,
            ),
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
              borderSide: BorderSide(
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
            borderRadius: BorderRadius.circular(appColors.radius),
            color: colors.surface,
            child: Container(
              width: 432,
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(appColors.radius),
                border: Border.all(color: colors.border),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final item = options.elementAt(index);
                  final highlighted =
                      AutocompleteHighlightedOption.of(context) == index;
                  if (highlighted) {
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      Scrollable.ensureVisible(context, alignment: 0.5);
                    });
                  }
                  return Container(
                    color: highlighted
                        ? AppColors.primaryOrange.withValues(alpha: 0.1)
                        : null,
                    child: InkWell(
                      onTap: () => onSelect(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                  fontFamily: brandFontFamily,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'Current stock: ${fmtStockQty(item.stockInHand)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textHint,
                                fontFamily: brandFontFamily,
                              ),
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

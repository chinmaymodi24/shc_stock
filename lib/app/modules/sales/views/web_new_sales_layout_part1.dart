part of 'web_new_sales_layout.dart';

class _ItemDetailsTable extends StatelessWidget {
  final List<SaleItemRow> items;
  final SaleStockGuard guard;
  final AppThemeColors colors;
  final VoidCallback onChanged;
  final void Function(int) onDelete;

  const _ItemDetailsTable({
    required this.items,
    required this.guard,
    required this.colors,
    required this.onChanged,
    required this.onDelete,
  });

  TextStyle get _h => TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: colors.textSecondary,
    fontFamily: brandFontFamily,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: colors.rowEven,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                flex: _iItemFlex,
                child: Text('Item (type to search)', style: _h),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: _iHsnWidth,
                child: Text('HSN/SAC', style: _h, textAlign: TextAlign.center),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: _iQtyWidth,
                child: Text('Quantity', style: _h, textAlign: TextAlign.center),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: _iUomWidth,
                child: Text('UoM', style: _h, textAlign: TextAlign.center),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: _iRateWidth,
                child: Text('Rate', style: _h, textAlign: TextAlign.right),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: _iAmtWidth,
                child: Text('Amount', style: _h, textAlign: TextAlign.right),
              ),
              SizedBox(width: _iDelWidth),
            ],
          ),
        ),
        Divider(height: 1, color: colors.divider),
        ...items.asMap().entries.map(
          (e) => _ItemDetailsRow(
            row: e.value,
            guard: guard,
            colors: colors,
            onChanged: onChanged,
            onDelete: () => onDelete(e.key),
          ),
        ),
      ],
    );
  }
}

class _ItemDetailsRow extends StatelessWidget {
  final SaleItemRow row;
  final SaleStockGuard guard;
  final AppThemeColors colors;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _ItemDetailsRow({
    required this.row,
    required this.guard,
    required this.colors,
    required this.onChanged,
    required this.onDelete,
  });

  /// A name typed over (or instead of) a picked product: the line is now a
  /// hand-typed one, so it is no longer tied to a product.
  void _typeName(String text) {
    row.product = text;
    row.productId = null;
    // A typed line is not a product: the usual 18% applies.
    row.taxPercent = kDefaultGstRate;
    onChanged();
  }

  void _applyProduct(ProductModel p) {
    // Nothing left to sell: the dropdown already refuses it, this is the
    // backstop for any other way a pick could arrive.
    if (guard.unavailableReason(p) != null) return;
    row.productId = int.tryParse(p.id);
    row.product = p.name;
    row.taxPercent = p.taxPercent;
    row.hsn = p.hsnCode ?? '';
    row.unit = p.unit;
    row.rate = p.sellingPrice;
    // A fresh row starts at qty 0, which pinned the line — and the invoice
    // total — to ₹0 until a quantity was typed; the picked product should
    // price itself straight away.
    if (row.qty == 0) row.qty = 1;
    // Re-seeds the HSN / UoM / Rate boxes below, which otherwise keep the
    // text they were first built with.
    row.version++;
    onChanged();
    // Say so the moment it's picked, not only when Save is pressed.
    final problem =
        guard.errorFor(row.productId) ?? guard.lowNoteFor(row.productId);
    if (problem != null) {
      showAppToast(
        guard.errorFor(row.productId) != null ? 'Not in stock' : 'Low stock',
        problem,
        backgroundColor: guard.errorFor(row.productId) != null
            ? AppColors.danger
            : AppColors.warning,
        colorText: Colors.white,
      );
    }
  }

  /// A quantity can't pass what inventory holds: a ± tap or typed number over
  /// the limit is pulled back to it, with a message saying why.
  void _setQty(double v) {
    final max = guard.maxQtyFor(row.productId, thisLineQty: row.qty);
    if (max != null && v > max) {
      row.qty = max;
      showAppToast(
        'Not enough stock',
        guard.limitMessage(row.productId),
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
      );
    } else {
      row.qty = v;
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final error = guard.errorFor(row.productId);
    final note = guard.lowNoteFor(row.productId);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.divider, width: 0.8)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fields(),
          StockMessage(error: error, note: note, colors: colors),
        ],
      ),
    );
  }

  Widget _fields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: _iItemFlex,
          child: _ProductAutocomplete(
            initialValue: row.product,
            colors: colors,
            onSelected: _applyProduct,
            onTyped: _typeName,
            blockReason: guard.unavailableReason,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: _iHsnWidth,
          child: AppSmallInput(
            key: ValueKey('${row.id}_hsn_${row.version}'),
            hint: 'HSN/SAC',
            value: row.hsn,
            colors: colors,
            center: true,
            onChanged: (v) {
              row.hsn = v;
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: _iQtyWidth,
          // Editable with ± steppers, same as the purchase form.
          child: AppSmallStepper(
            value: row.qty,
            colors: colors,
            onChanged: _setQty,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: _iUomWidth,
          child: AppSmallInput(
            key: ValueKey('${row.id}_uom_${row.version}'),
            hint: 'UoM',
            value: row.unit,
            colors: colors,
            center: true,
            onChanged: (v) {
              row.unit = v;
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: _iRateWidth,
          child: AppSmallNumber(
            key: ValueKey('${row.id}_rate_${row.version}'),
            value: row.rate,
            colors: colors,
            decimal: true,
            onChanged: (v) {
              row.rate = v;
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: _iAmtWidth,
          child: Text(
            '₹${row.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              fontFamily: brandFontFamily,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        SizedBox(
          width: _iDelWidth,
          child: IconButton(
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            icon: Icon(Icons.close_rounded, color: AppColors.danger, size: 16),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product autocomplete — typing filters ProductsController by name; selecting
// an option fetches its HSN/SAC, unit and rate into the row.
// ─────────────────────────────────────────────────────────────────────────────
class _ProductAutocomplete extends StatelessWidget {
  final String initialValue;
  final AppThemeColors colors;
  final ValueChanged<ProductModel> onSelected;
  final ValueChanged<String>? onTyped;

  /// Why a product cannot be picked (nothing left to sell), or null. Such a
  /// product stays listed, greyed with the reason, and picking it does nothing.
  final String? Function(ProductModel product)? blockReason;

  const _ProductAutocomplete({
    required this.initialValue,
    required this.colors,
    required this.onSelected,
    this.onTyped,
    this.blockReason,
  });

  @override
  Widget build(BuildContext context) {
    final products = Get.find<ProductsController>().products;
    // The framework's Autocomplete writes a chosen option's name into the
    // field before calling onSelected, so a refused pick has to put back what
    // was typed.
    TextEditingController? fieldController;
    var typed = initialValue;
    return Autocomplete<ProductModel>(
      displayStringForOption: (p) => p.name,
      optionsBuilder: (textEditingValue) {
        final q = textEditingValue.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<ProductModel>.empty();
        return products
            .where((p) => p.isActive && p.name.toLowerCase().contains(q))
            .take(30);
      },
      onSelected: (p) {
        if (blockReason?.call(p) != null) {
          final c = fieldController;
          if (c != null) {
            c.value = TextEditingValue(
              text: typed,
              selection: TextSelection.collapsed(offset: typed.length),
            );
          }
          return;
        }
        onSelected(p);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        fieldController = controller;
        if (controller.text.isEmpty && initialValue.isNotEmpty) {
          controller.text = initialValue;
        }
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: (t) {
            typed = t;
            onTyped?.call(t);
          },
          onSubmitted: (_) => onSubmit(),
          style: TextStyle(
            fontSize: 12.5,
            color: colors.textPrimary,
            fontFamily: brandFontFamily,
          ),
          decoration: InputDecoration(
            hintText: 'Type e.g. Ceramic Fiber Blanket 1260...',
            hintStyle: TextStyle(
              fontSize: 12,
              color: colors.textHint,
              fontFamily: brandFontFamily,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            filled: true,
            fillColor: colors.surface,
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 15,
              color: colors.textHint,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: AppColors.primaryOrange,
                width: 1.2,
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
              width: 380,
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
                  final p = options.elementAt(index);
                  final blocked = blockReason?.call(p);
                  final highlighted =
                      AutocompleteHighlightedOption.of(context) == index &&
                      blocked == null;
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
                      onTap: blocked == null ? () => onSelect(p) : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colors.textPrimary,
                                      fontFamily: brandFontFamily,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'HSN ${p.hsnCode ?? '—'} · ${p.unit}',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colors.textHint,
                                            fontFamily: brandFontFamily,
                                          ),
                                        ),
                                      ),
                                      if (blocked == null) ...[
                                        const SizedBox(width: 8),
                                        StockBadge(product: p, colors: colors),
                                      ],
                                    ],
                                  ),
                                  if (blocked != null) ...[
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline_rounded,
                                          size: 12,
                                          color: AppColors.danger,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            blocked,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.danger,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              '₹${p.sellingPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary,
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

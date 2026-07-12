import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';
import '../../../core/theme/app_colors.dart';

class CategoryBreakdown extends StatelessWidget {
  final List<CategorySlice> categories;

  const CategoryBreakdown({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: categories
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _CategoryRow(slice: c),
              ))
          .toList(),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategorySlice slice;
  const _CategoryRow({required this.slice});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(slice.label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: colors.textPrimary, fontFamily: 'Poppins')),
            Text('${slice.percent.toStringAsFixed(0)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary, fontFamily: 'Poppins')),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: slice.percent / 100,
            minHeight: 6,
            backgroundColor: colors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(slice.color),
          ),
        ),
      ],
    );
  }
}

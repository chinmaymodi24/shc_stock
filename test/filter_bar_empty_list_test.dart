import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/shared/widgets/filter_bar.dart';
import 'package:shc_stock/app/shared/widgets/mobile_filter_sheet.dart';

// An empty list has nothing to filter: the pills (Client, Category, Sort…)
// stay out of the toolbar until the list has records, and come back as soon as
// one is added. Search and Export are not pills and are not affected.
void main() {
  tearDown(Get.reset);

  Widget host(Widget child) => GetMaterialApp(
    theme: ThemeData(extensions: [AppThemeColors.light]),
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('web FilterBar hides its pills while the list is empty', (
    tester,
  ) async {
    final rows = <String>[].obs;
    await tester.pumpWidget(
      host(
        FilterBar(
          pillsVisible: () => rows.isNotEmpty,
          search: FilterSearchField(hint: 'Search', onChanged: (_) {}),
          pills: [
            MultiSelectFilterPill(
              label: 'Client',
              items: const ['A'],
              selected: <String>{}.obs,
              onToggle: (_) {},
            ),
          ],
        ),
      ),
    );
    expect(find.text('Client'), findsNothing);
    expect(find.text('Search'), findsOneWidget);

    rows.add('first record');
    await tester.pump();
    expect(find.text('Client'), findsOneWidget);
  });

  testWidgets('a FilterBar without pillsVisible always shows its pills', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        FilterBar(
          search: FilterSearchField(hint: 'Search', onChanged: (_) {}),
          pills: [
            MultiSelectFilterPill(
              label: 'Client',
              items: const ['A'],
              selected: <String>{}.obs,
              onToggle: (_) {},
            ),
          ],
        ),
      ),
    );
    expect(find.text('Client'), findsOneWidget);
  });

  testWidgets('mobile filter icon follows the same rule', (tester) async {
    await tester.pumpWidget(
      host(const MobileFilterButton(filters: [], visible: false)),
    );
    expect(find.byType(IconButton), findsNothing);

    await tester.pumpWidget(host(const MobileFilterButton(filters: [])));
    expect(find.byType(IconButton), findsOneWidget);
  });
}

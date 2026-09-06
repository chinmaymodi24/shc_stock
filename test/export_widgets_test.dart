import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/export/export_service.dart';
import 'package:shc_stock/app/core/export/export_source.dart';
import 'package:shc_stock/app/core/export/export_table.dart';
import 'package:shc_stock/app/core/export/statement.dart';
import 'package:shc_stock/app/core/theme/app_theme.dart';
import 'package:shc_stock/app/modules/reports/models/report_catalog.dart';
import 'package:shc_stock/app/modules/reports/models/report_period.dart';
import 'package:shc_stock/app/modules/reports/views/reports_catalog_view.dart';
import 'package:shc_stock/app/modules/reports/widgets/statement_sheet.dart';
import 'package:shc_stock/app/shared/widgets/export/export_dialog.dart';
import 'package:shc_stock/app/shared/widgets/export/export_menu_button.dart';
import 'package:shc_stock/app/shared/widgets/export/list_scope_bar.dart';

class _Row {
  final String name;
  const _Row(this.name);
}

ExportEntityConfig<_Row> _config({
  int total = 611,
  int shown = 248,
  int selected = 0,
}) {
  final all = [for (var i = 0; i < total; i++) _Row('Item $i')];
  return ExportEntityConfig<_Row>(
    entityKey: 'products',
    entityLabel: 'Products',
    rowNoun: 'products',
    allRows: () => all,
    filteredRows: () => all.take(shown).toList(),
    selectedRows: () => all.take(selected).toList(),
    defaultColumnKeys: const ['name'],
    presets: const [
      ExportColumnPreset('Price list', ['name', 'sku']),
    ],
    allColumns: [
      ExportColumn(key: 'name', label: 'Product', value: (r) => r.name),
      ExportColumn(key: 'sku', label: 'SKU', value: (r) => r.name),
      ExportColumn(
        key: 'price',
        label: 'Price',
        type: ExportCellType.money,
        value: (_) => 100,
      ),
    ],
  );
}

Widget _host(Widget child) => GetMaterialApp(
  theme: AppTheme.lightTheme,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  setUp(() {
    Get.reset();
    Get.put(ExportService());
  });
  tearDown(Get.reset);

  group('ExportMenuButton', () {
    testWidgets('reads "Export", and names the filtered count once open', (
      tester,
    ) async {
      await tester.pumpWidget(_host(ExportMenuButton(source: _config())));
      expect(find.text('Export'), findsOneWidget);

      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();

      expect(find.text('DOWNLOAD 248 FILTERED'), findsOneWidget);
      expect(find.text('Excel (.xlsx)'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('More options…'), findsOneWidget);
    });

    testWidgets('a selection changes the label and the menu heading', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(ExportMenuButton(source: _config(selected: 12))),
      );
      expect(find.text('Export 12 selected'), findsOneWidget);

      await tester.tap(find.text('Export 12 selected'));
      await tester.pumpAndSettle();
      expect(find.text('DOWNLOAD 12 SELECTED'), findsOneWidget);
    });

    testWidgets('an unfiltered list drops the FILTERED qualifier', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(ExportMenuButton(source: _config(total: 611, shown: 611))),
      );
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      expect(find.text('DOWNLOAD 611'), findsOneWidget);
    });

    testWidgets('the menu closes on a tap outside', (tester) async {
      await tester.pumpWidget(_host(ExportMenuButton(source: _config())));
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      expect(find.text('CSV'), findsOneWidget);

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.text('CSV'), findsNothing);
    });

    testWidgets('showMoreOptions: false hides the dialog row', (tester) async {
      await tester.pumpWidget(
        _host(ExportMenuButton(source: _config(), showMoreOptions: false)),
      );
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();
      expect(find.text('CSV'), findsOneWidget);
      expect(find.text('More options…'), findsNothing);
    });
  });

  group('ExportDialog', () {
    testWidgets('states the scope as a fact, with live counts', (tester) async {
      await tester.pumpWidget(_host(ExportDialog(source: _config())));
      await tester.pumpAndSettle();

      expect(find.text('Export Products'), findsOneWidget);
      expect(find.text('Current filtered view'), findsOneWidget);
      expect(find.text('248'), findsOneWidget);
      expect(find.text('All products'), findsOneWidget);
      expect(find.text('611'), findsOneWidget);
      // No selection, so no third card.
      expect(find.textContaining('selected row'), findsNothing);
    });

    testWidgets('a selection adds a third card', (tester) async {
      await tester.pumpWidget(
        _host(ExportDialog(source: _config(selected: 12))),
      );
      await tester.pumpAndSettle();
      expect(find.text('12 selected rows'), findsOneWidget);
    });

    testWidgets('PAGE LAYOUT only appears for PDF', (tester) async {
      await tester.pumpWidget(_host(ExportDialog(source: _config())));
      await tester.pumpAndSettle();
      expect(find.text('PAGE LAYOUT'), findsNothing);

      await tester.tap(find.text('Excel').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('PDF').last);
      await tester.pumpAndSettle();

      expect(find.text('PAGE LAYOUT'), findsOneWidget);
      expect(find.text('Landscape'), findsOneWidget);
      expect(find.text('Portrait'), findsOneWidget);
    });

    testWidgets('Select all ticks every column and the estimate grows', (
      tester,
    ) async {
      await tester.pumpWidget(_host(ExportDialog(source: _config())));
      await tester.pumpAndSettle();

      final before = tester
          .widget<Text>(find.textContaining('Estimated size'))
          .data!;
      await tester.tap(find.text('Select all'));
      await tester.pumpAndSettle();
      final after = tester
          .widget<Text>(find.textContaining('Estimated size'))
          .data!;

      expect(find.text('Reset'), findsOneWidget);
      expect(after, isNot(before));
    });
  });

  group('ListScopeBar', () {
    testWidgets('spells out the scope and renders removable chips', (
      tester,
    ) async {
      var removed = false;
      await tester.pumpWidget(
        _host(
          ListScopeBar(
            shown: 248,
            total: 611,
            noun: 'products',
            chips: [ListScopeChip('In stock', () => removed = true)],
            selectedCount: 12,
          ),
        ),
      );
      // The count is emphasised inside a RichText, not a plain Text.
      expect(
        find.text('Showing 248 of 611 products', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('In stock'), findsOneWidget);
      expect(find.text('12 selected'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded).first);
      expect(removed, isTrue);
    });
  });

  group('Reports catalog', () {
    // Narrow surface on purpose: the wide layout brings the sidebar and the
    // global top bar with it, and neither is what these assertions are about.
    setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

    testWidgets('groups the cards by domain', (tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const ReportsCatalogView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FINANCIAL'), findsOneWidget);
      expect(find.text('INVENTORY'), findsOneWidget);
      expect(find.text('SALES & PURCHASE'), findsOneWidget);
      expect(find.text('Profit & Loss'), findsOneWidget);
      expect(find.text('Balance Sheet'), findsOneWidget);
      expect(find.text('Client Ledger'), findsOneWidget);
    });

    testWidgets('search narrows the catalog', (tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const ReportsCatalogView(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'stock');
      await tester.pumpAndSettle();

      expect(find.text('Low Stock'), findsOneWidget);
      expect(find.text('Stock Valuation'), findsOneWidget);
      expect(find.text('Profit & Loss'), findsNothing);
      expect(find.text('FINANCIAL'), findsNothing);
    });
  });

  group('StatementSheet', () {
    testWidgets('prints the paper header, bands and footer', (tester) async {
      final doc = StatementDoc(
        companyName: kCompanyName,
        title: 'Profit & Loss Statement',
        periodLine: ReportPeriod.financialYear(2025).statementLine,
        rows: const [
          StatementRow.section('Income'),
          StatementRow.item('Sales Revenue', 14200000),
          StatementRow.subtotal('Total Income', 14380000),
          StatementRow.derived('Gross Profit', 4860000),
          StatementRow.result('Net Profit', 2240000),
        ],
      );
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: StatementSheet(
              doc: doc,
              generatedLine: 'Generated 06 Sep 2026, 2:15 PM · Admin',
            ),
          ),
        ),
      );

      expect(find.text('Secure Heat Care'), findsOneWidget);
      expect(find.text('Profit & Loss Statement'), findsOneWidget);
      expect(
        find.text('For the period 01 Apr 2025 to 31 Mar 2026'),
        findsOneWidget,
      );
      expect(find.text('PARTICULARS'), findsOneWidget);
      expect(find.text('AMOUNT (₹)'), findsOneWidget);
      // Indian grouping, no ₹ prefix on the rows themselves.
      expect(find.text('1,42,00,000'), findsOneWidget);
      expect(find.text('Page 1 of 1'), findsOneWidget);
    });

    testWidgets('a deduction prints in brackets', (tester) async {
      const doc = StatementDoc(
        companyName: 'Secure Heat Care',
        title: 'Profit & Loss Statement',
        periodLine: 'x',
        rows: [
          StatementRow.item('Less: Closing Stock', 3160000, negative: true),
        ],
      );
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            child: StatementSheet(doc: doc, generatedLine: 'x'),
          ),
        ),
      );
      expect(find.text('(31,60,000)'), findsOneWidget);
    });
  });
}

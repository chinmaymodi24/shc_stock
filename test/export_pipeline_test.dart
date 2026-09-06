import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/export/export_format.dart';
import 'package:shc_stock/app/core/export/export_presets.dart';
import 'package:shc_stock/app/core/export/export_job.dart';
import 'package:shc_stock/app/core/export/export_service.dart';
import 'package:shc_stock/app/core/export/export_source.dart';
import 'package:shc_stock/app/core/export/export_table.dart';
import 'package:shc_stock/app/core/export/statement.dart';
import 'package:shc_stock/app/modules/reports/export/statement_export.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Row {
  final String name;
  final double price;
  final int stock;
  const _Row(this.name, this.price, this.stock);
}

/// Stands in for a list page: a full list, a narrowed one, and a selection.
ExportEntityConfig<_Row> _config({
  int total = 6,
  int shown = 3,
  int selected = 0,
}) {
  final all = [for (var i = 0; i < total; i++) _Row('Item $i', 100.0 + i, i)];
  return ExportEntityConfig<_Row>(
    entityKey: 'products',
    entityLabel: 'Products',
    rowNoun: 'products',
    allRows: () => all,
    filteredRows: () => all.take(shown).toList(),
    selectedRows: () => all.take(selected).toList(),
    defaultColumnKeys: const ['name', 'price'],
    periodSlugBuilder: () => 'fy2025-26',
    allColumns: [
      ExportColumn(key: 'name', label: 'Product', value: (r) => r.name),
      ExportColumn(
        key: 'price',
        label: 'Price',
        type: ExportCellType.money,
        value: (r) => r.price,
      ),
      ExportColumn(
        key: 'stock',
        label: 'Stock',
        type: ExportCellType.number,
        value: (r) => r.stock,
      ),
    ],
  );
}

void main() {
  group('ExportEntityConfig', () {
    test('each scope counts the list it actually stands for', () {
      final config = _config(total: 6, shown: 3, selected: 2);
      expect(config.countOf(ExportScope.all), 6);
      expect(config.countOf(ExportScope.filtered), 3);
      expect(config.countOf(ExportScope.selected), 2);
      expect(config.hasSelection, isTrue);
      expect(config.isFiltered, isTrue);
    });

    test('an unfiltered list reports itself as such', () {
      final config = _config(total: 6, shown: 6);
      expect(config.isFiltered, isFalse);
      expect(config.hasSelection, isFalse);
    });

    test('the filtered scope exports exactly the rows on screen', () {
      final table = _config(
        total: 6,
        shown: 3,
      ).buildTable(ExportScope.filtered, ['name', 'price']);
      expect(table.rowCount, 3);
      expect(table.rows.first.first.text, 'Item 0');
      expect(table.rows.last.first.text, 'Item 2');
    });

    test('columns keep table order, not the order they were ticked', () {
      final table = _config().buildTable(ExportScope.all, ['stock', 'name']);
      expect(table.headers, ['Product', 'Stock']);
    });

    test('scope line states the narrowing in words', () {
      final config = _config(total: 611, shown: 248);
      expect(
        config.buildTable(ExportScope.filtered, ['name']).scopeLine,
        '248 of 611 products · current filters',
      );
    });

    test(
      'the async builder produces the same table and reports progress',
      () async {
        final config = _config(total: 600, shown: 600);
        final progress = <int>[];
        final table = await config.buildTableAsync(ExportScope.all, [
          'name',
          'price',
        ], onProgress: (done, _) => progress.add(done));
        expect(table.rowCount, 600);
        expect(progress.last, 600);
        // Chunked, so the bar has something to move through.
        expect(progress.length, greaterThan(1));
      },
    );

    test('money cells carry the raw number as well as the grouped text', () {
      final table = _config().buildTable(ExportScope.all, ['price']);
      expect(table.rows.first.first.number, 100.0);
      expect(table.rows.first.first.text, '₹100');
    });
  });

  group('filename', () {
    test('is entity-scope-period, lowercase and hyphenated', () {
      expect(
        buildExportFilename(
          entityKey: 'products',
          scope: ExportScope.filtered,
          periodSlug: 'fy2025-26',
          format: ExportFormat.excel,
        ),
        'products-filtered-fy2025-26.xlsx',
      );
    });

    test('slugs anything that is not already a clean token', () {
      expect(
        buildExportFilename(
          entityKey: 'Purchase Entries',
          scope: ExportScope.all,
          periodSlug: 'Q1 2026',
          format: ExportFormat.pdf,
        ),
        'purchase-entries-all-q1-2026.pdf',
      );
    });
  });

  group('ExportService', () {
    late ExportService service;

    setUp(() {
      Get.reset();
      service = Get.put(ExportService());
    });

    tearDown(Get.reset);

    test(
      'refuses a PDF past the row limit and says what to do instead',
      () async {
        final job = await service.start(
          _config(total: ExportService.pdfRowLimit + 1, shown: 2001),
          const ExportRequest(
            scope: ExportScope.all,
            format: ExportFormat.pdf,
            columnKeys: ['name'],
          ),
        );
        expect(job.state, ExportJobState.failed);
        expect(job.error, contains('try Excel'));
        // Nothing was produced, so nothing lands in Downloads.
        expect(service.downloads, isEmpty);
      },
    );

    test(
      'a large export runs as a background job and lands in Downloads',
      () async {
        final job = await service.start(
          _config(total: 1500, shown: 1500),
          const ExportRequest(
            scope: ExportScope.all,
            format: ExportFormat.excel,
            columnKeys: ['name', 'price'],
          ),
        );
        expect(job.state, ExportJobState.ready);
        expect(job.totalRows, 1500);
        expect(job.bytes, isNotNull);
        expect(
          service.downloads.single.filename,
          'products-all-fy2025-26.xlsx',
        );
        expect(service.hasNewDownload.value, isTrue);
      },
    );

    test('retry re-runs the same request', () async {
      final failed = await service.start(
        _config(total: 3000, shown: 3000),
        const ExportRequest(
          scope: ExportScope.all,
          format: ExportFormat.pdf,
          columnKeys: ['name'],
        ),
      );
      expect(service.jobs.single.state, ExportJobState.failed);
      await service.retry(failed);
      // Still too many rows, so it fails again — but it ran, and there is
      // exactly one toast rather than a growing stack.
      expect(service.jobs.length, 1);
      expect(service.jobs.single.state, ExportJobState.failed);
    });

    test('opening the panel clears the new-download dot', () async {
      await service.start(
        _config(total: 1200, shown: 1200),
        const ExportRequest(
          scope: ExportScope.all,
          format: ExportFormat.csv,
          columnKeys: ['name'],
        ),
      );
      expect(service.hasNewDownload.value, isTrue);
      service.openPanel();
      expect(service.panelOpen.value, isTrue);
      expect(service.hasNewDownload.value, isFalse);
    });

    test('downloads past the retention window are pruned', () {
      service.downloads.addAll([
        DownloadEntry(
          id: 1,
          filename: 'fresh.xlsx',
          format: ExportFormat.excel,
          rowCount: 1,
          bytes: Uint8List(0),
          createdAt: DateTime.now(),
        ),
        DownloadEntry(
          id: 2,
          filename: 'stale.xlsx',
          format: ExportFormat.excel,
          rowCount: 1,
          bytes: Uint8List(0),
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
        ),
      ]);
      service.pruneExpired();
      expect(service.downloads.map((d) => d.filename), ['fresh.xlsx']);
    });
  });

  group('StatementExportSource', () {
    final doc = StatementDoc(
      companyName: 'Secure Heat Care',
      title: 'Profit & Loss Statement',
      periodLine: 'For the period 01 Apr 2025 to 31 Mar 2026',
      rows: const [
        StatementRow.section('Income'),
        StatementRow.item('Sales Revenue', 14200000),
        StatementRow.note('Other income is not recorded.'),
        StatementRow.spacer(),
        StatementRow.item('Less: Closing Stock', 3160000, negative: true),
        StatementRow.result('Net Profit', 2240000),
      ],
    );

    final source = StatementExportSource(
      doc: doc,
      entityKey: 'profit-loss',
      periodSlug: 'fy2025-26',
    );

    test('flattens to Particulars / Amount, dropping prose and spacers', () {
      final table = source.buildTable(ExportScope.all, const []);
      expect(table.headers, ['Particulars', 'Amount (₹)']);
      expect(table.rows.map((r) => r.first.text), [
        'INCOME',
        'Sales Revenue',
        'Less: Closing Stock',
        'Net Profit',
      ]);
    });

    test(
      'a deduction keeps its sign so a spreadsheet can total the column',
      () {
        final table = source.buildTable(ExportScope.all, const []);
        expect(table.rows[2].last.number, -3160000);
      },
    );

    test('renders its own paper layout for PDF', () {
      final bytes = source.renderCustomPdf('Generated · Test');
      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(0));
    });
  });

  group('ExportPresetStore', () {
    late ExportPresetStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      Get.reset();
      store = Get.put(ExportPresetStore());
      await store.restore();
    });

    tearDown(Get.reset);

    test('saves a named column set against its entity', () async {
      await store.save('products', 'Monthly review', ['name', 'price']);
      expect(store.forEntity('products').single.name, 'Monthly review');
      expect(store.forEntity('products').single.columnKeys, ['name', 'price']);
      // Scoped per entity — Clients does not inherit it.
      expect(store.forEntity('clients'), isEmpty);
    });

    test('re-saving a name replaces it rather than duplicating', () async {
      await store.save('products', 'Review', ['name']);
      await store.save('products', 'review', ['name', 'price', 'stock']);
      expect(store.forEntity('products').length, 1);
      expect(store.forEntity('products').single.columnKeys.length, 3);
    });

    test('refuses a blank name or an empty column set', () async {
      expect(await store.save('products', '   ', ['name']), isFalse);
      expect(await store.save('products', 'Empty', []), isFalse);
      expect(store.forEntity('products'), isEmpty);
    });

    test('survives a restart', () async {
      await store.save('products', 'Price list', ['name', 'price']);
      final reloaded = ExportPresetStore();
      await reloaded.restore();
      expect(reloaded.forEntity('products').single.name, 'Price list');
    });

    test(
      'a corrupt blob costs the presets, not the ability to export',
      () async {
        SharedPreferences.setMockInitialValues({
          'export_column_presets': 'not json',
        });
        final reloaded = ExportPresetStore();
        await reloaded.restore();
        expect(reloaded.forEntity('products'), isEmpty);
      },
    );
  });
}

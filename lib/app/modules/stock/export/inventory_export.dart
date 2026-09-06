import 'package:shc_stock/app/core/export/export_source.dart';
import 'package:shc_stock/app/core/export/export_table.dart';
import 'package:shc_stock/app/modules/stock/controllers/stock_controller.dart';
import 'package:shc_stock/app/modules/stock/models/stock_item_model.dart';

/// Export config for the Inventory list.
ExportEntityConfig<StockItemModel> inventoryExportConfig(StockController c) {
  return ExportEntityConfig<StockItemModel>(
    entityKey: 'inventory',
    entityLabel: 'Inventory',
    rowNoun: 'items',
    filteredRows: () => c.filteredItems,
    allRows: () => c.items.toList(),
    defaultColumnKeys: const ['name', 'sku', 'category', 'stock', 'value'],
    presets: const [
      ExportColumnPreset('Reorder report', [
        'name',
        'sku',
        'stock',
        'minStock',
        'status',
        'location',
      ]),
      ExportColumnPreset('Valuation', [
        'name',
        'category',
        'stock',
        'costPrice',
        'value',
      ]),
    ],
    allColumns: [
      ExportColumn(key: 'name', label: 'Item', width: 3, value: (i) => i.name),
      ExportColumn(key: 'sku', label: 'SKU', width: 1.4, value: (i) => i.sku),
      ExportColumn(
        key: 'category',
        label: 'Category',
        width: 2,
        value: (i) => i.category,
      ),
      ExportColumn(
        key: 'stock',
        label: 'Stock In Hand',
        type: ExportCellType.number,
        width: 1.3,
        value: (i) => i.stockInHand,
      ),
      ExportColumn(
        key: 'value',
        label: 'Stock Value',
        type: ExportCellType.money,
        width: 1.5,
        value: (i) => i.stockValue,
      ),
      ExportColumn(
        key: 'available',
        label: 'Available',
        type: ExportCellType.number,
        width: 1.2,
        value: (i) => i.availableStock,
      ),
      ExportColumn(
        key: 'minStock',
        label: 'Reorder Level',
        type: ExportCellType.number,
        width: 1.3,
        value: (i) => i.minimumStock,
      ),
      ExportColumn(
        key: 'costPrice',
        label: 'Cost Price',
        type: ExportCellType.money,
        width: 1.3,
        value: (i) => i.costPrice,
      ),
      ExportColumn(
        key: 'sellingPrice',
        label: 'Selling Price',
        type: ExportCellType.money,
        width: 1.3,
        value: (i) => i.sellingPrice,
      ),
      ExportColumn(
        key: 'unit',
        label: 'Unit',
        width: 1.1,
        value: (i) => i.unit,
      ),
      ExportColumn(
        key: 'status',
        label: 'Status',
        width: 1.4,
        value: (i) => i.statusLabel,
      ),
      ExportColumn(
        key: 'location',
        label: 'Location',
        width: 1.5,
        value: (i) => i.stockLocation,
      ),
      ExportColumn(
        key: 'modifiedBy',
        label: 'Modified By',
        width: 1.5,
        value: (i) => i.modifiedBy,
      ),
    ],
  );
}

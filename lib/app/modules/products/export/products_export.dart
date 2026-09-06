import 'package:shc_stock/app/core/export/export_source.dart';
import 'package:shc_stock/app/core/export/export_table.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';

/// Export config for the Products list.
///
/// Columns are declared in table order, so a spreadsheet or a PDF reads like
/// the page it came from. The row providers hand back the controller's own
/// lists — the export never runs a query of its own.
ExportEntityConfig<ProductModel> productsExportConfig(ProductsController c) {
  return ExportEntityConfig<ProductModel>(
    entityKey: 'products',
    entityLabel: 'Products',
    rowNoun: 'products',
    filteredRows: () => c.filteredProducts.toList(),
    allRows: () => c.products.toList(),
    selectedRows: () => c.selectedProducts,
    defaultColumnKeys: const ['name', 'sku', 'category', 'price', 'stock'],
    presets: const [
      ExportColumnPreset('Price list', [
        'name',
        'sku',
        'category',
        'price',
        'costPrice',
        'tax',
      ]),
      ExportColumnPreset('Stock check', [
        'name',
        'sku',
        'stock',
        'minStock',
        'unit',
        'location',
      ]),
      ExportColumnPreset('GST filing', ['name', 'sku', 'hsn', 'tax', 'price']),
    ],
    allColumns: [
      ExportColumn(
        key: 'name',
        label: 'Product',
        width: 3,
        value: (p) => p.name,
      ),
      ExportColumn(key: 'sku', label: 'SKU', width: 1.4, value: (p) => p.sku),
      ExportColumn(
        key: 'category',
        label: 'Category',
        width: 2,
        // Historic rows carried a "1. " numeric prefix on the category name;
        // strip it so the file matches what the table shows.
        value: (p) => p.categoryName.replaceFirst(RegExp(r'^\d+\.\s*'), ''),
      ),
      ExportColumn(
        key: 'subcategory',
        label: 'Subcategory',
        width: 1.8,
        value: (p) => p.subCategory,
      ),
      ExportColumn(
        key: 'price',
        label: 'Price',
        type: ExportCellType.money,
        width: 1.3,
        value: (p) => p.sellingPrice,
      ),
      ExportColumn(
        key: 'stock',
        label: 'Stock',
        type: ExportCellType.number,
        width: 1,
        value: (p) => p.currentStock,
      ),
      ExportColumn(
        key: 'costPrice',
        label: 'Cost Price',
        type: ExportCellType.money,
        width: 1.3,
        value: (p) => p.costPrice,
      ),
      ExportColumn(
        key: 'minStock',
        label: 'Reorder Level',
        type: ExportCellType.number,
        width: 1.2,
        value: (p) => p.minimumStock,
      ),
      ExportColumn(
        key: 'unit',
        label: 'Unit',
        width: 1.2,
        value: (p) => p.unit,
      ),
      ExportColumn(
        key: 'hsn',
        label: 'HSN Code',
        width: 1.2,
        value: (p) => p.hsnCode ?? '',
      ),
      ExportColumn(
        key: 'tax',
        label: 'GST %',
        type: ExportCellType.number,
        width: 1,
        value: (p) => p.taxPercent,
      ),
      ExportColumn(
        key: 'brand',
        label: 'Brand',
        width: 1.4,
        value: (p) => p.brand ?? '',
      ),
      ExportColumn(
        key: 'location',
        label: 'Location',
        width: 1.5,
        value: (p) => p.stockLocation,
      ),
      ExportColumn(
        key: 'status',
        label: 'Status',
        width: 1.2,
        value: (p) => p.isActive ? 'Active' : 'Inactive',
      ),
      ExportColumn(
        key: 'modifiedBy',
        label: 'Modified By',
        width: 1.5,
        value: (p) => p.modifiedBy,
      ),
      ExportColumn(
        key: 'modifiedAt',
        label: 'Modified On',
        type: ExportCellType.date,
        width: 1.4,
        value: (p) => p.modifiedAt,
      ),
    ],
  );
}

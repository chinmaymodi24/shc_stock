import 'package:shc_stock/app/core/export/export_source.dart';
import 'package:shc_stock/app/core/export/export_table.dart';
import 'package:shc_stock/app/modules/categories/controllers/categories_controller.dart';
import 'package:shc_stock/app/modules/categories/models/category_model.dart';

/// Export config for the Categories list.
///
/// A category row carries its sub-categories inline rather than exploding
/// into one row each: the page is a list of categories, and the export
/// contract is that a file holds the rows the page was showing.
ExportEntityConfig<CategoryModel> categoriesExportConfig(
  CategoriesController c,
) {
  return ExportEntityConfig<CategoryModel>(
    entityKey: 'categories',
    entityLabel: 'Categories',
    rowNoun: 'categories',
    filteredRows: () => c.visibleCategories.toList(),
    allRows: () => c.categories.toList(),
    defaultColumnKeys: const ['name', 'description', 'subCount', 'subNames'],
    allColumns: [
      ExportColumn(
        key: 'name',
        label: 'Category',
        width: 2,
        value: (cat) => cat.name,
      ),
      ExportColumn(
        key: 'description',
        label: 'Description',
        width: 3,
        value: (cat) => cat.description,
      ),
      ExportColumn(
        key: 'subCount',
        label: 'Sub-categories',
        type: ExportCellType.number,
        width: 1.3,
        value: (cat) => cat.subCategories.length,
      ),
      ExportColumn(
        key: 'subNames',
        label: 'Sub-category Names',
        width: 4,
        value: (cat) => cat.subProducts.join(', '),
      ),
      ExportColumn(
        key: 'id',
        label: 'Category ID',
        width: 1,
        value: (cat) => cat.id,
      ),
    ],
  );
}

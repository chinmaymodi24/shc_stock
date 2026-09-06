import 'package:shc_stock/app/core/export/export_source.dart';
import 'package:shc_stock/app/core/export/export_table.dart';
import 'package:shc_stock/app/modules/transactions/controllers/transactions_controller.dart';
import 'package:shc_stock/app/modules/transactions/models/transaction_model.dart';

/// Export config for the Transactions list.
ExportEntityConfig<TransactionModel> transactionsExportConfig(
  TransactionsController c,
) {
  return ExportEntityConfig<TransactionModel>(
    entityKey: 'transactions',
    entityLabel: 'Transactions',
    rowNoun: 'transactions',
    filteredRows: () => c.filteredTransactions,
    allRows: () => c.transactions.toList(),
    defaultColumnKeys: const ['item', 'type', 'party', 'date', 'status'],
    presets: const [
      ExportColumnPreset('Movement log', [
        'date',
        'item',
        'type',
        'poNumber',
        'party',
        'status',
      ]),
    ],
    allColumns: [
      ExportColumn(key: 'item', label: 'Item', width: 3, value: (t) => t.item),
      ExportColumn(
        key: 'type',
        label: 'Type',
        width: 1.2,
        value: (t) => t.typeLabel,
      ),
      ExportColumn(
        key: 'party',
        label: 'Party',
        width: 2.5,
        value: (t) => t.party,
      ),
      ExportColumn(
        key: 'date',
        label: 'Date',
        type: ExportCellType.date,
        width: 1.4,
        value: (t) => t.date,
      ),
      ExportColumn(
        key: 'status',
        label: 'Status',
        width: 1.3,
        value: (t) => t.statusLabel,
      ),
      ExportColumn(
        key: 'poNumber',
        label: 'PO Number',
        width: 1.5,
        value: (t) => t.poNumber,
      ),
      ExportColumn(
        key: 'notes',
        label: 'Notes',
        width: 3,
        value: (t) => t.notes,
      ),
      ExportColumn(
        key: 'modifiedBy',
        label: 'Modified By',
        width: 1.5,
        value: (t) => t.modifiedBy,
      ),
      ExportColumn(
        key: 'modifiedAt',
        label: 'Modified On',
        type: ExportCellType.date,
        width: 1.4,
        value: (t) => t.modifiedAt,
      ),
    ],
  );
}

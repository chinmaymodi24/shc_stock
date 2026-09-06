import 'package:shc_stock/app/core/export/export_source.dart';
import 'package:shc_stock/app/core/export/export_table.dart';
import 'package:shc_stock/app/modules/purchase/controllers/purchase_controller.dart';
import 'package:shc_stock/app/modules/purchase/models/purchase_model.dart';

/// Export config for the Purchase list.
ExportEntityConfig<PurchaseOrder> purchaseExportConfig(PurchaseController c) {
  return ExportEntityConfig<PurchaseOrder>(
    entityKey: 'purchase',
    entityLabel: 'Purchase Entries',
    rowNoun: 'purchase orders',
    filteredRows: () => c.filteredOrders,
    allRows: () => c.orders.toList(),
    defaultColumnKeys: const [
      'poNumber',
      'supplier',
      'date',
      'amount',
      'status',
    ],
    presets: const [
      ExportColumnPreset('Payables', [
        'poNumber',
        'supplier',
        'date',
        'amount',
        'paidAmount',
        'dueAmount',
        'dueDate',
      ]),
      ExportColumnPreset('GST filing', [
        'invoiceNo',
        'invoiceDate',
        'supplier',
        'buyerGst',
        'placeOfSupply',
        'amount',
      ]),
    ],
    allColumns: [
      ExportColumn(
        key: 'poNumber',
        label: 'PO Number',
        width: 1.5,
        value: (o) => o.poNumber,
      ),
      ExportColumn(
        key: 'supplier',
        label: 'Supplier',
        width: 3,
        value: (o) => o.supplier,
      ),
      ExportColumn(
        key: 'date',
        label: 'Date',
        type: ExportCellType.date,
        width: 1.4,
        value: (o) => o.date,
      ),
      ExportColumn(
        key: 'amount',
        label: 'Amount',
        type: ExportCellType.money,
        width: 1.6,
        value: (o) => o.amount,
      ),
      ExportColumn(
        key: 'status',
        label: 'Status',
        width: 1.3,
        value: (o) => o.status.label,
      ),
      ExportColumn(
        key: 'items',
        label: 'Items',
        type: ExportCellType.number,
        width: 1,
        value: (o) => o.itemCount,
      ),
      ExportColumn(
        key: 'paidAmount',
        label: 'Paid',
        type: ExportCellType.money,
        width: 1.5,
        value: (o) => o.paidAmount,
      ),
      ExportColumn(
        key: 'dueAmount',
        label: 'Due',
        type: ExportCellType.money,
        width: 1.5,
        // Never negative: an overpayment is a credit note, not a due.
        value: (o) => (o.amount - o.paidAmount).clamp(0, double.infinity),
      ),
      ExportColumn(
        key: 'invoiceNo',
        label: 'Invoice No',
        width: 1.5,
        value: (o) => o.invoiceNo,
      ),
      ExportColumn(
        key: 'invoiceDate',
        label: 'Invoice Date',
        type: ExportCellType.date,
        width: 1.4,
        value: (o) => o.invoiceDate,
      ),
      ExportColumn(
        key: 'dueDate',
        label: 'Due Date',
        type: ExportCellType.date,
        width: 1.4,
        value: (o) => o.dueDate,
      ),
      ExportColumn(
        key: 'buyerGst',
        label: 'Buyer GST',
        width: 1.8,
        value: (o) => o.buyerGst,
      ),
      ExportColumn(
        key: 'placeOfSupply',
        label: 'Place of Supply',
        width: 1.8,
        value: (o) => o.placeOfSupply,
      ),
      ExportColumn(
        key: 'freight',
        label: 'Freight',
        type: ExportCellType.money,
        width: 1.3,
        value: (o) => o.freight,
      ),
      ExportColumn(
        key: 'modifiedBy',
        label: 'Modified By',
        width: 1.5,
        value: (o) => o.modifiedBy,
      ),
    ],
  );
}

import 'package:shc_stock/app/core/export/export_source.dart';
import 'package:shc_stock/app/core/export/export_table.dart';
import 'package:shc_stock/app/modules/sales/controllers/sales_controller.dart';
import 'package:shc_stock/app/modules/sales/models/sales_model.dart';

/// Export config for the Sell list.
ExportEntityConfig<SalesOrder> salesExportConfig(SalesController c) {
  return ExportEntityConfig<SalesOrder>(
    entityKey: 'sales',
    entityLabel: 'Sell Entries',
    rowNoun: 'sales orders',
    filteredRows: () => c.filteredOrders,
    allRows: () => c.orders.toList(),
    defaultColumnKeys: const ['soNumber', 'client', 'date', 'amount', 'status'],
    presets: const [
      ExportColumnPreset('Receivables', [
        'soNumber',
        'client',
        'date',
        'amount',
        'paidAmount',
        'dueAmount',
        'paymentStatus',
      ]),
      ExportColumnPreset('GST filing', [
        'invoiceNo',
        'invoiceDate',
        'client',
        'buyerGstin',
        'taxableValue',
        'cgst',
        'sgst',
        'amount',
      ]),
    ],
    allColumns: [
      ExportColumn(
        key: 'soNumber',
        label: 'SO Number',
        width: 1.5,
        value: (o) => o.soNumber,
      ),
      ExportColumn(
        key: 'client',
        label: 'Client',
        width: 3,
        value: (o) => o.client,
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
        key: 'paymentStatus',
        label: 'Payment',
        width: 1.3,
        value: (o) => o.paymentStatus.label,
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
        label: 'Received',
        type: ExportCellType.money,
        width: 1.5,
        value: (o) => o.paidAmount,
      ),
      ExportColumn(
        key: 'dueAmount',
        label: 'Outstanding',
        type: ExportCellType.money,
        width: 1.6,
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
        key: 'buyerGstin',
        label: 'Buyer GSTIN',
        width: 1.8,
        value: (o) => o.buyerGstin,
      ),
      ExportColumn(
        key: 'taxableValue',
        label: 'Taxable Value',
        type: ExportCellType.money,
        width: 1.6,
        value: (o) => o.taxableValue,
      ),
      ExportColumn(
        key: 'cgst',
        label: 'CGST',
        type: ExportCellType.money,
        width: 1.3,
        value: (o) => o.cgst,
      ),
      ExportColumn(
        key: 'sgst',
        label: 'SGST',
        type: ExportCellType.money,
        width: 1.3,
        value: (o) => o.sgst,
      ),
      ExportColumn(
        key: 'destination',
        label: 'Destination',
        width: 1.8,
        value: (o) => o.destination,
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

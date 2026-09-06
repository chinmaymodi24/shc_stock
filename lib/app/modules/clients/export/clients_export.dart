import 'package:shc_stock/app/core/export/export_source.dart';
import 'package:shc_stock/app/core/export/export_table.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';

/// Export config for the Clients list.
ExportEntityConfig<ClientModel> clientsExportConfig(ClientsController c) {
  return ExportEntityConfig<ClientModel>(
    entityKey: 'clients',
    entityLabel: 'Clients',
    rowNoun: 'clients',
    filteredRows: () => c.filteredClients,
    allRows: () => c.clients.toList(),
    defaultColumnKeys: const ['name', 'code', 'phone', 'state', 'gstin'],
    presets: const [
      ExportColumnPreset('Contact sheet', [
        'name',
        'contactPerson',
        'phone',
        'email',
        'city',
        'state',
      ]),
      ExportColumnPreset('Credit review', [
        'name',
        'code',
        'creditLimit',
        'creditDays',
        'openingBalance',
        'paymentTerms',
      ]),
      ExportColumnPreset('GST filing', [
        'name',
        'gstin',
        'pan',
        'registrationType',
        'state',
      ]),
    ],
    allColumns: [
      ExportColumn(
        key: 'name',
        label: 'Client',
        width: 3,
        value: (cl) => cl.name,
      ),
      ExportColumn(
        key: 'code',
        label: 'Code',
        width: 1.2,
        value: (cl) => cl.code,
      ),
      ExportColumn(
        key: 'phone',
        label: 'Phone',
        width: 1.5,
        value: (cl) => cl.phone,
      ),
      ExportColumn(
        key: 'state',
        label: 'State',
        width: 1.5,
        value: (cl) => cl.state,
      ),
      ExportColumn(
        key: 'gstin',
        label: 'GSTIN',
        width: 2,
        value: (cl) => cl.gstin,
      ),
      ExportColumn(
        key: 'email',
        label: 'Email',
        width: 2.5,
        value: (cl) => cl.email,
      ),
      ExportColumn(
        key: 'city',
        label: 'City',
        width: 1.5,
        value: (cl) => cl.city,
      ),
      ExportColumn(
        key: 'address',
        label: 'Address',
        width: 4,
        value: (cl) => cl.address,
      ),
      ExportColumn(key: 'pan', label: 'PAN', width: 1.4, value: (cl) => cl.pan),
      ExportColumn(
        key: 'registrationType',
        label: 'Registration',
        width: 1.5,
        value: (cl) => cl.registrationType,
      ),
      ExportColumn(
        key: 'contactPerson',
        label: 'Contact Person',
        width: 2,
        value: (cl) => cl.contactPerson,
      ),
      ExportColumn(
        key: 'creditLimit',
        label: 'Credit Limit',
        type: ExportCellType.money,
        width: 1.5,
        value: (cl) => cl.creditLimit,
      ),
      ExportColumn(
        key: 'creditDays',
        label: 'Credit Days',
        type: ExportCellType.number,
        width: 1.2,
        value: (cl) => cl.creditDays,
      ),
      ExportColumn(
        key: 'openingBalance',
        label: 'Opening Balance',
        type: ExportCellType.money,
        width: 1.6,
        value: (cl) => cl.openingBalance,
      ),
      ExportColumn(
        key: 'paymentTerms',
        label: 'Payment Terms',
        width: 1.6,
        value: (cl) => cl.paymentTerms,
      ),
      ExportColumn(
        key: 'clientSince',
        label: 'Client Since',
        type: ExportCellType.date,
        width: 1.4,
        value: (cl) => cl.clientSince,
      ),
    ],
  );
}

import 'package:shc_stock/app/core/api/api_client.dart';

/// The document series the server numbers.
enum OrderSeries {
  purchase('/purchase-orders/next-number'),
  sale('/sales-orders/next-number');

  const OrderSeries(this.path);
  final String path;
}

/// What the next order in [series] will be numbered — "PO/0001/26-27" — for
/// the forms' "Invoice No." prefill.
///
/// The server owns the sequence (per financial year, see backend
/// src/docNumber.js). It used to be guessed here from the loaded list with a
/// fixed "PO-2024-" prefix, which never moved past 2024 and, after a delete,
/// handed out a number that was still in use. Empty when the server can't be
/// reached — the field is then simply left for the user to fill.
Future<String> nextOrderNumber(OrderSeries series) async {
  try {
    final json = await ApiClient.instance.get(series.path);
    if (json is Map && json['number'] is String) return json['number'] as String;
  } catch (_) {}
  return '';
}

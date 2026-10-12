export 'package:shc_stock/app/core/utils/qty_format.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/utils/units.dart';
import 'package:shc_stock/app/core/utils/qty_format.dart';
import 'package:shc_stock/app/modules/products/controllers/products_controller.dart';
import 'package:shc_stock/app/modules/products/models/product_model.dart';

/// One line of a sale as the guard sees it — web and mobile use different row
/// classes, so each controller maps its rows into these.
typedef SaleStockLine = ({int? productId, double qty});

/// "5" for 5, "2.5" for 2.5 — no trailing ".00" in messages.

/// Stops a sale from selling more than the inventory holds, before the server
/// has to refuse it.
///
/// The rules, per product (lines of the same product are added together, so
/// two rows of 3 against a stock of 5 is caught too):
///  * nothing free to sell      -> blocking error
///  * total quantity > free     -> blocking error naming how many are left
///  * stock is running low      -> a non-blocking note
///  * a fraction on a product   -> blocking error: stock is counted in whole
///    units, so 2.5 of a product could never be booked correctly
///
/// "Free" means in the warehouse less what other open (not yet delivered)
/// sales have already promised — a sale only takes stock out on delivery, so
/// without that two open orders could each claim the same 5 units.
///
/// Lines typed in by hand (no productId) don't touch stock on the server, so
/// they are never checked.
///
/// When an existing order is being edited, the units it already holds were
/// taken out of stock when it was saved — [returnable] adds them back so
/// re-saving the same quantity isn't reported as "not enough".
class SaleStockGuard {
  final List<SaleStockLine> Function() lines;

  /// productId -> quantity the order being edited already holds.
  final Map<int, double> returnable = {};

  /// Where products come from. Defaults to the live ProductsController list;
  /// the products page refreshes it after every sale/purchase.
  final List<ProductModel> Function() products;

  SaleStockGuard({required this.lines, List<ProductModel> Function()? products})
    : products = products ?? (() => Get.find<ProductsController>().products);

  ProductModel? productFor(int? id) {
    if (id == null) return null;
    final key = id.toString();
    for (final p in products()) {
      if (p.id == key) return p;
    }
    return null;
  }

  /// Units that can still be sold for [productId]: in the warehouse, minus
  /// what open sales hold, plus what the order being edited already holds
  /// itself (open: it sits inside the held figure; delivered: it has already
  /// left the warehouse). Null for an unknown product.
  double? available(int? productId) {
    final p = productFor(productId);
    if (p == null) return null;
    final free =
        p.currentStock - p.committedStock + (returnable[productId] ?? 0);
    return free < 0 ? 0 : free.toDouble();
  }

  /// A fractional quantity on a product counted in whole units (pieces,
  /// rolls…). A measured unit (kg, m) may carry decimals — see units.dart.
  bool _hasFraction(int productId) {
    final p = productFor(productId);
    if (p == null || unitAllowsFraction(p.unit)) return false;
    return lines().any(
      (l) => l.productId == productId && l.qty != l.qty.roundToDouble(),
    );
  }

  double _totalQty(int productId) => lines()
      .where((l) => l.productId == productId)
      .fold(0.0, (s, l) => s + l.qty);

  /// The blocking message for a line of [productId], or null when it's fine.
  String? errorFor(int? productId) {
    final p = productFor(productId);
    final avail = available(productId);
    if (p == null || avail == null) return null;
    if (_hasFraction(productId!)) return wholeQtyMessage(p.name, p.unit);
    if (avail <= 0) {
      return p.currentStock > 0
          ? '"${p.name}" — all ${fmtStockQty(p.currentStock)} ${p.unit} in stock are already '
                'promised to other open sales.'
          : '"${p.name}" is not in inventory — there is no stock to sell.';
    }
    final total = _totalQty(productId);
    if (total > avail) {
      final held = p.committedStock > 0
          ? ' (${fmtStockQty(p.committedStock)} already promised to other open sales)'
          : '';
      return 'Only ${fmtStockQty(avail)} ${p.unit} of "${p.name}" available'
          '$held — you are trying to sell ${fmtStockQty(total)}.';
    }
    return null;
  }

  /// Why [p] cannot be put on a sale at all right now (nothing left to sell),
  /// or null when it can. Shown inside the item dropdown, where the product
  /// is also made unselectable.
  String? unavailableReason(ProductModel p) {
    final avail = available(int.tryParse(p.id));
    if (avail == null || avail > 0) return null;
    return p.currentStock > 0
        ? 'All ${fmtStockQty(p.currentStock)} ${p.unit} are promised to open sales'
        : 'Not in stock — nothing to sell';
  }

  /// A heads-up for a product that's selling out. Null when stock is healthy
  /// or [errorFor] already has something to say.
  String? lowNoteFor(int? productId) {
    if (errorFor(productId) != null) return null;
    final p = productFor(productId);
    final avail = available(productId);
    if (p == null || avail == null) return null;
    if (p.stockStatus != 'Low Stock') return null;
    return 'Low stock — only ${fmtStockQty(avail)} ${p.unit} left to sell.';
  }

  /// Quantity on every line of [productId] except the one being edited, which
  /// is passed in as [thisLineQty].
  double otherRowsQty(int productId, double thisLineQty) =>
      _totalQty(productId) - thisLineQty;

  /// How far a line's quantity may go. Null when there's no cap to apply
  /// (hand-typed line, unknown product, or nothing in stock — that case is
  /// reported as an error rather than clamped to 0).
  double? maxQtyFor(int? productId, {required double thisLineQty}) {
    final avail = available(productId);
    if (productId == null || avail == null || avail <= 0) return null;
    final room = avail - otherRowsQty(productId, thisLineQty);
    return room < 0 ? 0 : room;
  }

  /// Toast text for a quantity that was pushed past the stock and capped.
  String limitMessage(int? productId) {
    final p = productFor(productId);
    final avail = available(productId) ?? 0;
    return 'Only ${fmtStockQty(avail)} ${p?.unit ?? ''} of "${p?.name ?? ''}" '
        'available.';
  }

  /// First blocking message across the whole sale, for the Save button.
  String? firstError() {
    final seen = <int>{};
    for (final l in lines()) {
      final id = l.productId;
      if (id == null || !seen.add(id)) continue;
      final e = errorFor(id);
      if (e != null) return e;
    }
    return null;
  }
}

/// The message for a fractional quantity on a product counted in [unit].
String wholeQtyMessage(String productName, [String unit = '']) =>
    'Quantity of "$productName" must be a whole number — it is counted in '
    '${unit.isEmpty ? 'whole units' : unit}.';

/// Null when [qty] is fine for a line linked to a product; otherwise the
/// message. Decimals are fine for a free-typed line (it moves no stock) and
/// for a product measured in kg / m; only a counted unit (pieces, rolls,
/// bags…) must be whole. The unit is the product's own, looked up from the
/// loaded products when [unit] is not given. Shared by the Purchase forms.
String? wholeQtyError({
  required int? productId,
  required double qty,
  required String productName,
  String? unit,
}) {
  if (productId == null || qty == qty.roundToDouble()) return null;
  final u = unit ?? _productUnit(productId);
  if (u == null || unitAllowsFraction(u)) return null;
  return wholeQtyMessage(productName, u);
}

String? _productUnit(int productId) {
  if (!Get.isRegistered<ProductsController>()) return null;
  final key = productId.toString();
  for (final p in Get.find<ProductsController>().products) {
    if (p.id == key) return p.unit;
  }
  return null;
}

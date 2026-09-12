import 'package:flutter_test/flutter_test.dart';
import 'package:shc_stock/app/core/api/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The insufficient-stock 409, in words a person can act on.
//
// The backend refuses an over-sell (and an over-large stock-out) with the
// shortfall list attached. Inventory used to show only the bare "Insufficient
// stock", leaving the user to work out which line was the problem; Sales had
// its own separately-worded copy. Both now go through this one formatter.
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  test('names the item, what was asked for and what is there', () {
    final e = ApiException(
      409,
      'Insufficient stock',
      details: const [
        {
          'product': 'CF Bulk (Standard 1260°C)',
          'requested': 99,
          'available': 0,
        },
      ],
    );

    final msg = shortfallMessage(e)!;
    expect(msg, contains('CF Bulk (Standard 1260°C)'));
    expect(msg, contains('99'));
    expect(msg, contains('only 0 in stock'));
  });

  test('lists every short line, not just the first', () {
    final e = ApiException(
      409,
      'Insufficient stock',
      details: const [
        {'product': 'CF Bulk', 'requested': 10, 'available': 2},
        {'product': 'CF Blanket', 'requested': 5, 'available': 1},
      ],
    );

    final msg = shortfallMessage(e)!;
    expect(msg, contains('CF Bulk'));
    expect(msg, contains('CF Blanket'));
    expect(msg.split('\n').length, greaterThanOrEqualTo(3));
  });

  test('returns null for a failure that carries no shortfall', () {
    expect(shortfallMessage(ApiException(500, 'Server error')), isNull);
    expect(
      shortfallMessage(ApiException(409, 'x', details: const [])),
      isNull,
      reason: 'an empty list is not a shortfall',
    );
    expect(
      shortfallMessage(ApiException(409, 'x', details: 'not-a-list')),
      isNull,
      reason: 'so the caller can fall back to the plain message',
    );
  });
}

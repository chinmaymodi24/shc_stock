import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/utils/amount_format.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';

// Verbatim payloads from the live /api/stats endpoints.
const _salesStats = '''
{"salesMTD":5000,"totalOrders":1,"amountDue":5000,"receivedMTD":0,
 "trends":{"salesMTD":25.5,"totalOrders":null,"amountDue":null,
 "receivedMTD":-8.3}}
''';

const _clientsStats = '''
{"totalClients":1037,"gstRegistered":931,"unregistered":106,
 "statesCovered":27,
 "trends":{"totalClients":null,"gstRegistered":null,"unregistered":null,
 "statesCovered":null},
 "topStates":[{"state":"Gujarat","count":673},{"state":"Maharashtra","count":85}],
 "quickStats":{"avgOrderValue":5000,"repeatClientsPct":62},
 "newThisMonth":[{"id":1038,"code":"CLT-1038","name":"Zenith Refractory","state":"Gujarat"}]}
''';

StatsSnapshot _snap(String raw) =>
    StatsSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);

void main() {
  group('StatsSnapshot', () {
    test('reads card values off the sales payload', () {
      final s = _snap(_salesStats);
      expect(s.doubleOf('salesMTD'), 5000);
      expect(s.intOf('totalOrders'), 1);
      expect(s.doubleOf('amountDue'), 5000);
      expect(s.doubleOf('receivedMTD'), 0);
    });

    test('formats a positive trend', () {
      final s = _snap(_salesStats);
      expect(s.trendLabel('salesMTD'), '+25.5%');
      expect(s.trendUp('salesMTD'), isTrue);
    });

    test('formats a negative trend', () {
      final s = _snap(_salesStats);
      expect(s.trendLabel('receivedMTD'), '-8.3%');
      expect(s.trendUp('receivedMTD'), isFalse);
    });

    test('a null trend renders nothing rather than a fake percentage', () {
      final s = _snap(_salesStats);
      expect(s.trendOf('totalOrders'), isNull);
      // AppStatCard hides the whole trend row on an empty string.
      expect(s.trendLabel('totalOrders'), '');
    });

    test('the trends block is kept out of the values map', () {
      final s = _snap(_salesStats);
      expect(s.values.containsKey('trends'), isFalse);
      expect(s.trends['salesMTD'], 25.5);
    });

    test('empty snapshot reads as zeros, not a crash', () {
      const s = StatsSnapshot.empty;
      expect(s.intOf('anything'), 0);
      expect(s.doubleOf('anything'), 0);
      expect(s.trendLabel('anything'), '');
    });
  });

  group('clients right-panel payload', () {
    test('parses Top States in rank order', () {
      final json = jsonDecode(_clientsStats) as Map<String, dynamic>;
      final top = (json['topStates'] as List)
          .map((e) => TopStateEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(top.first.state, 'Gujarat');
      expect(top.first.count, 673);
      expect(top[1].state, 'Maharashtra');
    });

    test('parses New This Month rows', () {
      final json = jsonDecode(_clientsStats) as Map<String, dynamic>;
      final rows = (json['newThisMonth'] as List)
          .map((e) => NewClientEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(rows.single.code, 'CLT-1038');
      expect(rows.single.name, 'Zenith Refractory');
      expect(rows.single.initials, 'ZR');
    });

    test('quickStats carry the real avg order value and repeat rate', () {
      final json = jsonDecode(_clientsStats) as Map<String, dynamic>;
      final quick = json['quickStats'] as Map<String, dynamic>;
      expect(quick['avgOrderValue'], 5000);
      expect(quick['repeatClientsPct'], 62);
    });
  });

  group('formatRupees', () {
    test('groups lakhs the Indian way', () {
      expect(formatRupees(2485600), '₹24,85,600');
      expect(formatRupees(325400), '₹3,25,400');
      expect(formatRupees(653274), '₹6,53,274');
    });

    test('keeps the separator when the thousands digits are zero', () {
      // The old hand-rolled version returned "₹30,00000" here.
      expect(formatRupees(3000000), '₹30,00,000');
      expect(formatRupees(2500000), '₹25,00,000');
      expect(formatRupees(100000), '₹1,00,000');
    });

    test(
      'groups crores',
      () => expect(formatRupees(123456789), '₹12,34,56,789'),
    );
    test('groups thousands', () => expect(formatRupees(5000), '₹5,000'));
    test('leaves small amounts alone', () => expect(formatRupees(47), '₹47'));
    test('handles zero', () => expect(formatRupees(0), '₹0'));
    test(
      'handles negatives',
      () => expect(formatRupees(-325400), '-₹3,25,400'),
    );
  });
}

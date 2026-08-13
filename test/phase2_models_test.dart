import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/modules/dashboard/models/dashboard_models.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/modified_by_cell.dart';
import 'package:shc_stock/app/modules/transactions/models/transaction_model.dart';

// Verbatim rows from the live API.
const _txnRow = '''
{"id":4,"item":"Brass Valve 3/4\\"","type":"Outbound","party":"Shah Hardware",
 "poNumber":"#4408","date":"2026-07-07T18:30:00.000Z","status":"Delivered",
 "notes":"","modifiedBy":"Riya Patel","modifiedAt":"2026-07-08T10:42:00.000Z",
 "createdAt":"2026-08-11T04:00:00.000Z","updatedAt":"2026-08-11T04:00:00.000Z"}
''';

const _noteRow =
    '{"id":7,"userId":1,"text":"Follow up on restock","done":true,'
    '"sortOrder":2,"createdAt":"2026-08-11T04:00:00.000Z",'
    '"updatedAt":"2026-08-11T04:00:00.000Z"}';

void main() {
  group('TransactionModel', () {
    test('maps an API row', () {
      final t = TransactionModel.fromJson(
        jsonDecode(_txnRow) as Map<String, dynamic>,
      );
      expect(t.id, '4');
      expect(t.item, 'Brass Valve 3/4"');
      expect(t.type, TransactionType.outbound);
      expect(t.typeLabel, 'Outbound');
      expect(t.status, TransactionStatus.delivered);
      expect(t.party, 'Shah Hardware');
      expect(t.poNumber, '#4408');
      expect(t.modifiedBy, 'Riya Patel');
    });

    test('unknown type/status fall back instead of throwing', () {
      final t = TransactionModel.fromJson({
        'id': 1,
        'item': 'X',
        'type': 'Sideways',
        'status': 'Vibing',
        'date': '2026-08-11T00:00:00.000Z',
        'modifiedAt': '2026-08-11T00:00:00.000Z',
      });
      expect(t.type, TransactionType.inbound);
      expect(t.status, TransactionStatus.pending);
    });

    test('toJson sends the labels the API expects', () {
      final t = TransactionModel.fromJson(
        jsonDecode(_txnRow) as Map<String, dynamic>,
      );
      final json = t.toJson();
      expect(json['type'], 'Outbound');
      expect(json['status'], 'Delivered');
      expect(json.containsKey('id'), isFalse);
    });
  });

  group('NoteItem', () {
    test('maps an API row', () {
      final n = NoteItem.fromJson(jsonDecode(_noteRow) as Map<String, dynamic>);
      expect(n.id, 7);
      expect(n.text, 'Follow up on restock');
      expect(n.done, isTrue);
    });

    test('copyWith keeps the id so updates hit the right row', () {
      final n = NoteItem.fromJson(jsonDecode(_noteRow) as Map<String, dynamic>);
      final flipped = n.copyWith(done: false);
      expect(flipped.id, 7);
      expect(flipped.done, isFalse);
      expect(flipped.text, n.text);
    });
  });

  group('SessionUser', () {
    test('maps the login response and derives initials', () {
      final u = SessionUser.fromJson(const {
        'id': 1,
        'name': 'Chinmay Modi',
        'email': 'shc@gmail.com',
        'role': 'Admin',
      });
      expect(u.id, 1);
      expect(u.initials, 'CM');
      expect(u.role, 'Admin');
    });

    test('single-word and empty names degrade sensibly', () {
      expect(
        const SessionUser(id: 1, name: 'Prisha', email: '').initials,
        'PR',
      );
      expect(const SessionUser(id: 1, name: '', email: '').initials, '?');
    });

    test('round-trips through JSON for the shared_preferences blob', () {
      const u = SessionUser(
        id: 3,
        name: 'Ravi Sharma',
        email: 'ravi@shc.com',
        role: 'Manager',
      );
      final back = SessionUser.fromJson(
        jsonDecode(jsonEncode(u.toJson())) as Map<String, dynamic>,
      );
      expect(back.id, 3);
      expect(back.name, 'Ravi Sharma');
      expect(back.role, 'Manager');
    });
  });

  group('resolveModifiedBy', () {
    test('returns the stored modifier when there is one', () {
      final mod = resolveModifiedBy(
        storedName: 'Riya Patel',
        storedDate: DateTime(2026, 7, 8, 10, 42),
      );
      expect(mod, isNotNull);
      expect(mod!.name, 'Riya Patel');
      expect(mod.date.year, 2026);
    });

    test('returns null rather than inventing a name', () {
      // The old version picked a fake employee out of a pool here.
      expect(resolveModifiedBy(storedName: 'Admin', storedDate: null), isNull);
      expect(
        resolveModifiedBy(storedName: '', storedDate: DateTime.now()),
        isNull,
      );
    });

    test("'Admin' with a real date is kept — it's a legitimate actor", () {
      final mod = resolveModifiedBy(
        storedName: 'Admin',
        storedDate: DateTime(2026, 8, 1),
      );
      expect(mod, isNotNull);
      expect(mod!.name, 'Admin');
    });
  });
}

import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'support/session.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The Clients list, now that the server searches, filters and pages it.
//
// These drive the real code path — the URL the controller builds and the
// envelope it parses — by answering requests with a fake backend rather than
// stubbing the fetch methods, which would skip exactly the logic worth
// testing. Every request is recorded so a test can assert on what was asked
// for, not just what came back.
// ─────────────────────────────────────────────────────────────────────────────

/// Requests the fake backend saw, in order.
late List<String> requests;

/// A client row shaped the way /api/clients returns one.
Map<String, dynamic> _row(int id, {String state = 'Gujarat', String city = ''}) => {
  'id': id,
  'code': 'CLT-${id.toString().padLeft(4, '0')}',
  'name': 'Client $id',
  'address': 'Somewhere, $city - 380005',
  'regState': state,
  'regCity': city,
  'gstin': '24AAAAA0000A1Z$id',
  'modifiedBy': 'Admin',
  'modifiedAt': '2026-09-01T10:00:00.000Z',
  'createdAt': '2026-09-01T10:00:00.000Z',
};

/// Total rows the fake table holds; the envelope reports it so the pager and
/// the "Showing N" line have something real to read.
int fakeTotal = 1049;

/// Rows the next /clients call should answer with.
List<Map<String, dynamic>> fakePage = [_row(1), _row(2)];

/// States and cities /clients/options should report.
Map<String, dynamic> fakeOptions = {
  'states': ['Gujarat', 'Maharashtra'],
  'cities': ['Ahmedabad', 'Pune', 'Surat'],
};

void _installFakeBackend() {
  requests = [];
  ApiClient.useFakeBackend((options) async {
    // options.path already carries the query string the controller built;
    // appending uri.query as well would record every parameter twice.
    final url = options.path;
    requests.add(url);

    dynamic body;
    if (options.path.startsWith('/clients/options')) {
      body = fakeOptions;
    } else if (options.path.startsWith('/clients/directory')) {
      body = [
        {'id': 1, 'code': 'CLT-0001', 'name': 'Client 1', 'regState': 'Gujarat', 'gstin': 'G1'},
        {'id': 2, 'code': 'CLT-0002', 'name': 'Client 2', 'regState': 'Assam', 'gstin': ''},
      ];
    } else if (options.path.startsWith('/clients')) {
      final limit = int.tryParse(options.uri.queryParameters['limit'] ?? '') ?? 10;
      body = {
        'items': fakePage.take(limit).toList(),
        'page': int.tryParse(options.uri.queryParameters['page'] ?? '') ?? 1,
        'limit': limit,
        'total': fakeTotal,
        'totalPages': (fakeTotal / limit).ceil(),
        'hasMore': false,
      };
    } else if (options.path.startsWith('/stats/')) {
      body = <String, dynamic>{};
    } else {
      body = <String, dynamic>{};
    }
    return dio.Response<dynamic>(
      requestOptions: options,
      statusCode: 200,
      data: body,
    );
  });
}

/// Lets the pending futures and the debounce timer run. The fake backend
/// answers immediately, but ApiClient still applies its 1-second artificial
/// delay to anything not marked `instant` - the directory load, for one - so
/// the default here clears that.
Future<void> _settle([int ms = 1400]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

/// The query string of the last /clients list call (not options/directory).
String lastListQuery() => requests.lastWhere(
  (r) => r.startsWith('/clients?') || r == '/clients',
  orElse: () => '',
);

Future<ClientsController> _boot() async {
  final c = Get.put(ClientsController(), permanent: true);
  // onInit fires four calls; the directory one is not `instant`, so this has
  // to outlast ApiClient's artificial delay.
  await _settle(1400);
  return c;
}

void main() {
  setUp(() {
    signInSuperAdmin();
    fakeTotal = 1049;
    fakePage = [_row(1), _row(2)];
    fakeOptions = {
      'states': ['Gujarat', 'Maharashtra'],
      'cities': ['Ahmedabad', 'Pune', 'Surat'],
    };
    _installFakeBackend();
  });

  tearDown(() {
    ApiClient.clearFakeBackend();
    Get.reset();
  });

  test('the first load asks for page one and the supporting lists', () async {
    final c = await _boot();

    expect(requests.any((r) => r.startsWith('/clients?page=1&limit=10')), isTrue,
        reason: 'the table asks for its first page');
    expect(requests.any((r) => r.startsWith('/clients/directory')), isTrue,
        reason: 'the autocomplete needs every name');
    expect(requests.any((r) => r.startsWith('/clients/options')), isTrue,
        reason: 'the filter pills cannot be derived from a page');

    expect(c.clients.length, 2, reason: 'the page, not the whole table');
    expect(c.totalFiltered.value, 1049, reason: 'the match count comes from the server');
    expect(c.totalPages, 105);
    expect(c.directory.length, 2);
    expect(c.directory.first.state, 'Gujarat');
    expect(c.directory.first.gstin, 'G1');
  });

  test('typing is debounced into one request, and resets to page one', () async {
    final c = await _boot();
    c.goToPage(4);
    await _settle(100);
    requests.clear();

    // Four keystrokes in quick succession.
    for (final q in ['a', 'am', 'amb', 'ambi']) {
      c.searchQuery.value = q;
      await _settle(60);
    }
    await _settle(500);

    final listCalls = requests.where((r) => r.startsWith('/clients?')).toList();
    expect(listCalls.length, 1,
        reason: 'four keystrokes must not be four requests: $listCalls');
    expect(listCalls.single, contains('search=ambi'));
    expect(listCalls.single, contains('page=1'),
        reason: 'a new search starts at the first page, not page 4');
    expect(c.currentPage.value, 1);
  });

  test('search text is encoded, so an ampersand cannot split the query', () async {
    final c = await _boot();
    requests.clear();
    c.searchQuery.value = 'A & B Traders';
    await _settle(500);

    final q = lastListQuery();
    expect(q, contains('search=A+%26+B+Traders'));
    expect(q.split('&').where((p) => p.startsWith('search=')).length, 1,
        reason: 'the ampersand must not create a second parameter');
  });

  test('state and city filters ride along, and cities re-cascade', () async {
    final c = await _boot();
    requests.clear();

    c.stateFilters.add('Gujarat');
    await c.onStateFiltersChanged();
    await _settle(100);

    expect(requests.any((r) => r.startsWith('/clients/options?state=Gujarat')), isTrue,
        reason: 'the city list must narrow to the chosen state');
    expect(lastListQuery(), contains('state=Gujarat'));

    c.cityFilters.add('Ahmedabad');
    c.onCityFiltersChanged();
    await _settle(100);
    expect(lastListQuery(), contains('city=Ahmedabad'));
    expect(lastListQuery(), contains('state=Gujarat'),
        reason: 'city narrows within the state, it does not replace it');
  });

  test('several states go up as one comma-separated parameter', () async {
    final c = await _boot();
    requests.clear();
    c.stateFilters.addAll(['Gujarat', 'Maharashtra']);
    await c.onStateFiltersChanged();
    await _settle(100);
    expect(lastListQuery(), contains('state=Gujarat%2CMaharashtra'));
  });

  test('a city the server no longer offers stops filtering the list', () async {
    final c = await _boot();
    c.cityFilters.add('Pune');
    // Gujarat's cities do not include Pune.
    fakeOptions = {
      'states': ['Gujarat', 'Maharashtra'],
      'cities': ['Ahmedabad', 'Surat'],
    };
    c.stateFilters.add('Gujarat');
    await c.onStateFiltersChanged();
    await _settle(100);

    expect(c.cityFilters, isEmpty,
        reason: 'a stale city would keep filtering rows nobody asked to exclude');
    expect(lastListQuery(), isNot(contains('city=')));
  });

  test('the pager and rows-per-page each refetch', () async {
    final c = await _boot();
    requests.clear();

    c.goToPage(3);
    await _settle(100);
    expect(lastListQuery(), contains('page=3'));

    c.setRowsPerPage(25);
    await _settle(100);
    expect(lastListQuery(), contains('limit=25'));
    expect(lastListQuery(), contains('page=1'),
        reason: 'changing the page size starts again at the first page');
  });

  test('Reset clears everything and reloads unfiltered', () async {
    final c = await _boot();
    c.searchQuery.value = 'x';
    c.stateFilters.add('Gujarat');
    c.cityFilters.add('Ahmedabad');
    await _settle(500);
    expect(c.hasActiveFilters, isTrue);
    requests.clear();

    c.resetFilters();
    await _settle(500);

    expect(c.hasActiveFilters, isFalse);
    final q = lastListQuery();
    expect(q, isNot(contains('search=')));
    expect(q, isNot(contains('state=')));
    expect(q, isNot(contains('city=')));
  });

  test('the phone list appends the next page instead of replacing it', () async {
    fakeTotal = 4;
    fakePage = [_row(1), _row(2)];
    final c = await _boot();
    expect(c.clients.length, 2);
    expect(c.hasMore, isTrue);

    fakePage = [_row(3), _row(4)];
    await c.loadMore();
    await _settle(100);

    expect(c.clients.length, 4, reason: 'load more grows the list, it does not swap it');
    expect(c.clients.map((e) => e.id), ['1', '2', '3', '4']);
    expect(c.hasMore, isFalse, reason: 'nothing left to load');
    expect(lastListQuery(), contains('page=2'));
  });

  test('load more does nothing once every row is in', () async {
    fakeTotal = 2;
    final c = await _boot();
    requests.clear();
    await c.loadMore();
    expect(requests.where((r) => r.startsWith('/clients?')), isEmpty);
  });

  test('an export pulls every matching row, not just the page', () async {
    fakeTotal = 3;
    final c = await _boot();
    c.searchQuery.value = 'ambica';
    await _settle(500);

    fakePage = [_row(1), _row(2), _row(3)];
    requests.clear();
    await c.loadExportRows();

    expect(c.exportRows.length, 3,
        reason: 'the export must cover the whole result, not the ten rows on screen');
    final exportCalls = requests.where((r) => r.startsWith('/clients?')).toList();
    expect(exportCalls.first, contains('limit=500'));
    expect(exportCalls.first, contains('search=ambica'),
        reason: 'an export may never widen past what the screen was showing');
  });

  test('with no filters the export fetches one set, not two', () async {
    fakeTotal = 2;
    final c = await _boot();
    requests.clear();
    await c.loadExportRows();

    expect(c.exportRows.length, 2);
    expect(c.exportAllRows.length, 2);
    expect(requests.where((r) => r.startsWith('/clients?')).length, 1,
        reason: 'unfiltered, both scopes are the same rows');
  });

  test('a filtered export also fetches the unfiltered "all" scope', () async {
    fakeTotal = 2;
    final c = await _boot();
    c.searchQuery.value = 'x';
    await _settle(500);
    requests.clear();
    await c.loadExportRows();

    final calls = requests.where((r) => r.startsWith('/clients?')).toList();
    expect(calls.length, 2, reason: 'filtered rows, then the whole table');
    expect(calls.first, contains('search=x'));
    expect(calls.last, isNot(contains('search=')));
  });

  test('findByName answers from the page without a request', () async {
    final c = await _boot();
    requests.clear();

    final found = await c.findByName('Client 1');
    expect(found, isNotNull);
    expect(found!.name, 'Client 1');
    expect(requests, isEmpty, reason: 'it was already on the page');
  });

  test('findByName falls back to a search for a client off the page', () async {
    final c = await _boot();
    requests.clear();
    fakePage = [_row(77)];

    final found = await c.findByName('Client 77');
    expect(found, isNotNull);
    expect(found!.name, 'Client 77');
    expect(lastListQuery(), contains('search=Client+77'));
  });

  test('findByName returns null rather than the wrong client', () async {
    final c = await _boot();
    fakePage = [_row(5)]; // a search hit whose name does not actually match
    expect(await c.findByName('Nobody At All'), isNull);
    expect(await c.findByName('   '), isNull);
  });

  test('a write reloads the page, the cards, the names and the pills', () async {
    final c = await _boot();
    requests.clear();

    await c.deleteClient('1');
    await _settle(100);

    expect(requests.any((r) => r.startsWith('/clients?')), isTrue);
    expect(requests.any((r) => r.startsWith('/clients/directory')), isTrue,
        reason: 'a deleted client must leave the autocomplete too');
    expect(requests.any((r) => r.startsWith('/clients/options')), isTrue,
        reason: 'its state or city may have been the last one');
  });

  test('the pager steps back when the last page empties', () async {
    fakeTotal = 25;
    final c = await _boot();
    c.goToPage(3);
    await _settle(100);
    expect(c.currentPage.value, 3);

    // Rows were deleted while the user sat on the last page.
    fakeTotal = 10;
    fakePage = [];
    await c.fetchClients();
    await _settle(100);

    expect(c.currentPage.value, 1,
        reason: 'a page that no longer exists must not strand the user on empty');
  });
}

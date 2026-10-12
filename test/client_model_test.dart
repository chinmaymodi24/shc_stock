import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';

// Verbatim rows from GET /api/clients — a legacy row imported by
// backend/prisma/seedClients.js, and a row created through the Add Client
// form (structured address, credit terms, contact person).
const _legacyRow = '''
{"id":1,"code":"CLT-0001","name":"Aavkar Enterprise","clientType":"",
 "registrationType":"Regular","email":"","phone":"","altPhone":"",
 "gstin":"24AQTPM1621J1ZP","pan":"","clientSince":null,
 "address":"2nd Floor, Modi Nivas, In Lane of Canara Bank,, Ramnagar, Sabarmati,, Ahmedabad - 380005, Shri Shreyashbhai - 9428421959",
 "regAddr1":"","regAddr2":"","regCity":"","regState":"Gujarat","regPin":"",
 "regCountry":"India","shipSameAsRegistered":true,"shipSameAsBilling":false,
 "shipAddr1":"","shipAddr2":"","shipCity":"","shipState":"","shipPin":"",
 "shipCountry":"India","billingMode":"shipping","billAddr1":"","billAddr2":"",
 "billCity":"","billState":"","billPin":"","billCountry":"India",
 "paymentTerms":"","priceList":"","openingBalance":0,"creditLimit":0,
 "creditDays":0,"contactPerson":"","contactDesignation":"","contactPhone":"",
 "contactEmail":"","modifiedBy":"Admin","modifiedAt":"2026-08-09T16:55:00.000Z",
 "createdAt":"2026-08-09T16:55:00.000Z","updatedAt":"2026-08-09T16:55:00.000Z"}
''';

const _formRow = '''
{"id":1038,"code":"CLT-1038","name":"Zenith Refractory Test Co.",
 "clientType":"Business","registrationType":"Regular",
 "email":"test@zenith.example","phone":"9999900000","altPhone":"",
 "gstin":"24AAAAA0000A1Z5","pan":"AAAAA0000A","clientSince":null,
 "address":"Plot 42, GIDC Phase II, Nr. Water Tank, Morbi - 363642, Gujarat",
 "regAddr1":"Plot 42, GIDC Phase II","regAddr2":"Nr. Water Tank",
 "regCity":"Morbi","regState":"Gujarat","regPin":"363642","regCountry":"India",
 "shipSameAsRegistered":true,"shipSameAsBilling":false,"shipAddr1":"",
 "shipAddr2":"","shipCity":"","shipState":"","shipPin":"","shipCountry":"India",
 "billingMode":"shipping","billAddr1":"","billAddr2":"","billCity":"",
 "billState":"","billPin":"","billCountry":"India","paymentTerms":"Net 30",
 "priceList":"","openingBalance":1500.5,"creditLimit":25000,"creditDays":45,
 "contactPerson":"Shri Test Bhai","contactDesignation":"",
 "contactPhone":"9812345678","contactEmail":"","modifiedBy":"Admin",
 "modifiedAt":null,"createdAt":"2026-08-09T16:55:00.000Z",
 "updatedAt":"2026-08-09T16:55:00.000Z"}
''';

ClientModel _parse(String raw) =>
    ClientModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);

void main() {
  _pinCityGroup();
  _addressOnlyGroup();
  test('maps a legacy seeded row, keeping the list columns working', () {
    final c = _parse(_legacyRow);

    expect(c.id, '1');
    expect(c.code, 'CLT-0001');
    expect(c.name, 'Aavkar Enterprise');
    expect(c.gstin, '24AQTPM1621J1ZP');
    expect(c.registrationType, 'Regular');

    // `state` powers the State filter and the Top States card.
    expect(c.state, 'Gujarat');
    expect(c.country, 'India');
    expect(c.address, contains('Ahmedabad - 380005'));

    // No structured city on legacy rows — falls back to parsing the address.
    expect(c.regCity, '');
    expect(c.city, 'Ahmedabad');

    expect(c.initials, 'AE');
  });

  test('maps a row created through the Add Client form', () {
    final c = _parse(_formRow);

    expect(c.code, 'CLT-1038');
    expect(c.clientType, 'Business');
    expect(c.state, 'Gujarat');
    // Structured city wins over the address parse.
    expect(c.city, 'Morbi');
    expect(c.openingBalance, 1500.5);
    expect(c.creditLimit, 25000);
    expect(c.creditDays, 45);
    expect(c.paymentTerms, 'Net 30');
    expect(c.contactPerson, 'Shri Test Bhai');
    expect(c.contactInitials, 'ST');
    expect(c.modifiedAt, isNull);
  });

  test('toJson round-trips the fields the API accepts', () {
    final c = _parse(_formRow);
    final json = c.toJson();

    expect(json['code'], 'CLT-1038');
    expect(json['name'], 'Zenith Refractory Test Co.');
    expect(json['regCity'], 'Morbi');
    expect(json['creditDays'], 45);
    expect(json['openingBalance'], 1500.5);
    // Server-managed columns must not be echoed back.
    expect(json.containsKey('id'), isFalse);
    expect(json.containsKey('createdAt'), isFalse);
  });

  test('tolerates missing/null optional fields', () {
    final c = ClientModel.fromJson({'id': 7, 'code': 'CLT-0007', 'name': 'X'});
    expect(c.id, '7');
    expect(c.registrationType, 'Regular');
    expect(c.regCountry, 'India');
    expect(c.openingBalance, 0);
    expect(c.creditDays, 0);
    expect(c.city, '');
  });
}

void _pinCityGroup() {
  group('ClientModel city / pin for the order forms', () {
    test('legacy address: city and PIN come out of "City - PIN"', () {
      const c = ClientModel(
        id: '1',
        code: 'CLT-1',
        name: 'Aavkar',
        address:
            '2nd Floor, Modi Nivas, Ramnagar, Sabarmati, Ahmedabad - 380005',
      );
      expect(c.city, 'Ahmedabad');
      expect(c.pin, '380005');
    });

    test('structured fields win over the address', () {
      const c = ClientModel(
        id: '2',
        code: 'CLT-2',
        name: 'X',
        address: 'Somewhere - 111111',
        regCity: 'Rajkot',
        regPin: '360001',
      );
      expect(c.city, 'Rajkot');
      expect(c.pin, '360001');
    });

    test('no PIN anywhere gives an empty string', () {
      const c = ClientModel(
        id: '3',
        code: 'CLT-3',
        name: 'Y',
        address: 'Morbi.',
      );
      expect(c.pin, '');
    });

    test('a longer number is not mistaken for a PIN', () {
      const c = ClientModel(
        id: '4',
        code: 'CLT-4',
        name: 'Z',
        address: 'Plot 12345678, Surat',
      );
      expect(c.pin, '');
    });
  });
}

void _addressOnlyGroup() {
  group('ClientModel.addressOnly', () {
    String only(String a, {String regCity = '', String regPin = ''}) =>
        ClientModel(
          id: '1',
          code: 'C',
          name: 'N',
          address: a,
          regCity: regCity,
          regPin: regPin,
        ).addressOnly;

    test('drops "City - PIN"', () {
      expect(
        only('2nd Floor, Modi Nivas, Ramnagar, Sabarmati, Ahmedabad - 380005'),
        '2nd Floor, Modi Nivas, Ramnagar, Sabarmati',
      );
    });
    test(
      'drops a "Dist." prefix with the city, and the state after the PIN',
      () {
        expect(
          only(
            'Plot 687, Village Vanod, Th. Dasada, Dist. Surendranagar - 382750',
          ),
          'Plot 687, Village Vanod, Th. Dasada',
        );
        expect(
          only(
            'Room 31, Transport Nagar, Mango, Jamshedpur - 831012 Jharkhand',
          ),
          'Room 31, Transport Nagar, Mango',
        );
      },
    );
    test('no PIN: address untouched', () {
      expect(
        only('Samrajya Tower, Memnagar, Ahmedabad'),
        'Samrajya Tower, Memnagar, Ahmedabad',
      );
    });
    test('never returns an empty address', () {
      expect(only('Ahmedabad - 380005'), 'Ahmedabad - 380005');
    });
  });
}

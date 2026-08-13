import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_ripple_controller.dart';
import 'package:shc_stock/app/modules/users/controllers/users_controller.dart';
import 'package:shc_stock/app/modules/users/models/user_model.dart';
import 'package:shc_stock/app/modules/users/views/web_users_layout.dart';

// Verbatim rows from GET /api/users — note there is no passwordHash field.
const _adminRow = '''
{"id":1,"code":"USR-0001","name":"Chinmay Modi","email":"shc@gmail.com",
 "role":"Admin","phone":"+91 98765 00001","department":"Management",
 "isActive":true,"lastLoginAt":"2026-08-09T14:32:00.000Z",
 "modifiedBy":"Admin","modifiedAt":null,
 "createdAt":"2026-01-01T00:00:00.000Z"}
''';

const _inactiveRow = '''
{"id":7,"code":"USR-0007","name":"Neha Iyer","email":"neha@shc.com",
 "role":"Stock Manager","phone":"+91 98765 00007","department":"",
 "isActive":false,"lastLoginAt":null,"modifiedBy":"Admin","modifiedAt":null,
 "createdAt":"2026-02-10T00:00:00.000Z"}
''';

UserModel _parse(String raw) =>
    UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);

class _OfflineUsersController extends UsersController {
  @override
  Future<void> fetchUsers() async {
    users.assignAll([_parse(_adminRow), _parse(_inactiveRow)]);
  }

  @override
  Future<void> fetchStats() async {
    stats.value = StatsSnapshot.fromJson(const {
      'totalUsers': 15,
      'activeUsers': 12,
      'inactiveUsers': 3,
      'adminCount': 1,
      'trends': {'totalUsers': 7.1, 'activeUsers': null},
    });
    roleCounts.assignAll(const [
      RoleCount(role: 'Salesman', count: 6),
      RoleCount(role: 'Stock Manager', count: 3),
      RoleCount(role: 'Admin', count: 1),
    ]);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  group('UserModel.fromJson', () {
    test('maps an active admin row', () {
      final u = _parse(_adminRow);
      expect(u.id, '1');
      expect(u.code, 'USR-0001');
      expect(u.name, 'Chinmay Modi');
      expect(u.initials, 'CM');
      expect(u.email, 'shc@gmail.com');
      expect(u.role, UserRole.admin);
      expect(u.isActive, isTrue);
      expect(u.department, 'Management');
      expect(u.createdAt, '01 Jan 2026');
    });

    test(
      'formats lastLogin, and shows Never when the user never logged in',
      () {
        expect(_parse(_adminRow).lastLogin, contains('09 Aug 2026'));
        expect(_parse(_inactiveRow).lastLogin, 'Never');
      },
    );

    test('maps the multi-word "Stock Manager" role label', () {
      expect(_parse(_inactiveRow).role, UserRole.stockManager);
      expect(_parse(_inactiveRow).isActive, isFalse);
    });

    test('an unknown role falls back instead of throwing', () {
      final u = UserModel.fromJson({
        'id': 9,
        'code': 'USR-0009',
        'name': 'Future Role',
        'role': 'Chief Vibes Officer',
      });
      expect(u.role, UserRole.salesman);
    });

    test('toJson sends the role label and never a password', () {
      final json = _parse(_adminRow).toJson();
      expect(json['role'], 'Admin');
      expect(json['code'], 'USR-0001');
      expect(json.containsKey('password'), isFalse);
      expect(json.containsKey('passwordHash'), isFalse);
      expect(json.containsKey('id'), isFalse);
    });
  });

  testWidgets('Employee summary cards render the API figures', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Get.put(ThemeController(), permanent: true);
    Get.put(ThemeRippleController(), permanent: true);
    Get.put<UsersController>(_OfflineUsersController());

    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData(extensions: const [AppThemeColors.light]),
        home: const WebUsersLayout(),
      ),
    );
    await tester.pump();

    // Card values come from /api/stats/users, not from users.length (which
    // is 2 here) — proving the cards are API-driven, not locally computed.
    expect(find.text('15'), findsWidgets);
    expect(find.text('12'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.text('+7.1%'), findsWidgets);
    // A null trend prints nothing, and the retired literals are gone.
    expect(find.text('+12.5%'), findsNothing);
    expect(find.text('+8.3%'), findsNothing);
    expect(find.text('-5.0%'), findsNothing);

    // Rows still render from the list.
    expect(find.text('Chinmay Modi'), findsWidgets);
    expect(find.text('Neha Iyer'), findsWidgets);
  });
}

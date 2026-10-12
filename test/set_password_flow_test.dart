import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/auth/controllers/set_password_controller.dart';
import 'package:shc_stock/app/modules/auth/views/set_password_view.dart';
import 'package:shc_stock/app/routes/app_routes.dart';

// The "set your own password" step: an employee whose password somebody else
// chose is held on one screen until they pick their own.

late List<({String path, dynamic body})> requests;

/// Status and body the fake backend answers /settings/password with.
int passwordStatus = 200;
Map<String, dynamic> passwordBody = const {'ok': true};

void _fakeBackend() {
  requests = [];
  passwordStatus = 200;
  passwordBody = const {'ok': true};
  ApiClient.useFakeBackend((options) async {
    requests.add((path: options.path, body: options.data));
    final isPassword = options.path == '/settings/password';
    final res = dio.Response<dynamic>(
      requestOptions: options,
      statusCode: isPassword ? passwordStatus : 200,
      data: isPassword ? passwordBody : <String, dynamic>{},
    );
    if (res.statusCode! >= 400) {
      throw dio.DioException(requestOptions: options, response: res);
    }
    return res;
  });
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 1400));

SessionUser _tempUser({bool must = true}) => SessionUser(
  id: 7,
  name: 'New Employee',
  email: 'new@example.com',
  token: 'token-7',
  isSuperAdmin: true,
  mustChangePassword: must,
);

Future<void> _pumpView(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final session = Get.put(SessionController(), permanent: true);
  session.user.value = _tempUser();
  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(extensions: [AppThemeColors.light]),
      initialRoute: AppRoutes.setPassword,
      getPages: [
        GetPage(name: AppRoutes.setPassword, page: () => const SetPasswordView()),
        GetPage(name: AppRoutes.dashboard, page: () => const Text('DASHBOARD')),
        GetPage(name: AppRoutes.login, page: () => const Text('LOGIN')),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester, String cur, String next, String conf) async {
  final boxes = find.byType(TextField);
  await tester.enterText(boxes.at(0), cur);
  await tester.enterText(boxes.at(1), next);
  await tester.enterText(boxes.at(2), conf);
}

void main() {
  setUp(_fakeBackend);
  tearDown(() {
    ApiClient.clearFakeBackend();
    ApiClient.instance.onUnauthorized = null;
    ApiClient.instance.onPasswordChangeRequired = null;
    Get.reset();
  });

  group('checkNewPassword', () {
    test('accepts a good change', () {
      expect(checkNewPassword(current: 'old123', next: 'brandnew1', confirm: 'brandnew1'), isNull);
    });
    test('wants the current password', () {
      expect(checkNewPassword(current: '', next: 'brandnew1', confirm: 'brandnew1'), contains('given'));
    });
    test('wants at least 6 characters', () {
      expect(checkNewPassword(current: 'old123', next: 'abc', confirm: 'abc'), contains('at least 6'));
    });
    test('refuses the same password again', () {
      expect(checkNewPassword(current: 'old123', next: 'old123', confirm: 'old123'), contains('different'));
    });
    test('wants both entries to match', () {
      expect(checkNewPassword(current: 'old123', next: 'brandnew1', confirm: 'brandnew2'), contains('do not match'));
    });
  });

  group('session', () {
    test('mustChangePassword survives the stored JSON and routes to the screen', () {
      final u = SessionUser.fromJson({..._tempUser().toJson()});
      expect(u.mustChangePassword, isTrue);
      final session = Get.put(SessionController(), permanent: true);
      session.user.value = u;
      expect(session.homeRoute, AppRoutes.setPassword);
      session.user.value = u.withPasswordChosen();
      expect(session.homeRoute, AppRoutes.dashboard);
    });

    test('choosing a password swaps in the fresh token the server returned', () {
      final u = _tempUser();
      expect(u.withPasswordChosen(token: 'fresh').token, 'fresh');
      expect(u.withPasswordChosen(token: 'fresh').mustChangePassword, isFalse);
      expect(u.withPasswordChosen().token, 'token-7', reason: 'no token back -> keep the current one');
      expect(u.withPasswordChosen(token: '').token, 'token-7');
    });

    test('where an employee lands depends on what they were granted', () {
      final session = Get.put(SessionController(), permanent: true);
      SessionUser withPerms(Map<String, ModuleAccess> p) => SessionUser(
        id: 9, name: 'E', email: 'e@x.co', token: 't', permissions: p,
      );
      session.user.value = withPerms({'Dashboard': ModuleAccess.full});
      expect(session.homeRoute, AppRoutes.dashboard);
      session.user.value = withPerms({'Sales': ModuleAccess.full});
      expect(session.homeRoute, AppRoutes.sales, reason: 'no Dashboard -> the first module they have');
      session.user.value = withPerms({});
      expect(session.homeRoute, AppRoutes.settings, reason: 'nothing granted -> Settings, never a redirect loop');
    });

    test('a session saved before this existed is not held', () {
      final u = SessionUser.fromJson({'id': 1, 'name': 'Old', 'email': 'o@x.co', 'token': 't'});
      expect(u.mustChangePassword, isFalse);
    });
  });

  group('api client', () {
    test('a wrong current password (401) does not sign the person out', () async {
      var signedOut = 0;
      ApiClient.instance.onUnauthorized = () => signedOut++;
      passwordStatus = 401;
      passwordBody = const {'error': 'Current password is incorrect'};
      await expectLater(
        ApiClient.instance.post('/settings/password', {'currentPassword': 'x'}),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Current password is incorrect')),
      );
      expect(signedOut, 0);
    });

    test('a 401 anywhere else still means the session ended', () async {
      var signedOut = 0;
      ApiClient.instance.onUnauthorized = () => signedOut++;
      ApiClient.useFakeBackend((o) async {
        throw dio.DioException(
          requestOptions: o,
          response: dio.Response<dynamic>(requestOptions: o, statusCode: 401, data: {'error': 'Your session has ended.'}),
        );
      });
      await expectLater(ApiClient.instance.get('/products'), throwsA(isA<ApiException>()));
      expect(signedOut, 1);
    });

    test('403 PASSWORD_CHANGE_REQUIRED calls the hook', () async {
      var held = 0;
      ApiClient.instance.onPasswordChangeRequired = () => held++;
      ApiClient.useFakeBackend((o) async {
        throw dio.DioException(
          requestOptions: o,
          response: dio.Response<dynamic>(
            requestOptions: o,
            statusCode: 403,
            data: {'error': 'Set your own password before continuing.', 'code': 'PASSWORD_CHANGE_REQUIRED'},
          ),
        );
      });
      await expectLater(
        ApiClient.instance.get('/products'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'PASSWORD_CHANGE_REQUIRED')),
      );
      expect(held, 1);
    });
  });

  group('screen', () {
    testWidgets('mismatched confirmation is caught before any request', (tester) async {
      await _pumpView(tester);
      await _fill(tester, 'given1', 'brandnew1', 'brandnew2');
      await tester.tap(find.text('Save and continue'));
      await tester.pumpAndSettle();
      expect(find.text('New password and confirmation do not match.'), findsOneWidget);
      expect(requests.where((r) => r.path == '/settings/password'), isEmpty);
    });

    testWidgets('a good change posts, clears the flag and opens the dashboard', (tester) async {
      await _pumpView(tester);
      await _fill(tester, 'given1', 'brandnew1', 'brandnew1');
      await tester.tap(find.text('Save and continue'));
      await tester.pump();
      await tester.runAsync(_settle);
      await tester.pumpAndSettle();

      final sent = requests.singleWhere((r) => r.path == '/settings/password');
      expect(sent.body['userId'], 7);
      expect(sent.body['currentPassword'], 'given1');
      expect(sent.body['newPassword'], 'brandnew1');
      expect(Get.find<SessionController>().user.value!.mustChangePassword, isFalse);
      expect(find.text('DASHBOARD'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 4));
      }
    });

    testWidgets('a wrong current password stays on the screen with the message', (tester) async {
      await _pumpView(tester);
      passwordStatus = 401;
      passwordBody = const {'error': 'Current password is incorrect'};
      await _fill(tester, 'nope123', 'brandnew1', 'brandnew1');
      await tester.tap(find.text('Save and continue'));
      await tester.pump();
      await tester.runAsync(_settle);
      await tester.pumpAndSettle();
      expect(find.text('Current password is incorrect'), findsOneWidget);
      expect(find.text('LOGIN'), findsNothing, reason: 'must not be signed out');
      expect(Get.find<SessionController>().user.value!.mustChangePassword, isTrue);
    });

    testWidgets('Sign out returns to the login page', (tester) async {
      await _pumpView(tester);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('LOGIN'), findsOneWidget);
      expect(Get.find<SessionController>().isSignedIn, isFalse);
    });
  });
}

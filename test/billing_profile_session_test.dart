import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/modules/billing/controllers/billing_profile_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The billing profile follows the session.
//
// It used to be fetched straight from main(), which put a request to a
// token-guarded endpoint on the wire before anyone had signed in - a 401 in
// the console on every cold start. These drive the real path through a fake
// backend and assert on what was actually requested, and when.
// ─────────────────────────────────────────────────────────────────────────────

/// Paths the fake backend saw, in order.
late List<String> requests;

const _serverProfile = {
  'legalName': 'Secure Heat Care',
  'gstin': '24AAACS9876P1ZK',
  'invoicePrefix': 'ST',
};

void _installFakeBackend() {
  requests = [];
  ApiClient.useFakeBackend((options) async {
    requests.add(options.path);
    return dio.Response<dynamic>(
      requestOptions: options,
      statusCode: 200,
      data: options.path.startsWith('/settings/billing')
          ? _serverProfile
          : <String, dynamic>{},
    );
  });
}

/// Clears ApiClient's 1-second artificial delay plus the pending futures.
Future<void> _settle([int ms = 1400]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

int get _billingCalls =>
    requests.where((r) => r.startsWith('/settings/billing')).length;

SessionUser _user(int id, String name) => SessionUser(
  id: id,
  name: name,
  email: '$name@example.com',
  isSuperAdmin: true,
  token: 'token-$id',
);

void main() {
  late SessionController session;

  setUp(() {
    _installFakeBackend();
    // Registered by hand rather than through the shared helper: these tests
    // sign in and out mid-test, so they need to hold the controller.
    session = Get.put(SessionController(), permanent: true);
  });

  tearDown(() {
    Get.reset();
    ApiClient.clearFakeBackend();
  });

  test('signed out, nothing is requested', () async {
    Get.put(BillingProfileController(), permanent: true);
    await _settle();

    expect(_billingCalls, 0);
    expect(BillingProfileController.to.isLoaded.value, isFalse);
  });

  test('signing in fetches the profile', () async {
    Get.put(BillingProfileController(), permanent: true);
    await _settle(50);
    expect(_billingCalls, 0);

    session.user.value = _user(1, 'Deepak');
    await _settle();

    expect(_billingCalls, 1);
    expect(BillingProfileController.to.profile.value.gstin, '24AAACS9876P1ZK');
    expect(BillingProfileController.to.isLoaded.value, isTrue);
  });

  test('a session already signed in is picked up on registration', () async {
    session.user.value = _user(1, 'Deepak');
    Get.put(BillingProfileController(), permanent: true);
    await _settle();

    expect(_billingCalls, 1);
  });

  test('restore then refresh writes the same user twice, but fetches once',
      () async {
    Get.put(BillingProfileController(), permanent: true);
    await _settle(50);

    // What SessionController.restore() does: the saved session, then the
    // fresher copy /auth/me hands back.
    session.user.value = _user(7, 'Deepak');
    session.user.value = _user(7, 'Deepak Shah');
    await _settle();

    expect(_billingCalls, 1);
  });

  test('signing out drops the profile, and the next user fetches again',
      () async {
    session.user.value = _user(1, 'Deepak');
    Get.put(BillingProfileController(), permanent: true);
    await _settle();
    expect(_billingCalls, 1);

    session.user.value = null;
    await _settle(50);
    expect(BillingProfileController.to.profile.value.gstin, '');
    expect(BillingProfileController.to.isLoaded.value, isFalse);

    session.user.value = _user(2, 'Riya');
    await _settle();
    expect(_billingCalls, 2);
    expect(BillingProfileController.to.isLoaded.value, isTrue);
  });

  test('without a session registered it still fetches eagerly', () async {
    Get.reset();
    Get.put(BillingProfileController(), permanent: true);
    await _settle();

    expect(_billingCalls, 1);
  });
}

import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/api/api_client.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/utils/app_toast.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'package:shc_stock/app/shared/widgets/status_update_dialog_shell.dart';
import 'support/session.dart';

// A status change the server refuses (Delivered with too little stock) shows
// its reason in a toast. The shell used to call Get.back() afterwards, which
// closed that toast instead of the dialog.

Future<void> _open(WidgetTester tester, Future<void> Function() onSave) async {
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: ThemeData(extensions: [AppThemeColors.light]),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Get.dialog(
              StatusUpdateDialogShell(
                title: 'Update Status',
                subtitle: 'SO-1',
                body: const Text('body'),
                onSave: onSave,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    ApiClient.clearFakeBackend();
    Get.reset();
  });

  testWidgets('a refused status change keeps its reason on screen', (
    tester,
  ) async {
    await _open(tester, () async {
      showAppToast(
        'Error',
        'Not enough stock to deliver this order.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    });
    expect(find.text('Update Status'), findsOneWidget);
    await tester.tap(find.text('Update'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(
      find.text('Update Status'),
      findsNothing,
      reason: 'the dialog closes',
    );
    expect(
      find.textContaining('Not enough stock'),
      findsOneWidget,
      reason: 'the toast survives',
    );
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 4));
    }
    await tester.pumpAndSettle();
  });

  testWidgets('a successful save just closes the dialog', (tester) async {
    var saved = false;
    await _open(tester, () async => saved = true);
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(saved, isTrue);
    expect(find.text('Update Status'), findsNothing);
  });

  testWidgets('deleting a client that has sales shows the server reason', (
    tester,
  ) async {
    signInSuperAdmin();
    ApiClient.useFakeBackend((o) async {
      throw dio.DioException(
        requestOptions: o,
        response: dio.Response<dynamic>(
          requestOptions: o,
          statusCode: 409,
          data: {
            'error': 'This client has 2 sales orders, so it cannot be deleted.',
          },
        ),
      );
    });
    final c = Get.put<ClientsController>(_Clients());
    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData(extensions: [AppThemeColors.light]),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.runAsync(() => c.deleteClient('5'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('has 2 sales orders'), findsOneWidget);
    expect(find.text('Failed to delete client.'), findsNothing);
    Get.closeAllSnackbars();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 4));
    }
    await tester.pumpAndSettle();
  });
}

class _Clients extends ClientsController {
  @override
  void onInit() {} // ignore: must_call_super
  @override
  void onReady() {} // ignore: must_call_super
}

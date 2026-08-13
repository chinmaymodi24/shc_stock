import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_ripple_controller.dart';
import 'package:shc_stock/app/modules/clients/controllers/add_client_controller.dart';
import 'package:shc_stock/app/modules/clients/views/web_add_client_layout.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  testWidgets('Credit & Summary renders and tracks the credit inputs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Get.put(ThemeController(), permanent: true);
    Get.put(ThemeRippleController(), permanent: true);
    final c = Get.put(AddClientController());

    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData(extensions: const [AppThemeColors.light]),
        home: const WebAddClientLayout(),
      ),
    );
    await tester.pump();

    // The card used to throw "improper use of a GetX" here — an Obx with no
    // observable to subscribe to. Rendering it at all is the regression guard.
    expect(find.text('Credit & Summary'), findsOneWidget);
    expect(find.text('Opening Balance (₹)'), findsWidgets);

    // Values must also actually track the text fields as they change.
    c.opBalCtrl.text = '1500';
    c.crLimCtrl.text = '25000';
    c.crDaysCtrl.text = '45';
    await tester.pump();

    expect(find.text('1500.00'), findsOneWidget);
    expect(find.text('25000.00'), findsOneWidget);
    expect(find.text('45 days'), findsOneWidget);
  });
}

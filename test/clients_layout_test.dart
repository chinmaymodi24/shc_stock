import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/api/stats_snapshot.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_ripple_controller.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/clients/views/web_clients_layout.dart';

/// The real controller fetches /api/clients and /api/stats/clients on init.
/// This is a layout test, so it stands in fixed data instead of hitting the
/// network — which would otherwise leave the API client's delay timer pending.
class _OfflineClientsController extends ClientsController {
  @override
  Future<void> fetchStats() async {
    stats.value = StatsSnapshot.fromJson(const {
      'totalClients': 2,
      'gstRegistered': 2,
      'unregistered': 0,
      'statesCovered': 2,
      'trends': {'totalClients': 12.5},
    });
    topStates.assignAll(const [
      TopStateEntry(state: 'Gujarat', count: 1),
      TopStateEntry(state: 'Maharashtra', count: 1),
    ]);
  }

  @override
  Future<void> fetchClients() async {
    clients.assignAll(const [
      ClientModel(
        id: '1',
        code: 'CLT-0001',
        name: 'Aavkar Enterprise',
        address: 'Ramnagar, Sabarmati, Ahmedabad - 380005',
        regState: 'Gujarat',
        gstin: '24AQTPM1621J1ZP',
      ),
      ClientModel(
        id: '2',
        code: 'CLT-0002',
        name: 'Amaan Traders',
        address: 'Chikhali, Dist. Pune - 411062',
        regState: 'Maharashtra',
        gstin: '27ATXPM3307L1Z2',
      ),
    ]);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  testWidgets('right panel runs alongside the header and summary cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Get.put(ThemeController(), permanent: true);
    Get.put(ThemeRippleController(), permanent: true);
    Get.put<ClientsController>(_OfflineClientsController());

    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData(extensions: const [AppThemeColors.light]),
        home: const WebClientsLayout(),
      ),
    );
    await tester.pump();

    final topStates = tester.getTopLeft(find.text('Top States'));
    final totalClients = tester.getTopLeft(find.text('Total Clients'));
    final table = tester.getTopLeft(find.text('Client Code'));
    debugPrint('Top States    => $topStates');
    debugPrint('Total Clients => $totalClients');
    debugPrint('Client Code   => $table');

    // The panel must start at the top of the page, not below the summary row.
    expect(
      topStates.dy,
      lessThan(totalClients.dy),
      reason: 'Top States should sit above the summary cards, not below them',
    );

    // …and it must be to the right of the summary cards, not underneath them.
    expect(topStates.dx, greaterThan(totalClients.dx));

    // Rows come from the controller's list (now API-backed), and the stat
    // cards / Top States card are derived from the same data.
    expect(find.text('Aavkar Enterprise'), findsWidgets);
    expect(find.text('CLT-0002'), findsOneWidget);
    expect(find.text('Gujarat'), findsWidgets);
  });
}

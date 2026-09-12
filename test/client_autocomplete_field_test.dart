import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/clients/controllers/clients_controller.dart';
import 'package:shc_stock/app/modules/clients/models/client_model.dart';
import 'package:shc_stock/app/modules/clients/widgets/client_autocomplete_field.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The consignee/client field on Add Purchase and Add Sale. Web showed
// suggestions here; mobile silently didn't, because the framework's
// `Autocomplete` always drops its list BELOW the field — which on a phone is
// behind the soft keyboard. These tests pin the fix: suggestions appear, and
// they flip above the field when the keyboard leaves no room below.
// ─────────────────────────────────────────────────────────────────────────────

class _StubClients extends ClientsController {
  @override
  Future<void> fetchClients() async {}
  @override
  Future<void> fetchStats() async {}
}

ClientModel _client(
  String id,
  String name, {
  String state = 'Gujarat',
  String gstin = '',
}) => ClientModel(
  id: id,
  code: 'CL-$id',
  name: name,
  regState: state,
  gstin: gstin,
);

final _sampleClients = [
  _client('1', 'Aavkar Enterprise', gstin: '24AQTPM1621J1ZP'),
  _client('2', 'Maa Vaishnvi Enterprises', state: 'Assam'),
  _client('3', 'Amaan Traders', state: 'Maharashtra', gstin: '27ATXPM3307L1Z2'),
];

Widget _host(Widget child) => MaterialApp(
  theme: ThemeData(extensions: [AppThemeColors.light]),
  home: Scaffold(body: Center(child: child)),
);

Widget _field({ValueChanged<ClientModel>? onSelected}) =>
    ClientAutocompleteField(
      initialValue: '',
      colors: AppThemeColors.light,
      onSelected: onSelected ?? (_) {},
    );

void main() {
  setUp(() {
    final clients = _StubClients();
    Get.put<ClientsController>(clients, permanent: true);
    clients.clients.assignAll(_sampleClients);
  });

  tearDown(Get.reset);

  testWidgets('typing shows matching clients with their state/GSTIN', (
    tester,
  ) async {
    await tester.pumpWidget(_host(SizedBox(width: 380, child: _field())));

    expect(find.text('Aavkar Enterprise'), findsNothing);

    await tester.enterText(find.byType(TextField), 'aa');
    await tester.pumpAndSettle();

    // All three sample names contain "aa".
    expect(find.text('Aavkar Enterprise'), findsOneWidget);
    expect(find.text('Maa Vaishnvi Enterprises'), findsOneWidget);
    expect(find.text('Amaan Traders'), findsOneWidget);
    // Subtitle carries state · GSTIN, falling back to Unregistered.
    expect(find.text('Assam · Unregistered'), findsOneWidget);
  });

  testWidgets('narrowing the query narrows the list', (tester) async {
    await tester.pumpWidget(_host(SizedBox(width: 380, child: _field())));

    await tester.enterText(find.byType(TextField), 'aav');
    await tester.pumpAndSettle();

    expect(find.text('Aavkar Enterprise'), findsOneWidget);
    expect(find.text('Amaan Traders'), findsNothing);
  });

  testWidgets(
    'suggestions flip above the field once the keyboard covers the space '
    'below it — the mobile bug this widget exists for',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: 350);
      addTearDown(tester.view.reset);

      // Scaffold shrinks its body for the keyboard inset; bottom-aligning the
      // field inside that shrunk body puts it right above the keyboard, which
      // is exactly where a focused mid-form field ends up on a phone.
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AppThemeColors.light]),
          home: Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(padding: const EdgeInsets.all(16), child: _field()),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'aav');
      await tester.pumpAndSettle();

      expect(find.text('Aavkar Enterprise'), findsOneWidget);

      final fieldRect = tester.getRect(find.byType(TextField));
      final optionRect = tester.getRect(find.text('Aavkar Enterprise'));
      expect(
        optionRect.bottom,
        lessThanOrEqualTo(fieldRect.top + 1),
        reason:
            'with no room below, the list must render above the field '
            'instead of disappearing behind the keyboard',
      );
    },
  );

  testWidgets('tapping a suggestion fills the field and reports the client', (
    tester,
  ) async {
    ClientModel? picked;
    await tester.pumpWidget(
      _host(SizedBox(width: 380, child: _field(onSelected: (c) => picked = c))),
    );

    await tester.enterText(find.byType(TextField), 'aav');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aavkar Enterprise'));
    await tester.pumpAndSettle();

    expect(picked?.id, '1');
    expect(find.widgetWithText(TextField, 'Aavkar Enterprise'), findsOneWidget);
    // The dropdown is gone — its subtitle row was only there while showing.
    expect(find.text('Gujarat · 24AQTPM1621J1ZP'), findsNothing);
  });

  testWidgets('arrow keys move the highlight and Enter picks it', (
    tester,
  ) async {
    ClientModel? picked;
    await tester.pumpWidget(
      _host(SizedBox(width: 380, child: _field(onSelected: (c) => picked = c))),
    );

    await tester.enterText(find.byType(TextField), 'aa');
    await tester.pumpAndSettle();

    // Options come back in list order: Aavkar, Maa Vaishnvi, Amaan.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(picked?.name, 'Maa Vaishnvi Enterprises');
  });
}

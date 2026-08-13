import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/session/session_controller.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/core/theme/theme_controller.dart';
import 'package:shc_stock/app/core/theme/theme_ripple_controller.dart';
import 'package:shc_stock/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:shc_stock/app/modules/dashboard/views/web_dashboard_layout.dart';
import 'package:shc_stock/app/modules/dashboard/models/dashboard_models.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/bar_chart.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/category_breakdown.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/chart_tooltip.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/donut_chart.dart';
import 'package:shc_stock/app/modules/dashboard/widgets/sales_chart.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard charts: the legend has to fit the card it lives in, and every
// chart has to answer a hover with a tooltip.
//
// The donut legend is the reason the first group exists — six API-driven
// categories at a fixed row gap overflowed the 150px chart slot by 36px.
// ─────────────────────────────────────────────────────────────────────────────

final _slices = <CategorySlice>[
  const CategorySlice(
    label: 'Ceramic Fiber Products',
    percent: 56,
    color: AppColors.primaryPurple,
    value: 1250000,
  ),
  const CategorySlice(
    label: 'Fire & Welding Protection',
    percent: 12,
    color: AppColors.primaryOrange,
    value: 268000,
  ),
  const CategorySlice(
    label: 'Mortars & Castables',
    percent: 9,
    color: AppColors.accentPurple,
    value: 201000,
  ),
  const CategorySlice(
    label: 'Ceramic Fiber Textile',
    percent: 8,
    color: Color(0xFF0EA5E9),
    value: 178000,
  ),
  const CategorySlice(
    label: 'Insulation Bricks',
    percent: 8,
    color: Color(0xFF22C55E),
    value: 176000,
  ),
  const CategorySlice(
    label: 'Other (2)',
    percent: 7,
    color: Color(0xFF6366F1),
    value: 156000,
  ),
];

const _months = <ChartPoint>[
  ChartPoint(label: 'Mar', value: 120000),
  ChartPoint(label: 'Apr', value: 240000),
  ChartPoint(label: 'May', value: 90000),
  ChartPoint(label: 'Jun', value: 310000),
  ChartPoint(label: 'Jul', value: 150000),
  ChartPoint(label: 'Aug', value: 480000),
];

Widget _host(Widget child, {double width = 380}) {
  return MaterialApp(
    theme: ThemeData(extensions: const [AppThemeColors.light]),
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

/// Moves a synthetic mouse to [target] and settles the frame.
Future<TestGesture> _hover(WidgetTester tester, Offset target) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(target);
  await tester.pumpAndSettle();
  return gesture;
}

/// Signed-in user the top bar greets.
class _StubSession extends SessionController {
  @override
  Future<void> restore() async => user.value = const SessionUser(
    id: 1,
    name: 'Chinmay Modi',
    email: 'shc@gmail.com',
    role: 'Admin',
  );
}

/// Dashboard data as the API actually returns it — six category slices, which
/// is the case that overflowed the donut card.
class _SixSliceDashboard extends DashboardController {
  @override
  Future<void> fetchNotes() async {}

  @override
  Future<void> fetchDashboard() async {
    purchasesData.assignAll(_months);
    salesData.assignAll(_months);
    newClientsData.assignAll(_months);
    categorySlices.assignAll(_slices);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  group('donut legend fits its card', () {
    testWidgets('six slices do not overflow the real dashboard card', (
      tester,
    ) async {
      // A real laptop viewport — the card only misbehaves at true size.
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Get.put(ThemeController(), permanent: true);
      Get.put(ThemeRippleController(), permanent: true);
      Get.put<SessionController>(_StubSession(), permanent: true);
      Get.put<DashboardController>(_SixSliceDashboard());

      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData(extensions: const [AppThemeColors.light]),
          home: const WebDashboardLayout(),
        ),
      );
      await tester.pump();

      // flutter_test fails on any RenderFlex overflow, so reaching here with
      // all six labels on screen is the assertion.
      expect(find.textContaining('Other (2)'), findsWidgets);
      expect(find.textContaining('Ceramic Fiber Textile'), findsWidgets);
    });
  });

  group('donut legend fits a 150px slot', () {
    testWidgets('six slices in a 150px slot do not overflow', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            height: 150,
            child: Center(
              child: CategoryDonutChart(slices: [], size: 120),
            ),
          ),
        ),
      );
      // Re-pump with the real slices so the legend lays out against the same
      // 150px height the dashboard card gives it.
      await tester.pumpWidget(
        _host(
          SizedBox(
            height: 150,
            child: Center(
              child: CategoryDonutChart(slices: _slices, size: 120),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final legend = tester.getSize(
        find.ancestor(
          of: find.textContaining('Ceramic Fiber Products'),
          matching: find.byType(Column),
        ).first,
      );
      expect(legend.height, lessThanOrEqualTo(150));
    });
  });

  group('hover tooltips', () {
    testWidgets('bar chart reports the hovered month in rupees', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SimpleBarChart(
            data: _months,
            barColor: AppColors.primaryPurple,
            height: 150,
            valueFormatter: (v) => '₹${v.round()}',
          ),
        ),
      );

      expect(find.byType(ChartTooltip), findsNothing);
      // Centre of the last column ("Aug"), a little above the axis labels.
      final chart = tester.getRect(find.byType(SimpleBarChart));
      await _hover(
        tester,
        Offset(chart.left + chart.width * (5 + 0.5) / 6, chart.center.dy),
      );

      expect(find.byType(ChartTooltip), findsOneWidget);
      expect(find.text('₹480000'), findsOneWidget);
    });

    testWidgets('line chart reports the nearest point', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            height: 150,
            child: SalesLineChart(
              data: _months,
              lineColor: AppColors.accentPurple,
            ),
          ),
        ),
      );

      final chart = tester.getRect(find.byType(SalesLineChart));
      await _hover(tester, Offset(chart.left + 4, chart.center.dy));

      expect(find.byType(ChartTooltip), findsOneWidget);
      expect(find.text('Mar'), findsWidgets);
      expect(find.text('120000'), findsOneWidget);
    });

    testWidgets('donut reports the hovered arc with value and share', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            height: 150,
            child: Center(
              child: CategoryDonutChart(slices: _slices, size: 120),
            ),
          ),
        ),
      );

      // 12 o'clock on the ring is inside the first (56%) slice. The donut box
      // is the leading 120px of the chart row.
      final chart = tester.getRect(find.byType(CategoryDonutChart));
      await _hover(
        tester,
        Offset(chart.left + 60, chart.center.dy - 50),
      );

      expect(find.byType(ChartTooltip), findsOneWidget);
      expect(find.text('₹12,50,000 · 56%'), findsOneWidget);
    });

    testWidgets('category breakdown row reports its rupee value', (
      tester,
    ) async {
      await tester.pumpWidget(_host(CategoryBreakdown(categories: _slices)));

      final row = tester.getRect(find.text('Insulation Bricks'));
      await _hover(tester, row.center);

      expect(find.byType(ChartTooltip), findsOneWidget);
      expect(find.text('₹1,76,000 · 8%'), findsOneWidget);
    });
  });
}

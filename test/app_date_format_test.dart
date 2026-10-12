import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shc_stock/app/core/utils/app_date.dart';

// Settings › Preferences › Date Format used to be saved and ignored. Every
// date the app shows now goes through fmtDate / fmtDateTime.

void main() {
  final d = DateTime(2026, 10, 9, 8, 57);

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => AppDates.style.value = AppDateStyle.monthName);

  test('each setting label maps to its style', () {
    expect(
      AppDates.styleFor('MMM D, YYYY (Jul 18, 2026)'),
      AppDateStyle.monthName,
    );
    expect(
      AppDates.styleFor('DD/MM/YYYY (18/07/2026)'),
      AppDateStyle.dayMonthYear,
    );
    expect(AppDates.styleFor('YYYY-MM-DD (2026-07-18)'), AppDateStyle.isoDate);
    expect(AppDates.styleFor(null), AppDateStyle.monthName);
    expect(AppDates.styleFor('nonsense'), AppDateStyle.monthName);
  });

  test('dates follow the chosen format', () async {
    await AppDates.apply('DD/MM/YYYY (18/07/2026)');
    expect(fmtDate(d), '09/10/2026');
    expect(fmtDateTime(d), '09/10/2026, 8:57 AM');
    expect(AppDates.placeholder, 'dd/mm/yyyy');

    await AppDates.apply('YYYY-MM-DD (2026-07-18)');
    expect(fmtDate(d), '2026-10-09');

    await AppDates.apply('MMM D, YYYY (Jul 18, 2026)');
    expect(fmtDate(d), 'Oct 9, 2026');
    expect(fmtDateTime(d), 'Oct 9, 2026, 8:57 AM');
  });

  test('a missing date shows the empty marker', () {
    expect(fmtDate(null), '—');
    expect(fmtDate(null, empty: '-'), '-');
    expect(fmtDateTime(null, empty: 'Never'), 'Never');
  });

  test('a UTC instant is shown on the local calendar day', () {
    final utc = DateTime.utc(2026, 10, 9, 18, 30);
    expect(fmtDate(utc), fmtDate(utc.toLocal()));
  });

  test('the choice survives a restart', () async {
    await AppDates.apply('DD/MM/YYYY (18/07/2026)');
    AppDates.style.value = AppDateStyle.monthName; // as on a fresh start
    await AppDates.restore();
    expect(AppDates.style.value, AppDateStyle.dayMonthYear);
  });
}

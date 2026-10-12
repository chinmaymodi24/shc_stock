import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The one place a date is turned into text for the screen (and for exports).
//
// Settings › Preferences › Date Format used to be saved and then ignored: every
// screen had its own hardcoded pattern ("09 Oct 2026", "2026-10-09",
// "Oct 9, 2026"…). Everything that shows a date now calls [fmtDate] /
// [fmtDateTime], which follow the chosen format.
//
// The choice is cached in SharedPreferences so it applies from the first frame
// after a restart, before the settings have been fetched from the server.
// Bills and their PDFs keep their own fixed layout — they are documents, not
// screens — and do not follow this setting.
// ─────────────────────────────────────────────────────────────────────────────

enum AppDateStyle {
  /// Oct 9, 2026
  monthName,

  /// 09/10/2026
  dayMonthYear,

  /// 2026-10-09
  isoDate,
}

/// The labels offered in Settings › Preferences, in display order.
const kDateFormatLabels = [
  'MMM D, YYYY (Jul 18, 2026)',
  'DD/MM/YYYY (18/07/2026)',
  'YYYY-MM-DD (2026-07-18)',
];

const kDefaultDateFormatLabel = 'MMM D, YYYY (Jul 18, 2026)';

const _kPrefKey = 'pref_date_format';

class AppDates {
  AppDates._();

  /// The active style. Reactive, so anything rendered inside an `Obx` that
  /// formats a date redraws the moment the setting changes.
  static final style = AppDateStyle.monthName.obs;

  /// Maps a stored label ("DD/MM/YYYY (18/07/2026)") to its style. Anything
  /// unknown falls back to the default rather than throwing.
  static AppDateStyle styleFor(String? label) {
    final l = (label ?? '').trim().toUpperCase();
    if (l.startsWith('DD/MM/YYYY')) return AppDateStyle.dayMonthYear;
    if (l.startsWith('YYYY-MM-DD')) return AppDateStyle.isoDate;
    return AppDateStyle.monthName;
  }

  /// Applies [label] and remembers it for the next start.
  static Future<void> apply(String? label) async {
    style.value = styleFor(label);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefKey, label ?? kDefaultDateFormatLabel);
    } catch (_) {}
  }

  /// Loads the remembered choice. Called once at start-up.
  static Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      style.value = styleFor(prefs.getString(_kPrefKey));
    } catch (_) {}
  }

  static String get _datePattern {
    switch (style.value) {
      case AppDateStyle.dayMonthYear:
        return 'dd/MM/yyyy';
      case AppDateStyle.isoDate:
        return 'yyyy-MM-dd';
      case AppDateStyle.monthName:
        return 'MMM d, yyyy';
    }
  }

  /// Hint for an empty date box, in the active format.
  static String get placeholder {
    switch (style.value) {
      case AppDateStyle.dayMonthYear:
        return 'dd/mm/yyyy';
      case AppDateStyle.isoDate:
        return 'yyyy-mm-dd';
      case AppDateStyle.monthName:
        return 'mmm d, yyyy';
    }
  }
}

/// A calendar date in the chosen format; [empty] when there is none.
String fmtDate(DateTime? d, {String empty = '—'}) {
  if (d == null) return empty;
  return DateFormat(AppDates._datePattern).format(d.toLocal());
}

/// A date and clock time ("09/10/2026, 8:57 AM") in the chosen format.
String fmtDateTime(DateTime? d, {String empty = '—'}) {
  if (d == null) return empty;
  final local = d.toLocal();
  return '${DateFormat(AppDates._datePattern).format(local)}, '
      '${DateFormat('h:mm a').format(local)}';
}

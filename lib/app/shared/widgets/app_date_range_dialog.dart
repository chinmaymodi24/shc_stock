import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

/// Shared date-range picker dialog.
///
/// Material's `showDateRangePicker` opens a full-screen, un-themed sheet that
/// looks nothing like the rest of the app. Use this instead everywhere a
/// from/to range is needed, so every date UI in the app matches the other
/// dialogs (surface card, rounded header with an icon plate, accent
/// highlights, Cancel / Apply footer).
///
/// Returns `null` when the user cancels.
Future<DateTimeRange?> showAppDateRangePicker(
  BuildContext context, {
  DateTimeRange? initialRange,
  DateTime? firstDate,
  DateTime? lastDate,
  String title = 'Select Date Range',
}) {
  return Get.dialog<DateTimeRange>(
    AppDateRangeDialog(
      initialRange: initialRange,
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2035, 12, 31),
      title: title,
    ),
    barrierColor: Colors.black.withValues(alpha: 0.35),
  );
}

class AppDateRangeDialog extends StatefulWidget {
  final DateTimeRange? initialRange;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;

  const AppDateRangeDialog({
    super.key,
    required this.firstDate,
    required this.lastDate,
    this.initialRange,
    this.title = 'Select Date Range',
  });

  @override
  State<AppDateRangeDialog> createState() => _AppDateRangeDialogState();
}

class _AppDateRangeDialogState extends State<AppDateRangeDialog> {
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  late final Rx<DateTime?> _start;
  late final Rx<DateTime?> _end;

  /// First of the left-hand month currently on screen.
  late final Rx<DateTime> _visible;

  @override
  void initState() {
    super.initState();
    final r = widget.initialRange;
    _start = Rx<DateTime?>(r == null ? null : _dayOf(r.start));
    _end = Rx<DateTime?>(r == null ? null : _dayOf(r.end));
    final anchor = r?.start ?? DateTime.now();
    _visible = _monthOf(anchor).obs;
  }

  @override
  void dispose() {
    _start.close();
    _end.close();
    _visible.close();
    super.dispose();
  }

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _monthOf(DateTime d) => DateTime(d.year, d.month);

  bool _sameDay(DateTime? a, DateTime? b) =>
      a != null && b != null && _dayOf(a) == _dayOf(b);

  /// Tapping cycles: first tap sets the start, second closes the range, a
  /// third starts over. Tapping before the current start just moves the start.
  void _onDayTap(DateTime day) {
    final s = _start.value;
    final e = _end.value;
    if (s == null || e != null) {
      _start.value = day;
      _end.value = null;
    } else if (day.isBefore(s)) {
      _start.value = day;
    } else {
      _end.value = day;
    }
  }

  void _applyPreset(DateTime start, DateTime end) {
    _start.value = _dayOf(start);
    _end.value = _dayOf(end);
    _visible.value = _monthOf(start);
  }

  void _shiftMonth(int delta) {
    final v = _visible.value;
    _visible.value = DateTime(v.year, v.month + delta);
  }

  bool get _canGoBack =>
      _visible.value.isAfter(_monthOf(widget.firstDate));

  bool _canGoForward(int monthsShown) =>
      DateTime(
        _visible.value.year,
        _visible.value.month + monthsShown,
      ).isBefore(_monthOf(widget.lastDate)) ||
      DateTime(_visible.value.year, _visible.value.month + monthsShown) ==
          _monthOf(widget.lastDate);

  String _label(DateTime? d) => d == null
      ? '—'
      : '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1].substring(0, 3)} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final width = MediaQuery.sizeOf(context).width;
    final monthsShown = width >= 760 ? 2 : 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: monthsShown == 2 ? 660 : 380,
            minWidth: 300,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 36,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(colors),
                Divider(height: 1, color: colors.divider),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _presets(colors),
                        const SizedBox(height: 14),
                        _monthNav(colors, monthsShown),
                        const SizedBox(height: 8),
                        Obx(
                          () => Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < monthsShown; i++) ...[
                                if (i > 0) const SizedBox(width: 20),
                                Expanded(
                                  child: _monthGrid(
                                    colors,
                                    DateTime(
                                      _visible.value.year,
                                      _visible.value.month + i,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: colors.divider),
                _footer(colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(AppThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.date_range_rounded,
              color: colors.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Obx(
                  () => Text(
                    '${_label(_start.value)}  →  ${_label(_end.value)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => Get.back<DateTimeRange>(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.comingSoonBadge,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _presets(AppThemeColors colors) {
    final now = DateTime.now();
    final today = _dayOf(now);
    final presets = <String, DateTimeRange>{
      'Today': DateTimeRange(start: today, end: today),
      'Last 7 Days': DateTimeRange(
        start: today.subtract(const Duration(days: 6)),
        end: today,
      ),
      'Last 30 Days': DateTimeRange(
        start: today.subtract(const Duration(days: 29)),
        end: today,
      ),
      'This Month': DateTimeRange(
        start: DateTime(now.year, now.month),
        end: today,
      ),
      'Last Month': DateTimeRange(
        start: DateTime(now.year, now.month - 1),
        end: DateTime(now.year, now.month, 0),
      ),
      'This Year': DateTimeRange(start: DateTime(now.year), end: today),
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in presets.entries)
          Obx(() {
            final active =
                _sameDay(_start.value, entry.value.start) &&
                _sameDay(_end.value, entry.value.end);
            return InkWell(
              onTap: () => _applyPreset(entry.value.start, entry.value.end),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? colors.accent.withValues(alpha: 0.12)
                      : colors.tagBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active ? colors.accent : colors.border,
                  ),
                ),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active ? colors.accent : colors.textSecondary,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _monthNav(AppThemeColors colors, int monthsShown) {
    return Obx(() {
      final left = _visible.value;
      final right = DateTime(left.year, left.month + monthsShown - 1);
      final label = monthsShown == 2
          ? '${_months[left.month - 1]} ${left.year}  –  ${_months[right.month - 1]} ${right.year}'
          : '${_months[left.month - 1]} ${left.year}';
      return Row(
        children: [
          _navButton(
            colors,
            Icons.chevron_left_rounded,
            _canGoBack ? () => _shiftMonth(-1) : null,
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          _navButton(
            colors,
            Icons.chevron_right_rounded,
            _canGoForward(monthsShown) ? () => _shiftMonth(1) : null,
          ),
        ],
      );
    });
  }

  Widget _navButton(
    AppThemeColors colors,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colors.tagBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null ? colors.textHint : colors.textSecondary,
        ),
      ),
    );
  }

  Widget _monthGrid(AppThemeColors colors, DateTime month) {
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // DateTime.weekday is 1=Mon..7=Sun; the grid starts on Sunday.
    final leading = first.weekday % 7;
    final cells = <Widget>[];

    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(_dayCell(colors, DateTime(month.year, month.month, d)));
    }
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox.shrink());
    }

    return Column(
      children: [
        Row(
          children: [
            for (final w in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: colors.textHint,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var row = 0; row < cells.length / 7; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(child: cells[row * 7 + col]),
            ],
          ),
      ],
    );
  }

  Widget _dayCell(AppThemeColors colors, DateTime day) {
    final disabled =
        day.isBefore(_dayOf(widget.firstDate)) ||
        day.isAfter(_dayOf(widget.lastDate));
    final s = _start.value;
    final e = _end.value;
    final isStart = _sameDay(day, s);
    final isEnd = _sameDay(day, e);
    final inRange =
        s != null &&
        e != null &&
        day.isAfter(_dayOf(s)) &&
        day.isBefore(_dayOf(e));
    final isToday = _sameDay(day, DateTime.now());
    final edge = isStart || isEnd;

    return SizedBox(
      height: 38,
      child: Stack(
        children: [
          // Continuous band behind the days between the two ends.
          if (inRange || (edge && s != null && e != null && s != e))
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: ColoredBox(
                      color: isStart
                          ? Colors.transparent
                          : colors.accent.withValues(alpha: 0.10),
                    ),
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: isEnd
                          ? Colors.transparent
                          : colors.accent.withValues(alpha: 0.10),
                    ),
                  ),
                ],
              ),
            ),
          Center(
            child: InkWell(
              onTap: disabled ? null : () => _onDayTap(day),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: edge ? colors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: isToday && !edge
                      ? Border.all(color: colors.accent.withValues(alpha: 0.6))
                      : null,
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    fontWeight: edge ? FontWeight.w700 : FontWeight.w500,
                    color: disabled
                        ? colors.textHint
                        : edge
                        ? Colors.white
                        : colors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(AppThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Get.back<DateTimeRange>(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.border),
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Obx(() {
            // A single tapped day is a valid one-day range.
            final s = _start.value;
            final e = _end.value ?? s;
            final ready = s != null;
            return ElevatedButton(
              onPressed: ready
                  ? () => Get.back<DateTimeRange>(
                      result: DateTimeRange(start: s, end: e!),
                    )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                disabledBackgroundColor: colors.border,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

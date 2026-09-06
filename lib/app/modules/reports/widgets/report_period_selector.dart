import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';
import 'package:shc_stock/app/modules/reports/models/report_period.dart';
import 'package:shc_stock/app/shared/widgets/app_date_range_dialog.dart';

/// The report toolbar's period dropdown.
///
/// Same three financial years on every report, plus this month / this quarter
/// and a custom range — so switching reports never means relearning the
/// control. Closes on pick, on click-outside and on Esc.
class ReportPeriodSelector extends StatefulWidget {
  final String label;
  final ValueChanged<ReportPeriod> onChanged;

  /// Highlights the currently applied preset in the menu.
  final ReportPeriod current;

  const ReportPeriodSelector({
    super.key,
    required this.label,
    required this.current,
    required this.onChanged,
  });

  @override
  State<ReportPeriodSelector> createState() => _ReportPeriodSelectorState();
}

class _ReportPeriodSelectorState extends State<ReportPeriodSelector> {
  final _overlay = OverlayPortalController();
  final _link = LayerLink();
  final _open = false.obs;

  static const double _height = 34;

  @override
  void dispose() {
    _open.close();
    super.dispose();
  }

  void _toggle() {
    _open.value = !_open.value;
    _overlay.toggle();
  }

  void _close() {
    if (!_open.value) return;
    _open.value = false;
    _overlay.hide();
  }

  void _pick(ReportPeriod period) {
    _close();
    widget.onChanged(period);
  }

  Future<void> _pickCustom() async {
    _close();
    final range = await showAppDateRangePicker(
      context,
      initialRange: DateTimeRange(
        start: widget.current.from,
        end: widget.current.to,
      ),
    );
    if (range == null) return;
    widget.onChanged(ReportPeriod.custom(range.start, range.end));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlay,
        overlayChildBuilder: (_) => Positioned(
          width: 200,
          child: CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 6),
            child: TapRegion(onTapOutside: (_) => _close(), child: _menu()),
          ),
        ),
        child: Obx(() {
          final open = _open.value;
          return InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(7),
            child: Container(
              height: _height,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: open
                    ? AppColors.primaryOrange.withValues(alpha: 0.10)
                    : colors.surface,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: open ? AppColors.primaryOrange : colors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: open
                        ? AppColors.primaryOrange
                        : colors.textSecondary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: open
                          ? AppColors.primaryOrange
                          : colors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: open
                        ? AppColors.primaryOrange
                        : colors.textSecondary,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _menu() {
    final colors = context.appColors;
    final years = ReportPeriod.recentFinancialYears();
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final year in years)
              _MenuRow(
                label: year.label,
                active: widget.current.slug == year.slug,
                onTap: () => _pick(year),
              ),
            _divider(colors),
            _MenuRow(
              label: 'This Month',
              active: widget.current.label == 'This Month',
              onTap: () => _pick(ReportPeriod.thisMonth()),
            ),
            _MenuRow(
              label: 'This Quarter',
              active: widget.current.label == 'This Quarter',
              onTap: () => _pick(ReportPeriod.thisQuarter()),
            ),
            _divider(colors),
            _MenuRow(
              label: 'Custom range',
              active: widget.current.label == 'Custom range',
              trailing: Icon(
                Icons.date_range_rounded,
                size: 15,
                color: colors.textHint,
              ),
              onTap: _pickCustom,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(AppThemeColors colors) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Divider(height: 1, color: colors.divider),
  );
}

class _MenuRow extends StatelessWidget {
  final String label;
  final bool active;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuRow({
    required this.label,
    required this.active,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: active
            ? AppColors.primaryOrange.withValues(alpha: 0.10)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  color: active ? AppColors.primaryOrange : colors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

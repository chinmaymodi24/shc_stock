import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shc_stock/app/modules/dashboard/models/dashboard_models.dart';
import 'package:shc_stock/app/core/theme/app_colors.dart';

/// Vertical timeline of incoming deliveries — a filled green check for
/// items ticked off as arrived (label struck through), an orange ring for
/// the next one due, and grey rings for everything further out. Rows are
/// connected by a thin line, like a shipment tracker.
///
/// Tapping a row's marker toggles it done/not-done — `deliveries` must be
/// the controller's own `RxList` so the tap is reflected immediately.
class IncomingDeliveries extends StatelessWidget {
  final RxList<DeliveryItem> deliveries;
  final void Function(int index) onToggle;

  const IncomingDeliveries({
    super.key,
    required this.deliveries,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          for (int i = 0; i < deliveries.length; i++)
            _DeliveryRow(
              data: deliveries[i],
              isLast: i == deliveries.length - 1,
              onTapMarker: () => onToggle(i),
            ),
        ],
      ),
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  final DeliveryItem data;
  final bool isLast;
  final VoidCallback onTapMarker;
  const _DeliveryRow({
    required this.data,
    required this.isLast,
    required this.onTapMarker,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDone = data.done;
    final isNext = !isDone && data.emphasis == DeliveryEmphasis.next;

    final Color dotColor;
    final Color subtitleColor;
    if (isDone) {
      dotColor = colors.success;
      subtitleColor = colors.textHint;
    } else if (isNext) {
      dotColor = AppColors.primaryOrange;
      subtitleColor = AppColors.primaryOrange;
    } else {
      dotColor = colors.divider;
      subtitleColor = colors.textSecondary;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              InkWell(
                onTap: onTapMarker,
                borderRadius: BorderRadius.circular(999),
                child: _StatusDot(done: isDone, color: dotColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: colors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.item} — Client PO #${data.poRef}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
                      color: isDone ? colors.textHint : colors.textPrimary,
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${data.warehouse} · ${data.eta}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isNext ? FontWeight.w600 : FontWeight.w400,
                      color: subtitleColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The circular timeline marker — filled with a check when done, an
/// outlined ring otherwise. Tappable (see the InkWell wrapping it above).
class _StatusDot extends StatelessWidget {
  final bool done;
  final Color color;
  const _StatusDot({required this.done, required this.color});

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
    );
  }
}

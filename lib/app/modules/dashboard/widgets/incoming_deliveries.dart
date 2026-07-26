import 'package:flutter/material.dart';
import '../models/dashboard_models.dart';
import '../../../core/theme/app_colors.dart';

class IncomingDeliveries extends StatelessWidget {
  final List<DeliveryItem> deliveries;

  const IncomingDeliveries({super.key, required this.deliveries});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: deliveries
          .map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _DeliveryRow(data: d),
            ),
          )
          .toList(),
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  final DeliveryItem data;
  const _DeliveryRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: data.accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.item} — Client PO #${data.poRef}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${data.warehouse} · Arriving ${data.eta}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

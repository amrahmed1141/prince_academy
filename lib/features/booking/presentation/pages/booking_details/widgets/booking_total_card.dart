import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

class BookingTotalCard extends StatelessWidget {
  const BookingTotalCard({
    super.key,
    required this.coachName,
    required this.selectedDays,
    required this.fixedTime,
    required this.pricePerSession,
    required this.total,
  });

  final String coachName;
  final List<String> selectedDays;
  final String fixedTime;
  final double pricePerSession;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EColorConstants.authFieldBorder),
      ),
      child: Column(
        children: [
          _row(context, 'Coach', coachName),
          _row(
            context,
            'Session days',
            selectedDays.isEmpty ? '—' : selectedDays.join(', '),
          ),
          _row(context, 'Time', fixedTime),
          const Divider(height: 22),
          _row(
            context,
            'Price / session',
            '${pricePerSession.toStringAsFixed(2)} EGP',
          ),
          _row(
            context,
            'TOTAL',
            '${total.toStringAsFixed(2)} EGP',
            strong: true,
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool strong = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: EColorConstants.authPlaceholderGray,
                ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
                    color: strong ? EColorConstants.primaryColor : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

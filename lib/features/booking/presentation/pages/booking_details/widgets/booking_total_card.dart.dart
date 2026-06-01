import 'package:flutter/material.dart';

class BookingTotalCard extends StatelessWidget {
  const BookingTotalCard({
    super.key,
    required this.coachName,
    required this.sessions,
    required this.days,
    required this.time,
    required this.pricePerSession,
    required this.total,
  });

  final String coachName;
  final int? sessions;
  final Set<String> days;
  final String? time;
  final double pricePerSession;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _row(context, 'Coach', coachName),
          _row(context, 'Sessions', sessions == null ? '—' : '$sessions / month'),
          _row(context, 'Days', days.isEmpty ? '—' : days.join(', ')),
          _row(context, 'Time', time ?? '—'),
          const Divider(height: 22),
          _row(context, 'Price / session', pricePerSession.toStringAsFixed(2)),
          _row(context, 'Total', total.toStringAsFixed(2), strong: true),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
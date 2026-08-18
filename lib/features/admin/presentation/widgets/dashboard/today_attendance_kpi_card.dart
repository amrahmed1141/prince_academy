import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/widgets/semi_circular_gauge.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_section_card.dart';

/// Shared “Members today attendance” gauge used on the dashboard and detail page.
/// Wrap with [Hero] using [heroTag] for the open/close flight animation.
class TodayAttendanceKpiCard extends StatelessWidget {
  const TodayAttendanceKpiCard({
    super.key,
    required this.attended,
    required this.booked,
    this.fillHeight = true,
  });

  static const heroTag = 'today_attendance_kpi';

  final int attended;
  final int booked;

  /// When true, expands to fill a parent [Expanded]/dashboard PageView).
  /// When false, uses a compact fixed gauge height (detail page).
  final bool fillHeight;

  double get _progress {
    if (booked <= 0) return 0;
    return (attended / booked).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final gauge = SemiCircularGauge(
      progress: _progress,
      child: _AttendanceStatus(
        attended: attended,
        booked: booked,
      ),
    );

    return AdminSectionCard(
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Members today attendance',
            style: TextStyle(
              color: EColorConstants.authTextDarkBrown,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          if (fillHeight)
            Expanded(child: gauge)
          else
            SizedBox(height: 140, child: gauge),
        ],
      ),
    );
  }
}

class _AttendanceStatus extends StatelessWidget {
  const _AttendanceStatus({
    required this.attended,
    required this.booked,
  });

  final int attended;
  final int booked;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            style: const TextStyle(fontFamily: 'Poppins', height: 1.1),
            children: [
              TextSpan(
                text: '$attended',
                style: const TextStyle(
                  color: EColorConstants.authTextDarkBrown,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(
                text: ' attendance',
                style: TextStyle(
                  color: EColorConstants.authTextDarkBrown,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'from $booked members today',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: EColorConstants.authPlaceholderGray,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

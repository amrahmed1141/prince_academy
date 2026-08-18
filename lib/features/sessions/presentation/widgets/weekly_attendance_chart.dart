import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/widgets/semi_circular_gauge.dart';
import 'package:prince_academy/features/sessions/domain/weekly_progress_summary.dart';

/// Weekly attendance gauge: sessions attended vs scheduled this week.
class WeeklyAttendanceChart extends StatelessWidget {
  final WeeklyProgressSummary summary;

  const WeeklyAttendanceChart({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    if (summary.days.isEmpty) {
      return const SizedBox.shrink();
    }

    final attended = summary.totalAttended;
    final expected = summary.totalExpected;
    final progress = expected > 0 ? summary.weekRatio : 0.0;
    final sessionWord = expected == 1 ? 'session' : 'sessions';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EColorConstants.authFieldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Weekly attendance progress',
            style: TextStyle(
              color: EColorConstants.authTextDarkBrown,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: SemiCircularGauge(
              progress: progress,
              child: Column(
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
                        TextSpan(
                          text: attended == 1
                              ? ' session attended'
                              : ' sessions attended',
                          style: const TextStyle(
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
                    expected == 0
                        ? 'No sessions this week'
                        : 'out of $expected $sessionWord this week',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: EColorConstants.authPlaceholderGray,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

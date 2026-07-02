import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/sessions/domain/weekly_progress_calculator.dart';
import 'package:prince_academy/features/sessions/domain/weekly_progress_summary.dart';

/// Weekly attendance bar chart (Sun–Sat) with expected vs attended sessions.
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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    final maxExpected =
        summary.days.map((d) => d.expected).fold<int>(1, math.max);

    final performanceColor = _performanceColor(summary.weekRatio);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EColorConstants.authFieldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${summary.totalAttended}/${summary.totalExpected}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: EColorConstants.authTextDarkBrown,
                  fontFamily: 'Poppins',
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text(
                  'this week',
                  style: TextStyle(
                    fontSize: 12,
                    color: EColorConstants.authPlaceholderGray,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: performanceColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: performanceColor.withOpacity(0.35)),
                ),
                child: Text(
                  summary.performanceLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: performanceColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            summary.performanceHint,
            style: const TextStyle(
              fontSize: 11,
              color: EColorConstants.authPlaceholderGray,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final dayProgress = summary.days[index];
                final day = dayProgress.date;
                final isToday = WeeklyProgressCalculator.isSameDay(day, today);
                final isFuture = day.isAfter(today);
                final expected = dayProgress.expected;
                final attended = dayProgress.attended;
                final hasExpected = expected > 0;
                final fillRatio =
                    hasExpected ? (attended / expected).clamp(0.0, 1.0) : 0.0;
                final heightFactor = hasExpected
                    ? (expected / maxExpected).clamp(0.2, 1.0)
                    : 0.18;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasExpected && attended > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '$attended/$expected',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: isToday
                                    ? EColorConstants.primaryColor
                                    : EColorConstants.authPlaceholderGray,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 14),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: heightFactor,
                              widthFactor: 1,
                              child: _DayBar(
                                fillRatio: fillRatio,
                                hasExpected: hasExpected,
                                isFuture: isFuture,
                                isToday: isToday,
                                allAttended:
                                    hasExpected && attended >= expected,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          labels[index],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isToday ? FontWeight.w700 : FontWeight.w500,
                            color: isToday
                                ? EColorConstants.primaryColor
                                : EColorConstants.authPlaceholderGray,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        if (isToday && hasExpected)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: EColorConstants.primaryColor,
                                width: 1.5,
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 10),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Color _performanceColor(double ratio) {
    if (ratio >= 0.9) return const Color(0xFF2E7D32);
    if (ratio >= 0.7) return EColorConstants.primaryColor;
    if (ratio >= 0.4) return const Color(0xFFF9A825);
    return const Color(0xFFD32F2F);
  }
}

class _DayBar extends StatelessWidget {
  final double fillRatio;
  final bool hasExpected;
  final bool isFuture;
  final bool isToday;
  final bool allAttended;

  const _DayBar({
    required this.fillRatio,
    required this.hasExpected,
    required this.isFuture,
    required this.isToday,
    required this.allAttended,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasExpected) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: CustomPaint(
          painter: _StripedBarPainter(),
          child: const SizedBox.expand(),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(
            painter: _StripedBarPainter(),
            child: const SizedBox.expand(),
          ),
          if (!isFuture)
            FractionallySizedBox(
              heightFactor: fillRatio.clamp(0.08, 1.0),
              widthFactor: 1,
              alignment: Alignment.bottomCenter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: allAttended
                      ? const Color(0xFF2E7D32)
                      : isToday
                          ? const Color(0xFFE85D3B)
                          : EColorConstants.primaryColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StripedBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = Colors.grey.shade300;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(999),
      ),
      base,
    );

    final stripe = Paint()
      ..color = Colors.grey.shade400.withOpacity(0.55)
      ..strokeWidth = 1.2;

    const gap = 5.0;
    for (double x = -size.height; x < size.width + size.height; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripe,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/helper_function.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

class SessionDayTypePair {
  const SessionDayTypePair({
    required this.classType,
    required this.day,
    required this.time,
    required this.sessionsPerWeek,
  });

  final String classType;
  final String day;
  final String time;
  final int sessionsPerWeek;
}

List<SessionDayTypePair> expandCoachSessions(List<CoachSessionModel> sessions) {
  final pairs = <SessionDayTypePair>[];
  for (final row in sessions) {
    pairs.addAll(expandCoachSessionRow(row));
  }
  return pairs;
}

List<SessionDayTypePair> expandCoachSessionRow(CoachSessionModel row) {
  final days = row.days;
  final types = row.sessionType
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  final time = row.timeSlots.isNotEmpty ? row.timeSlots.first : 'Time not set';
  final freq = row.sessionsPerWeek;

  if (days.isEmpty && types.isEmpty) {
    return [];
  }

  if (days.isEmpty) {
    return types
        .map(
          (type) => SessionDayTypePair(
            classType: type,
            day: 'Day not set',
            time: time,
            sessionsPerWeek: freq,
          ),
        )
        .toList();
  }

  if (types.isEmpty) {
    return days
        .map(
          (day) => SessionDayTypePair(
            classType:
                row.sessionType.isNotEmpty ? row.sessionType : 'Session',
            day: day,
            time: time,
            sessionsPerWeek: freq,
          ),
        )
        .toList();
  }

  final pairCount = days.length > types.length ? days.length : types.length;
  return List.generate(pairCount, (i) {
    final day = i < days.length ? days[i] : days.last;
    final type = i < types.length ? types[i] : types.last;
    return SessionDayTypePair(
      classType: type,
      day: day,
      time: time,
      sessionsPerWeek: freq,
    );
  });
}

class SessionInfoCard extends StatelessWidget {
  const SessionInfoCard({
    super.key,
    required this.classType,
    required this.day,
    required this.time,
    required this.sessionsPerWeek,
  });

  final String classType;
  final String day;
  final String time;
  final int sessionsPerWeek;

  @override
  Widget build(BuildContext context) {
    final dark = EHelperFunction.isDarkMode(context);
    final secondaryColor =
        dark ? Colors.grey[400]! : EColorConstants.authPlaceholderGray;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  classType,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: dark ? Colors.white : Colors.black,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: EColorConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$sessionsPerWeek sessions/week',
                  style: const TextStyle(
                    color: EColorConstants.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: secondaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                day,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: secondaryColor,
                    ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 16,
                color: secondaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                time,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: secondaryColor,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

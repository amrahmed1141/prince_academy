import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/class_type_colors.dart';
import 'package:prince_academy/features/admin/data/models/coach_with_sessions.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_form_styles.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/admin/presentation/widgets/delete_confirmation_sheet.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

const _weekShortDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

const _weekFullNames = {
  'Sun': 'SUNDAY',
  'Mon': 'MONDAY',
  'Tue': 'TUESDAY',
  'Wed': 'WEDNESDAY',
  'Thu': 'THURSDAY',
  'Fri': 'FRIDAY',
  'Sat': 'SATURDAY',
};

class _DaySlot {
  final String classType;
  final String time;

  const _DaySlot({required this.classType, required this.time});
}

class GroupedCoachSessionCard extends StatelessWidget {
  final CoachWithSessions coachWithSessions;
  final VoidCallback onDelete;
  final void Function(CoachSessionModel)? onEdit;
  final VoidCallback? onDuplicate;

  const GroupedCoachSessionCard({
    super.key,
    required this.coachWithSessions,
    required this.onDelete,
    this.onEdit,
    this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    if (coachWithSessions.schedules.isEmpty) {
      return const SizedBox.shrink();
    }

    final coachName = coachWithSessions.name;
    final schedules = coachWithSessions.schedules;
    final daySchedule = _mergeDaySchedule(schedules);
    final activeDays =
        _weekShortDays.where((day) => daySchedule[day] != null).toList();
    final maxPrice = _maxPrice(schedules);
    final priceLabel =
        maxPrice > 0 ? '${maxPrice.toStringAsFixed(0)} EGP' : 'Price not set';

    final firstSession = schedules.isNotEmpty ? schedules.first : null;
    final branchName = coachWithSessions.branchName ?? firstSession?.branchName;

    return Dismissible(
      key: ValueKey('session_${coachWithSessions.groupKey}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final confirmed = await DeleteConfirmationSheet.show(
            context: context,
            title: 'Delete Session?',
            subtitle:
                "This will remove $coachName's training schedule permanently.",
          );
          if (confirmed) {
            onDelete();
            return true;
          }
          return false;
        } else {
          if (firstSession != null) onEdit?.call(firstSession);
          return false;
        }
      },
      background: _swipeBackground(
        alignment: Alignment.centerLeft,
        color: EColorConstants.primaryColor,
        icon: Icons.edit_outlined,
        label: 'Edit',
      ),
      secondaryBackground: _swipeBackground(
        alignment: Alignment.centerRight,
        color: Colors.red.shade500,
        icon: Icons.delete_outline_rounded,
        label: 'Delete',
        gradient: true,
      ),
      child: GestureDetector(
        onTap: () {
          if (firstSession != null) onEdit?.call(firstSession);
        },
        onLongPress: onDuplicate,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CoachAvatarWithBadge(
                      name: coachName,
                      photoUrl: coachWithSessions.photoUrl,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coachName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A2744),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.brown.shade300,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  branchName ?? 'No branch assigned',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.brown.shade300,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (activeDays.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(height: 1, color: Colors.brown.shade100),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (int i = 0; i < activeDays.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: _DayColumn(
                            day: activeDays[i],
                            classType: daySchedule[activeDays[i]]!.classType,
                            time: daySchedule[activeDays[i]]!.time,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: Colors.brown.shade100),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: EColorConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          priceLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: EColorConstants.primaryColor,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _swipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
    bool gradient = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      alignment: alignment,
      padding: EdgeInsets.only(
        left: alignment == Alignment.centerLeft ? 24 : 0,
        right: alignment == Alignment.centerRight ? 24 : 0,
      ),
      decoration: BoxDecoration(
        color: gradient ? null : color,
        gradient: gradient
            ? LinearGradient(
                colors: [Colors.red.shade300, Colors.red.shade600],
              )
            : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachAvatarWithBadge extends StatelessWidget {
  const _CoachAvatarWithBadge({
    required this.name,
    this.photoUrl,
  });

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CoachAvatar(
          coachName: name,
          photoUrl: photoUrl,
          size: 58,
        ),
        Positioned(
          right: -3,
          bottom: -3,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: EColorConstants.primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.check, size: 11, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AdminFormStyles.statChipFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: Colors.grey.shade600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: EColorConstants.authTextDarkBrown,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Map<String, _DaySlot?> _mergeDaySchedule(List<CoachSessionModel> schedules) {
  final Map<String, _DaySlot?> daySchedule = {
    for (final day in _weekShortDays) day: null,
  };

  const fillOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String? nextOpenDay() {
    for (final day in fillOrder) {
      if (daySchedule[day] == null) return day;
    }
    return null;
  }

  for (final schedule in schedules) {
    final time = schedule.timeSlots.isNotEmpty
        ? schedule.timeSlots.first
        : 'Time not set';
    final days = schedule.days;
    final types = schedule.sessionType
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    if (days.isEmpty) {
      for (final type in types) {
        final openDay = nextOpenDay();
        if (openDay == null) break;
        daySchedule[openDay] = _DaySlot(classType: type, time: time);
      }
      continue;
    }

    for (int i = 0; i < days.length; i++) {
      final shortDay = _toShortDay(days[i]);
      if (!_weekShortDays.contains(shortDay)) continue;
      final type = i < types.length
          ? types[i]
          : (types.isNotEmpty ? types.first : schedule.sessionType.trim());
      if (type.isEmpty) continue;
      daySchedule[shortDay] = _DaySlot(classType: type, time: time);
    }
  }

  return daySchedule;
}

String _toShortDay(String fullDay) {
  switch (fullDay.trim()) {
    case 'Sunday':
      return 'Sun';
    case 'Monday':
      return 'Mon';
    case 'Tuesday':
      return 'Tue';
    case 'Wednesday':
      return 'Wed';
    case 'Thursday':
      return 'Thu';
    case 'Friday':
      return 'Fri';
    case 'Saturday':
      return 'Sat';
    default:
      final trimmed = fullDay.trim();
      return trimmed.length >= 3 ? trimmed.substring(0, 3) : trimmed;
  }
}

double _maxPrice(List<CoachSessionModel> schedules) {
  if (schedules.isEmpty) return 0;
  return schedules
      .map((session) => session.pricePerSession)
      .fold<double>(0, (max, price) => price > max ? price : max);
}

int _totalSessionsPerWeek(List<CoachSessionModel> schedules) {
  if (schedules.isEmpty) return 0;
  return schedules.fold<int>(
    0,
    (sum, session) => sum + session.sessionsPerWeek,
  );
}

class _DayColumn extends StatelessWidget {
  final String day;
  final String classType;
  final String time;

  const _DayColumn({
    required this.day,
    required this.classType,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final dayLabel = _weekFullNames[day] ?? day.toUpperCase();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          dayLabel,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Colors.grey.shade600,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: ClassTypeColors.background(classType),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                classType,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ClassTypeColors.foreground(classType),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                time,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      ClassTypeColors.foreground(classType).withOpacity(0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SessionCoachDropdownTile extends StatelessWidget {
  final String name;
  final String? photoUrl;

  const SessionCoachDropdownTile({
    super.key,
    required this.name,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CoachAvatar(coachName: name, photoUrl: photoUrl, size: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: EColorConstants.authTextDarkBrown,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
}

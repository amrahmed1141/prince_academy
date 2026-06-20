import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/class_type_colors.dart';
import 'package:prince_academy/features/admin/data/models/coach_with_sessions.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_dismissible_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_name_with_verify.dart';
import 'package:prince_academy/features/admin/presentation/widgets/delete_confirmation_sheet.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

const _weekShortDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

class _DaySlot {
  final String classType;
  final String time;

  const _DaySlot({required this.classType, required this.time});
}

class GroupedCoachSessionCard extends StatelessWidget {
  final CoachWithSessions coachWithSessions;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const GroupedCoachSessionCard({
    super.key,
    required this.coachWithSessions,
    required this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (coachWithSessions.schedules.isEmpty) {
      return const SizedBox.shrink();
    }

    final coachName = coachWithSessions.name;
    final schedules = coachWithSessions.schedules;
    final daySchedule = _mergeDaySchedule(schedules);
    final activeDays = _weekShortDays
        .where((day) => daySchedule[day] != null)
        .toList();
    final maxPrice = _maxPrice(schedules);
    final totalSessionsPerWeek = _totalSessionsPerWeek(schedules);
    final pricesVary = _pricesVary(schedules);
    final priceLabel = maxPrice > 0
        ? '${maxPrice.toStringAsFixed(0)} EGP'
        : 'Price not set';
    final frequencyLabel =
        totalSessionsPerWeek > 0 ? '${totalSessionsPerWeek}x / week' : '— / week';

    return AdminDismissibleCard(
      dismissKey: ValueKey('session_${coachWithSessions.coachId}'),
      confirmTitle: 'Delete Session Schedule?',
      confirmSubtitle:
          "This will permanently remove $coachName's training schedule.",
      onDismissConfirmed: onDelete,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: EColorConstants.primaryColor.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CoachAvatar(
                  name: coachName,
                  photoUrl: coachWithSessions.photoUrl,
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CoachNameWithVerify(name: coachName),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Iconsax.more,
                    size: 18,
                    color: EColorConstants.authPlaceholderGray,
                  ),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      final confirmed = await DeleteConfirmationSheet.show(
                        context: context,
                        title: 'Delete Session Schedule?',
                        subtitle:
                            "This will permanently remove $coachName's training schedule.",
                      );
                      if (confirmed) onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(
                        'Edit',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoPill(
                  icon: Iconsax.money,
                  iconColor: const Color(0xFFFFC107),
                  iconBgColor: Colors.white,
                  label: priceLabel,
                  labelColor: maxPrice > 0
                      ? EColorConstants.authTextDarkBrown
                      : EColorConstants.authPlaceholderGray,
                ),
                const SizedBox(width: 12),
                _InfoPill(
                  icon: Icons.calendar_today_rounded,
                  iconColor: const Color(0xFF2196F3),
                  iconBgColor: Colors.white,
                  label: frequencyLabel,
                ),
              ],
            ),
            if (pricesVary) ...[
              const SizedBox(height: 6),
              Text(
                'Prices vary by session type',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: EColorConstants.authPlaceholderGray,
                      fontSize: 10,
                      fontFamily: 'Poppins',
                    ),
              ),
            ],
            if (activeDays.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  for (int i = 0; i < activeDays.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
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
            ],
          ],
        ),
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
      .map((schedule) => schedule.pricePerSession)
      .fold<double>(0, (max, price) => price > max ? price : max);
}

int _totalSessionsPerWeek(List<CoachSessionModel> schedules) {
  if (schedules.isEmpty) return 0;
  return schedules.fold<int>(
    0,
    (sum, schedule) => sum + schedule.sessionsPerWeek,
  );
}

bool _pricesVary(List<CoachSessionModel> schedules) {
  if (schedules.length <= 1) return false;
  final prices = schedules.map((s) => s.pricePerSession).toSet();
  return prices.length > 1;
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final Color? labelColor;

  const _InfoPill({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: EColorConstants.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: labelColor ?? EColorConstants.authTextDarkBrown,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
          ),
        ],
      ),
    );
  }
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          day,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: EColorConstants.authPlaceholderGray,
                fontFamily: 'Poppins',
              ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 1.5,
          width: 24,
          color: EColorConstants.primaryColor.withOpacity(0.15),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: ClassTypeColors.background(classType),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            classType,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ClassTypeColors.foreground(classType),
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  fontFamily: 'Poppins',
                ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: EColorConstants.authPlaceholderGray,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
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
        CoachAvatar(
          name: name,
          photoUrl: photoUrl,
          radius: 16,
        ),
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

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_name_with_verify.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

class SavedSessionCard extends StatelessWidget {
  final String coachName;
  final String? coachPhotoUrl;
  final CoachSessionModel session;
  final VoidCallback? onMenuTap;

  const SavedSessionCard({
    super.key,
    required this.coachName,
    this.coachPhotoUrl,
    required this.session,
    this.onMenuTap,
  });

  static String frequencyLabel(int sessionsPerWeek) {
    return '$sessionsPerWeek/week';
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'striking':
        return const Color(0xFFE53935);
      case 'grappling':
      case 'bjj':
        return const Color(0xFF00897B);
      case 'conditioning':
        return const Color(0xFFFB8C00);
      case 'sparring':
        return const Color(0xFF7E57C2);
      case 'drills':
        return const Color(0xFF3949AB);
      case 'muay thai':
        return const Color(0xFFD84315);
      case 'boxing':
        return const Color(0xFFC62828);
      case 'mma':
        return EColorConstants.primaryColor;
      default:
        return EColorConstants.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(session.sessionType);
    final day = session.weekdayLabel ?? '—';
    final frequency = frequencyLabel(session.sessionsPerWeek);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: EColorConstants.authCardWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: EColorConstants.authFieldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CoachAvatar(
                name: coachName,
                photoUrl: coachPhotoUrl,
                radius: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CoachNameWithVerify(name: coachName),
              ),
              if (onMenuTap != null)
                GestureDetector(
                  onTap: onMenuTap,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Iconsax.more,
                      size: 18,
                      color: EColorConstants.authPlaceholderGray,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoColumn(
                  label: 'Class Type',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      session.sessionType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: typeColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _InfoColumn(
                  label: 'Day',
                  icon: Iconsax.calendar_1,
                  value: day,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _InfoColumn(
                  label: 'Frequency',
                  icon: Iconsax.refresh,
                  value: frequency,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? value;
  final Widget? child;

  const _InfoColumn({
    required this.label,
    this.icon,
    this.value,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: EColorConstants.authPlaceholderGray,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        if (child != null)
          child!
        else
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: EColorConstants.authPlaceholderGray),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  value ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: EColorConstants.authTextDarkBrown,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
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

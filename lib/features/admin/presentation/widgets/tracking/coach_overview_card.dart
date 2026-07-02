import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/models/coach_tracking_overview_model.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';

class CoachOverviewCard extends StatelessWidget {
  final CoachTrackingOverview coach;
  final bool isSelected;
  final VoidCallback onTap;

  const CoachOverviewCard({
    super.key,
    required this.coach,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 156,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: EColorConstants.authCardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? EColorConstants.primaryColor
                : EColorConstants.authFieldBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: EColorConstants.authFieldBorder,
                  width: 2,
                ),
              ),
              child: CoachAvatar(
                coachName: coach.coachName,
                photoUrl: coach.coachPhoto,
                size: 60,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    coach.coachName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: EColorConstants.authTextDarkBrown,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Iconsax.verify5,
                  size: 15,
                  color: EColorConstants.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              coach.specialty,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: EColorConstants.authPlaceholderGray,
                fontFamily: 'Poppins',
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatusDot(
                  color: const Color(0xFF2E7D32),
                  label: '${coach.activeCount} active',
                ),
                const SizedBox(width: 8),
                _StatusDot(
                  color: const Color(0xFFD32F2F),
                  label: '${coach.expiredCount} expired',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 36,
              decoration: BoxDecoration(
                color: EColorConstants.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                '${coach.totalUsers} users',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '${label.split(' ')[0]} ${label.split(' ')[1].substring(0, 3)}', // e.g. "1 act", "1 exp"
          style: TextStyle(
            fontSize: 9,
            color: color,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

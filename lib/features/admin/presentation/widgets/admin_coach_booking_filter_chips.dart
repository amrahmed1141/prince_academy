import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';

typedef AdminCoachBookingOption = ({
  String coachId,
  String coachName,
  String? coachPhoto,
});

class AdminCoachBookingFilterChips extends StatelessWidget {
  final List<AdminCoachBookingOption> coaches;
  final String? selectedCoachId;
  final ValueChanged<String?> onSelected;

  const AdminCoachBookingFilterChips({
    super.key,
    required this.coaches,
    required this.selectedCoachId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (coaches.length <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SELECT BOOKING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: EColorConstants.authPlaceholderGray,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                CoachBookingFilterChip(
                  label: 'All Bookings',
                  isSelected: selectedCoachId == null,
                  onTap: () => onSelected(null),
                  isAll: true,
                ),
                ...coaches.map(
                  (coach) => CoachBookingFilterChip(
                    label: coach.coachName,
                    photoUrl: coach.coachPhoto,
                    isSelected: selectedCoachId == coach.coachId,
                    onTap: () => onSelected(coach.coachId),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CoachBookingFilterChip extends StatelessWidget {
  final String label;
  final String? photoUrl;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isAll;

  const CoachBookingFilterChip({
    super.key,
    required this.label,
    this.photoUrl,
    required this.isSelected,
    required this.onTap,
    this.isAll = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? EColorConstants.primaryColor.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? EColorConstants.primaryColor
                  : EColorConstants.authFieldBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAll)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? EColorConstants.primaryColor
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                )
              else
                ClipOval(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CoachAvatar(
                      coachName: label,
                      photoUrl: photoUrl,
                      size: 24,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? EColorConstants.primaryColor
                      : EColorConstants.authTextDarkBrown,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

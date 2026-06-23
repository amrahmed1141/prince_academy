import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/data/models/coach_tracking_overview_model.dart';
import 'package:prince_academy/features/admin/presentation/widgets/tracking/coach_overview_card.dart';

class CoachOverviewSection extends StatelessWidget {
  final List<CoachTrackingOverview> coaches;
  final String? selectedCoachId;
  final ValueChanged<String?> onCoachSelected;

  const CoachOverviewSection({
    super.key,
    required this.coaches,
    required this.selectedCoachId,
    required this.onCoachSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Iconsax.chart_2,
              size: 18,
              color: EColorConstants.primaryColor,
            ),
            SizedBox(width: 8),
            Text(
              'COACH OVERVIEW',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: EColorConstants.authTextDarkBrown,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 132,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _AllCoachChip(
                isSelected: selectedCoachId == null,
                onTap: () => onCoachSelected(null),
              ),
              ...coaches.map(
                (coach) => CoachOverviewCard(
                  coach: coach,
                  isSelected: selectedCoachId == coach.coachId,
                  onTap: () => onCoachSelected(coach.coachId),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AllCoachChip extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _AllCoachChip({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? EColorConstants.primaryColor.withOpacity(0.12)
              : EColorConstants.authCardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? EColorConstants.primaryColor
                : EColorConstants.authFieldBorder,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.people,
              size: 22,
              color: EColorConstants.primaryColor,
            ),
            SizedBox(height: 6),
            Text(
              'All',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: EColorConstants.authTextDarkBrown,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

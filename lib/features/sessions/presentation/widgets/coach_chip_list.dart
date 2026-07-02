import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/sessions/data/models/coach_summary_model.dart';

class CoachChipList extends StatelessWidget {
  final List<CoachSummary> coaches;
  final CoachSummary? selectedCoach;
  final void Function(String?) onSelect;

  const CoachChipList({
    super.key,
    required this.coaches,
    this.selectedCoach,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (coaches.length <= 1) return const SizedBox.shrink();

    return Container(
      height: 56,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: coaches.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _AllChip(
              isSelected: selectedCoach == null,
              onTap: () => onSelect(null),
            );
          }
          final coach = coaches[index - 1];
          return _CoachChip(
            coach: coach,
            isSelected: selectedCoach?.coachId == coach.coachId,
            onTap: () => onSelect(coach.coachId),
          );
        },
      ),
    );
  }
}

class _CoachChip extends StatelessWidget {
  final CoachSummary coach;
  final bool isSelected;
  final VoidCallback onTap;

  const _CoachChip({
    required this.coach,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Colors.grey.shade100,
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CoachAvatar(
              coachName: coach.coachName,
              photoUrl: coach.coachPhoto,
              size: 24,
            ),
            const SizedBox(width: 6),
            Text(
              coach.coachName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AllChip extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _AllChip({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1)
              : Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Center(
          child: Text(
            'All',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

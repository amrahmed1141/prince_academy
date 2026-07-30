# Widget excerpts

## A. Pure presentational

SOURCE: `lib/features/booking/presentation/widgets/already_booked_button.dart`

```dart
class AlreadyBookedButton extends StatelessWidget {
  const AlreadyBookedButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          const SizedBox(width: 8),
          Text(
            'Already Booked',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
```

## B. Data + callbacks in

SOURCE: `lib/features/sessions/presentation/widgets/coach_chip_list.dart`

```dart
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
```

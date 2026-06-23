import 'package:equatable/equatable.dart';

class CoachTrackingOverview extends Equatable {
  final String coachId;
  final String coachName;
  final String? coachPhoto;
  final String specialty;
  final int totalUsers;
  final int activeCount;
  final int expiredCount;

  const CoachTrackingOverview({
    required this.coachId,
    required this.coachName,
    this.coachPhoto,
    required this.specialty,
    required this.totalUsers,
    required this.activeCount,
    required this.expiredCount,
  });

  @override
  List<Object?> get props => [
        coachId,
        coachName,
        coachPhoto,
        specialty,
        totalUsers,
        activeCount,
        expiredCount,
      ];
}

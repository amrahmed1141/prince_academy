class CoachUserStats {
  final String coachId;
  final String coachName;
  final String? coachPhoto;
  final String coachSpecialty;
  final int totalSubscribers;
  final int activeSubscribers;
  final int expiredSubscribers;

  const CoachUserStats({
    required this.coachId,
    required this.coachName,
    this.coachPhoto,
    required this.coachSpecialty,
    required this.totalSubscribers,
    required this.activeSubscribers,
    required this.expiredSubscribers,
  });

  factory CoachUserStats.fromJson(Map<String, dynamic> json) {
    return CoachUserStats(
      coachId: json['coach_id'] as String? ?? '',
      coachName: json['coach_name'] as String? ?? 'Coach',
      coachPhoto: json['coach_photo'] as String?,
      coachSpecialty: json['coach_specialty'] as String? ?? 'MMA',
      totalSubscribers: (json['total_subscribers'] as num?)?.toInt() ?? 0,
      activeSubscribers: (json['active_subscribers'] as num?)?.toInt() ?? 0,
      expiredSubscribers: (json['expired_subscribers'] as num?)?.toInt() ?? 0,
    );
  }
}

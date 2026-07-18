class SessionConflictInfo {
  final String coachName;
  final String classType;
  final String timeSlot;

  const SessionConflictInfo({
    required this.coachName,
    required this.classType,
    required this.timeSlot,
  });

  /// e.g. "There is already a Fitness session at this time with coach kareem at 8:00 PM"
  String get message {
    final type = classType.trim().isNotEmpty ? classType.trim() : 'session';
    final coach = coachName.trim().isNotEmpty ? coachName.trim() : 'another coach';
    final time = timeSlot.trim().isNotEmpty ? timeSlot.trim() : 'this time';
    return 'There is already a $type session at this time with coach $coach at $time';
  }
}

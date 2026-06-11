class SessionDraft {
  final String day;
  final String classType;

  const SessionDraft({
    required this.day,
    required this.classType,
  });

  static const defaultDay = 'Monday';
  static const defaultClassType = 'Striking';

  factory SessionDraft.initial() {
    return const SessionDraft(
      day: defaultDay,
      classType: defaultClassType,
    );
  }

  SessionDraft copyWith({
    String? day,
    String? classType,
  }) {
    return SessionDraft(
      day: day ?? this.day,
      classType: classType ?? this.classType,
    );
  }

  static List<SessionDraft> listForCount(int count) {
    return List.generate(
      count,
      (_) => SessionDraft.initial(),
    );
  }

  static List<SessionDraft> resize(List<SessionDraft> current, int count) {
    if (count <= 0) return [];
    if (current.length == count) return List.from(current);
    if (current.length > count) return current.sublist(0, count);
    return [
      ...current,
      ...List.generate(
        count - current.length,
        (_) => SessionDraft.initial(),
      ),
    ];
  }
}

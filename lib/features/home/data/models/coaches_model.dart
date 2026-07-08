class CoachModel {
  final String id;
  final String name;
  final String specialty;
  final String? photoUrl;
  final bool isActive;
  final DateTime? createdAt;
  final int memberCount;

  const CoachModel({
    required this.id,
    required this.name,
    required this.specialty,
    this.photoUrl,
    required this.isActive,
    this.createdAt,
    this.memberCount = 0,
  });

  CoachModel copyWith({
    String? id,
    String? name,
    String? specialty,
    String? photoUrl,
    bool? isActive,
    DateTime? createdAt,
    int? memberCount,
  }) {
    return CoachModel(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  factory CoachModel.fromMap(Map<String, dynamic> map) {
    return CoachModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      specialty: map['specialty'] as String? ?? '',
      photoUrl: map['photo_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      memberCount: parseMemberCount(map),
    );
  }

  /// Parses member_count from a flat field or coach_member_count embed.
  static int parseMemberCount(Map<String, dynamic> map) {
    final direct = map['member_count'];
    if (direct != null) return (direct as num).toInt();

    final embed = map['coach_member_count'];
    if (embed is List && embed.isNotEmpty) {
      final row = Map<String, dynamic>.from(embed.first as Map);
      return (row['member_count'] as num?)?.toInt() ?? 0;
    }

    return 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'photo_url': photoUrl,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

// Deprecated: Use CoachModel instead. Left as typedef to prevent syntax issues during migration.
typedef CoachesModel = CoachModel;

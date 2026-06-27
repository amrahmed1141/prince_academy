class CoachModel {
  final String id;
  final String name;
  final String specialty;
  final String? photoUrl;
  final String? branchId;
  final String? branchName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CoachModel({
    required this.id,
    required this.name,
    required this.specialty,
    this.photoUrl,
    this.branchId,
    this.branchName,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory CoachModel.fromMap(Map<String, dynamic> map) {
    final branchesData = map['branches'];
    Map<String, dynamic>? branchMap;
    if (branchesData is Map<String, dynamic>) {
      branchMap = branchesData;
    }

    return CoachModel(
      id: map['id'] as String,
      name: map['name'] as String,
      specialty: map['specialty'] as String,
      photoUrl: map['photo_url'] as String?,
      branchId: map['branch_id'] as String?,
      branchName: map['branch_name'] as String? ?? branchMap?['name'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialty': specialty,
      'photo_url': photoUrl,
      'is_active': isActive,
    };
  }
}

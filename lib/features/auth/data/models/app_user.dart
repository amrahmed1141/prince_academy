class UserModel {
  final String id;
  final String role;
  final String? fullName;
  final String? phone;

  UserModel({
    required this.id,
    required this.role,
    this.fullName,
    this.phone,
  });

  factory UserModel.fromMap(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      role: json['role'] as String? ?? 'user',
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
    );
  }
}
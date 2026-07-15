class UserModel {
  final String id;
  final String role;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.role,
    this.fullName,
    this.phone,
    this.email,
    this.avatarUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> json, {String? email}) {
    return UserModel(
      id: json['id'].toString(),
      role: json['role'] as String? ?? 'user',
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      email: email ?? json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'role': role,
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'avatar_url': avatarUrl,
      };

  UserModel copyWith({
    String? id,
    String? role,
    String? fullName,
    String? phone,
    String? email,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UserModel &&
        other.id == id &&
        other.role == role &&
        other.fullName == fullName &&
        other.phone == phone &&
        other.email == email &&
        other.avatarUrl == avatarUrl;
  }

  @override
  int get hashCode => Object.hash(id, role, fullName, phone, email, avatarUrl);
}

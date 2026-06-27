class Branch {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final DateTime createdAt;

  Branch({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    required this.createdAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

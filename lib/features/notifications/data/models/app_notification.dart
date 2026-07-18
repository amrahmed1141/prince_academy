import 'package:equatable/equatable.dart';

/// In-app notification row from `public.notifications`.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.body,
    this.data,
  });

  final String id;
  final String userId;
  final String title;
  final String? body;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    Map<String, dynamic>? data;
    if (rawData is Map<String, dynamic>) {
      data = rawData;
    } else if (rawData is Map) {
      data = Map<String, dynamic>.from(rawData);
    }

    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: (json['title'] as String?) ?? '',
      body: json['body'] as String?,
      type: (json['type'] as String?) ?? 'general',
      data: data,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'is_read': isRead,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, userId, title, body, type, data, isRead, createdAt];
}

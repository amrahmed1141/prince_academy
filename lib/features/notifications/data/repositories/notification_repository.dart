import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:prince_academy/features/notifications/data/models/app_notification.dart';

/// Supabase-backed notifications + FCM token persistence.
///
/// - Reads / updates rows in `public.notifications` (RLS: own rows only)
/// - Saves device token to `public.profiles.fcm_token`
/// - Exposes a realtime stream for live list + unread badge
class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  RealtimeChannel? _channel;
  String? _subscribedUserId;
  StreamController<List<AppNotification>>? _controller;
  List<AppNotification> _cache = const [];

  String? get _userId => _client.auth.currentUser?.id;

  /// Cached snapshot for instant UI (may be empty before first fetch).
  List<AppNotification> get cachedNotifications => _cache;

  int get unreadCount => _cache.where((n) => !n.isRead).length;

  /// Broadcast stream of the full notification list for the signed-in user.
  Stream<List<AppNotification>> get notificationsStream {
    _controller ??=
        StreamController<List<AppNotification>>.broadcast(onListen: () {
      // Late subscribers get the latest cache immediately.
      if (_cache.isNotEmpty) {
        _controller?.add(_cache);
      }
    });
    _ensureRealtime();
    return _controller!.stream;
  }

  Future<List<AppNotification>> fetchNotifications({
    bool force = false,
  }) async {
    final userId = _userId;
    if (userId == null) return const [];

    _ensureRealtime();

    if (!force && _cache.isNotEmpty) {
      return _cache;
    }

    try {
      final rows = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);

      final list = rows
          .map((e) => AppNotification.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();

      _setCache(list);
      return list;
    } catch (error, stackTrace) {
      developer.log(
        'fetchNotifications failed: $error',
        name: 'NotificationRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = _userId;
    if (userId == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', userId);

    _setCache([
      for (final n in _cache)
        if (n.id == notificationId) n.copyWith(isRead: true) else n,
    ]);
  }

  Future<void> markAllAsRead() async {
    final userId = _userId;
    if (userId == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);

    _setCache([for (final n in _cache) n.copyWith(isRead: true)]);
  }

  /// Persists the device FCM token on the signed-in profile.
  Future<void> saveFcmToken(String token) async {
    final userId = _userId;
    if (userId == null) {
      developer.log(
        'Skipping FCM token save — no authenticated user.',
        name: 'NotificationRepository',
      );
      return;
    }

    await _client.from('profiles').update({
      'fcm_token': token,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userId);

    developer.log(
      'Saved FCM token for user $userId',
      name: 'NotificationRepository',
    );
  }

  /// Clears token on sign-out so the device stops receiving user pushes.
  Future<void> clearFcmToken() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await _client.from('profiles').update({
        'fcm_token': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);
    } catch (error, stackTrace) {
      developer.log(
        'clearFcmToken failed: $error',
        name: 'NotificationRepository',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _ensureRealtime() {
    final userId = _userId;
    if (userId == null) return;

    if (_channel != null && _subscribedUserId == userId) return;

    _teardownRealtime();
    _subscribedUserId = userId;

    _channel = _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) {
            // Re-fetch to keep ordering / full row shape consistent.
            unawaited(_refreshFromServer());
          },
        )
        .subscribe();
  }

  Future<void> _refreshFromServer() async {
    try {
      await fetchNotifications(force: true);
    } catch (_) {
      // Keep existing cache on transient realtime refresh failures.
    }
  }

  void _setCache(List<AppNotification> list) {
    _cache = list;
    _controller?.add(list);
  }

  void _teardownRealtime() {
    final channel = _channel;
    _channel = null;
    _subscribedUserId = null;
    if (channel != null) {
      unawaited(_client.removeChannel(channel));
    }
  }

  /// Call on sign-out to drop realtime + in-memory cache.
  Future<void> disposeSession() async {
    _teardownRealtime();
    _cache = const [];
    _controller?.add(const []);
  }
}

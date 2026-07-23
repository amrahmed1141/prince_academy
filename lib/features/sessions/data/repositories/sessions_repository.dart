import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' hide Session;
import 'package:prince_academy/core/cache/local_cache_store.dart';
import 'package:prince_academy/features/admin/data/models/session_detail_model.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/sessions/data/models/coach_summary_model.dart';
import 'package:prince_academy/features/sessions/data/models/session_model.dart';

class SessionsSnapshot {
  final List<CoachSummary> coaches;
  final List<Session> sessions;
  final List<BookingHistoryModel> bookings;

  const SessionsSnapshot({
    required this.coaches,
    required this.sessions,
    required this.bookings,
  });

  Map<String, dynamic> toJson() => {
        'coaches': coaches.map((c) => c.toJson()).toList(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'bookings': bookings.map((b) => b.toJson()).toList(),
      };

  factory SessionsSnapshot.fromJson(Map<String, dynamic> json) {
    return SessionsSnapshot(
      coaches: (json['coaches'] as List? ?? [])
          .map((e) => CoachSummary.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      sessions: (json['sessions'] as List? ?? [])
          .map((e) => Session.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      bookings: (json['bookings'] as List? ?? [])
          .map(
            (e) => BookingHistoryModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

class SessionsRepository {
  SessionsRepository(this.supabase, {LocalCacheStore? cache})
      : _cache = cache ?? LocalCacheStore.instance {
    _hydrateFromDisk();
  }

  final SupabaseClient supabase;
  final LocalCacheStore _cache;

  static SessionsSnapshot? _cachedSnapshot;
  static final Map<String, List<SessionDetail>> _bookingSessionsCache = {};

  StreamController<SessionsSnapshot>? _snapshotController;
  final Map<String, StreamController<List<SessionDetail>>> _bookingControllers =
      {};

  RealtimeChannel? _realtimeChannel;
  String? _subscribedUserId;
  bool _isFetchingSnapshot = false;
  final Set<String> _fetchingBookings = {};

  SessionsSnapshot? get cachedSnapshot => _cachedSnapshot;

  List<SessionDetail>? getCachedBookingSessions(String bookingId) =>
      _bookingSessionsCache[bookingId];

  void invalidateCache() {
    _cachedSnapshot = null;
    _bookingSessionsCache.clear();
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      unawaited(_cache.delete(LocalCacheStore.sessionsSnapshotKey(userId)));
    }
  }

  void _hydrateFromDisk() {
    if (_cachedSnapshot != null) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    final map = _cache.getMap(LocalCacheStore.sessionsSnapshotKey(userId));
    if (map == null) return;
    try {
      _cachedSnapshot = SessionsSnapshot.fromJson(map);
    } catch (_) {}
  }

  Future<void> _persistSnapshot(SessionsSnapshot snapshot) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _cache.putJson(
      LocalCacheStore.sessionsSnapshotKey(userId),
      snapshot.toJson(),
    );
  }

  Stream<SessionsSnapshot> get sessionsStream {
    _ensureSnapshotController();
    _ensureRealtimeSubscription();
    return _snapshotController!.stream;
  }

  Stream<List<SessionDetail>> watchBookingSessions(String bookingId) {
    _ensureRealtimeSubscription();
    _bookingControllers.putIfAbsent(
      bookingId,
      () => StreamController<List<SessionDetail>>.broadcast(),
    );
    return _bookingControllers[bookingId]!.stream;
  }

  Future<SessionsSnapshot> refreshSessions({bool force = false}) async {
    _hydrateFromDisk();
    if (!force && _isFetchingSnapshot && _cachedSnapshot != null) {
      return _cachedSnapshot!;
    }
    if (!force && _cachedSnapshot != null) {
      return _cachedSnapshot!;
    }

    _isFetchingSnapshot = true;
    try {
      final results = await Future.wait([
        _fetchUserCoaches(),
        _fetchSessions(),
        _fetchUserBookings(),
      ]);

      var coaches = results[0] as List<CoachSummary>;
      final sessions = results[1] as List<Session>;
      final bookings = results[2] as List<BookingHistoryModel>;

      if (coaches.isEmpty && sessions.isNotEmpty) {
        coaches = _deriveCoachesFromSessions(sessions);
      }

      final snapshot = SessionsSnapshot(
        coaches: coaches,
        sessions: sessions,
        bookings: bookings,
      );
      _cachedSnapshot = snapshot;
      unawaited(_persistSnapshot(snapshot));
      _emitSnapshot(snapshot);
      return snapshot;
    } finally {
      _isFetchingSnapshot = false;
    }
  }

  Future<List<SessionDetail>> refreshBookingSessions(
    String bookingId, {
    bool force = false,
  }) async {
    if (_fetchingBookings.contains(bookingId) &&
        _bookingSessionsCache.containsKey(bookingId)) {
      return _bookingSessionsCache[bookingId]!;
    }
    if (!force && _bookingSessionsCache.containsKey(bookingId)) {
      return _bookingSessionsCache[bookingId]!;
    }

    _fetchingBookings.add(bookingId);
    try {
      final sessions = await _fetchBookingSessions(bookingId);
      _bookingSessionsCache[bookingId] = sessions;
      _bookingControllers[bookingId]?.add(sessions);
      return sessions;
    } finally {
      _fetchingBookings.remove(bookingId);
    }
  }

  Future<List<CoachSummary>> getUserCoaches() => _fetchUserCoaches();

  Future<List<Session>> getSessions({String? coachId, bool force = false}) async {
    if (coachId == null) {
      final snapshot = await refreshSessions(force: force);
      return snapshot.sessions;
    }
    return _fetchSessions(coachId: coachId);
  }

  Future<List<BookingHistoryModel>> getUserBookings() => _fetchUserBookings();

  Future<List<SessionDetail>> getBookingSessions(String bookingId) =>
      refreshBookingSessions(bookingId, force: true);

  void _ensureSnapshotController() {
    _snapshotController ??= StreamController<SessionsSnapshot>.broadcast();
  }

  void _emitSnapshot(SessionsSnapshot snapshot) {
    _ensureSnapshotController();
    _snapshotController!.add(snapshot);
  }

  void _ensureRealtimeSubscription() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    if (_subscribedUserId == userId && _realtimeChannel != null) return;

    _realtimeChannel?.unsubscribe();
    _subscribedUserId = userId;

    _realtimeChannel = supabase
        .channel('user-sessions-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => unawaited(_onRealtimeChanged()),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => unawaited(_onRealtimeChanged()),
        )
        .subscribe();
  }

  Future<void> _onRealtimeChanged() async {
    try {
      await refreshSessions(force: true);
      for (final bookingId in _bookingControllers.keys.toList()) {
        await refreshBookingSessions(bookingId, force: true);
      }
    } catch (_) {
      // Realtime refresh is best-effort; pull-to-refresh remains available.
    }
  }

  Future<List<CoachSummary>> _fetchUserCoaches() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await supabase.rpc('get_user_coaches', params: {
      'p_user_id': userId,
    });

    if (response == null) return [];

    return (response as List)
        .map((json) => CoachSummary.fromJson(json as Map<String, dynamic>))
        .where((coach) => coach.coachId.isNotEmpty)
        .toList();
  }

  Future<List<Session>> _fetchSessions({String? coachId}) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await supabase.rpc('get_user_sessions_by_coach', params: {
      'p_user_id': userId,
      'p_coach_id': coachId,
    });

    if (response == null) return [];

    return (response as List)
        .map((json) => Session.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<BookingHistoryModel>> _fetchUserBookings() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await supabase
        .from('user_booking_history')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (json) => BookingHistoryModel.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        )
        .toList();
  }

  Future<List<SessionDetail>> _fetchBookingSessions(String bookingId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final owned = await supabase
        .from('bookings')
        .select('id')
        .eq('id', bookingId)
        .eq('user_id', userId)
        .maybeSingle();

    if (owned == null) {
      throw Exception('Booking not found or access denied');
    }

    final response = await supabase.rpc(
      'get_booking_sessions',
      params: {'p_booking_id': bookingId},
    );

    if (response == null) return [];

    return (response as List)
        .map(
          (json) => SessionDetail.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        )
        .toList();
  }

  List<CoachSummary> _deriveCoachesFromSessions(List<Session> sessions) {
    final byCoach = <String, CoachSummary>{};

    for (final session in sessions) {
      byCoach.putIfAbsent(
        session.coachId,
        () => CoachSummary(
          coachId: session.coachId,
          coachName: session.coachName,
          coachPhoto: session.coachPhoto,
          coachSpecialty: session.coachSpecialty,
          totalSessions: session.totalSessions,
          attendedSessions: session.attendedSessions,
          remainingSessions: session.remainingSessions,
          activeBooking: true,
        ),
      );
    }

    return byCoach.values.toList();
  }
}

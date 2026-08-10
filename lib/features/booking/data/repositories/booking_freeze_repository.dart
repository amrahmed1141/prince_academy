import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/core/base/stream_repository.dart';
import 'package:prince_academy/core/services/member_data_sync.dart';
import 'package:prince_academy/features/admin/data/models/session_detail_model.dart';
import 'package:prince_academy/features/booking/data/models/booking_freeze_model.dart';

/// Remote I/O for session freeze request / apply / review flows.
///
/// Admin pending/active lists: [StreamRepository] TTL + realtime.
/// Per-booking context/sessions: short in-memory TTL (form cache-first).
/// Member "my requests": separate broadcast stream (existing).
class BookingFreezeRepository extends StreamRepository<AdminFreezeLists> {
  BookingFreezeRepository(this._client)
      : super(cacheTtl: const Duration(seconds: 30));

  final SupabaseClient _client;

  static const _formCacheTtl = Duration(minutes: 2);

  final Map<String, _TtlEntry<BookingFreezeContext?>> _contextCache = {};
  final Map<String, _TtlEntry<List<SessionDetail>>> _sessionsCache = {};

  StreamController<List<MemberFreezeRequest>>? _myFreezesController;
  RealtimeChannel? _myFreezesChannel;
  RealtimeChannel? _adminListsChannel;
  String? _subscribedUserId;
  bool _myFreezesFetching = false;

  // ---------------------------------------------------------------------------
  // Admin lists (StreamRepository)
  // ---------------------------------------------------------------------------

  Stream<List<MemberFreezeRequest>> get myFreezeRequestsStream {
    _myFreezesController ??=
        StreamController<List<MemberFreezeRequest>>.broadcast();
    _ensureMyFreezesRealtime();
    return _myFreezesController!.stream;
  }

  void ensureMyFreezesRealtime() => _ensureMyFreezesRealtime();

  void ensureAdminListsRealtime() {
    if (_adminListsChannel != null) return;
    _adminListsChannel = _client
        .channel('admin-freeze-lists')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'booking_freezes',
          callback: (_) => unawaited(refresh()),
        )
        .subscribe();
  }

  Future<AdminFreezeLists> getAdminLists({bool force = false}) async {
    if (!force && hasValidCache && cachedValue != null) {
      return cachedValue!;
    }
    return refresh();
  }

  @override
  Future<AdminFreezeLists> fetchFromApi() async {
    final results = await Future.wait([
      _fetchPendingRequests(),
      _fetchActiveFreezes(),
    ]);
    return AdminFreezeLists(
      pending: results[0] as List<PendingFreezeRequest>,
      active: results[1] as List<ActiveBookingFreeze>,
    );
  }

  Future<List<PendingFreezeRequest>> getPendingRequests({
    bool force = false,
  }) async {
    final lists = await getAdminLists(force: force);
    return lists.pending;
  }

  Future<List<ActiveBookingFreeze>> getActiveFreezes({
    bool force = false,
  }) async {
    final lists = await getAdminLists(force: force);
    return lists.active;
  }

  // ---------------------------------------------------------------------------
  // Per-booking form cache (context + sessions)
  // ---------------------------------------------------------------------------

  /// Last known context (may be stale) — for immediate paint only.
  BookingFreezeContext? getCachedFreezeContext(String bookingId) =>
      _contextCache[bookingId]?.value;

  List<SessionDetail>? getCachedBookingSessions(String bookingId) {
    final entry = _sessionsCache[bookingId];
    if (entry == null) return null;
    return entry.value;
  }

  Future<BookingFreezeContext?> getFreezeContext(
    String bookingId, {
    bool force = false,
  }) async {
    if (!force) {
      final entry = _contextCache[bookingId];
      if (entry != null && _isFresh(entry.at)) return entry.value;
    }

    final value = await _fetchFreezeContext(bookingId);
    _contextCache[bookingId] = _TtlEntry(value, DateTime.now());
    return value;
  }

  Future<List<SessionDetail>> getBookingSessions(
    String bookingId, {
    bool force = false,
  }) async {
    if (!force) {
      final entry = _sessionsCache[bookingId];
      if (entry != null && _isFresh(entry.at)) return entry.value;
    }

    final sessions = await _fetchBookingSessions(bookingId);
    _sessionsCache[bookingId] = _TtlEntry(sessions, DateTime.now());
    return sessions;
  }

  void invalidateBookingFormCache(String bookingId) {
    _contextCache.remove(bookingId);
    _sessionsCache.remove(bookingId);
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  Future<String> requestFreeze({
    required String bookingId,
    required List<DateTime> sessionDates,
  }) async {
    try {
      final response = await _client.rpc(
        'request_booking_freeze',
        params: {
          'p_booking_id': bookingId,
          'p_session_dates':
              sessionDates.map(formatFreezeDateParam).toList(),
        },
      );
      _afterFreezeMutation(bookingId);
      return response as String? ?? '';
    } on PostgrestException catch (e) {
      throw Exception(_friendly(e, 'request freeze'));
    }
  }

  Future<String> applyFreeze({
    required String bookingId,
    required List<DateTime> sessionDates,
  }) async {
    try {
      final response = await _client.rpc(
        'apply_booking_freeze',
        params: {
          'p_booking_id': bookingId,
          'p_session_dates':
              sessionDates.map(formatFreezeDateParam).toList(),
        },
      );
      _afterFreezeMutation(bookingId);
      return response as String? ?? '';
    } on PostgrestException catch (e) {
      throw Exception(_friendly(e, 'apply freeze'));
    }
  }

  Future<void> reviewFreeze({
    required String freezeId,
    required bool approve,
  }) async {
    try {
      await _client.rpc(
        'review_booking_freeze',
        params: {
          'p_freeze_id': freezeId,
          'p_approve': approve,
        },
      );
      invalidateStreamCache();
      unawaited(refresh());
    } on PostgrestException catch (e) {
      throw Exception(_friendly(e, approve ? 'approve freeze' : 'reject freeze'));
    }
  }

  Future<int> getPendingCount() async {
    try {
      final response = await _client.rpc('get_freeze_dashboard_count');
      if (response is int) return response;
      if (response is num) return response.toInt();
      return int.tryParse(response?.toString() ?? '') ?? 0;
    } on PostgrestException catch (e) {
      throw Exception(_friendly(e, 'load freeze count'));
    }
  }

  Future<List<MemberFreezeRequest>> getMyFreezeRequests({
    bool emit = true,
  }) async {
    _ensureMyFreezesRealtime();
    try {
      final response = await _client.rpc('get_my_freeze_requests');
      final items = response == null
          ? const <MemberFreezeRequest>[]
          : (response as List)
              .map(
                (json) => MemberFreezeRequest.fromJson(
                  Map<String, dynamic>.from(json as Map),
                ),
              )
              .toList();
      if (emit) {
        _myFreezesController ??=
            StreamController<List<MemberFreezeRequest>>.broadcast();
        _myFreezesController!.add(items);
      }
      return items;
    } on PostgrestException catch (e) {
      throw Exception(_friendly(e, 'load your freeze requests'));
    }
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _afterFreezeMutation(String bookingId) {
    invalidateBookingFormCache(bookingId);
    invalidateStreamCache();
    unawaited(refresh());
  }

  bool _isFresh(DateTime at) =>
      DateTime.now().difference(at) < _formCacheTtl;

  Future<BookingFreezeContext?> _fetchFreezeContext(String bookingId) async {
    try {
      final response = await _client.rpc(
        'get_booking_freeze_context',
        params: {'p_booking_id': bookingId},
      );
      if (response == null) return null;
      final list = response as List;
      if (list.isEmpty) return null;
      return BookingFreezeContext.fromJson(
        Map<String, dynamic>.from(list.first as Map),
      );
    } on PostgrestException catch (_) {
      // Fallback when freeze RPCs are not deployed yet.
      return _getFreezeContextFromBooking(bookingId);
    } catch (_) {
      return _getFreezeContextFromBooking(bookingId);
    }
  }

  Future<BookingFreezeContext?> _getFreezeContextFromBooking(
    String bookingId,
  ) async {
    try {
      final row = await _client
          .from('bookings')
          .select('id, user_id, subscription_start, subscription_end, status')
          .eq('id', bookingId)
          .maybeSingle();
      if (row == null) return null;
      return BookingFreezeContext.fromJson({
        'booking_id': row['id'],
        'user_id': row['user_id'],
        'subscription_start': row['subscription_start'],
        'subscription_end': row['subscription_end'],
        'status': row['status'],
      });
    } on PostgrestException catch (e) {
      throw Exception(_friendly(e, 'load freeze context'));
    }
  }

  Future<List<SessionDetail>> _fetchBookingSessions(String bookingId) async {
    try {
      final response = await _client.rpc(
        'get_booking_sessions',
        params: {'p_booking_id': bookingId},
      );
      if (response == null) return const [];
      return (response as List)
          .map(
            (json) => SessionDetail.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(_friendly(e, 'load booking sessions'));
    }
  }

  Future<List<PendingFreezeRequest>> _fetchPendingRequests() async {
    try {
      final response = await _client.rpc('get_pending_freeze_requests');
      if (response == null) return const [];
      return (response as List)
          .map(
            (json) => PendingFreezeRequest.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(_friendly(e, 'load pending freezes'));
    }
  }

  Future<List<ActiveBookingFreeze>> _fetchActiveFreezes() async {
    try {
      final response = await _client.rpc('get_active_booking_freezes');
      if (response == null) return const [];
      return (response as List)
          .map(
            (json) => ActiveBookingFreeze.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(_friendly(e, 'load active freezes'));
    }
  }

  void _ensureMyFreezesRealtime() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    if (_subscribedUserId == userId && _myFreezesChannel != null) return;

    _myFreezesChannel?.unsubscribe();
    _subscribedUserId = userId;
    _myFreezesChannel = _client
        .channel('user-freeze-requests-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'booking_freezes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => unawaited(_onMyFreezesChanged()),
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
          callback: (_) => unawaited(_onMyFreezesChanged()),
        )
        .subscribe();
  }

  Future<void> _onMyFreezesChanged() async {
    if (_myFreezesFetching) return;
    _myFreezesFetching = true;
    try {
      await getMyFreezeRequests(emit: true);
      // Keep Sessions / Booking History expiry in sync with approved freezes.
      MemberDataSync.afterBookingMutationUnawaited();
    } catch (_) {
      // Best-effort; pull-to-refresh remains available.
    } finally {
      _myFreezesFetching = false;
    }
  }

  String _friendly(PostgrestException e, String action) {
    final msg = e.message.trim();
    if (msg.isEmpty) return 'Could not $action. Please try again.';
    // Prefer short DB raise messages over raw Postgrest noise.
    if (msg.length < 160 && !msg.contains('PGRST')) return msg;
    return 'Could not $action. Please try again.';
  }

  @override
  void dispose() {
    _myFreezesChannel?.unsubscribe();
    _adminListsChannel?.unsubscribe();
    _myFreezesController?.close();
    super.dispose();
  }
}

class _TtlEntry<T> {
  const _TtlEntry(this.value, this.at);
  final T value;
  final DateTime at;
}

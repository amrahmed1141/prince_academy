import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/core/base/stream_repository.dart';
import 'package:prince_academy/core/cache/ttl_cache.dart';
import 'package:prince_academy/core/helpers/image_resize_helper.dart';
import 'package:prince_academy/features/admin/data/models/active_user_model.dart';
import 'package:prince_academy/features/admin/data/models/coach_model.dart';
import 'package:prince_academy/features/admin/data/models/coach_user_stats_model.dart';
import 'package:prince_academy/features/admin/data/models/paged_result.dart';
import 'package:prince_academy/features/admin/data/models/day_attendance_model.dart';
import 'package:prince_academy/features/admin/data/models/session_conflict_info.dart';
import 'package:prince_academy/features/admin/data/models/session_detail_model.dart';
import 'package:prince_academy/features/admin/data/models/session_draft.dart';
import 'package:prince_academy/features/admin/data/models/today_booking_model.dart';
import 'package:prince_academy/features/admin/data/models/admin_scan_profile_model.dart';
import 'package:prince_academy/features/admin/data/models/user_booking_detail_model.dart';
import 'package:prince_academy/features/admin/data/models/user_qr_profile_model.dart';
import 'package:prince_academy/features/admin/presentation/helpers/session_conflict_detector.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

class CoachRepository extends StreamRepository<List<CoachModel>> {
  CoachRepository(this._supabase) : super();

  final SupabaseClient _supabase;

  static const _coachListColumns =
      'id, name, specialty, photo_url, is_active, branch_id, created_at, updated_at, branches(name)';

  static const _activeUserColumns =
      'user_id, full_name, phone, qr_code, total_bookings, active_bookings, expired_bookings, latest_subscription_end';

  static const int defaultPageSize = 50;
  static const Duration _scanProfileCacheTtl = Duration(minutes: 5);

  final TtlCache<List<ActiveUser>> _activeUsersCache = TtlCache();
  final Map<String, List<AdminScanProfile>> _scanProfileCache = {};
  final Map<String, DateTime> _scanProfileCachedAt = {};
  final Map<String, StreamController<List<AdminScanProfile>>>
      _scanProfileControllers = {};
  final Map<String, RealtimeChannel> _scanProfileChannels = {};
  final Map<String, Timer> _scanProfileDebounce = {};

  void invalidateCaches() {
    invalidateStreamCache();
    _activeUsersCache.invalidate();
  }

  void invalidateUserScanProfileCache(String userId) {
    _scanProfileCache.remove(userId);
    _scanProfileCachedAt.remove(userId);
  }

  List<AdminScanProfile>? getCachedUserScanProfiles(String userId) {
    final cachedAt = _scanProfileCachedAt[userId];
    final cached = _scanProfileCache[userId];
    if (cached == null || cachedAt == null) return null;
    if (DateTime.now().difference(cachedAt) > _scanProfileCacheTtl) {
      invalidateUserScanProfileCache(userId);
      return null;
    }
    return List<AdminScanProfile>.from(cached);
  }

  @override
  Future<List<CoachModel>> fetchFromApi() async {
    try {
      final response = await _supabase
          .from('coaches')
          .select(_coachListColumns)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => CoachModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load coaches'));
    }
  }

  Future<List<CoachModel>> fetchCoaches({bool force = false}) async {
    if (!force && hasValidCache && cachedValue != null) {
      return cachedValue!;
    }
    return refresh();
  }

  Future<String> uploadCoachPhoto(File file, String fileName) async {
    final resized = await ImageResizeHelper.resizeCoachPhoto(file);
    final uploadFile = resized;
    final uploadName = uploadFile.path.toLowerCase().endsWith('.jpg')
        ? fileName.replaceAll(RegExp(r'\.[^.]+$'), '.jpg')
        : fileName;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanFileName = uploadName.replaceAll(RegExp(r'\s+'), '_');
    final path = 'coaches/${timestamp}_$cleanFileName';

    await _supabase.storage.from('coach-photos').upload(
          path,
          uploadFile,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _mimeTypeForFile(uploadName),
          ),
        );
    return _supabase.storage.from('coach-photos').getPublicUrl(path);
  }

  String _mimeTypeForFile(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<void> _requireAdmin() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user session found.');
    }

    final profile = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', currentUser.id)
        .maybeSingle();

    if (profile == null) {
      throw Exception('User profile not found in database.');
    }

    final role = profile['role'] as String?;
    if (role != 'admin') {
      throw Exception(
        'Unauthorized: Only administrators can perform this action.',
      );
    }
  }

  Future<void> addCoach({
    required String name,
    required String specialty,
    String? photoUrl,
  }) async {
    await _requireAdmin();

    try {
      await _supabase.from('coaches').insert({
        'name': name,
        'specialty': specialty,
        'photo_url': photoUrl,
        'is_active': true,
      });
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'add coach'));
    }
  }

  Future<List<CoachSessionModel>> getCoachSessions(String coachId) async {
    try {
      final response = await _supabase
          .from('coach_sessions')
          .select('*, branches(name)')
          .eq('coach_id', coachId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return _mapSessionList(response);
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load coach sessions'));
    }
  }

  Future<List<CoachSessionModel>> getAllSessionsWithCoach() async {
    try {
      final response = await _supabase
          .from('coach_sessions')
          .select('*, coaches(name, specialty, photo_url), branches(name)')
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return _mapSessionList(response);
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load sessions'));
    }
  }

  Future<SessionConflictInfo?> findSessionConflict(SessionDraft draft) async {
    if (draft.branchId == null ||
        draft.branchId!.isEmpty ||
        draft.coachId == null ||
        draft.coachId!.isEmpty ||
        draft.sessions.isEmpty ||
        draft.timeSlot.trim().isEmpty) {
      return null;
    }

    try {
      final response = await _supabase.rpc(
        'find_coach_session_conflict',
        params: {
          'p_branch_id': draft.branchId,
          'p_coach_id': draft.coachId,
          'p_time_slot': draft.timeSlot,
          'p_days': draft.sessions.map((s) => s.day).toList(),
          'p_class_types': draft.sessions.map((s) => s.classType).toList(),
        },
      );

      final rows = response as List? ?? const [];
      if (rows.isEmpty) return null;

      final first = Map<String, dynamic>.from(rows.first as Map);
      final name = (first['coach_name'] as String?)?.trim();
      final classType = (first['class_type'] as String?)?.trim();
      final timeSlot = (first['time_slot'] as String?)?.trim();
      return SessionConflictInfo(
        coachName: (name != null && name.isNotEmpty) ? name : 'Another coach',
        classType: (classType != null && classType.isNotEmpty)
            ? classType
            : 'session',
        timeSlot: (timeSlot != null && timeSlot.isNotEmpty)
            ? timeSlot
            : draft.timeSlot.trim(),
      );
    } on PostgrestException catch (e) {
      // Fallback if RPC is unavailable: load branch sessions and check locally.
      try {
        final response = await _supabase
            .from('coach_sessions')
            .select(
              'id, coach_id, days, session_type, session_date, time_slots, '
              'branch_id, is_active, coaches(name)',
            )
            .eq('branch_id', draft.branchId!)
            .eq('is_active', true)
            .neq('coach_id', draft.coachId!);

        final sessions = (response as List)
            .map(
              (e) => CoachSessionModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();

        return SessionConflictDetector.find(
          draft: draft,
          existingSessions: sessions,
        );
      } on PostgrestException catch (_) {
        throw Exception(_mapPostgrestError(e, 'check session conflict'));
      }
    }
  }

  Future<void> upsertSession(SessionDraft draft) async {
    await _requireAdmin();

    if (draft.coachId == null || draft.coachId!.isEmpty) {
      throw Exception('Coach is required.');
    }
    if (draft.branchId == null || draft.branchId!.isEmpty) {
      throw Exception('Branch is required.');
    }
    if (draft.timeSlot.isEmpty) {
      throw Exception('Time slot is required.');
    }
    if (draft.pricePerSession <= 0) {
      throw Exception('Enter a valid price per session.');
    }
    if (draft.sessions.isEmpty) {
      throw Exception('Add at least one session detail.');
    }
    if (draft.sessions.length != draft.sessionsPerWeek) {
      throw Exception('Session details count does not match sessions per week.');
    }

    for (int i = 0; i < draft.sessions.length; i++) {
      final slot = draft.sessions[i];
      if (slot.day.isEmpty) {
        throw Exception('Session ${i + 1}: please select a day.');
      }
      if (slot.classType.isEmpty) {
        throw Exception('Session ${i + 1}: please select a class type.');
      }
    }

    try {
      final firstDay = draft.sessions.first.day;
      final payload = {
        'coach_id': draft.coachId,
        'branch_id': draft.branchId,
        'sessions_per_week': draft.sessionsPerWeek,
        'session_type': draft.sessions.map((s) => s.classType).join(', '),
        'session_date': _formatDateForDb(_getNextWeekdayDate(firstDay)),
        'days': draft.sessions.map((s) => s.day).toList(),
        'time_slots': [draft.timeSlot],
        'price_per_session': draft.pricePerSession,
        'is_active': true,
      };

      await _supabase.from('coach_sessions').insert(payload);
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'save session'));
    }
  }

  Future<void> deleteSessionsByCoachId(String coachId) async {
    await _requireAdmin();

    try {
      await _supabase.from('coach_sessions').delete().eq('coach_id', coachId);
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'delete sessions'));
    }
  }

  Future<void> deleteSession(String sessionId) async {
    await _requireAdmin();

    try {
      await _supabase.from('coach_sessions').delete().eq('id', sessionId);
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'delete session'));
    }
  }

  Future<void> deleteCoach(String coachId) async {
    await _requireAdmin();

    try {
      await _supabase.from('coach_sessions').delete().eq('coach_id', coachId);
      await _supabase.from('coaches').delete().eq('id', coachId);
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'delete coach'));
    }
  }

  Future<void> updateCoach({
    required String coachId,
    String? name,
    String? specialty,
    String? photoUrl,
  }) async {
    await _requireAdmin();
    try {
      await _supabase.from('coaches').update({
        if (name != null) 'name': name,
        if (specialty != null) 'specialty': specialty,
        if (photoUrl != null) 'photo_url': photoUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', coachId);
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'update coach'));
    }
  }

  Future<Set<String>> getUserIdsWithPendingPayments() async {
    await _requireAdmin();

    try {
      final response = await _supabase
          .from('bookings')
          .select('user_id')
          .or(
            'payment_status.eq.pending_payment,'
            'payment_status.eq.awaiting_verification,'
            'payment_status.eq.pending',
          );

      return (response as List)
          .map((row) => (row as Map)['user_id'] as String?)
          .whereType<String>()
          .toSet();
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load pending payment user IDs'));
    }
  }

  Future<void> deleteCoachPhoto(String photoUrl) async {
    await _requireAdmin();
    try {
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf('coach-photos');
      if (bucketIndex != -1 && bucketIndex + 1 < pathSegments.length) {
        final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from('coach-photos').remove([storagePath]);
      } else {
        final fileName = pathSegments.last;
        await _supabase.storage.from('coach-photos').remove([fileName]);
      }
    } catch (e) {
      // Non-blocking log
      print('Failed to delete coach photo: $e');
    }
  }

  Future<void> updateSession({
    required String sessionId,
    String? branchId,
    String? timeSlot,
    double? pricePerSession,
    int? sessionsPerWeek,
    List<String>? days,
    List<String>? classTypes,
  }) async {
    await _requireAdmin();
    try {
      await _supabase.from('coach_sessions').update({
        if (branchId != null) 'branch_id': branchId,
        if (timeSlot != null) 'time_slots': [timeSlot],
        if (pricePerSession != null) 'price_per_session': pricePerSession,
        if (sessionsPerWeek != null) 'sessions_per_week': sessionsPerWeek,
        if (days != null) 'days': days,
        if (classTypes != null) 'session_type': classTypes.join(', '),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', sessionId);
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'update session'));
    }
  }


  Future<List<CoachUserStats>> getCoachUserStats() async {
    await _requireAdmin();

    try {
      final response = await _supabase
          .from('coach_user_stats')
          .select(
            'coach_id, coach_name, coach_photo, coach_specialty, branch_id, '
            'branch_name, total_subscribers, active_subscribers, expired_subscribers',
          );
      final stats = (response as List)
          .map(
            (json) => CoachUserStats.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();

      final byCoachId = <String, CoachUserStats>{
        for (final coach in stats) coach.coachId: coach,
      };

      // Include coaches that already have active sessions even if they currently
      // have zero subscribers and are missing from coach_user_stats view.
      final sessions = await getAllSessionsWithCoach();
      for (final session in sessions) {
        if (session.coachId.isEmpty) continue;
        final sessionBranchId = session.branchId;
        final sessionBranchName = session.branchName;
        final existing = byCoachId[session.coachId];
        if (existing == null) {
          byCoachId[session.coachId] = CoachUserStats(
            coachId: session.coachId,
            coachName: session.coachName ?? 'Coach',
            coachPhoto: session.coachPhotoUrl,
            coachSpecialty: session.coachSpecialty ?? 'MMA',
            branchId: sessionBranchId,
            branchName: sessionBranchName,
            totalSubscribers: 0,
            activeSubscribers: 0,
            expiredSubscribers: 0,
          );
          continue;
        }

        // Always prefer active session branch mapping for tracking filters.
        if (sessionBranchId != null && sessionBranchId.isNotEmpty) {
          byCoachId[session.coachId] = CoachUserStats(
            coachId: existing.coachId,
            coachName: existing.coachName,
            coachPhoto: existing.coachPhoto,
            coachSpecialty: existing.coachSpecialty,
            branchId: sessionBranchId,
            branchName: sessionBranchName ?? existing.branchName,
            totalSubscribers: existing.totalSubscribers,
            activeSubscribers: existing.activeSubscribers,
            expiredSubscribers: existing.expiredSubscribers,
          );
        }
      }

      return byCoachId.values.toList();
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load coach stats'));
    }
  }

  /// Server-paginated members list. Prefer this over unbounded fetches.
  Future<PagedResult<ActiveUser>> getMembers({
    int limit = defaultPageSize,
    int offset = 0,
    String? search,
    String? coachId,
    String? branchId,
    bool? pendingOnly,
  }) async {
    await _requireAdmin();

    final safeLimit = limit.clamp(1, 100);
    final trimmedSearch = search?.trim();
    final searchParam =
        (trimmedSearch == null || trimmedSearch.isEmpty) ? null : trimmedSearch;

    try {
      final response = await _supabase.rpc(
        'get_active_users_page',
        params: {
          'p_limit': safeLimit,
          'p_offset': offset,
          'p_search': searchParam,
          'p_coach_id': coachId,
          'p_branch_id': branchId,
          'p_pending_only': pendingOnly,
        },
      );

      final rows = (response as List?) ?? const [];
      final users = rows
          .map(
            (json) => ActiveUser.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();

      final totalCount = rows.isEmpty
          ? 0
          : ((rows.first as Map)['total_count'] as num?)?.toInt();

      if (offset == 0 &&
          searchParam == null &&
          coachId == null &&
          branchId == null &&
          pendingOnly != true) {
        _activeUsersCache.set(users);
      }

      return PagedResult(
        items: users,
        hasMore: users.length >= safeLimit,
        totalCount: totalCount,
      );
    } on PostgrestException catch (e) {
      // Fallback when RPC is not deployed yet.
      if (_isMissingRpc(e)) {
        return _getMembersFallback(
          limit: safeLimit,
          offset: offset,
          search: searchParam,
          coachId: coachId,
          branchId: branchId,
          pendingOnly: pendingOnly,
        );
      }
      throw Exception(_mapPostgrestError(e, 'load members'));
    }
  }

  Future<List<ActiveUser>> getActiveUsersWithQr({
    bool force = false,
    int? limit,
    int offset = 0,
  }) async {
    if (!force && offset == 0 && (limit == null || limit >= defaultPageSize)) {
      final cached = _activeUsersCache.value;
      if (cached != null) return cached;
    }

    final page = await getMembers(
      limit: limit ?? defaultPageSize,
      offset: offset,
    );
    return page.items;
  }

  Future<List<ActiveUser>> searchActiveUsers(
    String query, {
    int limit = defaultPageSize,
    int offset = 0,
  }) async {
    final page = await getMembers(
      limit: limit,
      offset: offset,
      search: query,
    );
    return page.items;
  }

  Future<PagedResult<ActiveUser>> _getMembersFallback({
    required int limit,
    required int offset,
    String? search,
    String? coachId,
    String? branchId,
    bool? pendingOnly,
  }) async {
    try {
      final List<dynamic> rawRows;
      if (search != null && search.isNotEmpty) {
        final escaped = search.replaceAll(RegExp(r'[%_,]'), '');
        rawRows = await _supabase
            .from('active_users_with_qr')
            .select(_activeUserColumns)
            .or('full_name.ilike.%$escaped%,phone.ilike.%$escaped%')
            .order('full_name')
            .range(offset, offset + limit - 1) as List;
      } else {
        rawRows = await _supabase
            .from('active_users_with_qr')
            .select(_activeUserColumns)
            .order('full_name')
            .range(offset, offset + limit - 1) as List;
      }
      var users = rawRows
          .map(
            (json) => ActiveUser.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();

      // Coach/branch/pending filters without RPC: narrow after fetch of this page.
      // Prefer deploying get_active_users_page for correct cross-page filters.
      if (coachId != null) {
        final ids = await getUserIdsForCoach(coachId);
        users = users.where((u) => ids.contains(u.userId)).toList();
      }
      if (branchId != null) {
        final ids = await getUserIdsForBranch(branchId);
        users = users.where((u) => ids.contains(u.userId)).toList();
      }

      final pendingIds = await getUserIdsWithPendingPayments();
      users = users
          .map(
            (u) => u.copyWith(hasPendingPayment: pendingIds.contains(u.userId)),
          )
          .toList();

      if (pendingOnly == true) {
        users = users.where((u) => u.hasPendingPayment).toList();
      }

      users.sort((a, b) {
        if (a.hasPendingPayment && !b.hasPendingPayment) return -1;
        if (!a.hasPendingPayment && b.hasPendingPayment) return 1;
        return a.fullName.compareTo(b.fullName);
      });

      return PagedResult(
        items: users,
        hasMore: rawRows.length >= limit,
      );
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load members'));
    }
  }

  bool _isMissingRpc(PostgrestException e) {
    final message = e.message.toLowerCase();
    return e.code == 'PGRST202' ||
        e.code == '42883' ||
        message.contains('get_active_users_page') ||
        message.contains('could not find the function');
  }

  Future<Set<String>> getUserIdsForCoach(String coachId) async {
    await _requireAdmin();

    try {
      final response = await _supabase
          .from('user_attendance_history')
          .select('user_id')
          .eq('coach_id', coachId);

      return (response as List)
          .map((row) => (row as Map)['user_id'] as String?)
          .whereType<String>()
          .toSet();
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load coach subscribers'));
    }
  }

  Future<Set<String>> getUserIdsForBranch(String branchId) async {
    await _requireAdmin();

    try {
      final response = await _supabase
          .from('user_attendance_history')
          .select('user_id')
          .eq('branch_id', branchId);

      return (response as List)
          .map((row) => (row as Map)['user_id'] as String?)
          .whereType<String>()
          .toSet();
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load branch subscribers'));
    }
  }

  Future<List<UserBookingDetail>> getUserBookingDetails(String userId) async {
    await _requireAdmin();

    try {
      final response = await _supabase
          .from('user_attendance_history')
          .select()
          .eq('user_id', userId);

      return (response as List)
          .map(
            (json) => UserBookingDetail.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load user bookings'));
    }
  }

  Future<List<DayAttendance>> getWeeklyAttendance(
    String userId,
    String bookingId,
  ) async {
    await _requireAdmin();

    try {
      final response = await _supabase.rpc(
        'get_user_weekly_attendance',
        params: {
          'p_user_id': userId,
          'p_booking_id': bookingId,
        },
      );

      if (response == null) return [];

      return (response as List)
          .map(
            (json) => DayAttendance.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load weekly attendance'));
    }
  }

  Future<List<SessionDetail>> getBookingSessions(String bookingId) async {
    await _requireAdmin();

    try {
      final response = await _supabase.rpc(
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
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load booking sessions'));
    }
  }

  Future<bool> reAttendSession(
    String bookingId,
    DateTime sessionDate,
  ) async {
    await _requireAdmin();

    try {
      final local = sessionDate.toLocal();
      final formatted =
          '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';

      final response = await _supabase.rpc(
        're_attend_session',
        params: {
          'p_booking_id': bookingId,
          'p_session_date': formatted,
        },
      );

      if (response is bool) {
        if (response) invalidateCaches();
        return response;
      }
      return false;
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 're-attend session'));
    }
  }

  Future<bool> unmarkSession(
    String bookingId,
    DateTime sessionDate,
  ) async {
    await _requireAdmin();

    try {
      final local = sessionDate.toLocal();
      final formatted =
          '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';

      final response = await _supabase.rpc(
        'unmark_session',
        params: {
          'p_booking_id': bookingId,
          'p_session_date': formatted,
        },
      );

      if (response is bool) {
        if (response) invalidateCaches();
        return response;
      }
      return false;
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'unmark session'));
    }
  }

  Future<List<AdminScanProfile>> getUserScanProfiles(
    String userId, {
    bool force = false,
  }) async {
    if (!force) {
      final cached = getCachedUserScanProfiles(userId);
      if (cached != null) return cached;
    }

    return _refreshUserScanProfiles(userId);
  }

  /// Emits cached data immediately (if any), then live refreshes on
  /// bookings / attendance / payments changes for this member.
  Stream<List<AdminScanProfile>> watchUserScanProfiles(String userId) {
    final controller = _scanProfileControllers.putIfAbsent(
      userId,
      () => StreamController<List<AdminScanProfile>>.broadcast(),
    );

    final cached = getCachedUserScanProfiles(userId);
    if (cached != null) {
      scheduleMicrotask(() {
        if (!controller.isClosed) controller.add(cached);
      });
      // Soft background refresh — UI already has cache, no loading spinner.
      unawaited(_safeRefreshUserScanProfiles(userId));
    } else {
      unawaited(_safeRefreshUserScanProfiles(userId));
    }

    _ensureUserScanRealtime(userId);

    return controller.stream;
  }

  Future<void> _safeRefreshUserScanProfiles(String userId) async {
    final controller = _scanProfileControllers[userId];
    try {
      await _refreshUserScanProfiles(userId);
    } catch (e, st) {
      if (controller != null && !controller.isClosed) {
        controller.addError(e, st);
      }
    }
  }

  void stopWatchingUserScanProfiles(String userId) {
    _scanProfileDebounce.remove(userId)?.cancel();
    _scanProfileChannels.remove(userId)?.unsubscribe();
    final controller = _scanProfileControllers.remove(userId);
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
  }

  Future<List<AdminScanProfile>> _refreshUserScanProfiles(String userId) async {
    await _requireAdmin();

    try {
      final response = await _supabase
          .from('admin_scan_profile')
          .select()
          .eq('user_id', userId);

      final profiles = (response as List)
          .map(
            (e) => AdminScanProfile.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();

      _scanProfileCache[userId] = profiles;
      _scanProfileCachedAt[userId] = DateTime.now();

      final controller = _scanProfileControllers[userId];
      if (controller != null && !controller.isClosed) {
        controller.add(List<AdminScanProfile>.from(profiles));
      }

      return profiles;
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load member bookings'));
    }
  }

  void _ensureUserScanRealtime(String userId) {
    if (_scanProfileChannels.containsKey(userId)) return;

    final channel = _supabase
        .channel('admin-user-scan-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => _scheduleUserScanRefresh(userId),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => _scheduleUserScanRefresh(userId),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payments',
          callback: (_) => _scheduleUserScanRefresh(userId),
        )
        .subscribe();

    _scanProfileChannels[userId] = channel;
  }

  void _scheduleUserScanRefresh(String userId) {
    _scanProfileDebounce[userId]?.cancel();
    _scanProfileDebounce[userId] = Timer(
      const Duration(milliseconds: 500),
      () {
        invalidateUserScanProfileCache(userId);
        unawaited(_refreshUserScanProfiles(userId));
      },
    );
  }

  Future<List<AdminScanProfile>> getUserByQrCode(String qrCode) async {
    await _requireAdmin();

    try {
      final response = await _supabase
          .from('admin_scan_profile')
          .select()
          .eq('qr_code', qrCode);

      return (response as List)
          .map(
            (e) => AdminScanProfile.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load member by QR code'));
    }
  }

  Future<List<UserQrProfile>> getUserQrProfileByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('user_qr_profile')
          .select()
          .eq('user_id', userId);

      return (response as List)
          .map(
            (e) => UserQrProfile.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load your QR profile'));
    }
  }

  Future<List<TodayBooking>> getTodayBookings(String userId) async {
    await _requireAdmin();

    try {
      final response = await _supabase
          .from('today_bookings')
          .select()
          .eq('user_id', userId);

      return (response as List)
          .map(
            (e) => TodayBooking.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load today\'s bookings'));
    }
  }

  Future<void> markAttendance({
    required String bookingId,
    required String userId,
    required String coachId,
    required String adminId,
  }) async {
    await _requireAdmin();

    try {
      final today = _formatDateForDb(DateTime.now());
      await _supabase.from('attendance').insert({
        'booking_id': bookingId,
        'user_id': userId,
        'coach_id': coachId,
        'attended_on': today,
        'status': 'attended',
        'scanned_by': adminId,
      });
      invalidateCaches();
      unawaited(_refreshUserScanProfiles(userId));
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'mark attendance'));
    }
  }

  Future<BookingModel> renewSubscription(String bookingId) async {
    try {
      final response = await _supabase.rpc(
        'renew_booking_subscription',
        params: {'p_booking_id': bookingId},
      );

      if (response is Map) {
        return BookingModel.fromJson(Map<String, dynamic>.from(response));
      }
      if (response is List && response.isNotEmpty) {
        return BookingModel.fromJson(
          Map<String, dynamic>.from(response.first as Map),
        );
      }

      throw Exception('Unexpected response from subscription renewal.');
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'renew subscription'));
    }
  }

  List<CoachSessionModel> _mapSessionList(dynamic response) {
    return (response as List)
        .map(
          (e) => CoachSessionModel.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  DateTime _getNextWeekdayDate(String dayOfWeekName) {
    final now = DateTime.now();
    final dayMap = <String, int>{
      'mon': DateTime.monday,
      'tue': DateTime.tuesday,
      'wed': DateTime.wednesday,
      'thu': DateTime.thursday,
      'fri': DateTime.friday,
      'sat': DateTime.saturday,
      'sun': DateTime.sunday,
    };
    final key = dayOfWeekName.toLowerCase().substring(0, 3);
    final targetWeekday = dayMap[key] ?? now.weekday;
    int daysToAdd = targetWeekday - now.weekday;
    if (daysToAdd <= 0) {
      daysToAdd += 7;
    }
    return DateTime(now.year, now.month, now.day + daysToAdd, 18, 0);
  }

  String? _formatDateForDb(DateTime? date) {
    if (date == null) return null;
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _mapPostgrestError(PostgrestException e, String action) {
    if (e.code == 'PGRST205' || e.code == '42P01') {
      return 'Database table missing. Please run the coach_sessions setup SQL in Supabase.';
    }
    if (e.code == '42501') {
      return 'Permission denied. Check Row Level Security policies for coach_sessions.';
    }
    if (e.message.contains('updated_at') &&
        e.message.contains('attendance')) {
      return 'Database needs update. Run supabase/fix_re_attend_updated_at.sql in Supabase SQL Editor.';
    }
    return 'Failed to $action: ${e.message}';
  }
}

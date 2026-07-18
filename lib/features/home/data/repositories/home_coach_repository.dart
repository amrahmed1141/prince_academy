import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/core/cache/local_cache_store.dart';
import 'package:prince_academy/core/cache/ttl_cache.dart';
import 'package:prince_academy/features/home/data/models/coaches_model.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

class HomeCoachRepository {
  final SupabaseClient _supabase;
  final LocalCacheStore _cache;

  HomeCoachRepository(this._supabase, {LocalCacheStore? cache})
      : _cache = cache ?? LocalCacheStore.instance {
    _hydrateFromDisk();
  }

  static const _coachColumns =
      'id, name, specialty, photo_url, is_active, branch_id';

  static const _coachColumnsWithCounts =
      'id, name, specialty, photo_url, is_active, branch_id, coach_member_count(member_count)';

  static const _coachColumnsWithCountsAndSessions =
      'id, name, specialty, photo_url, is_active, branch_id, '
      'coach_member_count(member_count), coach_sessions!inner(id)';

  static const _coachColumnsWithSessions =
      'id, name, specialty, photo_url, is_active, branch_id, '
      'coach_sessions!inner(id)';

  final TtlCache<List<CoachModel>> _coachesCache = TtlCache();
  final TtlCache<Map<String, String>> _classTypesCache = TtlCache();
  final TtlCache<Map<String, int>> _studentCountsCache = TtlCache();

  final Map<String, CoachModel> _coachByIdCache = {};
  final Map<String, List<CoachSessionModel>> _coachSessionsCache = {};
  final Set<String> _fetchingCoachIds = {};
  final Set<String> _fetchingSessionCoachIds = {};

  void _hydrateFromDisk() {
    if (_coachesCache.value != null) return;
    final list = _cache.getList(LocalCacheStore.coachesKey());
    if (list == null) return;
    try {
      final coaches = list
          .map((e) => CoachModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      _coachesCache.set(coaches);
      for (final coach in coaches) {
        _coachByIdCache[coach.id] = coach;
      }
    } catch (_) {}
  }

  CoachModel? cachedCoach(String coachId) {
    _hydrateFromDisk();
    final memory = _coachByIdCache[coachId];
    if (memory != null) return memory;

    final list = _coachesCache.value;
    if (list != null) {
      for (final coach in list) {
        if (coach.id == coachId) {
          _coachByIdCache[coachId] = coach;
          return coach;
        }
      }
    }

    final map = _cache.getMap(LocalCacheStore.coachProfileKey(coachId));
    if (map == null) return null;
    try {
      final coach = CoachModel.fromMap(map);
      _coachByIdCache[coachId] = coach;
      return coach;
    } catch (_) {
      return null;
    }
  }

  List<CoachSessionModel>? cachedCoachSessions(String coachId) {
    final memory = _coachSessionsCache[coachId];
    if (memory != null) return memory;

    final list = _cache.getList(LocalCacheStore.coachSessionsKey(coachId));
    if (list == null) return null;
    try {
      final sessions = list
          .map(
            (e) => CoachSessionModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
      _coachSessionsCache[coachId] = sessions;
      return sessions;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistCoach(CoachModel coach) async {
    _coachByIdCache[coach.id] = coach;
    await _cache.putJson(
      LocalCacheStore.coachProfileKey(coach.id),
      coach.toMap(),
    );
  }

  Future<void> _persistCoachSessions(
    String coachId,
    List<CoachSessionModel> sessions,
  ) async {
    _coachSessionsCache[coachId] = sessions;
    await _cache.putJson(
      LocalCacheStore.coachSessionsKey(coachId),
      sessions.map((s) => s.toMap()).toList(),
    );
  }

  Future<void> _persistCoaches(List<CoachModel> coaches) async {
    for (final coach in coaches) {
      _coachByIdCache[coach.id] = coach;
    }
    await _cache.putJson(
      LocalCacheStore.coachesKey(),
      coaches.map((c) => c.toMap()).toList(),
    );
  }

  /// Fetch all active coaches (cached). Filter by specialty in memory.
  Future<List<CoachModel>> getActiveCoaches({bool force = false}) async {
    _hydrateFromDisk();
    if (!force) {
      final cached = _coachesCache.value;
      if (cached != null) return cached;
    }

    final response = await _fetchCoachesSelect();

    final coaches = (response as List)
        .map((e) => CoachModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    _coachesCache.set(coaches);
    unawaited(_persistCoaches(coaches));
    return coaches;
  }

  Future<dynamic> _fetchCoachesSelect() async {
    try {
      return await _supabase
          .from('coaches')
          .select(_coachColumnsWithCountsAndSessions)
          .eq('is_active', true)
          .eq('coach_sessions.is_active', true);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST200' || e.code == 'PGRST205' || e.code == '42P01') {
        try {
          return await _supabase
              .from('coaches')
              .select(_coachColumnsWithSessions)
              .eq('is_active', true)
              .eq('coach_sessions.is_active', true);
        } on PostgrestException catch (e2) {
          if (e2.code == 'PGRST200' ||
              e2.code == 'PGRST205' ||
              e2.code == '42P01') {
            return _supabase
                .from('coaches')
                .select(_coachColumns)
                .eq('is_active', true);
          }
          rethrow;
        }
      }
      rethrow;
    }
  }

  CoachModel _withMemberCount(CoachModel coach, Map<String, int> counts) {
    final count = counts[coach.id];
    if (count == null || count == coach.memberCount) return coach;
    return coach.copyWith(memberCount: count);
  }

  /// Filter cached coaches by specialty — no extra network call.
  Future<List<CoachModel>> getCoachesBySpecialty(String specialty) async {
    final all = await getActiveCoaches();
    return all
        .where((c) => c.specialty.toLowerCase() == specialty.toLowerCase())
        .toList();
  }

  Future<CoachModel> getCoachById(
    String coachId, {
    bool force = false,
  }) async {
    if (!force) {
      final cached = cachedCoach(coachId);
      if (cached != null) return cached;
    }

    if (_fetchingCoachIds.contains(coachId)) {
      final cached = cachedCoach(coachId);
      if (cached != null) return cached;
    }

    _fetchingCoachIds.add(coachId);
    try {
      try {
        final response = await _supabase
            .from('coaches')
            .select(_coachColumnsWithCounts)
            .eq('id', coachId)
            .single();
        final coach =
            CoachModel.fromMap(Map<String, dynamic>.from(response));
        unawaited(_persistCoach(coach));
        return coach;
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST200' || e.code == 'PGRST205' || e.code == '42P01') {
          final response = await _supabase
              .from('coaches')
              .select(_coachColumns)
              .eq('id', coachId)
              .single();
          final coach =
              CoachModel.fromMap(Map<String, dynamic>.from(response));
          final counts = await getStudentCountsForCoaches([coachId]);
          final withCount = _withMemberCount(coach, counts);
          unawaited(_persistCoach(withCount));
          return withCount;
        }
        rethrow;
      }
    } finally {
      _fetchingCoachIds.remove(coachId);
    }
  }

  Future<Map<String, String>> getPrimaryClassTypesForCoaches(
    List<String> coachIds, {
    bool force = false,
  }) async {
    if (coachIds.isEmpty) return {};

    if (!force) {
      final cached = _classTypesCache.value;
      if (cached != null) {
        return {
          for (final id in coachIds)
            if (cached.containsKey(id)) id: cached[id]!,
        };
      }
    }

    try {
      final response = await _supabase
          .from('coach_sessions')
          .select('coach_id, session_type')
          .inFilter('coach_id', coachIds)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final map = <String, String>{};
      for (final row in response as List) {
        final data = Map<String, dynamic>.from(row as Map);
        final coachId = data['coach_id'] as String?;
        final sessionType = data['session_type'] as String?;
        if (coachId == null || coachId.isEmpty) continue;
        if (map.containsKey(coachId)) continue;
        if (sessionType != null && sessionType.isNotEmpty) {
          map[coachId] = sessionType;
        }
      }

      _classTypesCache.set(map);
      return map;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.code == '42P01') {
        return {};
      }
      rethrow;
    }
  }

  /// Distinct students (users) who have booked with each coach.
  Future<Map<String, int>> getStudentCountsForCoaches(
    List<String> coachIds, {
    bool force = false,
  }) async {
    if (coachIds.isEmpty) return {};

    if (!force) {
      final cached = _studentCountsCache.value;
      if (cached != null) {
        return {
          for (final id in coachIds)
            if (cached.containsKey(id)) id: cached[id]!,
        };
      }
    }

    try {
      final response = await _supabase.rpc(
        'get_coach_member_counts',
        params: {'p_coach_ids': coachIds},
      );

      final counts = <String, int>{};
      for (final row in response as List) {
        final data = Map<String, dynamic>.from(row as Map);
        final coachId = data['coach_id'] as String?;
        final count = (data['member_count'] as num?)?.toInt();
        if (coachId != null && count != null) {
          counts[coachId] = count;
        }
      }

      _studentCountsCache.set(counts);
      return counts;
    } on PostgrestException catch (e) {
      if (e.code != 'PGRST202') {
        if (e.code == 'PGRST205' || e.code == '42P01') {
          return {};
        }
        rethrow;
      }
    }

    try {
      final response = await _supabase
          .from('coach_member_count')
          .select('coach_id, member_count')
          .inFilter('coach_id', coachIds);

      final counts = <String, int>{};
      for (final row in response as List) {
        final data = Map<String, dynamic>.from(row as Map);
        final coachId = data['coach_id'] as String?;
        final count = (data['member_count'] as num?)?.toInt();
        if (coachId != null && count != null) {
          counts[coachId] = count;
        }
      }

      _studentCountsCache.set(counts);
      return counts;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.code == '42P01') {
        return {};
      }
      rethrow;
    }
  }

  void invalidateCache() {
    _coachesCache.invalidate();
    _classTypesCache.invalidate();
    _studentCountsCache.invalidate();
    _coachByIdCache.clear();
    _coachSessionsCache.clear();
  }

  Future<List<CoachSessionModel>> getCoachSessions(
    String coachId, {
    bool force = false,
  }) async {
    if (!force) {
      final cached = cachedCoachSessions(coachId);
      if (cached != null) return cached;
    }

    if (_fetchingSessionCoachIds.contains(coachId)) {
      final cached = cachedCoachSessions(coachId);
      if (cached != null) return cached;
    }

    _fetchingSessionCoachIds.add(coachId);
    try {
      final sessions = await _fetchCoachSessions(coachId);
      unawaited(_persistCoachSessions(coachId, sessions));
      return sessions;
    } finally {
      _fetchingSessionCoachIds.remove(coachId);
    }
  }

  Future<List<CoachSessionModel>> _fetchCoachSessions(String coachId) async {
    try {
      final response = await _supabase
          .from('coach_sessions')
          .select(
            'id, coach_id, branch_id, sessions_per_week, session_type, '
            'session_date, days, time_slots, price_per_session, is_active, '
            'branches(name)',
          )
          .eq('coach_id', coachId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (e) => CoachSessionModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST200' || e.code == 'PGRST205' || e.code == '42P01') {
        try {
          final response = await _supabase
              .from('coach_sessions')
              .select(
                'id, coach_id, branch_id, sessions_per_week, session_type, '
                'session_date, days, time_slots, price_per_session, is_active',
              )
              .eq('coach_id', coachId)
              .eq('is_active', true)
              .order('created_at', ascending: false);

          return (response as List)
              .map(
                (e) => CoachSessionModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();
        } on PostgrestException catch (e2) {
          if (e2.code == 'PGRST205' || e2.code == '42P01') {
            throw Exception(
              'Sessions are not available yet. Please contact support.',
            );
          }
          throw Exception('Failed to load sessions: ${e2.message}');
        }
      }
      if (e.code == 'PGRST205' || e.code == '42P01') {
        throw Exception(
          'Sessions are not available yet. Please contact support.',
        );
      }
      throw Exception('Failed to load sessions: ${e.message}');
    }
  }
}

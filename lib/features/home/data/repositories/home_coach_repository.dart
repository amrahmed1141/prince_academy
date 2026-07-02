import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/core/cache/ttl_cache.dart';
import 'package:prince_academy/features/home/data/models/coaches_model.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

class HomeCoachRepository {
  final SupabaseClient _supabase;

  HomeCoachRepository(this._supabase);

  static const _coachColumns =
      'id, name, specialty, photo_url, is_active, branch_id';

  final TtlCache<List<CoachModel>> _coachesCache = TtlCache();
  final TtlCache<Map<String, String>> _classTypesCache = TtlCache();
  final TtlCache<Map<String, int>> _studentCountsCache = TtlCache();

  /// Fetch all active coaches (cached). Filter by specialty in memory.
  Future<List<CoachModel>> getActiveCoaches({bool force = false}) async {
    if (!force) {
      final cached = _coachesCache.value;
      if (cached != null) return cached;
    }

    final response = await _supabase
        .from('coaches')
        .select(_coachColumns)
        .eq('is_active', true);

    final coaches = (response as List)
        .map((e) => CoachModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    _coachesCache.set(coaches);
    return coaches;
  }

  /// Filter cached coaches by specialty — no extra network call.
  Future<List<CoachModel>> getCoachesBySpecialty(String specialty) async {
    final all = await getActiveCoaches();
    return all
        .where((c) => c.specialty.toLowerCase() == specialty.toLowerCase())
        .toList();
  }

  Future<CoachModel> getCoachById(String coachId) async {
    final response = await _supabase
        .from('coaches')
        .select(_coachColumns)
        .eq('id', coachId)
        .single();

    return CoachModel.fromMap(Map<String, dynamic>.from(response));
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
      final response = await _supabase
          .from('bookings')
          .select('coach_id, user_id')
          .inFilter('coach_id', coachIds);

      final usersByCoach = <String, Set<String>>{};
      for (final row in response as List) {
        final data = Map<String, dynamic>.from(row as Map);
        final coachId = data['coach_id'] as String?;
        final userId = data['user_id'] as String?;
        if (coachId == null ||
            coachId.isEmpty ||
            userId == null ||
            userId.isEmpty) {
          continue;
        }
        usersByCoach.putIfAbsent(coachId, () => {}).add(userId);
      }

      final counts = {
        for (final entry in usersByCoach.entries) entry.key: entry.value.length,
      };

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
  }

  Future<List<CoachSessionModel>> getCoachSessions(String coachId) async {
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
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.code == '42P01') {
        throw Exception(
          'Sessions are not available yet. Please contact support.',
        );
      }
      throw Exception('Failed to load sessions: ${e.message}');
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/features/home/data/models/coaches_model.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

class HomeCoachRepository {
  final SupabaseClient _supabase;

  HomeCoachRepository(this._supabase);

  /// Fetch only active coaches
  Future<List<CoachModel>> getActiveCoaches() async {
    final response = await _supabase
        .from('coaches')
        .select()
        .eq('is_active', true);

    return (response as List)
        .map((e) => CoachModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Fetch active coaches by specialty
  Future<List<CoachModel>> getCoachesBySpecialty(String specialty) async {
    final response = await _supabase
        .from('coaches')
        .select()
        .eq('is_active', true)
        .eq('specialty', specialty);

    return (response as List)
        .map((e) => CoachModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Fetch a coach by their ID
  Future<CoachModel> getCoachById(String coachId) async {
    final response = await _supabase
        .from('coaches')
        .select()
        .eq('id', coachId)
        .single();

    return CoachModel.fromMap(Map<String, dynamic>.from(response));
  }

  /// First active session class type per coach (for list cards).
  Future<Map<String, String>> getPrimaryClassTypesForCoaches(
    List<String> coachIds,
  ) async {
    if (coachIds.isEmpty) return {};

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
      return map;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST205' || e.code == '42P01') {
        return {};
      }
      rethrow;
    }
  }

  /// Fetch sessions of a coach
  Future<List<CoachSessionModel>> getCoachSessions(String coachId) async {
    try {
      final response = await _supabase
          .from('coach_sessions')
          .select()
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
          "Sessions are not available yet. Please contact support.",
        );
      }
      throw Exception('Failed to load sessions: ${e.message}');
    }
  }
}

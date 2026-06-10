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

    return response
        .map((e) => CoachModel.fromMap(e))
        .toList();
  }

  /// Fetch active coaches by specialty
  Future<List<CoachModel>> getCoachesBySpecialty(String specialty) async {
    final response = await _supabase
        .from('coaches')
        .select()
        .eq('is_active', true)
        .eq('specialty', specialty);

    return response
        .map((e) => CoachModel.fromMap(e))
        .toList();
  }

  /// Fetch a coach by their ID
  Future<CoachModel> getCoachById(String coachId) async {
    final response = await _supabase
        .from('coaches')
        .select()
        .eq('id', coachId)
        .single();

    return CoachModel.fromMap(response);
  }

  /// Fetch sessions of a coach
  Future<List<CoachSessionModel>> getCoachSessions(String coachId) async {
    final response = await _supabase
        .from('coach_sessions')
        .select()
        .eq('coach_id', coachId)
        .eq('is_active', true);

    return response
        .map((e) => CoachSessionModel.fromMap(e))
        .toList();
  }
}


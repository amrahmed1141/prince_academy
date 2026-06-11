import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/features/admin/data/models/coach_model.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

class CoachRepository {
  final SupabaseClient _supabase;

  CoachRepository(this._supabase);

  /// Fetches all coaches sorted by creation date descending.
  Future<List<CoachModel>> fetchCoaches() async {
    try {
      final response = await _supabase
          .from('coaches')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => CoachModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load coaches'));
    }
  }

  /// Uploads a photo to the public bucket `coach-photos` using a unique path: coaches/{timestamp}_{filename}
  /// Returns the public URL of the uploaded image.
  Future<String> uploadCoachPhoto(File file, String fileName) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanFileName = fileName.replaceAll(RegExp(r'\s+'), '_');
    final path = 'coaches/${timestamp}_$cleanFileName';

    await _supabase.storage.from('coach-photos').upload(path, file);
    return _supabase.storage.from('coach-photos').getPublicUrl(path);
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
      throw Exception('Unauthorized: Only administrators can perform this action.');
    }
  }

  /// Inserts a new coach row into `public.coaches` after validating admin role.
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
          .select()
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
          .select('*, coaches(name, specialty, photo_url)')
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return _mapSessionList(response);
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load sessions'));
    }
  }

  Future<void> addCoachSession({
    required String coachId,
    required int sessionsPerWeek,
    required String sessionType,
    DateTime? sessionDate,
  }) async {
    await _requireAdmin();

    try {
      await _supabase.from('coach_sessions').insert({
        'coach_id': coachId,
        'sessions_per_week': sessionsPerWeek,
        'session_type': sessionType,
        'session_date': _formatDateForDb(sessionDate),
        'is_active': true,
      });
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'add session'));
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
      return "Database table missing. Please run the coach_sessions setup SQL in Supabase.";
    }
    if (e.code == '42501') {
      return "Permission denied. Check Row Level Security policies for coach_sessions.";
    }
    return 'Failed to $action: ${e.message}';
  }
}

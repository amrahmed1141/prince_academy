import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/features/admin/data/models/coach_model.dart';

class CoachRepository {
  final SupabaseClient _supabase;

  CoachRepository(this._supabase);

  /// Fetches all coaches sorted by creation date descending.
  Future<List<CoachModel>> fetchCoaches() async {
    final response = await _supabase
        .from('coaches')
        .select()
        .order('created_at', ascending: false);
    return response
        .map((e) => CoachModel.fromMap(e))
        .toList();
  }

  /// Uploads a photo to the public bucket `coach-photos` using a unique path: coaches/{timestamp}_{filename}
  /// Returns the public URL of the uploaded image.
  Future<String> uploadCoachPhoto(File file, String fileName) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanFileName = fileName.replaceAll(RegExp(r'\s+'), '_');
    final path = 'coaches/${timestamp}_$cleanFileName';

    // Upload to bucket 'coach-photos'
    await _supabase.storage.from('coach-photos').upload(path, file);

    // Retrieve public URL
    final publicUrl = _supabase.storage.from('coach-photos').getPublicUrl(path);
    return publicUrl;
  }

  /// Inserts a new coach row into `public.coaches` after validating that the currently
  /// authenticated user possesses an 'admin' role in the `public.profiles` table.
  Future<void> addCoach({
    required String name,
    required String specialty,
    String? photoUrl,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user session found.');
    }

    // Verify user role matches 'admin' in profiles table
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
      throw Exception('Unauthorized: Only administrators can add coaches.');
    }

    // Insert new coach
    await _supabase.from('coaches').insert({
      'name': name,
      'specialty': specialty,
      'photo_url': photoUrl,
      'is_active': true,
    });
  }
}

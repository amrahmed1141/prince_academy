import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

class BookingRemoteDs {
  final SupabaseClient _supabase;

  BookingRemoteDs(this._supabase);

  Future<CoachSessionModel?> getActiveSessionForCoach(String coachId) async {
    final response = await _supabase
        .from('coach_sessions')
        .select('*, coaches(name, specialty, photo_url)')
        .eq('coach_id', coachId)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return CoachSessionModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<BookingModel> createBooking(BookingModel booking) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('You must be signed in to book a session.');
    }

    final response = await _supabase
        .from('bookings')
        .insert(booking.toInsertJson(userId: userId))
        .select()
        .single();

    return BookingModel.fromJson(Map<String, dynamic>.from(response));
  }

  Future<String?> getProfileQrCode(String userId) async {
    final profile = await _supabase
        .from('profiles')
        .select('qr_code')
        .eq('id', userId)
        .maybeSingle();

    if (profile == null) return null;
    return profile['qr_code'] as String?;
  }

  Future<List<BookingHistoryModel>> getUserBookings() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('You must be signed in to view booking history.');
    }

    final response = await _supabase
        .from('user_booking_history')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (json) => BookingHistoryModel.fromJson(
            Map<String, dynamic>.from(json),
          ),
        )
        .toList();
  }

  Future<String> ensureUserQrCode(String userId) async {
    final profile = await _supabase
        .from('profiles')
        .select('qr_code')
        .eq('id', userId)
        .single();

    final existing = profile['qr_code'] as String?;
    if (existing != null && existing.isNotEmpty) return existing;

    final newCode = 'PA-${const Uuid().v4()}';
    await _supabase.from('profiles').update({'qr_code': newCode}).eq('id', userId);
    return newCode;
  }
}

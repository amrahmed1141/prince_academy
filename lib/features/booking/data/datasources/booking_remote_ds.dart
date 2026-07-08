import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:prince_academy/core/helpers/session_schedule_helper.dart';
import 'package:prince_academy/features/admin/data/models/pending_payment_model.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';
import 'package:prince_academy/features/sessions/data/models/calendar_session_model.dart';

class BookingRemoteDs {
  final SupabaseClient _supabase;

  BookingRemoteDs(this._supabase);

  Future<CoachSessionModel?> getActiveSessionForCoach(String coachId) async {
    final response = await _supabase
        .from('coach_sessions')
        .select('*, coaches(name, specialty, photo_url), branches(name)')
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

  // ADDED: RPC create_booking_with_schedule
  Future<BookingModel> createBookingWithSchedule({
    required String coachId,
    required String branchId,
    required List<String> days,
    required String time,
    required DateTime startDate,
    required double price,
    required String method,
    String? paymentReference,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('You must be signed in to book a session.');
    }

    try {
      final response = await _supabase.rpc(
        'create_booking_with_schedule',
        params: {
          'p_user_id': userId,
          'p_coach_id': coachId,
          'p_branch_id': branchId,
          'p_days': days,
          'p_time': time,
          'p_start_date': SessionScheduleHelper.formatDateForDb(startDate),
          'p_price': price,
          'p_method': method,
          if (paymentReference != null) 'p_payment_reference': paymentReference,
        },
      );

      if (response is Map) {
        return BookingModel.fromJson(Map<String, dynamic>.from(response));
      }
      if (response is List && response.isNotEmpty) {
        return BookingModel.fromJson(
          Map<String, dynamic>.from(response.first as Map),
        );
      }

      throw Exception('Unexpected response from booking creation.');
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'create booking'));
    }
  }

  // ADDED: upload InstaPay screenshot
  Future<String> uploadPaymentScreenshot({
    required String bookingId,
    required File file,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('You must be signed in.');
    }

    final ext = _fileExtension(file.path);
    final path = 'payments/$userId/$bookingId-${const Uuid().v4()}.$ext';

    await _supabase.storage.from('payment-screenshots').upload(
          path,
          file,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _mimeForExt(ext),
          ),
        );

    final publicUrl =
        _supabase.storage.from('payment-screenshots').getPublicUrl(path);

    await _supabase.from('bookings').update({
      'payment_screenshot_url': publicUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', bookingId);

    return publicUrl;
  }

  // ADDED: mark InstaPay as awaiting verification
  Future<void> confirmInstaPayPayment(String bookingId) async {
    await _supabase.from('bookings').update({
      'payment_status': 'awaiting_verification',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', bookingId);
  }

  // ADDED: admin verify cash/instapay payment
  Future<void> verifyPayment({
    required String bookingId,
    required String adminId,
    String? notes,
  }) async {
    try {
      await _supabase.rpc(
        'verify_payment',
        params: {
          'p_booking_id': bookingId,
          'p_admin_id': adminId,
          'p_notes': notes,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'verify payment'));
    }
  }

  Future<List<PendingPaymentModel>> getPendingPayments() async {
    try {
      final response = await _supabase
          .from('pending_payments')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (json) => PendingPaymentModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load pending payments'));
    }
  }

  Future<List<CalendarSessionModel>> getUserCalendarSessions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    try {
      final response = await _supabase
          .from('user_calendar_sessions')
          .select()
          .eq('user_id', userId);

      return (response as List)
          .map(
            (json) => CalendarSessionModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'load calendar sessions'));
    }
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

  // ADDED: active coach IDs for duplicate booking prevention
  Future<List<String>> getUserActiveCoachIds() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('You must be signed in.');
    }

    final response = await _supabase
        .from('bookings')
        .select('coach_id')
        .eq('user_id', userId)
        .inFilter('status', ['pending_payment', 'active']);

    return (response as List)
        .map((row) => row['coach_id'] as String)
        .toList();
  }

  Future<bool> hasActiveBookingWithCoach(String coachId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('You must be signed in.');
    }

    final response = await _supabase
        .from('bookings')
        .select('id')
        .eq('user_id', userId)
        .eq('coach_id', coachId)
        .inFilter('status', ['pending_payment', 'active'])
        .limit(1)
        .maybeSingle();

    return response != null;
  }

  // ADDED: booking id + coach name for duplicate dialog
  Future<({String bookingId, String? coachName})?> getActiveBookingForCoach(
    String coachId,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('bookings')
        .select('id, coaches(name)')
        .eq('user_id', userId)
        .eq('coach_id', coachId)
        .inFilter('status', ['pending_payment', 'active'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    final coaches = response['coaches'];
    final coachName = coaches is Map ? coaches['name'] as String? : null;

    return (
      bookingId: response['id'] as String,
      coachName: coachName,
    );
  }

  Future<bool> hasActiveBookingWithSession({
    required String coachId,
    required List<String> selectedDays,
    required String selectedTime,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('You must be signed in.');
    }

    final response = await _supabase
        .from('bookings')
        .select('id, selected_days, selected_time')
        .eq('user_id', userId)
        .eq('coach_id', coachId)
        .inFilter('status', ['pending_payment', 'active']);

    for (final row in response as List) {
      final data = Map<String, dynamic>.from(row as Map);
      final days = _parseStringList(data['selected_days']);
      final time = data['selected_time'] as String?;
      if (time == selectedTime &&
          days.length == selectedDays.length &&
          days.toSet().containsAll(selectedDays)) {
        return true;
      }
    }

    return false;
  }

  List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  String _fileExtension(String filePath) {
    final fileName = filePath.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == fileName.length - 1) {
      return 'jpg';
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  String _mimeForExt(String ext) {
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }

  // ── User booking management ──────────────────────────────────

  Future<void> cancelBooking(String bookingId) async {
    try {
      await _supabase.rpc('cancel_booking', params: {
        'p_booking_id': bookingId,
      });
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'cancel booking'));
    }
  }

  Future<void> updateBookingDays({
    required String bookingId,
    required List<String> days,
  }) async {
    try {
      await _supabase.rpc('update_booking_days', params: {
        'p_booking_id': bookingId,
        'p_days': days,
      });
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'update booking days'));
    }
  }

  Future<void> rescheduleBooking({
    required String bookingId,
    required DateTime startDate,
  }) async {
    try {
      await _supabase.rpc('reschedule_booking', params: {
        'p_booking_id': bookingId,
        'p_start_date': SessionScheduleHelper.formatDateForDb(startDate),
      });
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'reschedule booking'));
    }
  }

  String _mapPostgrestError(PostgrestException e, String action) {
    if (e.code == '42501') {
      return 'Permission denied. Check booking RLS policies in Supabase.';
    }
    if (e.message.contains('valid_payment_status')) {
      return 'Booking payment status is out of date in the database. '
          'Ask an admin to run supabase/fix_booking_payment_status.sql '
          'in Supabase SQL Editor, then try again.';
    }
    return 'Failed to $action: ${e.message}';
  }
}

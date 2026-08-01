import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/features/admin/data/models/session_detail_model.dart';
import 'package:prince_academy/features/booking/data/models/booking_freeze_model.dart';

/// Remote I/O for session freeze request / apply / review flows.
class BookingFreezeRepository {
  BookingFreezeRepository(this._client);

  final SupabaseClient _client;

  Future<BookingFreezeContext?> getFreezeContext(String bookingId) async {
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

  Future<List<SessionDetail>> getBookingSessions(String bookingId) async {
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
    } on PostgrestException catch (e) {
      throw Exception(_friendly(e, approve ? 'approve freeze' : 'reject freeze'));
    }
  }

  Future<List<PendingFreezeRequest>> getPendingRequests() async {
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

  Future<List<ActiveBookingFreeze>> getActiveFreezes() async {
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

  String _friendly(PostgrestException e, String action) {
    final msg = e.message.trim();
    if (msg.isEmpty) return 'Could not $action. Please try again.';
    // Prefer short DB raise messages over raw Postgrest noise.
    if (msg.length < 160 && !msg.contains('PGRST')) return msg;
    return 'Could not $action. Please try again.';
  }
}

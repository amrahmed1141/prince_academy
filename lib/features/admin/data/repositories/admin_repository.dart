import 'dart:async';

import 'package:prince_academy/core/base/stream_repository.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/features/admin/data/models/pending_payment_model.dart';
import 'package:prince_academy/features/admin/data/repositories/admin_dashboard_repository.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/data/repositories/finance_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRepository extends StreamRepository<List<PendingPaymentModel>> {
  AdminRepository(this._supabase) : super(cacheTtl: const Duration(seconds: 30));

  final SupabaseClient _supabase;
  RealtimeChannel? _bookingsChannel;

  void ensureRealtimeSubscription() {
    if (_bookingsChannel != null) return;

    _bookingsChannel = _supabase
        .channel('admin-pending-payments')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (_) => unawaited(refreshInBackground()),
        )
        .subscribe();
  }

  void disposeRealtime() {
    _bookingsChannel?.unsubscribe();
    _bookingsChannel = null;
    dispose();
  }

  @override
  Future<List<PendingPaymentModel>> fetchFromApi() async {
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
  }

  Future<List<PendingPaymentModel>> getPendingPayments({bool force = false}) {
    if (!force && hasValidCache && cachedValue != null) {
      return Future.value(cachedValue!);
    }
    return refresh();
  }

  Future<void> verifyPayment(String bookingId, {String? notes}) async {
    final adminId = _supabase.auth.currentUser?.id;
    if (adminId == null) {
      throw Exception('Admin session expired. Please sign in again.');
    }

    final userId = await _lookupBookingUserId(bookingId);

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

    await _recordConfirmedPayment(bookingId);
    await _invalidateAfterPaymentMutation(userId);
  }

  Future<void> rejectPayment(String bookingId, String reason) async {
    final adminId = _supabase.auth.currentUser?.id;
    if (adminId == null) {
      throw Exception('Admin session expired. Please sign in again.');
    }

    final userId = await _lookupBookingUserId(bookingId);

    try {
      await _supabase.rpc(
        'reject_payment',
        params: {
          'p_booking_id': bookingId,
          'p_admin_id': adminId,
          'p_reason': reason,
        },
      );
    } on PostgrestException catch (e) {
      throw Exception(_mapPostgrestError(e, 'reject payment'));
    }

    await _invalidateAfterPaymentMutation(userId);
  }

  Future<String?> _lookupBookingUserId(String bookingId) async {
    final booking = await _supabase
        .from('bookings')
        .select('user_id')
        .eq('id', bookingId)
        .maybeSingle();
    if (booking == null) return null;
    return Map<String, dynamic>.from(booking as Map)['user_id'] as String?;
  }

  Future<void> _invalidateAfterPaymentMutation(String? userId) async {
    invalidateStreamCache();
    await refresh();

    if (sl.isRegistered<CoachRepository>()) {
      final coachRepo = sl<CoachRepository>();
      coachRepo.invalidateCaches();
      if (userId != null && userId.isNotEmpty) {
        coachRepo.invalidateUserScanProfileCache(userId);
        unawaited(coachRepo.getUserScanProfiles(userId, force: true));
      }
    }

    if (sl.isRegistered<AdminDashboardRepository>()) {
      final dashboardRepo = sl<AdminDashboardRepository>();
      dashboardRepo.invalidateStreamCache();
      unawaited(dashboardRepo.refresh());
    }

    if (sl.isRegistered<FinanceRepository>()) {
      final financeRepo = sl<FinanceRepository>();
      financeRepo.invalidateStreamCache();
      unawaited(financeRepo.refresh());
    }
  }

  Future<void> _recordConfirmedPayment(String bookingId) async {
    final existing = await _supabase
        .from('payments')
        .select('id')
        .eq('booking_id', bookingId)
        .eq('status', 'confirmed')
        .limit(1);
    if ((existing as List).isNotEmpty) return;

    final booking = await _supabase
        .from('bookings')
        .select('id, user_id, total_price, payment_method')
        .eq('id', bookingId)
        .maybeSingle();

    if (booking == null) return;
    final data = Map<String, dynamic>.from(booking as Map);
    final amount = (data['total_price'] as num?)?.toDouble() ?? 0;
    if (amount <= 0) return;

    await _supabase.from('payments').insert({
      'user_id': data['user_id'],
      'booking_id': bookingId,
      'amount': amount,
      'payment_method': data['payment_method'] ?? 'cash',
      'status': 'confirmed',
      'payment_date': DateTime.now().toIso8601String().split('T').first,
    });
  }

  String _mapPostgrestError(PostgrestException error, String action) {
    final message = error.message.trim();
    if (message.isNotEmpty) {
      return 'Failed to $action: $message';
    }
    return 'Failed to $action. Please try again.';
  }
}

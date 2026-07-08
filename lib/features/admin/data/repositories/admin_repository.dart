import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/core/base/stream_repository.dart';
import 'package:prince_academy/features/admin/data/models/pending_payment_model.dart';

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
          callback: (_) => unawaited(refresh()),
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

  // ADDED: direct verify_payment RPC — no local SQL file checks
  Future<void> verifyPayment(String bookingId, {String? notes}) async {
    final adminId = _supabase.auth.currentUser?.id;
    if (adminId == null) {
      throw Exception('Admin session expired. Please sign in again.');
    }

    await _supabase.rpc(
      'verify_payment',
      params: {
        'p_booking_id': bookingId,
        'p_admin_id': adminId,
        'p_notes': notes,
      },
    );

    await _recordConfirmedPayment(bookingId);

    invalidateStreamCache();
    await refresh();
  }

  // ADDED: direct reject_payment RPC
  Future<void> rejectPayment(String bookingId, String reason) async {
    final adminId = _supabase.auth.currentUser?.id;
    if (adminId == null) {
      throw Exception('Admin session expired. Please sign in again.');
    }

    await _supabase.rpc(
      'reject_payment',
      params: {
        'p_booking_id': bookingId,
        'p_admin_id': adminId,
        'p_reason': reason,
      },
    );

    invalidateStreamCache();
    await refresh();
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
}

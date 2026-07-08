import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/features/admin/data/models/pending_payment_model.dart';
import 'package:prince_academy/features/booking/data/datasources/booking_remote_ds.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';
import 'package:prince_academy/features/sessions/data/models/calendar_session_model.dart';

/// Direct Supabase access — no cache/coordinator layer.
class BookingRepository {
  BookingRepository(this._remoteDs);

  final BookingRemoteDs _remoteDs;
  final SupabaseClient _supabase = Supabase.instance.client;

  RealtimeChannel? _bookingsChannel;
  String? _subscribedUserId;
  StreamController<List<BookingHistoryModel>>? _bookingsController;

  List<BookingHistoryModel>? _bookingsCache;
  DateTime? _bookingsCachedAt;
  Future<List<BookingHistoryModel>>? _bookingsInFlight;

  static const Duration _bookingsCacheTtl = Duration(minutes: 2);

  Stream<List<BookingHistoryModel>> get bookingsStream {
    _bookingsController ??= StreamController<List<BookingHistoryModel>>.broadcast();
    _ensureBookingsRealtime();
    return _bookingsController!.stream;
  }

  List<BookingHistoryModel>? get cachedBookings {
    if (_bookingsCache == null || _bookingsCachedAt == null) return null;
    final isValid = DateTime.now().difference(_bookingsCachedAt!) < _bookingsCacheTtl;
    return isValid ? _bookingsCache : null;
  }

  Future<CoachSessionModel?> getActiveSession(String coachId) {
    return _remoteDs.getActiveSessionForCoach(coachId);
  }

  Future<List<BookingHistoryModel>> getUserBookings({bool force = false}) {
    _ensureBookingsRealtime();

    final cached = cachedBookings;
    if (!force && cached != null) return Future.value(cached);
    if (!force && _bookingsInFlight != null) return _bookingsInFlight!;

    final future = _wrap(_remoteDs.getUserBookings()).then((bookings) {
      _setBookingsCache(bookings);
      _bookingsController?.add(bookings);
      return bookings;
    }).whenComplete(() {
      _bookingsInFlight = null;
    });

    _bookingsInFlight = future;
    return future;
  }

  Future<List<String>> getUserActiveCoachIds() {
    return _wrap(_remoteDs.getUserActiveCoachIds());
  }

  Future<List<PendingPaymentModel>> getPendingPayments() {
    return _wrap(_remoteDs.getPendingPayments());
  }

  Future<List<CalendarSessionModel>> getUserCalendarSessions() {
    return _wrap(_remoteDs.getUserCalendarSessions());
  }

  Future<BookingModel> submitBooking(BookingModel booking) {
    return _wrap(_remoteDs.createBooking(booking));
  }

  Future<BookingModel> createBookingWithSchedule({
    required String coachId,
    required String branchId,
    required List<String> days,
    required String time,
    required DateTime startDate,
    required double price,
    required String method,
    String? paymentReference,
  }) {
    return _wrap(
      _remoteDs.createBookingWithSchedule(
        coachId: coachId,
        branchId: branchId,
        days: days,
        time: time,
        startDate: startDate,
        price: price,
        method: method,
        paymentReference: paymentReference,
      ),
    );
  }

  Future<String> uploadPaymentScreenshot({
    required String bookingId,
    required File file,
  }) {
    return _wrap(_remoteDs.uploadPaymentScreenshot(bookingId: bookingId, file: file));
  }

  Future<void> confirmInstaPayPayment(String bookingId) {
    return _wrap(_remoteDs.confirmInstaPayPayment(bookingId));
  }

  Future<void> verifyPayment({
    required String bookingId,
    required String adminId,
    String? notes,
  }) {
    return _wrap(
      _remoteDs.verifyPayment(
        bookingId: bookingId,
        adminId: adminId,
        notes: notes,
      ),
    );
  }

  Future<String?> getProfileQrCode(String userId) {
    return _remoteDs.getProfileQrCode(userId);
  }

  Future<String> ensureUserQrCode(String userId) {
    return _remoteDs.ensureUserQrCode(userId);
  }

  Future<bool> hasActiveBookingWithCoach(String coachId) {
    return _wrap(_remoteDs.hasActiveBookingWithCoach(coachId));
  }

  Future<({String bookingId, String? coachName})?> getActiveBookingForCoach(
    String coachId,
  ) {
    return _remoteDs.getActiveBookingForCoach(coachId);
  }

  Future<bool> hasActiveBookingWithSession({
    required String coachId,
    required List<String> selectedDays,
    required String selectedTime,
  }) {
    return _wrap(
      _remoteDs.hasActiveBookingWithSession(
        coachId: coachId,
        selectedDays: selectedDays,
        selectedTime: selectedTime,
      ),
    );
  }

  // ── User booking management ──────────────────────────────────

  Future<void> cancelBooking(String bookingId) {
    return _wrap(_remoteDs.cancelBooking(bookingId));
  }

  Future<void> updateBookingDays({
    required String bookingId,
    required List<String> days,
  }) {
    return _wrap(_remoteDs.updateBookingDays(bookingId: bookingId, days: days));
  }

  Future<void> rescheduleBooking({
    required String bookingId,
    required DateTime startDate,
  }) {
    return _wrap(
      _remoteDs.rescheduleBooking(bookingId: bookingId, startDate: startDate),
    );
  }

  Future<T> _wrap<T>(Future<T> future) async {
    try {
      return await future.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw Exception('Request timed out. Check your connection and try again.');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _setBookingsCache(List<BookingHistoryModel> bookings) {
    _bookingsCache = bookings;
    _bookingsCachedAt = DateTime.now();
  }

  void _ensureBookingsRealtime() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    if (_subscribedUserId == userId && _bookingsChannel != null) return;

    _bookingsChannel?.unsubscribe();
    _subscribedUserId = userId;
    _bookingsChannel = _supabase
        .channel('user-bookings-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => unawaited(getUserBookings(force: true)),
        )
        .subscribe();
  }
}

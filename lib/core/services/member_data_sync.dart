import 'dart:async';

import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/features/booking/data/repositories/booking_repository.dart';
import 'package:prince_academy/features/sessions/data/repositories/sessions_repository.dart';

/// Force-refreshes member booking + sessions caches after mutations.
///
/// Home / Sessions / Booking History pick this up via repository streams.
abstract final class MemberDataSync {
  static Future<void> afterBookingMutation() async {
    final bookingRepo = sl<BookingRepository>();
    final sessionsRepo = sl<SessionsRepository>();

    sessionsRepo.invalidateCache();

    await Future.wait([
      bookingRepo.getUserBookings(force: true),
      sessionsRepo.refreshSessions(force: true),
    ]);
  }

  static void afterBookingMutationUnawaited() {
    unawaited(afterBookingMutation().catchError((Object _) {}));
  }
}

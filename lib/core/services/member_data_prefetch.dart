import 'dart:async';

import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/services/user_qr_service.dart';
import 'package:prince_academy/features/admin/data/repositories/branch_repository.dart';
import 'package:prince_academy/features/booking/data/repositories/booking_repository.dart';
import 'package:prince_academy/features/home/data/repositories/home_coach_repository.dart';
import 'package:prince_academy/features/sessions/data/repositories/sessions_repository.dart';

/// Warms member tab data in parallel after shell mount (non-blocking).
abstract final class MemberDataPrefetch {
  static Future<void> _safe(Future<void> Function() run) async {
    try {
      await run();
    } catch (_) {}
  }

  static Future<void> warm() {
    return Future.wait([
      _safe(() async {
        await sl<SessionsRepository>().refreshSessions(force: true);
      }),
      _safe(() async {
        await sl<BookingRepository>().getUserBookings(force: true);
      }),
      _safe(() async {
        await sl<HomeCoachRepository>().getActiveCoaches(force: true);
      }),
      _safe(() async {
        await sl<BranchRepository>().getAllBranches(force: true);
      }),
      _safe(() async {
        await sl<UserQrService>().refresh(silent: true);
      }),
    ]);
  }

  static void warmUnawaited() {
    unawaited(warm());
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/services/admin_tab_controller.dart';
import 'package:prince_academy/features/admin/data/admin_search_index.dart';
import 'package:prince_academy/features/admin/presentation/bloc/finance_bloc.dart';
import 'package:prince_academy/features/admin/presentation/pages/admin_profile.dart';
import 'package:prince_academy/features/admin/presentation/pages/all_finance_transactions_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/all_freeze_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/all_schedules_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/pending_payments_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/qr_scanner_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/today_attendance_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/today_sessions_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/edit_coach_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/edit_session_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/tracking/all_coaches_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/tracking/all_members_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/tracking/user_tracking_detail_page.dart';
import 'package:prince_academy/features/admin/data/models/active_user_model.dart';
import 'package:prince_academy/features/admin/data/models/coach_model.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';
import 'package:prince_academy/features/notifications/presentation/pages/notifications_page.dart';

/// Closes admin search, then opens a tab or pushed admin page.
Future<void> openAdminSearchDestination(
  BuildContext context,
  AdminSearchDestinationId id,
) async {
  final navigator = Navigator.of(context);
  final tabs = sl<AdminTabController>();

  navigator.pop();

  switch (id) {
    case AdminSearchDestinationId.dashboard:
      tabs.goHome();
    case AdminSearchDestinationId.manageAcademy:
    case AdminSearchDestinationId.addCoach:
    case AdminSearchDestinationId.addSession:
      tabs.goAddInfo();
    case AdminSearchDestinationId.tracking:
      tabs.goTracking();
    case AdminSearchDestinationId.finance:
      tabs.goFinance();
    case AdminSearchDestinationId.allMembers:
      await navigator.push<void>(
        MaterialPageRoute(builder: (_) => const AllMembersPage()),
      );
    case AdminSearchDestinationId.allCoaches:
      await navigator.push<void>(
        MaterialPageRoute(builder: (_) => const AllCoachesPage()),
      );
    case AdminSearchDestinationId.pendingPayments:
      await navigator.push<void>(
        MaterialPageRoute(builder: (_) => const PendingPaymentsPage()),
      );
    case AdminSearchDestinationId.todaySessions:
      await navigator.push<void>(
        MaterialPageRoute(builder: (_) => const TodaySessionsPage()),
      );
    case AdminSearchDestinationId.todayAttendance:
      await navigator.push<void>(
        MaterialPageRoute(builder: (_) => const TodayAttendancePage()),
      );
    case AdminSearchDestinationId.allSchedules:
      await navigator.push<void>(
        MaterialPageRoute(builder: (_) => const AllSchedulesPage()),
      );
    case AdminSearchDestinationId.freezeRequests:
      await navigator.push<void>(
        MaterialPageRoute(builder: (_) => const AllFreezePage()),
      );
    case AdminSearchDestinationId.scanQr:
      await navigator.push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const QrScannerPage(),
        ),
      );
    case AdminSearchDestinationId.notifications:
      await navigator.push<void>(
        MaterialPageRoute(builder: (_) => const NotificationsPage()),
      );
    case AdminSearchDestinationId.profile:
      await navigator.push<void>(
        MaterialPageRoute(builder: (_) => const AdminProfilePage()),
      );
    case AdminSearchDestinationId.transactions:
      await navigator.push<void>(
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<FinanceCubit>()..load(),
            child: const AllFinanceTransactionsPage(),
          ),
        ),
      );
  }
}

Future<void> openAdminSearchCoach(BuildContext context, CoachModel coach) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => EditCoachPage(coach: coach)),
  );
}

Future<void> openAdminSearchMember(BuildContext context, ActiveUser member) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => UserTrackingDetailPage(
        userId: member.userId,
        initialName: member.fullName,
        phone: member.phone,
      ),
    ),
  );
}

Future<void> openAdminSearchSession(
  BuildContext context,
  CoachSessionModel session,
) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => EditSessionPage(session: session)),
  );
}

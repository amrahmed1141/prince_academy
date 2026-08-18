import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/services/main_tab_controller.dart';
import 'package:prince_academy/features/auth/data/models/app_user.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_state.dart';
import 'package:prince_academy/features/home/presentation/pages/coaches_page.dart';
import 'package:prince_academy/features/notifications/presentation/pages/notifications_page.dart';
import 'package:prince_academy/features/profile/presentation/pages/profile/edit_profile_page.dart';
import 'package:prince_academy/features/profile/presentation/pages/profile/payments_page.dart';
import 'package:prince_academy/features/booking/presentation/pages/my_freeze_requests_page.dart';
import 'package:prince_academy/features/search/data/member_app_search_index.dart';

/// Routes a global-search destination hit and closes the search overlay first.
Future<void> openMemberSearchDestination(
  BuildContext context,
  MemberSearchDestinationId id,
) async {
  final navigator = Navigator.of(context);
  final tabs = sl<MainTabController>();

  UserModel? editUser;
  if (id == MemberSearchDestinationId.editProfile) {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthed) editUser = auth.user;
  }

  navigator.pop();

  switch (id) {
    case MemberSearchDestinationId.home:
      tabs.goHome();
    case MemberSearchDestinationId.bookingHistory:
      tabs.goBooking();
    case MemberSearchDestinationId.sessions:
      tabs.goSessions();
    case MemberSearchDestinationId.profile:
      tabs.select(MainTabController.profile);
    case MemberSearchDestinationId.notifications:
      await navigator.push<void>(
        MaterialPageRoute(builder: (_) => const NotificationsPage()),
      );
    case MemberSearchDestinationId.editProfile:
      if (editUser != null) {
        await navigator.push<void>(
          MaterialPageRoute(
            builder: (_) => EditProfilePage(user: editUser!),
          ),
        );
      }
    case MemberSearchDestinationId.payments:
      await navigator.push<void>(
        MaterialPageRoute(builder: (_) => const PaymentsPage()),
      );
    case MemberSearchDestinationId.freezeRequests:
      await navigator.push<void>(
        MaterialPageRoute(builder: (_) => const MyFreezeRequestsPage()),
      );
    case MemberSearchDestinationId.coaches:
      await navigator.push<void>(
        MaterialPageRoute(builder: (_) => const CoachesPage()),
      );
    case MemberSearchDestinationId.bookCoach:
      tabs.goHome();
      await navigator.push<void>(
        MaterialPageRoute(builder: (_) => const CoachesPage()),
      );
  }
}

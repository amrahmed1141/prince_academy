import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:prince_academy/features/auth/presentation/bloc/auth_event.dart';
import 'package:prince_academy/features/auth/presentation/bloc/auth_state.dart';
import 'package:prince_academy/features/auth/presentation/pages/authentication/auth_page.dart';
import 'package:prince_academy/app/bottom_navigation/navigation_bottom.dart';
import 'package:prince_academy/app/splash/splash_screen.dart';
import 'package:prince_academy/core/services/firebase_messaging_service.dart';
import 'package:prince_academy/core/theme/theme.dart';
import 'package:prince_academy/features/admin/presentation/pages/admin_home.dart';
import 'package:prince_academy/features/notifications/data/repositories/notification_repository.dart';
import 'package:prince_academy/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:prince_academy/features/notifications/presentation/bloc/notification_event.dart';
import 'package:prince_academy/features/notifications/presentation/pages/notifications_page.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../core/di/injection.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class PrinceAcademyApp extends StatelessWidget {
  const PrinceAcademyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(const AuthStarted()),
        ),
      ],
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        title: 'Prince Academy',
        theme: EAppTheme.lightTheme,
        themeMode: ThemeMode.light,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthInitial) {
              return const SplashScreen();
            } else if (state is AuthAuthed) {
              return AuthenticatedShell(
                isAdmin: state.user.role == 'admin',
              );
            } else {
              // Includes AuthNoSession and AuthError
              return const AuthPage();
            }
          },
        ),
      ),
    );
  }
}

/// Provides [NotificationBloc], binds FCM callbacks, and hosts member/admin UI.
///
/// Always enter admin/member UI through this shell — never push
/// [AdminHomeScreen] / [NavigationBottom] bare, or [NotificationBloc] is missing.
class AuthenticatedShell extends StatefulWidget {
  const AuthenticatedShell({super.key, required this.isAdmin});

  final bool isAdmin;

  @override
  State<AuthenticatedShell> createState() => _AuthenticatedShellState();
}

class _AuthenticatedShellState extends State<AuthenticatedShell> {
  late final NotificationBloc _notificationBloc;

  @override
  void initState() {
    super.initState();
    _notificationBloc = sl<NotificationBloc>()
      ..add(const NotificationsStarted());

    FirebaseMessagingService.onToken = (token) {
      return sl<NotificationRepository>().saveFcmToken(token);
    };
    FirebaseMessagingService.onForegroundMessage = _showForegroundSnackBar;
    FirebaseMessagingService.onNotificationOpened = _onNotificationOpened;

    // Token may already exist from cold start before auth — sync now.
    FirebaseMessagingService.refreshAndSyncToken();
  }

  @override
  void dispose() {
    FirebaseMessagingService.onToken = null;
    FirebaseMessagingService.onForegroundMessage = null;
    FirebaseMessagingService.onNotificationOpened = null;
    _notificationBloc.close();
    super.dispose();
  }

  void _showForegroundSnackBar(RemoteMessage message) {
    final title = message.notification?.title ?? 'Prince Academy';
    final body = message.notification?.body;
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          body == null || body.isEmpty ? title : '$title — $body',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            rootNavigatorKey.currentState?.push(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider.value(
                  value: _notificationBloc,
                  child: const NotificationsPage(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onNotificationOpened(RemoteMessage message) {
    // Prefer in-app feed; deep-links from message.data can be added later.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => BlocProvider.value(
            value: _notificationBloc,
            child: const NotificationsPage(),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationBloc>.value(
      value: _notificationBloc,
      child: widget.isAdmin
          ? const AdminHomeScreen()
          : const NavigationBottom(),
    );
  }
}

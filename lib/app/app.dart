import 'dart:async';

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
import 'package:prince_academy/features/notifications/data/models/app_notification.dart';
import 'package:prince_academy/features/notifications/data/repositories/notification_repository.dart';
import 'package:prince_academy/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:prince_academy/features/notifications/presentation/bloc/notification_event.dart';
import 'package:prince_academy/features/notifications/presentation/bloc/notification_state.dart';
import 'package:prince_academy/features/notifications/presentation/helpers/notification_navigation.dart';
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
  final Set<String> _seenNotificationIds = <String>{};
  bool _notificationBaselineReady = false;
  Timer? _tokenRetryTimer;

  @override
  void initState() {
    super.initState();
    _notificationBloc = sl<NotificationBloc>()
      ..add(const NotificationsStarted());

    FirebaseMessagingService.onToken = (token) {
      return sl<NotificationRepository>().saveFcmToken(token);
    };
    // Fallback only — Android foreground banners are shown by the messaging service.
    FirebaseMessagingService.onForegroundMessage = _showForegroundSnackBar;
    FirebaseMessagingService.onNotificationOpened = _onNotificationOpened;
    FirebaseMessagingService.onNotificationDataOpened = _onNotificationDataOpen;

    // Token may already exist from cold start before auth — sync now + retry.
    unawaited(FirebaseMessagingService.refreshAndSyncToken());
    _tokenRetryTimer = Timer(const Duration(seconds: 4), () {
      unawaited(FirebaseMessagingService.refreshAndSyncToken());
    });
  }

  @override
  void dispose() {
    _tokenRetryTimer?.cancel();
    FirebaseMessagingService.onToken = null;
    FirebaseMessagingService.onForegroundMessage = null;
    FirebaseMessagingService.onNotificationOpened = null;
    FirebaseMessagingService.onNotificationDataOpened = null;
    _notificationBloc.close();
    super.dispose();
  }

  void _onNotificationsState(NotificationState state) {
    if (state is! NotificationLoaded) return;

    final ids = state.notifications.map((n) => n.id).toSet();
    if (!_notificationBaselineReady) {
      _seenNotificationIds
        ..clear()
        ..addAll(ids);
      _notificationBaselineReady = true;
      return;
    }

    final fresh = state.notifications
        .where((n) => !_seenNotificationIds.contains(n.id))
        .toList();
    if (fresh.isEmpty) {
      _seenNotificationIds.addAll(ids);
      return;
    }

    _seenNotificationIds.addAll(ids);
    // Newest first in feed — banner the newest insert.
    unawaited(_showRealtimeBanner(fresh.first));
  }

  Future<void> _showRealtimeBanner(AppNotification notification) async {
    final data = <String, dynamic>{
      ...?notification.data,
      'type': notification.type,
      'notification_id': notification.id,
    };
    final posted = await FirebaseMessagingService.showLocalBanner(
      title: notification.title,
      body: notification.body,
      data: data,
      id: notification.id.hashCode,
    );
    if (!posted) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            (notification.body == null || notification.body!.isEmpty)
                ? notification.title
                : '${notification.title} — ${notification.body}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => _pushForData(data),
          ),
        ),
      );
    }
  }

  void _showForegroundSnackBar(RemoteMessage message) {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Prince Academy';
    final body = message.notification?.body ?? message.data['body']?.toString();
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
          onPressed: () => _pushForMessage(message),
        ),
      ),
    );
  }

  void _onNotificationOpened(RemoteMessage message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pushForMessage(message);
    });
  }

  void _onNotificationDataOpen(Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pushForData(data);
    });
  }

  void _pushForMessage(RemoteMessage message) {
    _pushForData(message.data);
  }

  void _pushForData(Map<String, dynamic> data) {
    final nav = rootNavigatorKey.currentState;
    if (nav == null) return;

    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationNavigation.destination(
          isAdmin: widget.isAdmin,
          data: data,
          fallback: _notificationsPage(),
        ),
      ),
    );
  }

  Widget _notificationsPage() {
    return BlocProvider.value(
      value: _notificationBloc,
      child: const NotificationsPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationBloc>.value(
      value: _notificationBloc,
      child: BlocListener<NotificationBloc, NotificationState>(
        listenWhen: (prev, next) =>
            next is NotificationLoaded &&
            (prev is! NotificationLoaded ||
                prev.notifications != next.notifications),
        listener: (context, state) => _onNotificationsState(state),
        child:
            widget.isAdmin ? const AdminHomeScreen() : const NavigationBottom(),
      ),
    );
  }
}

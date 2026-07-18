import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Top-level background handler. Must be a top-level / static function and
/// registered before [Firebase.initializeApp] / [runApp].
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  developer.log(
    'Background/terminated push: id=${message.messageId} '
    'title=${message.notification?.title}',
    name: 'FirebaseMessagingService',
  );
}

/// Production Firebase Cloud Messaging facade for Android + iOS.
///
/// Responsibilities:
/// - Request permission (iOS / Android 13+)
/// - Cache / refresh FCM token
/// - Persist token via [onToken] (wired to Supabase after login)
/// - Handle foreground, background, and terminated notification opens
///
/// iOS notes (ready once Apple Developer + APNs key are configured):
/// - Runner.entitlements already has `aps-environment`
/// - Info.plist already has `remote-notification` background mode
/// - Upload an APNs Auth Key in Firebase Console → Project settings → Cloud Messaging
class FirebaseMessagingService {
  FirebaseMessagingService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Latest known FCM token (null until fetched or if APNs is not ready on iOS).
  static String? currentToken;

  /// Called whenever a usable FCM token is obtained or refreshed.
  static Future<void> Function(String token)? onToken;

  /// Optional navigation / deep-link hook when user taps a notification.
  static void Function(RemoteMessage message)? onNotificationOpened;

  /// Optional UI hook for foreground messages (e.g. SnackBar).
  static void Function(RemoteMessage message)? onForegroundMessage;

  static StreamSubscription<String>? _tokenRefreshSub;
  static StreamSubscription<RemoteMessage>? _foregroundSub;
  static StreamSubscription<RemoteMessage>? _openedSub;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    if (Firebase.apps.isEmpty) {
      developer.log(
        'Skipping FCM setup — Firebase is not initialized.',
        name: 'FirebaseMessagingService',
      );
      return;
    }

    _initialized = true;

    await _requestPermission();
    await _configureForegroundPresentation();
    _listenForTokenRefresh();
    _listenForForegroundMessages();
    await _listenForNotificationOpens();
    await refreshAndSyncToken();
  }

  /// Re-fetch token and push it to [onToken] (call after login / DI ready).
  static Future<void> refreshAndSyncToken() async {
    try {
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        // On iOS, FCM token requires APNs token first.
        final apnsToken = await _messaging.getAPNSToken();
        developer.log(
          'APNs token available: ${apnsToken != null}',
          name: 'FirebaseMessagingService',
        );
        if (apnsToken == null) {
          developer.log(
            'Skipping FCM getToken until APNs is ready '
            '(Simulator without APNs, or missing APNs key in Firebase).',
            name: 'FirebaseMessagingService',
          );
          return;
        }
      }

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;

      currentToken = token;
      developer.log('FCM token: $token', name: 'FirebaseMessagingService');
      await _emitToken(token);
    } catch (error, stackTrace) {
      developer.log(
        'FCM getToken failed: $error',
        name: 'FirebaseMessagingService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> _emitToken(String token) async {
    final saver = onToken;
    if (saver == null) return;
    try {
      await saver(token);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to persist FCM token: $error',
        name: 'FirebaseMessagingService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    developer.log(
      'Notification permission: ${settings.authorizationStatus.name}',
      name: 'FirebaseMessagingService',
    );
  }

  /// Shows system banners while app is in foreground on Apple platforms.
  static Future<void> _configureForegroundPresentation() async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isMacOS)) return;

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static void _listenForTokenRefresh() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) async {
      currentToken = token;
      developer.log(
        'FCM token refreshed: $token',
        name: 'FirebaseMessagingService',
      );
      await _emitToken(token);
    });
  }

  static void _listenForForegroundMessages() {
    _foregroundSub?.cancel();
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      developer.log(
        'Foreground push: id=${message.messageId} '
        'title=${message.notification?.title}',
        name: 'FirebaseMessagingService',
      );
      // Android: no system tray while foreground — UI layer shows SnackBar.
      // iOS: setForegroundNotificationPresentationOptions shows the banner.
      onForegroundMessage?.call(message);
    });
  }

  static Future<void> _listenForNotificationOpens() async {
    try {
      // Terminated → opened via notification tap.
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        _handleOpened(initial);
      }

      _openedSub?.cancel();
      _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to attach open listeners: $error',
        name: 'FirebaseMessagingService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static void _handleOpened(RemoteMessage message) {
    developer.log(
      'Notification opened: id=${message.messageId} data=${message.data}',
      name: 'FirebaseMessagingService',
    );
    onNotificationOpened?.call(message);
  }

  /// Clears local token reference on sign-out (optional server clear via repo).
  static Future<void> clearLocalToken() async {
    currentToken = null;
  }

  static Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    _tokenRefreshSub = null;
    _foregroundSub = null;
    _openedSub = null;
    _initialized = false;
  }
}

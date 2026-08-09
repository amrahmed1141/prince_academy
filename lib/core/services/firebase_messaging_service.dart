import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Dedicated channel for foreground local notifications.
  /// Keep separate from the FCM default channel to avoid stale channel settings.
  static const String androidChannelId = 'prince_academy_foreground_high';

  static const AndroidNotificationChannel _androidForegroundChannel =
      AndroidNotificationChannel(
    androidChannelId,
    'Prince Academy',
    description: 'Bookings, sessions, and payment updates',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Latest known FCM token (null until fetched or if APNs is not ready on iOS).
  static String? currentToken;

  /// Called whenever a usable FCM token is obtained or refreshed.
  static Future<void> Function(String token)? onToken;

  /// Optional UI hook for foreground messages (fallback SnackBar, etc.).
  static void Function(RemoteMessage message)? onForegroundMessage;
  static void Function(Map<String, dynamic> data)? onNotificationDataOpened;

  static void Function(RemoteMessage message)? _onNotificationOpened;
  static RemoteMessage? _pendingOpenedMessage;
  static bool _localNotificationsReady = false;

  /// Optional navigation / deep-link hook when user taps a notification.
  ///
  /// Assigning a non-null handler immediately drains any terminated-state tap
  /// that arrived before [AuthenticatedShell] was mounted.
  static void Function(RemoteMessage message)? get onNotificationOpened =>
      _onNotificationOpened;

  static set onNotificationOpened(
    void Function(RemoteMessage message)? handler,
  ) {
    _onNotificationOpened = handler;
    final pending = _pendingOpenedMessage;
    if (handler != null && pending != null) {
      _pendingOpenedMessage = null;
      handler(pending);
    }
  }

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

    try {
      await _requestPermission();
      // Never block FCM listeners on local-notification setup failures.
      await _initializeLocalNotifications();
      await _configureForegroundPresentation();
      _listenForTokenRefresh();
      _listenForForegroundMessages();
      await _listenForNotificationOpens();
      await refreshAndSyncToken();
      _initialized = true;
    } catch (error, stackTrace) {
      _initialized = false;
      developer.log(
        'FCM initialize failed: $error',
        name: 'FirebaseMessagingService',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
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
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) async {
      developer.log(
        'Foreground push: id=${message.messageId} '
        'title=${message.notification?.title} '
        'data=${message.data}',
        name: 'FirebaseMessagingService',
      );
      // Android does not show FCM banners while app is foregrounded.
      // Always post a local heads-up notification first.
      final posted = await showForegroundNotification(message);
      if (!posted) {
        // Keep in-app UX resilient when local-notification posting fails.
        onForegroundMessage?.call(message);
      }
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
    _emitOpenedData(message.data);
    final handler = _onNotificationOpened;
    if (handler == null) {
      // Cold start: shell has not bound yet — replay when it does.
      _pendingOpenedMessage = message;
      return;
    }
    handler(message);
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
    _pendingOpenedMessage = null;
    _onNotificationOpened = null;
    onNotificationDataOpened = null;
    _localNotificationsReady = false;
    _initialized = false;
  }

  static Future<void> _initializeLocalNotifications() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final android = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // Android 13+ runtime permission for local banners.
      await android?.requestNotificationsPermission();
      await android?.createNotificationChannel(_androidForegroundChannel);

      // defaultIcon MUST be a drawable (not mipmap).
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_notification'),
      );
      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload == null || payload.isEmpty) return;
          try {
            final decoded = jsonDecode(payload);
            if (decoded is Map) {
              _emitOpenedData(Map<String, dynamic>.from(decoded));
            }
          } catch (_) {
            // Keep tap handling resilient when payload is malformed.
          }
        },
      );
      _localNotificationsReady = true;
      developer.log(
        'Local notifications ready (channel=$androidChannelId)',
        name: 'FirebaseMessagingService',
      );
    } catch (error, stackTrace) {
      _localNotificationsReady = false;
      developer.log(
        'Local notifications init failed (SnackBar fallback): $error',
        name: 'FirebaseMessagingService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Shows an Android heads-up notification while the app is in foreground.
  /// Returns `true` when a banner was posted successfully.
  static Future<bool> showForegroundNotification(RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Prince Academy';
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';
    return showLocalBanner(
      title: title,
      body: body,
      data: message.data,
      id: message.messageId?.hashCode ?? message.hashCode,
    );
  }

  /// Posts a local heads-up banner (Android). Used for FCM foreground messages
  /// and realtime in-app notification inserts while the app is open.
  static Future<bool> showLocalBanner({
    required String title,
    String? body,
    Map<String, dynamic>? data,
    int? id,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (!_localNotificationsReady) {
      await _initializeLocalNotifications();
      if (!_localNotificationsReady) return false;
    }

    try {
      final dataPayload = jsonEncode(data ?? const <String, dynamic>{});

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          'Prince Academy',
          channelDescription: 'Bookings, sessions, and payment updates',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_stat_notification',
          // App logo shown in expanded / heads-up presentation.
          largeIcon: DrawableResourceAndroidBitmap('notification_logo'),
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.message,
        ),
      );

      await _localNotifications.show(
        id ?? title.hashCode ^ (body?.hashCode ?? 0),
        title,
        body ?? '',
        details,
        payload: dataPayload,
      );
      return true;
    } catch (error, stackTrace) {
      developer.log(
        'showLocalBanner failed: $error',
        name: 'FirebaseMessagingService',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  static void _emitOpenedData(Map<String, dynamic> data) {
    onNotificationDataOpened?.call(data);
  }
}
